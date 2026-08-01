/// Regression tests for the alert providers going stale.
///
/// THE BUG: alertScheduleSummaryProvider, alertHistoryProvider and
/// alertPendingCountProvider all watch kundliAlertServiceProvider, which
/// is a plain Provider and never changes identity. As cached
/// FutureProviders they therefore resolved ONCE and served that answer
/// forever — so unfollowing every kundli cancelled the OS schedule
/// correctly while the screen went on listing the alerts it had read
/// minutes earlier. The documented "sweep on read" in the history
/// provider was defeated the same way: it swept exactly once.
///
/// THE FIX has two halves, and both are tested here because either
/// alone leaves a real hole:
///   * autoDispose — a screen MOUNTED after a pass reads fresh;
///   * AlertRefresher.run invalidating in a finally — a screen already
///     OPEN when a debounced pass lands under it updates live.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/event_feed.dart';
import 'package:kaaljyoti/data/kundli_repository.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/services/kundli_alert_service.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what it was asked to schedule; reports a pending count that
/// tracks it, so the cross-check provider has something to go stale on.
class _FakeScheduler implements AlertScheduler {
  final List<PendingAlert> scheduled = [];
  int cancelAllCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(PendingAlert alert) async => scheduled.add(alert);

  @override
  Future<int?> pendingCount() async => scheduled.length;

  @override
  Future<void> init({required void Function(String payload) onTap}) async {}
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<bool> notificationsEnabled() async => true;
}

Kundli _kundli(String id, String name) => Kundli(
      id: id,
      name: name,
      relationTag: 'Client',
      birthUtc: DateTime.utc(1985, 3, 17, 6, 30),
      latitude: 28.6139,
      longitude: 77.2090,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
      placeName: 'New Delhi, India',
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 1),
    );

