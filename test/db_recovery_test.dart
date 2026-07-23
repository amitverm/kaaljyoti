/// AppDb must self-heal when the local DB can't be opened with our key —
/// the Android Auto Backup restore scenario (KAALJYOTI-PROD-E): the DB file
/// travels to the new device but the Keystore-held SQLCipher passphrase
/// doesn't, so every open fails and the app was permanently bricked.
///
/// Runs against sqflite_common_ffi (plain sqlite3): opening a garbage file
/// fails with SQLITE_NOTADB exactly like SQLCipher does on a wrong key.
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

  Map<String, Object?> kundliRow(String id) => {
        'id': id,
        'name': 'Test',
        'birth_utc': 0,
        'lat': 28.6,
        'lon': 77.2,
        'tz_name': 'Asia/Kolkata',
        'utc_offset_min': 330,
        'place_name': 'Delhi',
        'created_at': 0,
        'updated_at': 0,
      };

  test('recovers from an undecryptable DB file by quarantining it', () async {
    // A restored-from-backup DB whose key we don't have is, to sqlite,
    // just a file that is not a database.
    final garbage = List.generate(4096, (i) => (i * 31 + 7) & 0xff);
    File(dbPath).writeAsBytesSync(garbage);
    // Stale sidecar files must not survive into the fresh DB.
    File('$dbPath-wal').writeAsBytesSync([1, 2, 3]);

    final appDb = newDb();
    final db = await appDb.database;

    // Usable, empty DB with the full schema.
    expect(await db.query('kundlis'), isEmpty);
    await db.insert('kundlis', kundliRow('k1'));
    expect((await db.query('kundlis')).single['id'], 'k1');

    // The unreadable original was kept for forensics, sidecars dropped.
    expect(File('$dbPath.quarantined').readAsBytesSync(), garbage);
    expect(File('$dbPath-wal').existsSync(), isFalse);
    await appDb.close();
  });

  test('a healthy DB opens normally — data intact, nothing quarantined',
      () async {
    final first = newDb();
    await (await first.database).insert('kundlis', kundliRow('keep-me'));
    await first.close();

    final second = newDb();
    final rows = await (await second.database).query('kundlis');
    expect(rows.single['id'], 'keep-me');
    expect(File('$dbPath.quarantined').existsSync(), isFalse);
    await second.close();
  });

  test('recovery replaces an existing quarantine generation', () async {
    File(dbPath).writeAsBytesSync([1, 2, 3]);
    File('$dbPath.quarantined').writeAsBytesSync([9, 9, 9]);

    final appDb = newDb();
    await appDb.database;

    expect(File('$dbPath.quarantined').readAsBytesSync(), [1, 2, 3]);
    await appDb.close();
  });
}
