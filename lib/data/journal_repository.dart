import 'package:uuid/uuid.dart';

import 'db.dart';
import 'models.dart';

/// Local persistence for per-kundli journal entries. Entries cascade-delete
/// with their kundli (see the FK in db.dart), so there's no explicit cleanup
/// here. Mirrors [KundliEventRepository] — including the parent-touch that
/// keeps kundli-level last-write-wins honest.
class JournalRepository {
  JournalRepository({AppDb? db}) : _db = db ?? AppDb.instance;
  final AppDb _db;
  static const _uuid = Uuid();

  /// Newest entry first — a journal is read from the latest observation
  /// backwards, unlike the life-events timeline which reads forwards.
  Future<List<JournalEntry>> forKundli(String kundliId) async {
    final db = await _db.database;
    final rows = await db.query(
      'journal_entries',
      where: 'kundli_id = ?',
      whereArgs: [kundliId],
      orderBy: 'at DESC, created_at DESC',
    );
    return rows.map(JournalEntry.fromRow).toList();
  }

  Future<JournalEntry> create({
    required String kundliId,
    required DateTime at,
    required String text,
    String? contextJson,
  }) async {
    final now = DateTime.now().toUtc();
    final entry = JournalEntry(
      id: _uuid.v4(),
      kundliId: kundliId,
      at: at,
      text: text,
      contextJson: contextJson,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('journal_entries', entry.toRow());
    await _touchKundli(kundliId);
    return entry;
  }

  Future<void> update(JournalEntry entry) async {
    final db = await _db.database;
    await db.update(
      'journal_entries',
      entry.copyWith(updatedAt: DateTime.now().toUtc()).toRow(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    await _touchKundli(entry.kundliId);
  }

  Future<void> delete(String id, {required String kundliId}) async {
    final db = await _db.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
    await _touchKundli(kundliId);
  }

  /// Bump the parent kundli's updated_at so cross-device sync's kundli-level
  /// last-write-wins treats a journal change as a change to the kundli — else
  /// journal-only edits never overtake the remote copy's timestamp. NOT called
  /// from [replaceForKundli], which applies remote data and must not re-touch.
  Future<void> _touchKundli(String kundliId) async {
    final db = await _db.database;
    await db.update(
      'kundlis',
      {'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [kundliId],
    );
  }

  /// Replace the full journal for a kundli — used by cross-device sync to
  /// apply the remote copy verbatim (last-write-wins at the kundli level).
  Future<void> replaceForKundli(
      String kundliId, List<JournalEntry> entries) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('journal_entries',
          where: 'kundli_id = ?', whereArgs: [kundliId]);
      for (final e in entries) {
        await txn.insert('journal_entries', e.toRow());
      }
    });
  }
}