/// One alert per followed chart, a week out.
List<FeedEvent> _events({
  required Kundli kundli,
  required int defaultAyanamsaId,
  required dynamic l10n,
  required AlertSettings settings,
  required DateTime from,
  required DateTime to,
}) =>
    [
      FeedEvent(
        time: from.add(const Duration(days: 7)),
        label: '${kundli.id} MD',
        source: FeedSource.dasha,
        dashaLevel: 1,
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeScheduler fake;

  setUp(() {
    fake = _FakeScheduler();
    SharedPreferences.setMockInitialValues({});
  });

  /// A container wired to the fake, with a real (prefs-backed) service so
  /// the providers exercise the actual persistence path.
  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      kundliAlertServiceProvider.overrideWithValue(
          KundliAlertService(scheduler: fake, events: _events)),
      kundliRepoProvider.overrideWithValue(_StubKundliRepo()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('the summary provider reflects a later pass, same container', () async {
    final c = container();
    c.read(followedKundlisProvider.notifier).addAll(['k1', 'k2']);

    await c.read(alertRefresherProvider).run();
    expect((await c.read(alertScheduleSummaryProvider.future)).alerts,
        hasLength(2));

    // THE USER'S REPRO. Unfollow everything, run the pass again, and
    // read the SAME provider from the SAME container — the old code
    // handed back the cached two.
    c.read(followedKundlisProvider.notifier).removeAll(['k1', 'k2']);
    await c.read(alertRefresherProvider).run();

    expect((await c.read(alertScheduleSummaryProvider.future)).alerts, isEmpty);
    expect(fake.scheduled, isEmpty, reason: 'the OS schedule really is empty');
  });

  test('the count a screen would show follows the follow-set down', () async {
    // The bottom-tile count and the scheduled list both derive from this
    // provider, so this is the number the user was watching not change.
    final c = container();
    final counts = <int>[];

    for (final follows in [
      {'k1', 'k2', 'k3'},
      {'k1'},
      <String>{},
    ]) {
      c.read(followedKundlisProvider.notifier)
        ..removeAll(c.read(followedKundlisProvider))
        ..addAll(follows);
      await c.read(alertRefresherProvider).run();
      counts.add(
          (await c.read(alertScheduleSummaryProvider.future)).alerts.length);
    }

    expect(counts, [3, 1, 0]);
  });

  test('run() invalidates even when a listener is holding the provider',
      () async {
    // autoDispose only helps a screen mounted AFTER the pass. This is
    // the screen already open while a debounced pass lands under it.
    final c = container();
    c.read(followedKundlisProvider.notifier).addAll(['k1']);
    await c.read(alertRefresherProvider).run();

    // Simulate a mounted widget subscribing and keeping it alive.
    final sub = c.listen(alertScheduleSummaryProvider, (_, __) {});
    addTearDown(sub.close);
    expect((await c.read(alertScheduleSummaryProvider.future)).alerts,
        hasLength(1));

    c.read(followedKundlisProvider.notifier).removeAll(['k1']);
    await c.read(alertRefresherProvider).run();

    expect((await c.read(alertScheduleSummaryProvider.future)).alerts, isEmpty);
  });

  test('the pending-count cross-check refreshes too', () async {
    final c = container();
    c.read(followedKundlisProvider.notifier).addAll(['k1', 'k2']);
    await c.read(alertRefresherProvider).run();
    expect(await c.read(alertPendingCountProvider.future), 2);

    c.read(followedKundlisProvider.notifier).removeAll(['k2']);
    await c.read(alertRefresherProvider).run();
    // A cross-check that answers from a cache is not a cross-check.
    expect(await c.read(alertPendingCountProvider.future), 1);
  });

  test('the history sweep re-runs on a fresh read, not just the first',
      () async {
    // The sweep-on-read promise: alerts fire while the app is closed, so
    // opening the screen has to catch up without waiting for a pass.
    // Cached, this swept exactly once and never again.
    //
    // The fresh read is forced with invalidate rather than by letting
    // autoDispose collect it: a bare ProviderContainer has no widget
    // lifecycle, so nothing drives autoDispose cleanup here. What the
    // app gets on remount, this gets on invalidate — and autoDispose
    // itself is pinned by the structural test below.
    final c = container();
    c.read(followedKundlisProvider.notifier).addAll(['k1']);
    await c.read(alertRefresherProvider).run();

    expect(await c.read(alertHistoryProvider.future), isEmpty);

    // Age the scheduled alert past its moment by rewriting the summary
    // with a time in the past, then read again.
    final repo = SettingsRepository();
    final summary = await repo.alertScheduleSummary();
    await repo.setAlertScheduleSummary(AlertScheduleSummary(
      computedAt: summary.computedAt,
      alerts: [
        for (final a in summary.alerts)
          ScheduledAlertRecord(
            id: a.id,
            when: DateTime.now().subtract(const Duration(hours: 2)),
            title: a.title,
            body: a.body,
            kundliId: a.kundliId,
          ),
      ],
    ));

    c.invalidate(alertHistoryProvider);
    expect(await c.read(alertHistoryProvider.future), hasLength(1));
  });

  test('a failed pass still invalidates', () async {
    // reschedule begins with cancelAll, so even a pass that throws has
    // already changed what the OS holds. Leaving the old answer on
    // screen after that is the worse outcome.
    final c = ProviderContainer(overrides: [
      kundliAlertServiceProvider.overrideWithValue(
          KundliAlertService(scheduler: fake, events: _events)),
      kundliRepoProvider.overrideWithValue(_ThrowingKundliRepo()),
    ]);
    addTearDown(c.dispose);

    c.read(followedKundlisProvider.notifier).addAll(['k1']);
    expect(await c.read(alertRefresherProvider).run(), isNull,
        reason: 'the pass failed');
    // It must not throw, and the provider must be re-readable.
    expect((await c.read(alertScheduleSummaryProvider.future)).alerts, isEmpty);
  });

  test('all three alert providers are autoDispose', () {
    // Structural: with a keep-alive cache and a service provider that
    // never changes identity, every one of these serves its first read
    // forever. Naming them here means a future edit that drops
    // autoDispose fails loudly rather than silently going stale.
    expect(alertScheduleSummaryProvider,
        isA<AutoDisposeFutureProvider<AlertScheduleSummary>>());
    expect(alertHistoryProvider,
        isA<AutoDisposeFutureProvider<List<ScheduledAlertRecord>>>());
    expect(alertPendingCountProvider, isA<AutoDisposeFutureProvider<int?>>());
  });
}

/// Returns whichever charts the follow-set names, so the pass has
/// something to schedule without touching sqflite.
class _StubKundliRepo implements KundliRepository {
  @override
  Future<List<Kundli>> saved() async => [
        for (final id in ['k1', 'k2', 'k3']) _kundli(id, id.toUpperCase())
      ];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingKundliRepo implements KundliRepository {
  @override
  Future<List<Kundli>> saved() async => throw StateError('db unavailable');

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
