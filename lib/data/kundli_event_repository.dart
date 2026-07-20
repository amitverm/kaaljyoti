import 'package:uuid/uuid.dart';

import 'db.dart';
import 'models.dart';

/// Local persistence for per-kundli life events. Events cascade-delete with
/// their kundli (see the FK in db.dart), so there's no explicit cleanup here.
class KundliEventRepository {
  KundliEventRepository({AppDb? db}) : _db = db ?? AppDb.instance;
  final AppDb _db;
  static const _uuid = Uuid();

  Future<List<KundliEvent>> forKundli(String kundliId) async {
    final db = await _db.database;
    final rows = await db.query(
      'kundli_events',
      where: 'kundli_id = ?',
      whereArgs: [kundliId],
      // Nulls (age-only) sort first; the UI re-sorts using the birth year.
      orderBy: 'event_date ASC, created_at ASC',
    );
    return rows.map(KundliEvent.fromRow).toList();
  }

  Future<KundliEvent> create({
    required String kundliId,
    String category = 'other',
    String? customTag,
    String? title,
    String? description,
    DateTime? eventDate,
    EventDatePrecision datePrecision = EventDatePrecision.exact,
    int? ageYears,
    bool isHealthRelated = false,
  }) async {
    final now = DateTime.now().toUtc();
    final event = KundliEvent(
      id: _uuid.v4(),
      kundliId: kundliId,
      category: category,
      customTag: customTag,
      title: title,
      description: description,
      eventDate: eventDate,
      datePrecision: datePrecision,
      ageYears: ageYears,
      isHealthRelated: isHealthRelated,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('kundli_events', event.toRow());
    await _touchKundli(kundliId);
    return event;
  }

  Future<void> update(KundliEvent event) async {
    final db = await _db.database;
    await db.update(
      'kundli_events',
      event.copyWith(updatedAt: DateTime.now().toUtc()).toRow(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    await _touchKundli(event.kundliId);
  }

  Future<void> delete(String id, {required String kundliId}) async {
    final db = await _db.database;
    await db.delete('kundli_events', where: 'id = ?', whereArgs: [id]);
    await _touchKundli(kundliId);
  }

  /// Bump the parent kundli's updated_at so cross-device sync's kundli-level
  /// last-write-wins treats an event change as a change to the kundli — else
  /// event-only edits never overtake the remote copy's timestamp. NOT called
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

  /// Replace the full event set for a kundli — used by cross-device sync to
  /// apply the remote copy verbatim (last-write-wins at the kundli level).
  Future<void> replaceForKundli(
      String kundliId, List<KundliEvent> events) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('kundli_events',
          where: 'kundli_id = ?', whereArgs: [kundliId]);
      for (final e in events) {
        await txn.insert('kundli_events', e.toRow());
      }
    });
  }
}
