/// AppDb.checkpoint() flushes the WAL into the main DB file so kaaljyoti.db
/// alone holds every committed write — the insurance against app-update
/// container migrations and backups that copy the main file without its
/// -wal sidecar (the simulator dashboard-config revert; same bug class as
/// KAALJYOTI-PROD-E's backup rules, which exclude -wal).
///
/// Runs against sqflite_common_ffi (plain sqlite3). FFI databases open in
/// rollback-journal mode by default, so the WAL test switches the journal
/// mode explicitly.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/db.dart';
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

void main() {
  sqfliteFfiInit();

  late Directory dir;
  late String dbPath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kaaljyoti_db_test');
    dbPath = '${dir.path}/kaaljyoti.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  AppDb newDb() => AppDb.forTest(
        path: dbPath,
        opener: _ffiOpener,
        passphrase: 'test-passphrase',
      );

  test('checkpoint() empties the WAL of an open DB into the main file',
      () async {
    final appDb = newDb();
    final db = await appDb.database;
    await db.rawQuery('PRAGMA journal_mode = WAL');
    await db.insert('dashboard_views', {
      'id': 'v1',
      'name': 'Main',
      'position': 0,
    });
    // The committed write lives in the sidecar — exactly the state a
    // container migration that drops -wal would lose.
    expect(File('$dbPath-wal').lengthSync(), greaterThan(0));

    await appDb.checkpoint();

    expect(File('$dbPath-wal').lengthSync(), 0);
    expect((await db.query('dashboard_views')).single['id'], 'v1');
    await appDb.close();
  });

  test('checkpoint() is a no-op when the DB was never opened', () async {
    await newDb().checkpoint();
  });

  test('checkpoint() is a no-op after close()', () async {
    final appDb = newDb();
    await appDb.database;
    await appDb.close();
    await appDb.checkpoint();
  });
}
