/// The journal store, and the two sync-critical behaviours around it:
///
///   • a LOCAL journal write must bump the parent kundli's `updated_at`,
///     or a journal-only edit never overtakes the remote copy and the
///     note silently loses to an older device;
///   • applying a REMOTE journal must NOT bump it, or every pull looks
///     like a fresh local edit and the two devices push at each other
///     forever.
///
/// Also covers the payload shape sync uses (embed → split), since the
/// SyncService itself needs a live Supabase client to exercise.
///
/// Runs against sqflite_common_ffi (plain sqlite3), like db_recovery_test.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/db.dart';
import 'package:kaaljyoti/data/journal_repository.dart';
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

Map<String, Object?> _kundliRow(String id) => {
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
      'sync_enabled': 1,
      'created_at': 0,
      'updated_at': 0,
    };

void main() {
  sqfliteFfiInit();

  late Directory dir;
  late AppDb appDb;
  late JournalRepository repo;

  Future<int> parentUpdatedAt(String id) async {
    final db = await appDb.database;
    final rows =
        await db.query('kundlis', where: 'id = ?', whereArgs: [id]);
    return rows.single['updated_at'] as int;
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('kaaljyoti_journal_test');
    appDb = AppDb.forTest(
        path: '${dir.path}/kaaljyoti.db',
        opener: _ffiOpener,
        passphrase: 'test-passphrase');
    repo = JournalRepository(db: appDb);
    final db = await appDb.database;
    await db.insert('kundlis', _kundliRow('k1'));
    await db.insert('kundlis', _kundliRow('k2'));
  });

  tearDown(() async {
    await appDb.close();
    dir.deleteSync(recursive: true);
  });

  test('entries round-trip through create / update / delete', () async {
    final created = await repo.create(
      kundliId: 'k1',
      at: DateTime(2026, 3, 14),
      text: 'Client reports a job offer — verify against the AD change.',
      contextJson: '{"v":1}',
    );

    final loaded = (await repo.forKundli('k1')).single;
    expect(loaded.id, created.id);
    expect(loaded.at, DateTime(2026, 3, 14));
    expect(loaded.text, startsWith('Client reports'));
    expect(loaded.contextJson, '{"v":1}');

    await repo.update(loaded.copyWith(text: 'Offer confirmed.'));
    expect((await repo.forKundli('k1')).single.text, 'Offer confirmed.');

    await repo.delete(loaded.id, kundliId: 'k1');
    expect(await repo.forKundli('k1'), isEmpty);
  });

  test('entries are scoped to their kundli and read newest first', () async {
    await repo.create(kundliId: 'k1', at: DateTime(2024, 1, 1), text: 'older');
    await repo.create(kundliId: 'k1', at: DateTime(2026, 1, 1), text: 'newer');
    await repo.create(kundliId: 'k2', at: DateTime(2025, 1, 1), text: 'other');

    expect([for (final e in await repo.forKundli('k1')) e.text],
        ['newer', 'older']);
    expect([for (final e in await repo.forKundli('k2')) e.text], ['other']);
  });

  test('entries cascade-delete with their kundli', () async {
    await repo.create(kundliId: 'k1', at: DateTime(2026, 1, 1), text: 'note');
    final db = await appDb.database;
    await db.delete('kundlis', where: 'id = ?', whereArgs: ['k1']);
    expect(await repo.forKundli('k1'), isEmpty);
  });

  test('local writes bump the parent kundli updated_at', () async {
    expect(await parentUpdatedAt('k1'), 0);

    final e =
        await repo.create(kundliId: 'k1', at: DateTime(2026, 1, 1), text: 'a');
    final afterCreate = await parentUpdatedAt('k1');
    expect(afterCreate, greaterThan(0), reason: 'create must touch');

    await repo.update(e.copyWith(text: 'b'));
    expect(await parentUpdatedAt('k1'), greaterThanOrEqualTo(afterCreate),
        reason: 'update must touch');

    // A write on one kundli must not disturb its neighbour's timestamp.
    expect(await parentUpdatedAt('k2'), 0);

    await repo.delete(e.id, kundliId: 'k1');
    expect(await parentUpdatedAt('k1'), greaterThan(0),
        reason: 'delete must touch');
  });

  test('replaceForKundli applies remote entries without touching the parent',
      () async {
    final remote = [
      JournalEntry(
        id: 'r1',
        kundliId: 'k1',
        at: DateTime(2026, 2, 2),
        text: 'written on the other device',
        contextJson: '{"v":1,"sky":{"sun":"aquarius"}}',
        createdAt: DateTime.utc(2026, 2, 2),
        updatedAt: DateTime.utc(2026, 2, 2),
      ),
    ];

    await repo.replaceForKundli('k1', remote);

    expect(await parentUpdatedAt('k1'), 0,
        reason: 'applying a pull must not look like a local edit');
    final loaded = (await repo.forKundli('k1')).single;
    expect(loaded.id, 'r1');
    expect(loaded.contextJson, '{"v":1,"sky":{"sun":"aquarius"}}');
  });

  test('replaceForKundli replaces the whole set, including with an empty one',
      () async {
    await repo.create(kundliId: 'k1', at: DateTime(2026, 1, 1), text: 'local');
    await repo.create(kundliId: 'k2', at: DateTime(2026, 1, 1), text: 'other');

    await repo.replaceForKundli('k1', const []);

    expect(await repo.forKundli('k1'), isEmpty);
    expect(await repo.forKundli('k2'), hasLength(1),
        reason: 'the replace is scoped to one kundli');
  });

  test('the sync payload round-trips entries unchanged', () async {
    await repo.create(
      kundliId: 'k1',
      at: DateTime(2026, 3, 14),
      text: 'consultation notes',
      contextJson: '{"v":1,"moon":{"sign":"cancer"}}',
    );
    await repo.create(kundliId: 'k1', at: DateTime(2026, 4, 1), text: 'later');
    final before = await repo.forKundli('k1');

    // Exactly what SyncService.pushAll embeds and pullAll splits back out,
    // through a JSON encode/decode so type coercion is exercised too.
    final payload = jsonEncode({
      'id': 'k1',
      'journal': [for (final e in before) e.toRow()],
    });
    final map = (jsonDecode(payload) as Map).cast<String, Object?>();
    final journalJson = map.remove('journal') as List?;

    await repo.replaceForKundli('k1', [
      for (final j in journalJson ?? const [])
        JournalEntry.fromRow((j as Map).cast<String, Object?>()),
    ]);

    final after = await repo.forKundli('k1');
    expect([for (final e in after) e.toRow()],
        [for (final e in before) e.toRow()]);
    // The kundli columns survive the split untouched.
    expect(map.keys, ['id']);
  });

  test('a payload with no journal key reads as an empty journal', () async {
    await repo.create(kundliId: 'k1', at: DateTime(2026, 1, 1), text: 'local');

    // A kundli pushed by a build that predates the journal: the key is
    // simply absent, and must mean "no entries", not a crash.
    final map = (jsonDecode(jsonEncode({'id': 'k1', 'events': []})) as Map)
        .cast<String, Object?>();
    final journalJson = map.remove('journal') as List?;
    expect(journalJson, isNull);

    await repo.replaceForKundli('k1', [
      for (final j in journalJson ?? const [])
        JournalEntry.fromRow((j as Map).cast<String, Object?>()),
    ]);
    expect(await repo.forKundli('k1'), isEmpty);
  });

  test('a row missing optional columns still decodes', () async {
    // Defensive: a payload written by a future build could drop a column
    // we consider optional. That must degrade, not throw.
    final e = JournalEntry.fromRow({'id': 'x', 'kundli_id': 'k1'});
    expect(e.text, isEmpty);
    expect(e.contextJson, isNull);
    expect(e.at.millisecondsSinceEpoch, 0);
  });
}
