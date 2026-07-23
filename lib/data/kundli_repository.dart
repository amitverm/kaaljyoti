import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'models.dart';

class KundliRepository {
  KundliRepository({AppDb? db}) : _db = db ?? AppDb.instance;
  final AppDb _db;
  static const _uuid = Uuid();

  Future<List<Kundli>> all() async {
    final db = await _db.database;
    final rows = await db.query('kundlis', orderBy: 'created_at ASC');
    return rows.map(Kundli.fromRow).toList();
  }

  Future<Kundli?> byId(String id) async {
    final db = await _db.database;
    final rows = await db.query('kundlis', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Kundli.fromRow(rows.first);
  }

  Future<int> count() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM kundlis');
    return r.first['c'] as int;
  }

  Future<Kundli> create({
    required String name,
    required String relationTag,
    String? note,
    required DateTime birthUtc,
    required double latitude,
    required double longitude,
    required String timezoneName,
    required int utcOffsetMinutes,
    required String placeName,
    int? ayanamsaOverrideId,
    String chartStyle = 'north',
    bool isPrashna = false,
    bool isEphemeral = false,
    bool syncEnabled = false,
  }) async {
    final now = DateTime.now().toUtc();
    final kundli = Kundli(
      id: _uuid.v4(),
      name: name,
      relationTag: relationTag,
      note: note,
      birthUtc: birthUtc,
      latitude: latitude,
      longitude: longitude,
      timezoneName: timezoneName,
      utcOffsetMinutes: utcOffsetMinutes,
      placeName: placeName,
      ayanamsaOverrideId: ayanamsaOverrideId,
      chartStyle: chartStyle,
      isPrashna: isPrashna,
      isEphemeral: isEphemeral,
      syncEnabled: syncEnabled,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('kundlis', kundli.toRow());
    return kundli;
  }

  /// Insert-or-replace preserving the given id/timestamps — used by
  /// cross-device sync to apply remote rows verbatim.
  Future<void> upsertRaw(Kundli kundli) async {
    final db = await _db.database;
    await db.insert('kundlis', kundli.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Kundli kundli) async {
    final db = await _db.database;
    await db.update(
      'kundlis',
      kundli.copyWith(updatedAt: DateTime.now().toUtc()).toRow(),
      where: 'id = ?',
      whereArgs: [kundli.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('kundlis', where: 'id = ?', whereArgs: [id]);
  }

  /// Bulk-enable cloud sync (Settings ▸ Sync all kundlis). Bumps
  /// updated_at so last-write-wins treats this as a deliberate edit —
  /// a stale tombstone from an old deletion must not swallow a kundli
  /// the user just asked to sync. Returns how many were newly enabled.
  /// Ephemeral Prashna kundlis are skipped (they vanish on restart).
  Future<int> enableSyncAll() async {
    final db = await _db.database;
    return db.update(
      'kundlis',
      {
        'sync_enabled': 1,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'sync_enabled = 0 AND is_ephemeral = 0',
    );
  }

  /// Local wipe of every kundli (events and export configs follow via
  /// FK CASCADE). Deliberately writes NO tombstones — the caller decides
  /// whether the deletion is device-only or propagates to the cloud.
  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('kundlis');
  }
}
