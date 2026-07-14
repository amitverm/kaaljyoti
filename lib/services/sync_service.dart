/// Opt-in cross-device sync of personal kundlis (brief §4.3). The
/// payload is the kundli's own row data; server storage is per-user
/// with strict RLS. Personal charts stay on-device unless the user
/// enables sync per kundli.
library;

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/kundli_event_repository.dart';
import '../data/kundli_repository.dart';
import '../data/models.dart';

class SyncService {
  SyncService(this._client, this._kundlis, this._events);
  final SupabaseClient _client;
  final KundliRepository _kundlis;
  final KundliEventRepository _events;

  String? get _userId => _client.auth.currentUser?.id;
  bool get isSignedIn => _userId != null;

  /// Push all sync-enabled kundlis (last-write-wins on updated_at).
  Future<void> pushAll() async {
    if (!isSignedIn) return;
    final all = await _kundlis.all();
    final toPush = all.where((k) => k.syncEnabled).toList();
    if (toPush.isEmpty) return;
    // Tombstone guard: never re-upload a kundli that another device
    // deleted after our last local edit — that would resurrect it
    // everywhere. pullAll applies the deletion locally; a local edit
    // NEWER than the tombstone legitimately wins and clears it.
    final remote =
        await _client.from('synced_kundlis').select('id, deleted_at');
    final tombstones = {
      for (final r in remote)
        if (r['deleted_at'] != null)
          r['id'] as String: DateTime.parse(r['deleted_at'] as String),
    };
    for (final k in toPush) {
      final deletedAt = tombstones[k.id];
      if (deletedAt != null && deletedAt.isAfter(k.updatedAt)) continue;
      // The kundli's life events ride along inside the same payload so they
      // stay together and last-write-wins applies to the pair atomically.
      final events = await _events.forKundli(k.id);
      final payload = {
        ...k.toRow(),
        'events': [for (final e in events) e.toRow()],
      };
      // Conflict target is the composite key (0022): another account
      // may legitimately hold a row for the same kundli id (a chart
      // first synced by a different user on this device).
      await _client.from('synced_kundlis').upsert({
        'id': k.id,
        'user_id': _userId,
        'payload_encrypted': jsonEncode(payload),
        'updated_at': k.updatedAt.toIso8601String(),
        'deleted_at': null,
      }, onConflict: 'id,user_id');
    }
  }

  /// Pull remote kundlis; insert unknown ones, update older local ones,
  /// and apply tombstoned deletions from other devices.
  Future<int> pullAll() async {
    if (!isSignedIn) return 0;
    final rows = await _client.from('synced_kundlis').select();
    var applied = 0;
    for (final r in rows) {
      final deletedAtRaw = r['deleted_at'] as String?;
      if (deletedAtRaw != null) {
        // Deleted on another device. Apply locally only if the tombstone
        // is newer than our copy (LWW — a later local edit wins and gets
        // re-pushed) and only to sync-enabled copies: a kundli whose sync
        // was switched off locally is never touched by remote state.
        final deletedAt = DateTime.parse(deletedAtRaw);
        final local = await _kundlis.byId(r['id'] as String);
        if (local != null &&
            local.syncEnabled &&
            deletedAt.isAfter(local.updatedAt)) {
          await _kundlis.delete(local.id); // events cascade-delete
          applied++;
        }
        continue;
      }
      final map = (jsonDecode(r['payload_encrypted'] as String) as Map)
          .cast<String, Object?>();
      // Split the events array back out before Kundli.fromRow (which only
      // reads the kundli columns; older payloads have no 'events' key).
      final eventsJson = map.remove('events') as List?;
      final remote = Kundli.fromRow(map);
      final local = await _kundlis.byId(remote.id);
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        await _kundlis.upsertRaw(remote);
        await _events.replaceForKundli(remote.id, [
          for (final e in eventsJson ?? const [])
            KundliEvent.fromRow((e as Map).cast<String, Object?>()),
        ]);
        applied++;
      }
    }
    return applied;
  }

  /// The kundli was DELETED locally: tombstone it server-side so other
  /// devices apply the deletion too. The payload is cleared immediately —
  /// deleted data must not linger on the server.
  Future<void> deleteRemote(String kundliId) async {
    if (!isSignedIn) return;
    await _client.from('synced_kundlis').upsert({
      'id': kundliId,
      'user_id': _userId,
      'payload_encrypted': '',
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id,user_id');
  }

  /// Sync was switched OFF for the kundli: remove it from the server
  /// without tombstoning — other devices keep their local copies.
  Future<void> removeRemote(String kundliId) async {
    if (!isSignedIn) return;
    await _client.from('synced_kundlis').delete().eq('id', kundliId);
  }

  RealtimeChannel? _channel;

  /// Live cross-device sync. Pulls once now, then subscribes to this
  /// user's synced_kundlis so a kundli synced on one device shows up on
  /// the others automatically — no manual "Sync now". [onApplied] fires
  /// after any pull that changed local data, so the UI can refresh.
  Future<void> start(void Function() onApplied) async {
    final uid = _userId;
    if (uid == null) return;

    if (await pullAll() > 0) onApplied();

    await _channel?.unsubscribe();
    _channel = _client
        .channel('synced_kundlis:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'synced_kundlis',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) async {
            // Re-pull on any server change; pullAll already applies
            // last-write-wins and only touches rows that are new/newer.
            if (await pullAll() > 0) onApplied();
          },
        )
        .subscribe();
  }

  /// Tear down the realtime subscription (e.g. on sign-out).
  Future<void> stop() async {
    await _channel?.unsubscribe();
    _channel = null;
  }
}
