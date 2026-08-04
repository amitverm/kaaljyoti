/// Anonymous device analytics (0030) — the counter, the seed, and the
/// throttle. Three separate things, all of which get the numbers wrong
/// in a way nobody would notice for months if they broke:
///
///   • the ephemeral rule — an instant Prashna is a discarded question,
///     not a kundli, until Keep flips it, and a sync pull is somebody
///     else's creation arriving, never one of ours;
///   • the seed — a device that already holds a library must not start
///     counting from zero;
///   • the 24h throttle — including a clock that has moved backwards,
///     which must not silence a device permanently;
///   • the dirty flag — the thing that turns a create or a delete into a
///     ping within the minute instead of within the day, and that must
///     survive being killed before the ping goes out.
///
/// The repository half runs against sqflite_common_ffi (plain sqlite3),
/// like journal_repository_test. The ping service itself needs a live
/// SupabaseClient, so what is tested here is its decision functions,
/// which are pure for exactly that reason — plus the debounce timer,
/// which is observable without ever reaching the network.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/db.dart';
import 'package:kaaljyoti/data/kundli_repository.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/services/device_ping_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('ping throttle', () {
    final t0 = DateTime(2026, 8, 4, 9);

    test('a device that has never pinged is due', () {
      expect(devicePingIsDue(lastPingAt: null, now: t0), isTrue);
    });

    test('not due again within 24h', () {
      expect(
        devicePingIsDue(
            lastPingAt: t0,
            now: t0.add(const Duration(hours: 23, minutes: 59))),
        isFalse,
      );
    });

    test('due once 24h have passed', () {
      expect(
        devicePingIsDue(lastPingAt: t0, now: t0.add(const Duration(hours: 24))),
        isTrue,
      );
    });

    test('a clock that moved backwards leaves the device due, not muted', () {
      // Travel, a manual time change, or a restored backup. Treating the
      // negative interval as "not yet" would silence this install until
      // real time caught up — potentially never.
      expect(
        devicePingIsDue(
            lastPingAt: t0, now: t0.subtract(const Duration(days: 3))),
        isTrue,
      );
    });
  });

  group('ping dueness with the dirty flag', () {
    final t0 = DateTime(2026, 8, 4, 9);
    final justNow = t0.add(const Duration(minutes: 5));

    test('a clean device inside the window stays quiet', () {
      expect(
        devicePingIsDueNow(
            countersDirty: false, lastPingAt: t0, now: justNow),
        isFalse,
      );
    });

    test('a changed count pings now, throttle or no throttle', () {
      // The whole point of the flag: the user just made or deleted a
      // chart, and waiting up to 23 more hours to say so is exactly the
      // staleness this replaces.
      expect(
        devicePingIsDueNow(countersDirty: true, lastPingAt: t0, now: justNow),
        isTrue,
      );
    });

    test('the daily heartbeat still fires with nothing dirty', () {
      // The dirty flag ADDS a reason to ping; it must not become the
      // only one, or a device whose counts never change would go silent
      // and quietly drop out of devices_active_30d.
      expect(
        devicePingIsDueNow(
            countersDirty: false,
            lastPingAt: t0,
            now: t0.add(const Duration(hours: 25))),
        isTrue,
      );
    });

    test('a device that has never pinged is due either way', () {
      expect(
        devicePingIsDueNow(
            countersDirty: false, lastPingAt: null, now: t0),
        isTrue,
      );
      expect(
        devicePingIsDueNow(countersDirty: true, lastPingAt: null, now: t0),
        isTrue,
      );
    });
  });

  group('SettingsRepository analytics prefs', () {
    late SettingsRepository settings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsRepository();
    });

    test('install id is minted once and then stable', () async {
      final first = await settings.installId();
      expect(first, isNotEmpty);
      expect(await settings.installId(), first);
      // A uuid v4 and nothing else — no device or account material.
      expect(first.length, 36);
      expect(await SettingsRepository().installId(), first);
    });

    test('the counter seeds from the caller-supplied count, once', () async {
      // A device that already holds 17 kundlis when this build lands.
      expect(await settings.kundlisCreatedTotal(() async => 17), 17);
      // The seed is never consulted again, even if it would now differ.
      expect(await settings.kundlisCreatedTotal(() async => 0), 17);
    });

    test('bump seeds then increments', () async {
      expect(await settings.bumpKundlisCreatedTotal(() async => 4), 5);
      expect(await settings.bumpKundlisCreatedTotal(() async => 999), 6);
      expect(await settings.kundlisCreatedTotal(() async => 999), 6);
    });

    test('a negative seed clamps to zero', () async {
      // The repository derives the seed as savedCount() - 1, which is -1
      // on a device whose very first kundli is the one being counted.
      expect(await settings.kundlisCreatedTotal(() async => -1), 0);
    });

    test('lastPingAt is null until a ping succeeds', () async {
      expect(await settings.lastPingAt(), isNull);
      final at = DateTime(2026, 8, 4, 9, 30);
      await settings.setLastPingAt(at);
      expect(await settings.lastPingAt(), at);
    });

    test('countersDirty defaults to clean and round-trips both ways',
        () async {
      // A fresh install owes the server nothing it has not already been
      // told, so the default must be false — defaulting to true would
      // make every cold start ping regardless of the throttle.
      expect(await settings.countersDirty(), isFalse);
      await settings.setCountersDirty(true);
      expect(await settings.countersDirty(), isTrue);
      // On disk, not in this instance: the point of persisting it is
      // that a kill before the debounced ping still corrects next launch.
      expect(await SettingsRepository().countersDirty(), isTrue);
      await settings.setCountersDirty(false);
      expect(await SettingsRepository().countersDirty(), isFalse);
    });
  });

  group('KundliRepository creation counter', () {
    late Directory dir;
    late AppDb appDb;
    late SettingsRepository settings;
    late KundliRepository repo;

    Future<int> counter() => settings.kundlisCreatedTotal(() async => -1);

    /// The stored counter WITHOUT seeding it as a side effect — the only
    /// way to assert "nothing ever counted here". Key spelled out on
    /// purpose: a rename would silently orphan every device's tally.
    Future<int?> rawCounter() async => (await SharedPreferences.getInstance())
        .getInt('analytics_kundlis_created_total');

    Future<Kundli> make({bool ephemeral = false}) => repo.create(
          name: 'Ramesh Sharma',
          relationTag: 'Client',
          birthUtc: DateTime.utc(1987, 3, 14, 6, 42),
          latitude: 18.52,
          longitude: 73.86,
          timezoneName: 'Asia/Kolkata',
          utcOffsetMinutes: 330,
          placeName: 'Pune',
          isEphemeral: ephemeral,
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsRepository();
      dir = Directory.systemTemp.createTempSync('kaaljyoti_analytics_test');
      appDb = AppDb.forTest(
          path: '${dir.path}/kaaljyoti.db',
          opener: _ffiOpener,
          passphrase: 'test-passphrase');
      repo = KundliRepository(db: appDb, settings: settings);
    });

    tearDown(() async {
      await appDb.close();
      dir.deleteSync(recursive: true);
    });

    test('each saved create counts once', () async {
      await make();
      expect(await counter(), 1);
      await make();
      await make();
      expect(await counter(), 3);
      expect(await repo.savedCount(), 3);
    });

    test('an ephemeral Prashna does not count until it is kept', () async {
      final prashna = await make(ephemeral: true);
      expect(await counter(), 0);
      expect(await repo.savedCount(), 0);

      // The Keep action, exactly as the dashboard performs it.
      await repo.update(prashna.copyWith(isEphemeral: false));
      expect(await counter(), 1);
      expect(await repo.savedCount(), 1);
    });

    test('an ordinary edit does not count again', () async {
      final k = await make();
      await repo.update(k.copyWith(name: 'Ramesh Kumar Sharma'));
      await repo.update(k.copyWith(note: 'Rectified birth time.'));
      expect(await counter(), 1);
    });

    test('a sync pull is not a creation', () async {
      // upsertRaw applies a kundli created on ANOTHER device, which
      // already counted it. Counting it here is the double-count 0030's
      // header calls the device sums an upper bound for.
      final remote = Kundli(
        id: 'remote-1',
        name: 'Sita Devi',
        relationTag: 'Client',
        birthUtc: DateTime.utc(1990, 1, 2, 3, 4),
        latitude: 28.61,
        longitude: 77.20,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
        placeName: 'New Delhi',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await repo.upsertRaw(remote);
      expect(await rawCounter(), isNull, reason: 'nothing was counted');
      expect(await repo.savedCount(), 1);
    });

    test('the counter seeds from a library that predates it', () async {
      // Simulate an existing install: rows in the table, no counter pref.
      await make();
      await make();
      SharedPreferences.setMockInitialValues({});
      settings = SettingsRepository();
      repo = KundliRepository(db: appDb, settings: settings);

      await make();
      // Seed = the two that were already here; +1 for the new one.
      expect(await counter(), 3);
    });

    test('deleting a kundli leaves the ever-created count alone', () async {
      final k = await make();
      await repo.delete(k.id);
      expect(await counter(), 1);
      expect(await repo.savedCount(), 0);
    });

    // --- the dirty flag: which mutations owe the server a fresh ping ---
    //
    // The flag is the delivery guarantee behind pingSoon's timer. If a
    // mutation forgets to set it, a kill-before-ping loses the update
    // silently until the next daily heartbeat; if a mutation sets it
    // that shouldn't, the cost is one extra three-integer request.

    /// The stored flag WITHOUT the default false the getter applies —
    /// the only way to tell "explicitly cleared" from "never written".
    Future<bool?> rawDirty() async => (await SharedPreferences.getInstance())
        .getBool('analytics_counters_dirty');

    test('a saved create marks the counters dirty', () async {
      expect(await rawDirty(), isNull, reason: 'nothing owed yet');
      await make();
      expect(await settings.countersDirty(), isTrue);
    });

    test('an ephemeral Prashna marks dirty only once Keep flips it',
        () async {
      final prashna = await make(ephemeral: true);
      // A question asked and not yet kept changes neither reported
      // number, so there is nothing to tell the server about.
      expect(await rawDirty(), isNull);

      await repo.update(prashna.copyWith(isEphemeral: false));
      expect(await settings.countersDirty(), isTrue);
    });

    test('an ordinary edit does not mark dirty', () async {
      final k = await make();
      await settings.setCountersDirty(false);
      await repo.update(k.copyWith(name: 'Ramesh Kumar Sharma'));
      // Renaming a chart moves no count. A ping would carry the exact
      // three numbers the server already holds.
      expect(await settings.countersDirty(), isFalse);
    });

    test('a delete marks dirty', () async {
      final k = await make();
      await settings.setCountersDirty(false);
      await repo.delete(k.id);
      expect(await settings.countersDirty(), isTrue);
    });

    test('discarding an ephemeral marks dirty too — spuriously, on purpose',
        () async {
      // delete() cannot tell an ephemeral row from a saved one without a
      // point-read it refuses to pay for on every deletion. The result
      // is one extra ping after a discarded Prashna, which is the
      // cheaper of the two mistakes available.
      final prashna = await make(ephemeral: true);
      expect(await rawDirty(), isNull);
      await repo.delete(prashna.id);
      expect(await settings.countersDirty(), isTrue);
    });

    test('deleteAll marks dirty', () async {
      await make();
      await make();
      await settings.setCountersDirty(false);
      await repo.deleteAll();
      expect(await settings.countersDirty(), isTrue);
      expect(await repo.savedCount(), 0);
    });

    test('a sync pull does not mark dirty', () async {
      // It genuinely changes this device's "current" — but a first sync
      // or a realtime burst arrives as a flurry of these, and a ping per
      // row is a ping storm. These rows are counted exactly by 0029's
      // registry anyway; the daily heartbeat reconciles the device's
      // slice of the estimate within a day.
      final remote = Kundli(
        id: 'remote-2',
        name: 'Sita Devi',
        relationTag: 'Client',
        birthUtc: DateTime.utc(1990, 1, 2, 3, 4),
        latitude: 28.61,
        longitude: 77.20,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
        placeName: 'New Delhi',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await repo.upsertRaw(remote);
      expect(await rawDirty(), isNull, reason: 'no ping owed for a pull');
    });
  });

  group('pingSoon debounce', () {
    // No SupabaseClient here and none needed: what is under test is the
    // timer, and the observable is how many times the debounced callback
    // reaches its first await. A real (very short) duration rather than
    // fakeAsync — the codebase has no fakeAsync anywhere, and the timing
    // margins below are an order of magnitude wide.
    const debounce = Duration(milliseconds: 40);

    late _CountingSettings settings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settings = _CountingSettings();
    });

    /// The service with its network end left null — nothing in these
    /// tests gets far enough to touch it, and pingIfDue swallows the
    /// type error if one ever did.
    DevicePingService service({bool debugBuild = false}) =>
        DevicePingService(_nullClient(),
            settings: settings, debugBuild: debugBuild, debounce: debounce);

    test('a burst of calls produces one ping', () async {
      final s = service();
      for (var i = 0; i < 25; i++) {
        s.pingSoon();
      }
      expect(settings.dueChecks, 0, reason: 'nothing fires immediately');
      await Future<void>.delayed(debounce * 6);
      // Multi-selecting twenty-five charts and deleting them is one
      // event as far as the server is concerned.
      expect(settings.dueChecks, 1);
    });

    test('each call restarts the timer', () async {
      final s = service();
      s.pingSoon();
      await Future<void>.delayed(debounce ~/ 2);
      s.pingSoon();
      await Future<void>.delayed(debounce ~/ 2);
      s.pingSoon();
      // Two full debounce periods have elapsed since the first call, and
      // the ping has still not gone: the window slides with the burst.
      expect(settings.dueChecks, 0);
      await Future<void>.delayed(debounce * 6);
      expect(settings.dueChecks, 1);
    });

    test('separate bursts ping separately', () async {
      final s = service();
      s.pingSoon();
      await Future<void>.delayed(debounce * 6);
      s.pingSoon();
      await Future<void>.delayed(debounce * 6);
      expect(settings.dueChecks, 2);
    });

    test('dispose cancels a pending ping', () async {
      final s = service();
      s.pingSoon();
      s.dispose();
      await Future<void>.delayed(debounce * 6);
      expect(settings.dueChecks, 0);
    });

    test('a debug build never schedules anything', () async {
      // The same guard pingIfDue has. An afternoon of hot restarts must
      // not outnumber a week of real installs.
      final s = service(debugBuild: true);
      s.pingSoon();
      await Future<void>.delayed(debounce * 6);
      expect(settings.dueChecks, 0);
    });
  });
}

/// A SettingsRepository that counts dueness reads. countersDirty() is
/// the first thing pingIfDue awaits, so the count is "how many times did
/// the debounced callback actually run" — and returning false keeps
/// every one of them short of the network.
class _CountingSettings extends SettingsRepository {
  int dueChecks = 0;

  @override
  Future<bool> countersDirty() async {
    dueChecks++;
    return false;
  }

  @override
  Future<DateTime?> lastPingAt() async => DateTime.now();
}

/// A stand-in for the Supabase client. The debounce tests never reach an
/// RPC (see [_CountingSettings]), so the client is only ever a field.
SupabaseClient _nullClient() =>
    SupabaseClient('https://example.invalid', 'test-anon-key');
