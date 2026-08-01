/// Encrypted local database (SQLCipher). Offline-first: personal
/// kundlis never leave the device unless the user opts into sync.
/// The passphrase is generated once and held in the platform keystore
/// via flutter_secure_storage.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../services/key_backup_service.dart';

/// Signature of the low-level open call. Production uses SQLCipher's
/// [openDatabase]; tests substitute an FFI factory (the plugin doesn't
/// exist on the host VM).
typedef DbOpener = Future<Database> Function(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
});

Future<Database> _sqlCipherOpener(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) =>
    openDatabase(
      path,
      password: password,
      version: version,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );

class AppDb {
  AppDb._()
      : _opener = _sqlCipherOpener,
        _fixedPath = null,
        _passphraseOverride = null;
  static final AppDb instance = AppDb._();

  /// Unit tests run on the host VM, where neither path_provider nor the
  /// SQLCipher plugin exist — they inject a path, an FFI opener and a
  /// fixed passphrase instead.
  @visibleForTesting
  AppDb.forTest({
    required String path,
    required DbOpener opener,
    required String passphrase,
  })  : _opener = opener,
        _fixedPath = path,
        _passphraseOverride = passphrase;

  static const _keyName = 'te_db_passphrase_v1';
  static const _kBlockStoreDone = 'db_key_in_blockstore_v1';
  final DbOpener _opener;
  final String? _fixedPath;
  final String? _passphraseOverride;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    // Startup hygiene: Prashna kundlis the user never chose to keep
    // don't survive an app restart.
    await _db!.delete('kundlis', where: 'is_ephemeral = 1');
    return _db!;
  }

  /// Key lookup order: secure storage (Keystore/Keychain) → Block Store
  /// (the copy a previous device backed up) → generate new. Whatever wins
  /// is written back to both stores, so the key is always device-local
  /// AND rides to the user's next device.
  Future<String> _passphrase() async {
    if (_passphraseOverride != null) return _passphraseOverride;
    const storage = FlutterSecureStorage();
    String? pass;
    try {
      pass = await storage.read(key: _keyName);
    } catch (_) {
      // A restored-from-backup prefs file can hold ciphertext the new
      // device's Keystore can't decrypt — treat as absent, same as null.
      pass = null;
    }
    if (pass != null) {
      await _ensureKeyInBlockStore(pass);
      return pass;
    }
    // Empty Keystore but possibly a restored DB: Block Store may hold the
    // key from the previous device — the case that used to brick the app.
    pass = await KeyBackupService().read();
    final prefs = await SharedPreferences.getInstance();
    if (pass != null) {
      await storage.write(key: _keyName, value: pass);
      await prefs.setBool(_kBlockStoreDone, true);
      return pass;
    }
    final rng = Random.secure();
    pass = List.generate(32, (_) => rng.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await storage.write(key: _keyName, value: pass);
    // Unconditional write, NOT _ensureKeyInBlockStore: restored prefs can
    // carry the done-flag from the old device, and this key is brand new.
    await prefs.setBool(_kBlockStoreDone, await KeyBackupService().write(pass));
    return pass;
  }

  /// Push the key to Block Store once per install (flag set only on a
  /// successful write, so no-lockscreen / no-Play-Services devices retry
  /// on later launches). Existing installs migrate here on their next
  /// launch — their key predates Block Store support.
  Future<void> _ensureKeyInBlockStore(String pass) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kBlockStoreDone) ?? false) return;
    if (await KeyBackupService().write(pass)) {
      await prefs.setBool(_kBlockStoreDone, true);
    }
  }

  Future<Database> _open() async {
    final path = _fixedPath ??
        p.join((await getApplicationDocumentsDirectory()).path, 'kaaljyoti.db');
    final pass = await _passphrase();
    try {
      return await _openAt(path, pass);
    } on DatabaseException catch (e, stack) {
      if (!_isUndecryptable(e)) rethrow;
      // The DB exists but can't be opened with our key. The known cause:
      // Android Auto Backup restored kaaljyoti.db to a new device, but the
      // SQLCipher passphrase lives in the Keystore, which never leaves the
      // old device — every launch then died here (KAALJYOTI-PROD-E) and
      // the app was permanently bricked. Quarantine the file and start
      // fresh; signed-in users get their synced kundlis back via pullAll.
      _quarantine(path);
      // Countable in Sentry (no-op in DSN-less AGPL builds).
      await Sentry.captureMessage(
        'Local DB undecryptable — quarantined and recreated '
        '(backup-restored without key?): $e',
        level: SentryLevel.warning,
        withScope: (scope) => scope.setContexts('db_recovery', {
          'error': '$e',
          'stack': '$stack',
        }),
      );
      return _openAt(path, pass);
    }
  }

  /// True for the failure modes of "this file cannot be read with this
  /// key" (wrong SQLCipher key / not a database). Deliberately narrow:
  /// transient errors (locked, disk full…) must NOT wipe user data.
  bool _isUndecryptable(DatabaseException e) =>
      e.isOpenFailedError() ||
      e.toString().contains('not a database') ||
      e.getResultCode() == 26 /* SQLITE_NOTADB */;

  /// Move the unreadable DB aside (keeping one generation for forensics)
  /// and drop journal/WAL leftovers so the fresh DB starts clean.
  void _quarantine(String path) {
    final db = File(path);
    if (db.existsSync()) {
      final quarantined = File('$path.quarantined');
      if (quarantined.existsSync()) quarantined.deleteSync();
      db.renameSync(quarantined.path);
    }
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final f = File('$path$suffix');
      if (f.existsSync()) f.deleteSync();
    }
  }

  Future<Database> _openAt(String path, String password) {
    return _opener(
      path,
      password: password,
      version: 10,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // v2: instance-based widget placement — allows duplicates of
          // the same module and per-instance span. Old rows migrate
          // with generated instance ids; 'navamsa' widgets become
          // configurable 'divisional' widgets pinned to D9.
          await db.execute('''
            CREATE TABLE view_widgets_v2 (
              instance_id TEXT PRIMARY KEY,
              view_id TEXT NOT NULL REFERENCES dashboard_views(id) ON DELETE CASCADE,
              widget_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              span TEXT NOT NULL DEFAULT 'half',
              config TEXT NOT NULL DEFAULT '{}'
            )
          ''');
          final old = await db.query('view_widgets');
          for (final row in old) {
            final widgetId = row['widget_id'] as String;
            final isNavamsa = widgetId == 'navamsa';
            final isWide = const {'birth_chart', 'dasha', 'planetary_positions'}
                .contains(widgetId);
            await db.insert('view_widgets_v2', {
              'instance_id': '${row['view_id']}_${widgetId}_${row['position']}',
              'view_id': row['view_id'],
              'widget_id': isNavamsa ? 'divisional' : widgetId,
              'position': row['position'],
              'span': isWide ? 'full' : 'half',
              'config': isNavamsa ? '{"varga":"d9"}' : row['config'],
            });
          }
          await db.execute('DROP TABLE view_widgets');
          await db
              .execute('ALTER TABLE view_widgets_v2 RENAME TO view_widgets');
        }
        if (oldVersion < 3) {
          // v3: instant Prashna kundlis are created immediately and
          // marked ephemeral until the user keeps them.
          await _addColumnIfMissing(
              db, 'kundlis', 'is_ephemeral', 'INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 5 && oldVersion >= 1) {
          // v5: dashboard layouts become GLOBAL (a layout is a lens,
          // the kundli is the data) — a professional shouldn't re-
          // arrange widgets for every client. Keep the view set of the
          // most-customized kundli as the global set.
          await db.execute('''
            CREATE TABLE dashboard_views_v2 (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              position INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO dashboard_views_v2 (id, name, position)
            SELECT id, name, position FROM dashboard_views
            WHERE kundli_id = (
              SELECT dv.kundli_id FROM dashboard_views dv
              LEFT JOIN view_widgets vw ON vw.view_id = dv.id
              GROUP BY dv.kundli_id
              ORDER BY COUNT(vw.instance_id) DESC LIMIT 1
            )
          ''');
          await db.execute('DELETE FROM view_widgets WHERE view_id NOT IN '
              '(SELECT id FROM dashboard_views_v2)');
          await db.execute('DROP TABLE dashboard_views');
          await db.execute(
              'ALTER TABLE dashboard_views_v2 RENAME TO dashboard_views');
        }
        // v4 runs HERE, in version order. It used to sit after the v8
        // block, which is how this whole path became a trap: a device
        // upgrading from v3 or earlier applied v8's ALTER first and only
        // then tried v4's CREATE TABLE. If that CREATE failed, the
        // upgrade aborted with user_version never bumped — but the ALTER
        // had already stuck, so every later launch retried it and died
        // on "duplicate column name". A permanent brick, unrecoverable
        // by reinstalling, because the database outlives the app.
        if (oldVersion < 4) {
          // v4: the PDF report composition lives separately from the
          // dashboard — what a jyotish works with is not what they
          // hand to a client.
          await db.execute('''
            CREATE TABLE IF NOT EXISTS export_configs (
              kundli_id TEXT PRIMARY KEY
                REFERENCES kundlis(id) ON DELETE CASCADE,
              blocks TEXT NOT NULL,
              paper TEXT NOT NULL DEFAULT 'a4',
              cover_page INTEGER NOT NULL DEFAULT 1,
              branding TEXT NOT NULL DEFAULT ''
            )
          ''');
        }
        if (oldVersion < 6) {
          // v6: optional free-text note on a kundli — lets the astrologer
          // record who the person is ("Ramesh's daughter — marriage match").
          await _addColumnIfMissing(db, 'kundlis', 'note', 'TEXT');
        }
        if (oldVersion < 7) {
          // v7: life events are first-class per-kundli data (previously they
          // existed only transiently in the Mahakosh contribute form).
          await db.execute(_createKundliEventsSql);
        }
        if (oldVersion < 8) {
          // v8: user-defined labels for grouping a large library — a
          // JSON list on the row, so it rides the existing sync payload.
          await _addColumnIfMissing(db, 'kundlis', 'labels', 'TEXT');
        }
        if (oldVersion < 9) {
          // v9: the report composition becomes GLOBAL, exactly as the
          // dashboard layout did in v5 — deselecting Panchang once should
          // apply to every client's report, not just the kundli that
          // happened to be open. One row replaces the per-kundli table.
          await db.execute(_createExportTemplateSql);
          await _migrateLegacyExportConfigs(db);
        }
        if (oldVersion < 10) {
          // v10: the practitioner's journal — date-stamped observations
          // per kundli, each carrying the astro context of its own date.
          await _createJournalEntries(db);
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE kundlis (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            relation_tag TEXT NOT NULL DEFAULT 'Self',
            note TEXT,
            labels TEXT,
            birth_utc INTEGER NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            tz_name TEXT NOT NULL,
            utc_offset_min INTEGER NOT NULL,
            place_name TEXT NOT NULL,
            ayanamsa_id INTEGER,
            chart_style TEXT DEFAULT 'north',
            is_prashna INTEGER NOT NULL DEFAULT 0,
            is_ephemeral INTEGER NOT NULL DEFAULT 0,
            sync_enabled INTEGER NOT NULL DEFAULT 0,
            mahakosh_code TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(_createKundliEventsSql);
        await _createJournalEntries(db);
        await db.execute('''
          CREATE TABLE dashboard_views (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            position INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE view_widgets (
            instance_id TEXT PRIMARY KEY,
            view_id TEXT NOT NULL REFERENCES dashboard_views(id) ON DELETE CASCADE,
            widget_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            span TEXT NOT NULL DEFAULT 'half',
            config TEXT NOT NULL DEFAULT '{}'
          )
        ''');
        await db.execute('''
          CREATE TABLE mahakosh_bookmarks (
            mk_code TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(_createExportTemplateSql);
      },
    );
  }

  /// Flushes the WAL into the main DB file and truncates it, so
  /// kaaljyoti.db alone holds every committed write. Called on app
  /// backgrounding: an app-update container migration or a backup can
  /// copy the main file without its -wal sidecar (Android backup rules
  /// exclude it, and simctl updates have been observed dropping it —
  /// the dashboard-config revert on the iOS simulator), silently losing
  /// whatever still lived only in the WAL. No-op when the DB isn't open.
  Future<void> checkpoint() async {
    final db = _db;
    if (db == null || !db.isOpen) return;
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// Adds a column only when it isn't already there.
///
/// SQLite has no `ADD COLUMN IF NOT EXISTS`, and sqflite's onUpgrade is
/// not reliably atomic — a step that lands before a later step throws
/// stays applied while user_version is left behind. Re-running the
/// upgrade then hits "duplicate column name" and the app can never open
/// its database again. Reinstalling doesn't help: the database file
/// outlives the app. Every schema step here must therefore be safe to
/// run twice.
Future<void> _addColumnIfMissing(
    Database db, String table, String column, String definition) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  final exists = columns.any((c) => c['name'] == column);
  if (exists) return;
  await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
}

/// The one-row global report template (v9+). `id` is pinned to 1 by the
/// CHECK, so an accidental second row is a database error rather than a
/// silently ignored duplicate. Shared between onCreate and the v9
/// migration so the schema stays identical on both paths.
const _createExportTemplateSql = '''
  CREATE TABLE IF NOT EXISTS export_template (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    blocks TEXT NOT NULL,
    paper TEXT NOT NULL DEFAULT 'a4',
    cover_page INTEGER NOT NULL DEFAULT 1,
    branding TEXT NOT NULL DEFAULT ''
  )
''';

/// Folds the legacy per-kundli `export_configs` into the single global
/// row, then drops the old table.
///
/// There is no principled way to merge N per-kundli compositions into
/// one, so the first row (by kundli_id, for determinism) wins — the same
/// "keep one, discard the rest" call v5 made when dashboard layouts went
/// global. Every migrated block is marked `overridden`: legacy rows
/// recorded no instance link, so they cannot follow a dashboard widget
/// and must keep the config they were saved with.
///
/// Safe to run twice: the insert replaces, and the drop is skipped once
/// the legacy table is gone.
Future<void> _migrateLegacyExportConfigs(Database db) async {
  final legacyTable = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='export_configs'",
  );
  if (legacyTable.isEmpty) return;
  final rows = await db.query('export_configs', orderBy: 'kundli_id ASC');
  if (rows.isNotEmpty) {
    final r = rows.first;
    final decoded = jsonDecode(r['blocks'] as String) as List;
    await db.insert(
      'export_template',
      {
        'id': 1,
        'blocks': jsonEncode([
          for (final b in decoded)
            {
              'widget_id': (b as Map)['widget_id'],
              'instance_id': null,
              'overridden': true,
              'config': b['config'] ?? <String, dynamic>{},
            },
        ]),
        'paper': r['paper'],
        'cover_page': r['cover_page'],
        'branding': r['branding'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await db.execute('DROP TABLE export_configs');
}

/// Per-kundli journal entries (v10+): the practitioner's own date-stamped
/// observations, each with the astro context computed for its entry date
/// frozen into `context_json` (schema-versioned, stable keys — see
/// core/astro/journal_context.dart). Cascade-deletes with the kundli, like
/// [_createKundliEventsSql]. Both statements are idempotent, and this
/// helper is shared between onCreate and the v10 migration so the schema
/// stays identical on both paths.
Future<void> _createJournalEntries(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS journal_entries (
      id TEXT PRIMARY KEY,
      kundli_id TEXT NOT NULL REFERENCES kundlis(id) ON DELETE CASCADE,
      at INTEGER NOT NULL,
      text TEXT NOT NULL,
      context_json TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  // The only query shape is "every entry for this kundli, newest first".
  await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_entries_kundli '
      'ON journal_entries(kundli_id)');
}

/// Per-kundli life events. FK CASCADE means deleting a kundli removes its
/// events automatically (foreign_keys pragma is ON). Shared between onCreate
/// and the v7 migration so the schema stays identical on both paths.
const _createKundliEventsSql = '''
  CREATE TABLE IF NOT EXISTS kundli_events (
    id TEXT PRIMARY KEY,
    kundli_id TEXT NOT NULL REFERENCES kundlis(id) ON DELETE CASCADE,
    category TEXT NOT NULL DEFAULT 'other',
    custom_tag TEXT,
    title TEXT,
    description TEXT,
    event_date INTEGER,
    date_precision TEXT NOT NULL DEFAULT 'exact',
    age_years INTEGER,
    is_health_related INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
''';
