import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'models.dart';
import 'settings_repository.dart';

class KundliRepository {
  KundliRepository({AppDb? db, SettingsRepository? settings})
      : _db = db ?? AppDb.instance,
        _settings = settings ?? SettingsRepository();
  final AppDb _db;

  /// Where the "kundlis created on this device, ever" counter lives —
  /// the only thing this repository writes outside its own table.
  /// Optional and defaulted like [KundliAlertService]'s deps so no
  /// existing construction site has to know about it.
  final SettingsRepository _settings;

  static const _uuid = Uuid();

  /// Every row, ephemeral Prashna charts included — for sync and for the
  /// Settings counters. The kundli LIST must not use this; see [saved].
  Future<List<Kundli>> all() async {
    final db = await _db.database;
    final rows = await db.query('kundlis', orderBy: 'created_at ASC');
    return rows.map(Kundli.fromRow).toList();
  }

  /// What the user thinks of as "my kundlis". An instant Prashna is
  /// written to the row store the moment it's cast, but until the user
  /// taps Keep it isn't saved in any sense they'd recognise — listing it
  /// makes a discarded question look like a stored chart. AppDb sweeps
  /// these on the next launch; this keeps them out in the meantime.
  Future<List<Kundli>> saved() async {
    final db = await _db.database;
    final rows = await db.query('kundlis',
        where: 'is_ephemeral = 0', orderBy: 'created_at ASC');
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

  /// What the user would call "how many kundlis I have" — the same set
  /// [saved] lists. This is the number the device ping reports as
  /// "current"; ephemeral Prashna rows are discarded questions and are
  /// no more a kundli here than they are in the list.
  Future<int> savedCount() async {
    final db = await _db.database;
    final r = await db
        .rawQuery('SELECT COUNT(*) AS c FROM kundlis WHERE is_ephemeral = 0');
    return r.first['c'] as int;
  }

  /// Record one creation against the device counter (see
  /// [SettingsRepository.kundlisCreatedTotal]).
  ///
  /// The seed runs at most once per install, and runs AFTER the row that
  /// triggered it is already stored — so [savedCount] here includes that
  /// row, and the seed ("kundlis that existed before we started
  /// counting") is one less. The bump then adds this creation back.
  ///
  /// Failures are swallowed: an analytics counter is never worth losing
  /// a kundli the user just saved.
  Future<void> _countCreation() async {
    try {
      await _settings
          .bumpKundlisCreatedTotal(() async => (await savedCount()) - 1);
    } catch (_) {}
    await _markCountersDirty();
  }

  /// Flag that what a ping would report has changed, so the next ping is
  /// due immediately instead of at the next daily heartbeat. Swallowed
  /// like [_countCreation] — the flag is an optimisation, and failing to
  /// set it costs at most one day of staleness, never a user's data.
  Future<void> _markCountersDirty() async {
    try {
      await _settings.setCountersDirty(true);
    } catch (_) {}
  }

  Future<Kundli> create({
    required String name,
    required String relationTag,
    String? note,
    List<String> labels = const [],
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
      labels: labels,
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
    // THE creation event, for the device counter. An ephemeral Prashna
    // is not one: it is a question asked and discarded unless the user
    // taps Keep, and that flip is counted in [update] instead.
    if (!isEphemeral) await _countCreation();
    return kundli;
  }

  /// Insert-or-replace preserving the given id/timestamps — used by
  /// cross-device sync to apply remote rows verbatim.
  ///
  /// Deliberately does NOT touch the creation counter: a sync pull is
  /// this device receiving a kundli that was created somewhere else and
  /// already counted there. Counting it again is exactly the
  /// double-count 0030's header warns the device sums for.
  ///
  /// It does not set the dirty flag either, and that is a separate
  /// decision from the one above. A pull DOES change this device's
  /// "current" — the row is here now — but a first sync or a realtime
  /// burst applies rows in a flurry, and a ping per flurry is a ping
  /// storm dressed up as telemetry. These rows are already counted
  /// exactly by 0029's registry (they synced, by definition), so the
  /// only thing riding on them is this device's slice of an
  /// acknowledged upper bound. The daily heartbeat reconciles it within
  /// a day, which is what it was always doing before event pings
  /// existed.
  Future<void> upsertRaw(Kundli kundli) async {
    final db = await _db.database;
    await db.insert('kundlis', kundli.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Kundli kundli) async {
    // One point-read before the write, purely to spot the ephemeral →
    // saved flip: tapping Keep on an instant Prashna is the moment a
    // discarded question becomes a kundli, and it is the only creation
    // that does not arrive through [create]. Cheap (primary-key lookup),
    // and it keeps the rule in the repository rather than in whichever
    // screen happens to own the Keep button.
    final before = await byId(kundli.id);
    final db = await _db.database;
    await db.update(
      'kundlis',
      kundli.copyWith(updatedAt: DateTime.now().toUtc()).toRow(),
      where: 'id = ?',
      whereArgs: [kundli.id],
    );
    if (before != null && before.isEphemeral && !kundli.isEphemeral) {
      await _countCreation();
    }
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('kundlis', where: 'id = ?', whereArgs: [id]);
    // Unconditionally, without first asking whether the row was
    // ephemeral. Discarding a Prashna changes no reported number, so
    // this marks dirty spuriously — and the alternative is a point-read
    // before every delete to save a request that costs three integers.
    // One extra ping is the cheaper mistake.
    await _markCountersDirty();
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
    // Its own SQL path, so its own flag: a wipe is the single largest
    // change "current" can undergo, and it must not wait for tomorrow.
    await _markCountersDirty();
  }
}
