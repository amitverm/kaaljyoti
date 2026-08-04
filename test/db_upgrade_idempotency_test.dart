/// The local (on-device) schema upgrade must be safe to run twice.
///
/// SQLite has no `ADD COLUMN IF NOT EXISTS` and sqflite's onUpgrade is
/// not reliably atomic, so a step that lands before a later step throws
/// stays applied while user_version is left behind. The next launch
/// re-runs the upgrade, hits "duplicate column name: labels", and the
/// app can never open its database again — a brick that reinstalling
/// does NOT clear, because the database file outlives the app.
///
/// Runs against sqflite_common_ffi (plain sqlite3), like db_recovery_test.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/db.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _ffiOpener(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) =>
    databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      ),
    );

/// The kundlis table as v7 shipped it — no `labels`.
const _v7Kundlis = '''
  CREATE TABLE kundlis (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    relation_tag TEXT NOT NULL DEFAULT 'Self',
    note TEXT,
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
''';

/// The per-kundli export table as v4–v8 shipped it, dropped by v9.
const _v8ExportConfigs = '''
  CREATE TABLE export_configs (
    kundli_id TEXT PRIMARY KEY,
    blocks TEXT NOT NULL,
    paper TEXT NOT NULL DEFAULT 'a4',
    cover_page INTEGER NOT NULL DEFAULT 1,
    branding TEXT NOT NULL DEFAULT ''
  )
''';

Map<String, Object?> _row(String id) => {
      'id': id,
      'name': 'Ramesh Sharma',
      'relation_tag': 'Client',
      'birth_utc': 542534520000,
      'lat': 18.52,
      'lon': 73.86,
      'tz_name': 'Asia/Kolkata',
      'utc_offset_min': 330,
      'place_name': 'Pune',
      'is_prashna': 0,
      'is_ephemeral': 0,
      'sync_enabled': 0,
      'created_at': 0,
      'updated_at': 0,
    };

