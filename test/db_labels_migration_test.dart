/// Label persistence, end to end: the v7 → v8 migration that adds the
/// `labels` column, and the repository writes that fill it. Every
/// existing user is on v7 or earlier, so that migration runs on their
/// first launch after the update — an untested ALTER here bricks the app
/// on open.
///
/// Runs against sqflite_common_ffi (plain sqlite3), like db_recovery_test.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/db.dart';
import 'package:kaaljyoti/data/kundli_repository.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// The kundlis table exactly as v7 shipped it — no `labels`.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late String dbPath;

  setUp(() {
    // KundliRepository writes the creation counter through prefs.
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('kaaljyoti_labels_test');
    dbPath = '${dir.path}/kaaljyoti.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Lays down a v7 database holding one kundli, then closes it.
  Future<void> seedV7() async {
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: (db, _) async {
          await db.execute(_v7Kundlis);
        },
      ),
    );
    await db.insert('kundlis', {
      'id': 'existing',
      'name': 'Ramesh Sharma',
      'relation_tag': 'Client',
      'note': 'career reading',
      'birth_utc': 542534520000,
      'lat': 18.52,
      'lon': 73.86,
      'tz_name': 'Asia/Kolkata',
      'utc_offset_min': 330,
      'place_name': 'Pune, India',
      'is_prashna': 0,
      'is_ephemeral': 0,
      'sync_enabled': 1,
      'created_at': 0,
      'updated_at': 0,
    });
    await db.close();
  }

  test('upgrading a v7 database keeps existing kundlis and adds labels',
      () async {
    await seedV7();

    final appDb = AppDb.forTest(
        path: dbPath, opener: _ffiOpener, passphrase: 'test-passphrase');
    final db = await appDb.database;

    final rows = await db.query('kundlis');
    expect(rows, hasLength(1), reason: 'the migration must not drop rows');

    final k = Kundli.fromRow(rows.single);
    expect(k.name, 'Ramesh Sharma');
    expect(k.note, 'career reading');
    expect(k.syncEnabled, isTrue);
    // A pre-v8 row has no labels column value at all — that must read
    // as "no labels", not as a crash.
    expect(k.labels, isEmpty);

    await appDb.close();
  });

  test('labels written after the upgrade round-trip through the column',
      () async {
    await seedV7();

    final appDb = AppDb.forTest(
        path: dbPath, opener: _ffiOpener, passphrase: 'test-passphrase');
    final db = await appDb.database;

    final before = Kundli.fromRow((await db.query('kundlis')).single);
    await db.update(
      'kundlis',
      before.copyWith(labels: const ['2026 clients', 'matchmaking']).toRow(),
      where: 'id = ?',
      whereArgs: [before.id],
    );

    final after = Kundli.fromRow((await db.query('kundlis')).single);
    expect(after.labels, ['2026 clients', 'matchmaking']);

    await appDb.close();
  });

  test('a fresh database has the labels column from onCreate', () async {
    // onCreate and onUpgrade define the schema separately, so they drift
    // silently unless both are exercised.
    final appDb = AppDb.forTest(
        path: dbPath, opener: _ffiOpener, passphrase: 'test-passphrase');
    final db = await appDb.database;

    final columns = await db.rawQuery('PRAGMA table_info(kundlis)');
    expect(columns.map((c) => c['name']), contains('labels'));

    await appDb.close();
  });

  group('create() writes labels', () {
    late AppDb appDb;
    late KundliRepository repo;

    setUp(() {
      appDb = AppDb.forTest(
          path: dbPath, opener: _ffiOpener, passphrase: 'test-passphrase');
      repo = KundliRepository(db: appDb);
    });

    tearDown(() => appDb.close());

    Future<Kundli> make({List<String> labels = const []}) => repo.create(
          name: 'Ramesh Sharma',
          relationTag: 'Client',
          labels: labels,
          birthUtc: DateTime.utc(1987, 3, 14, 6, 42),
          latitude: 18.52,
          longitude: 73.86,
          timezoneName: 'Asia/Kolkata',
          utcOffsetMinutes: 330,
          placeName: 'Pune',
        );

    test('the labels chosen at cast time reach the stored row', () async {
      // The create screen's chips are worth nothing if the selection is
      // dropped between the form and the row.
      final created = await make(labels: const ['2026 clients', 'matchmaking']);
      expect(created.labels, ['2026 clients', 'matchmaking']);

      final stored = await repo.byId(created.id);
      expect(stored!.labels, ['2026 clients', 'matchmaking']);
      expect((await repo.saved()).single.labels,
          ['2026 clients', 'matchmaking']);
    });

    test('creating without labels stores none', () async {
      final created = await make();
      expect(created.labels, isEmpty);
      expect((await repo.byId(created.id))!.labels, isEmpty);
    });
  });

  test('onCreate and onUpgrade agree on the child tables', () async {
    // The same drift risk, one level up: a table added to onCreate but not
    // to the migration (or the reverse) only shows up on the device that
    // took the other path.
    Future<Set<String>> tablesOf(String path) async {
      final appDb = AppDb.forTest(
          path: path, opener: _ffiOpener, passphrase: 'test-passphrase');
      final db = await appDb.database;
      final rows = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'");
      final names = {for (final r in rows) r['name'] as String};
      await appDb.close();
      return names;
    }

    // Seeded at v6 — below every version that introduces a child table,
    // so the upgrade path has to create all of them (a v7 fixture would
    // already carry kundli_events, hiding half the comparison).
    final legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
          version: 6, onCreate: (db, _) async => db.execute(_v7Kundlis)),
    );
    await legacy.close();

    final fresh = await tablesOf('${dir.path}/fresh.db');
    final upgraded = await tablesOf(dbPath);

    for (final table in ['kundli_events', 'journal_entries']) {
      expect(fresh, contains(table), reason: '$table missing from onCreate');
      expect(upgraded, contains(table), reason: '$table missing from upgrade');
    }
  });
}
