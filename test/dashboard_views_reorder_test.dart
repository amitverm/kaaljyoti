/// Dashboard view chips are drag-reorderable, and their order is GLOBAL
/// (views are shared by every kundli) — so it has to survive in the DB,
/// not in widget state. This pins [DashboardRepository.reorderViews]
/// against the `ORDER BY position ASC` that [DashboardRepository.views]
/// reads back.
///
/// Runs against sqflite_common_ffi (plain sqlite3), like db_recovery_test.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/dashboard_repository.dart';
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
    dir = Directory.systemTemp.createTempSync('kaaljyoti_view_reorder_test');
    dbPath = '${dir.path}/kaaljyoti.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  AppDb newDb() => AppDb.forTest(
      path: dbPath, opener: _ffiOpener, passphrase: 'test-passphrase');

  /// Three named views in creation order. The first call to views() also
  /// seeds the default Overview, so the fixture is built on top of it.
  Future<(DashboardRepository, List<String>)> seeded() async {
    final repo = DashboardRepository(db: newDb());
    await repo.views(); // seeds "Overview" at position 0
    final b = await repo.createView('Transit');
    final c = await repo.createView('Divisional');
    final all = await repo.views();
    expect(all.map((v) => v.name), ['Overview', 'Transit', 'Divisional']);
    expect(all.map((v) => v.id), [all[0].id, b.id, c.id]);
    return (repo, all.map((v) => v.id).toList());
  }

  test('reorderViews rewrites position to the list index', () async {
    final (repo, ids) = await seeded();

    // Drag the last chip to the front.
    await repo.reorderViews([ids[2], ids[0], ids[1]]);

    final after = await repo.views();
    expect(after.map((v) => v.name), ['Divisional', 'Overview', 'Transit']);
    // Positions stay dense (0,1,2) so the ORDER BY is total — a later
    // createView() appends after the last chip, not into the middle.
    expect(after.map((v) => v.position), [0, 1, 2]);

    final appended = await repo.createView('Yogas');
    expect(appended.position, 3);
    expect((await repo.views()).last.name, 'Yogas');
  });

  test('reorderViews survives a reopen of the database', () async {
    final (repo, ids) = await seeded();
    await repo.reorderViews([ids[1], ids[2], ids[0]]);

    // A brand-new repo over the same file — the order is persisted, not
    // cached in the instance.
    final reopened = DashboardRepository(db: newDb());
    expect((await reopened.views()).map((v) => v.name),
        ['Transit', 'Divisional', 'Overview']);
  });

  test('reorderViews is a no-op for an unchanged order', () async {
    final (repo, ids) = await seeded();
    await repo.reorderViews(ids);
    expect((await repo.views()).map((v) => v.id), ids);
  });
}