void main() {
  sqfliteFfiInit();

  late Directory dir;
  late String dbPath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kaaljyoti_upgrade_test');
    dbPath = '${dir.path}/kaaljyoti.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  AppDb newDb() => AppDb.forTest(
      path: dbPath, opener: _ffiOpener, passphrase: 'test-passphrase');

  /// Lays down a database at [version] with the v7 kundlis shape, then
  /// optionally applies [extra] — used to simulate a half-applied
  /// upgrade, where a column landed but user_version never moved.
  ///
  /// Below v5 the fixture also carries the PER-KUNDLI dashboard tables,
  /// because the v2 and v5 steps read them; a kundlis-only stub would
  /// fail for reasons that have nothing to do with what's under test.
  Future<void> seed(int version, {List<String> extra = const []}) async {
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, _) async {
          await db.execute(_v7Kundlis);
          if (version < 5) {
            await db.execute('''
              CREATE TABLE dashboard_views (
                id TEXT PRIMARY KEY,
                kundli_id TEXT NOT NULL,
                name TEXT NOT NULL,
                position INTEGER NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE view_widgets (
                instance_id TEXT PRIMARY KEY,
                view_id TEXT NOT NULL,
                widget_id TEXT NOT NULL,
                position INTEGER NOT NULL,
                span TEXT NOT NULL DEFAULT 'half',
                config TEXT NOT NULL DEFAULT '{}'
              )
            ''');
            await db.insert('dashboard_views', {
              'id': 'v1',
              'kundli_id': 'existing',
              'name': 'Overview',
              'position': 0,
            });
            await db.insert('view_widgets', {
              'instance_id': 'v1_birth_chart_0',
              'view_id': 'v1',
              'widget_id': 'birth_chart',
              'position': 0,
              'span': 'half',
              'config': '{}',
            });
          }
        },
      ),
    );
    await db.insert('kundlis', _row('existing'));
    for (final sql in extra) {
      await db.execute(sql);
    }
    await db.close();
  }

  test('a clean v7 database upgrades to the current version', () async {
    await seed(7);
    final appDb = newDb();
    final db = await appDb.database;

    final rows = await db.query('kundlis');
    expect(rows, hasLength(1));
    expect(Kundli.fromRow(rows.single).labels, isEmpty);
    await appDb.close();
  });

  test('a half-applied v8 upgrade recovers instead of bricking', () async {
    // The reported device state: `labels` already added by an upgrade
    // that then aborted, so user_version is still 7. Before the fix this
    // threw "duplicate column name: labels" on EVERY launch, forever.
    await seed(7, extra: ['ALTER TABLE kundlis ADD COLUMN labels TEXT']);

    final appDb = newDb();
    final db = await appDb.database;

    final rows = await db.query('kundlis');
    expect(rows, hasLength(1), reason: 'the kundli must survive');
    expect(await db.getVersion(), 11);
    await appDb.close();
  });

  test('a half-applied v9 upgrade recovers instead of bricking', () async {
    // export_template created by an upgrade that then aborted before
    // dropping export_configs, so user_version is still 8. Re-running
    // must not trip over the table that is already there.
    await seed(8, extra: [
      'ALTER TABLE kundlis ADD COLUMN labels TEXT',
      _v8ExportConfigs,
      '''CREATE TABLE export_template (
           id INTEGER PRIMARY KEY CHECK (id = 1),
           blocks TEXT NOT NULL,
           paper TEXT NOT NULL DEFAULT 'a4',
           cover_page INTEGER NOT NULL DEFAULT 1,
           branding TEXT NOT NULL DEFAULT ''
         )''',
    ]);

    final appDb = newDb();
    final db = await appDb.database;
    expect(await db.getVersion(), 11);
    expect(await db.query('kundlis'), hasLength(1));
    await appDb.close();
  });

  test('a half-applied upgrade keeps data already in the new column', () async {
    await seed(7, extra: [
      'ALTER TABLE kundlis ADD COLUMN labels TEXT',
      '''UPDATE kundlis SET labels = '["2026 clients"]' ''',
    ]);

    final appDb = newDb();
    final k =
        Kundli.fromRow((await (await appDb.database).query('kundlis')).single);
    expect(k.labels, ['2026 clients'],
        reason: 'recovery must not wipe the column it is repairing');
    await appDb.close();
  });

  test('an old v3 database upgrades all the way without tripping', () async {
    // v4 used to run AFTER v8. From v3 that meant applying v8's ALTER
    // first and only then v4's CREATE TABLE — the ordering that made a
    // failure mid-upgrade unrecoverable.
    await seed(3);
    final appDb = newDb();
    final db = await appDb.database;

    expect(await db.getVersion(), 11);
    final columns = await db.rawQuery('PRAGMA table_info(kundlis)');
    final names = columns.map((c) => c['name']).toSet();
    expect(names,
        containsAll(['labels', 'note', 'is_ephemeral', 'is_archived']));
    // Every table the later versions introduce is present exactly once.
    for (final table in [
      'export_template',
      'kundli_events',
      'journal_entries'
    ]) {
      final found = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table]);
      expect(found, hasLength(1), reason: table);
    }
    // v4 creates export_configs on the way through; v9 must remove it
    // again rather than leave two competing report tables behind.
    expect(
      await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' "
          "AND name='export_configs'"),
      isEmpty,
    );
    await appDb.close();
  });

  test('a v3 database whose export_configs already exists still upgrades',
      () async {
    // The trigger for the original brick: v4's CREATE TABLE throwing
    // after v8's ALTER had already landed.
    await seed(3, extra: [_v8ExportConfigs]);

    final appDb = newDb();
    final db = await appDb.database;
    expect(await db.getVersion(), 11);
    expect(await db.query('kundlis'), hasLength(1));
    await appDb.close();
  });

  test('v9 → v10 adds journal_entries with its index', () async {
    await seed(9, extra: [
      'ALTER TABLE kundlis ADD COLUMN labels TEXT',
      '''CREATE TABLE export_template (
           id INTEGER PRIMARY KEY CHECK (id = 1),
           blocks TEXT NOT NULL,
           paper TEXT NOT NULL DEFAULT 'a4',
           cover_page INTEGER NOT NULL DEFAULT 1,
           branding TEXT NOT NULL DEFAULT ''
         )''',
    ]);

    final appDb = newDb();
    final db = await appDb.database;
    expect(await db.getVersion(), 11);

    final columns = await db.rawQuery('PRAGMA table_info(journal_entries)');
    expect(
      columns.map((c) => c['name']),
      containsAll(
          ['id', 'kundli_id', 'at', 'text', 'context_json', 'updated_at']),
    );
    expect(
      await db.rawQuery("SELECT name FROM sqlite_master WHERE type='index' "
          "AND name='idx_journal_entries_kundli'"),
      hasLength(1),
    );

    // The FK must actually cascade — foreign_keys is ON via onConfigure,
    // and a journal that outlives its kundli would resurface under a
    // recycled id.
    await db.insert('journal_entries', {
      'id': 'j1',
      'kundli_id': 'existing',
      'at': 1700000000000,
      'text': 'first consultation',
      'created_at': 0,
      'updated_at': 0,
    });
    await db.delete('kundlis', where: 'id = ?', whereArgs: ['existing']);
    expect(await db.query('journal_entries'), isEmpty);
    await appDb.close();
  });

  test('a half-applied v10 upgrade recovers instead of bricking', () async {
    // journal_entries created by an upgrade that then aborted, so
    // user_version is still 9. Re-running must not trip over the table
    // (or the index) that is already there.
    await seed(9, extra: [
      'ALTER TABLE kundlis ADD COLUMN labels TEXT',
      '''CREATE TABLE journal_entries (
           id TEXT PRIMARY KEY,
           kundli_id TEXT NOT NULL REFERENCES kundlis(id) ON DELETE CASCADE,
           at INTEGER NOT NULL,
           text TEXT NOT NULL,
           context_json TEXT,
           created_at INTEGER NOT NULL,
           updated_at INTEGER NOT NULL
         )''',
      'CREATE INDEX idx_journal_entries_kundli ON journal_entries(kundli_id)',
      '''INSERT INTO journal_entries (id, kundli_id, at, text, created_at,
           updated_at)
         VALUES ('j1', 'existing', 1700000000000, 'kept', 0, 0)''',
    ]);

    final appDb = newDb();
    final db = await appDb.database;
    expect(await db.getVersion(), 11);
    expect(await db.query('journal_entries'), hasLength(1),
        reason: 'recovery must not wipe entries already written');
    await appDb.close();
  });

  test('v10 → v11 adds is_archived, defaulted off for existing rows',
      () async {
    await seed(10, extra: [
      'ALTER TABLE kundlis ADD COLUMN labels TEXT',
    ]);

    final appDb = newDb();
    final db = await appDb.database;
    expect(await db.getVersion(), 11);

    final columns = await db.rawQuery('PRAGMA table_info(kundlis)');
    expect(columns.map((c) => c['name']), contains('is_archived'));
    // A chart that existed before archiving did must not come back
    // hidden from its owner.
    expect(Kundli.fromRow((await db.query('kundlis')).single).isArchived,
        isFalse);
    await appDb.close();
  });

  test('a half-applied v11 upgrade recovers instead of bricking', () async {
    // is_archived already added by an upgrade that then aborted, so
    // user_version is still 10. Re-running must not hit "duplicate
    // column name" — the failure mode that bricks the app for good.
    await seed(10, extra: [
      'ALTER TABLE kundlis ADD COLUMN labels TEXT',
      'ALTER TABLE kundlis ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
      'UPDATE kundlis SET is_archived = 1',
    ]);

    final appDb = newDb();
    final db = await appDb.database;
    expect(await db.getVersion(), 11);
    expect(Kundli.fromRow((await db.query('kundlis')).single).isArchived,
        isTrue,
        reason: 'recovery must not wipe the column it is repairing');
    await appDb.close();
  });

  test('reopening an upgraded database is a no-op', () async {
    await seed(7);
    final first = newDb();
    await first.database;
    await first.close();

    final second = newDb();
    final db = await second.database;
    expect(await db.getVersion(), 11);
    expect(await db.query('kundlis'), hasLength(1));
    await second.close();
  });
}
