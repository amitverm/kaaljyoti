/// On-device kundli alerts: the selection policy, the follow-set, and
/// one full scheduling pass through a faked OS surface.
///
/// No ephemeris anywhere — the policy is a pure function of synthetic
/// [FeedEvent]s, and the scheduling pass takes its events through the
/// injectable [KundliEventsBuilder] seam (sweph needs native assets no
/// unit test has).
library;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AndroidScheduleMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/event_feed.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/transit_scan.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart';
import 'package:kaaljyoti/services/kundli_alert_service.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _t0 = DateTime.utc(2026, 8, 1);

DateTime _at(int days) => _t0.add(Duration(days: days));

FeedEvent _dasha(int level, int day) => FeedEvent(
      time: _at(day),
      label: 'dasha L$level d$day',
      source: FeedSource.dasha,
      dashaLevel: level,
    );

FeedEvent _sadeSati(int day) => FeedEvent(
      time: _at(day),
      label: 'sade sati d$day',
      source: FeedSource.sadeSati,
    );

FeedEvent _ingress(Planet planet, int day) => FeedEvent(
      time: _at(day),
      label: '${planet.displayName} ingress d$day',
      source: FeedSource.transit,
      planet: planet,
      transitKind: TransitEventKind.ingress,
    );

FeedEvent _aspect(Planet planet, int day) => FeedEvent(
      time: _at(day),
      label: '${planet.displayName} aspect d$day',
      source: FeedSource.transit,
      planet: planet,
      transitKind: TransitEventKind.aspect,
    );

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
      createdAt: _t0,
      updatedAt: _t0,
    );

/// Records what the OS was asked to do, and nothing else.
class FakeScheduler implements AlertScheduler {
  final List<PendingAlert> scheduled = [];
  int cancelAllCalls = 0;
  int permissionRequests = 0;
  void Function(String payload)? tapHandler;
  String? launchPayloadValue;

  /// Stands in for the platform rejecting one particular alert.
  bool Function(PendingAlert)? rejects;

  /// What the "OS" claims to hold — null means it won't answer.
  int? osPendingCount;

  @override
  Future<void> init({required void Function(String payload) onTap}) async {
    tapHandler = onTap;
  }

  @override
  Future<String?> launchPayload() async => launchPayloadValue;

  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<int?> pendingCount() async => osPendingCount;

  @override
  Future<void> schedule(PendingAlert alert) async {
    if (rejects?.call(alert) ?? false) {
      throw ArgumentError('platform rejected ${alert.body}');
    }
    scheduled.add(alert);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = lookupAppLocalizations(const Locale('en'));

  group('selectAlertEvents — priority bands', () {
    test('fills band by band, not by time', () {
      // An aspect on day 1 must still lose to a mahadasha change on day
      // 29: the cap exists to protect attention, and chronology is not
      // the same thing as consequence.
      final picked = selectAlertEvents([
        _aspect(Planet.saturn, 1),
        _dasha(1, 29),
      ], cap: 1);
      expect(picked, hasLength(1));
      expect(picked.single.dashaLevel, 1);
    });

    test('full band ordering: MD/Sade Sati > AD > PD > slow > Mars > aspect',
        () {
      final events = [
        _aspect(Planet.saturn, 1),
        _ingress(Planet.mars, 2),
        _ingress(Planet.jupiter, 3),
        _dasha(3, 4),
        _dasha(2, 5),
        _dasha(1, 6),
        _sadeSati(7),
      ];
      // Take them one band at a time and check what survives each cap.
      List<String> at(int cap) =>
          selectAlertEvents(events, cap: cap).map((e) => e.label).toList();

      expect(at(2), ['dasha L1 d6', 'sade sati d7']);
      expect(at(3), ['dasha L2 d5', 'dasha L1 d6', 'sade sati d7']);
      expect(
          at(4), ['dasha L3 d4', 'dasha L2 d5', 'dasha L1 d6', 'sade sati d7']);
      expect(at(5).first, 'Jupiter ingress d3');
      expect(at(6).first, 'Mars ingress d2');
      expect(at(7).first, 'Saturn aspect d1');
    });

    test('within a band the earliest events win', () {
      final picked = selectAlertEvents([
        _dasha(2, 20),
        _dasha(2, 5),
        _dasha(2, 12),
      ], cap: 2);
      expect(picked.map((e) => e.time), [_at(5), _at(12)]);
    });

    test('result is sorted by time regardless of band', () {
      final picked = selectAlertEvents([
        _aspect(Planet.saturn, 1),
        _dasha(1, 20),
        _ingress(Planet.saturn, 10),
      ]);
      expect(picked.map((e) => e.time), [_at(1), _at(10), _at(20)]);
    });

    test('honours the cap across every band', () {
      final events = [
        for (var i = 0; i < 100; i++) _aspect(Planet.saturn, i),
        for (var i = 0; i < 100; i++) _dasha(3, i),
      ];
      expect(selectAlertEvents(events), hasLength(kAlertCap));
      expect(selectAlertEvents(events, cap: 7), hasLength(7));
      expect(selectAlertEvents(events, cap: 0), isEmpty);
    });

    test('drops events no band claims', () {
      // Sookshma/pran dasha changes and fast-graha ingresses are noise
      // at notification volume — they are feed content, not alerts.
      expect(alertBandOf(_dasha(4, 1)), isNull);
      expect(alertBandOf(_dasha(5, 1)), isNull);
      expect(alertBandOf(_ingress(Planet.mercury, 1)), isNull);
      expect(alertBandOf(_ingress(Planet.moon, 1)), isNull);
      expect(
        selectAlertEvents([_dasha(5, 1), _ingress(Planet.venus, 2)]),
        isEmpty,
      );
    });

    test('bands the four slow movers above Mars', () {
      for (final p in [
        Planet.saturn,
        Planet.jupiter,
        Planet.rahu,
        Planet.ketu
      ]) {
        expect(alertBandOf(_ingress(p, 1)), AlertBand.slowIngress,
            reason: '$p');
      }
      expect(alertBandOf(_ingress(Planet.mars, 1)), AlertBand.marsIngress);
      expect(
          AlertBand.slowIngress.index, lessThan(AlertBand.marsIngress.index));
    });
  });

  group('followedKundlisProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('toggle adds and removes', () {
      final c = container();
      final n = c.read(followedKundlisProvider.notifier);
      n.toggle('k1');
      expect(c.read(followedKundlisProvider), {'k1'});
      n.toggle('k1');
      expect(c.read(followedKundlisProvider), isEmpty);
    });

    test('round-trips through prefs', () async {
      final c = container();
      c.read(followedKundlisProvider.notifier).addAll(['k1', 'k2']);
      // The notifier writes asynchronously; let it land.
      await Future<void>.delayed(Duration.zero);
      expect(
        (await SettingsRepository().followedKundliIds()).toSet(),
        {'k1', 'k2'},
      );
    });

    test('loads what a previous run stored', () async {
      SharedPreferences.setMockInitialValues({
        'kundli_followed_ids': ['k7'],
      });
      final c = container();
      c.read(followedKundlisProvider); // instantiate
      await Future<void>.delayed(Duration.zero);
      expect(c.read(followedKundlisProvider), {'k7'});
    });

    test('removeAll drops a deleted kundli', () {
      final c = container();
      final n = c.read(followedKundlisProvider.notifier);
      n.addAll(['k1', 'k2', 'k3']);
      n.removeAll(['k2']);
      expect(c.read(followedKundlisProvider), {'k1', 'k3'});
    });

    test('is stored under its own key, separate from the pins', () async {
      final c = container();
      c.read(pinnedKundlisProvider.notifier).toggle('pinned-only');
      c.read(followedKundlisProvider.notifier).toggle('followed-only');
      await Future<void>.delayed(Duration.zero);
      final repo = SettingsRepository();
      expect(await repo.pinnedKundliIds(), ['pinned-only']);
      expect(await repo.followedKundliIds(), ['followed-only']);
    });
  });

  group('KundliAlertService.reschedule', () {
    late FakeScheduler fake;

    /// Two dasha changes and one aspect per chart, at fixed offsets.
    List<FeedEvent> events({
      required Kundli kundli,
      required int defaultAyanamsaId,
      required AppLocalizations l10n,
      required AlertSettings settings,
      required DateTime from,
      required DateTime to,
    }) =>
        [
          if (settings.dasha) ...[
            FeedEvent(
              time: from.add(const Duration(days: 3)),
              label: '${kundli.id} MD',
              source: FeedSource.dasha,
              dashaLevel: 1,
            ),
            FeedEvent(
              time: from.add(const Duration(days: 9)),
              label: '${kundli.id} AD',
              source: FeedSource.dasha,
              dashaLevel: 2,
            ),
          ],
          if (settings.transits)
            FeedEvent(
              time: from.add(const Duration(days: 5)),
              label: '${kundli.id} aspect',
              source: FeedSource.transit,
              planet: Planet.saturn,
              transitKind: TransitEventKind.aspect,
            ),
        ];

    KundliAlertService service() =>
        KundliAlertService(scheduler: fake, events: events);

    /// The diagnostics summary the pass persisted.
    Future<AlertScheduleSummary> stored() =>
        SettingsRepository().alertScheduleSummary();

    Future<void> run(
      KundliAlertService s, {
      List<Kundli>? kundlis,
      Set<String> followed = const {'k1'},
      AlertSettings settings = const AlertSettings(),
    }) =>
        s.reschedule(
          kundlis: kundlis ?? [_kundli('k1', 'Asha'), _kundli('k2', 'Bhanu')],
          followedIds: followed,
          defaultAyanamsaId: 1,
          l10n: l10n,
          settings: settings,
          now: _t0,
        );

    setUp(() {
      fake = FakeScheduler();
      // The pass persists its diagnostics summary through
      // SettingsRepository, so prefs have to exist.
      SharedPreferences.setMockInitialValues({});
    });

    test('schedules only followed charts, cancelling first', () async {
      await run(service());
      expect(fake.cancelAllCalls, 1);
      expect(fake.scheduled, hasLength(3));
      expect(fake.scheduled.every((a) => a.payload == 'k1'), isTrue);
      expect(fake.scheduled.every((a) => a.title == 'Asha'), isTrue);
    });

    test('covers every followed chart', () async {
      await run(service(), followed: {'k1', 'k2'});
      expect(fake.scheduled, hasLength(6));
      expect(fake.scheduled.map((a) => a.payload).toSet(), {'k1', 'k2'});
    });

    test('ids are stable across two identical runs', () async {
      // The whole schedule is rebuilt on every resume; an event that
      // survives has to keep its id or the OS treats it as new.
      final s = service();
      await run(s);
      final first = fake.scheduled.map((a) => a.id).toList();
      await run(s);
      expect(fake.scheduled.map((a) => a.id).toList(), first);
      expect(first.toSet(), hasLength(3), reason: 'ids must not collide');
      expect(first.every((id) => id >= 0 && id <= 0x7FFFFFFF), isTrue);
    });

    test('a different chart or instant yields a different id', () {
      final a = alertNotificationId('k1', _t0, 'x');
      expect(alertNotificationId('k2', _t0, 'x'), isNot(a));
      expect(alertNotificationId('k1', _at(1), 'x'), isNot(a));
      expect(alertNotificationId('k1', _t0, 'y'), isNot(a));
      // …and the same triple always yields the same id.
      expect(alertNotificationId('k1', _t0, 'x'), a);
    });

    test('scheduled alerts come out in time order', () async {
      await run(service(), followed: {'k1', 'k2'});
      final times = fake.scheduled.map((a) => a.when).toList();
      expect(times, orderedEquals([...times]..sort()));
    });

    test('body states the change and its source, and nothing more', () async {
      await run(service());
      final md = fake.scheduled.firstWhere((a) => a.body.startsWith('k1 MD'));
      expect(md.body, 'k1 MD · ${l10n.ueSourceDasha}');
    });

    test('the master switch cancels without scheduling', () async {
      await run(service(), settings: const AlertSettings(enabled: false));
      expect(fake.cancelAllCalls, 1);
      expect(fake.scheduled, isEmpty);
    });

    test('a category switch narrows what is scheduled', () async {
      await run(
        service(),
        settings: const AlertSettings(dasha: false, sadeSati: false),
      );
      expect(fake.scheduled, hasLength(1));
      expect(fake.scheduled.single.body, startsWith('k1 aspect'));
    });

    test('every category off schedules nothing', () async {
      await run(
        service(),
        settings:
            const AlertSettings(dasha: false, transits: false, sadeSati: false),
      );
      expect(fake.scheduled, isEmpty);
    });

    test('an empty follow-set clears the schedule', () async {
      await run(service(), followed: const {});
      expect(fake.cancelAllCalls, 1);
      expect(fake.scheduled, isEmpty);
    });

    test('ephemeral (unkept Prashna) charts are skipped even if followed',
        () async {
      final prashna = Kundli(
        id: 'p1',
        name: 'Prashna',
        relationTag: 'Prashna',
        birthUtc: _t0,
        latitude: 0,
        longitude: 0,
        timezoneName: 'UTC',
        utcOffsetMinutes: 0,
        placeName: 'Nowhere',
        isEphemeral: true,
        createdAt: _t0,
        updatedAt: _t0,
      );
      await run(service(), kundlis: [prashna], followed: {'p1'});
      expect(fake.scheduled, isEmpty);
    });

    test('one unbuildable chart does not cost the others their alerts',
        () async {
      final s = KundliAlertService(
        scheduler: fake,
        events: ({
          required kundli,
          required defaultAyanamsaId,
          required l10n,
          required settings,
          required from,
          required to,
        }) {
          if (kundli.id == 'k1') throw StateError('corrupt row');
          return events(
            kundli: kundli,
            defaultAyanamsaId: defaultAyanamsaId,
            l10n: l10n,
            settings: settings,
            from: from,
            to: to,
          );
        },
      );
      await run(s, followed: {'k1', 'k2'});
      expect(fake.scheduled, hasLength(3));
      expect(fake.scheduled.every((a) => a.payload == 'k2'), isTrue);
    });

    /// Four events for the one chart, the FIRST of which has already
    /// slipped behind the clock — the shape of a long ephemeris pass
    /// overtaking an event that was still ahead when the scan began.
    List<FeedEvent> withOnePastEvent({
      required Kundli kundli,
      required int defaultAyanamsaId,
      required AppLocalizations l10n,
      required AlertSettings settings,
      required DateTime from,
      required DateTime to,
    }) =>
        [
          for (final (offset, tag) in [
            (const Duration(seconds: -30), 'past'),
            (const Duration(days: 2), 'a'),
            (const Duration(days: 4), 'b'),
            (const Duration(days: 6), 'c'),
          ])
            FeedEvent(
              time: from.add(offset),
              label: '${kundli.id} $tag',
              source: FeedSource.dasha,
              dashaLevel: 1,
            ),
        ];

    test('an event that slipped into the past is never handed to the OS',
        () async {
      await run(KundliAlertService(scheduler: fake, events: withOnePastEvent));
      expect(fake.scheduled.map((a) => a.body.split(' · ').first),
          ['k1 a', 'k1 b', 'k1 c']);
    });

    test('an event inside the lead time is skipped as well', () async {
      // The margin exists so an alert can't be handed over in the same
      // instant it is due — the platform round trip alone can outlast
      // that, and the plugin throws on anything already past.
      final s = KundliAlertService(
        scheduler: fake,
        events: ({
          required kundli,
          required defaultAyanamsaId,
          required l10n,
          required settings,
          required from,
          required to,
        }) =>
            [
          for (final d in [
            kAlertLeadTime - const Duration(seconds: 1),
            kAlertLeadTime + const Duration(seconds: 1),
          ])
            FeedEvent(
              time: from.add(d),
              label: '${kundli.id} +${d.inSeconds}s',
              source: FeedSource.dasha,
              dashaLevel: 1,
            ),
        ],
      );
      await run(s);
      expect(fake.scheduled, hasLength(1));
      expect(
          fake.scheduled.single.body,
          startsWith(
              'k1 +${(kAlertLeadTime + const Duration(seconds: 1)).inSeconds}s'));
    });

    test('a rejected alert does not take the rest of the pass down', () async {
      // The likeliest offender sorts FIRST (time order), so an
      // unguarded loop would lose everything after it.
      fake.rejects = (a) => a.body.startsWith('k1 a');
      await run(KundliAlertService(scheduler: fake, events: withOnePastEvent));
      expect(fake.scheduled.map((a) => a.body.split(' · ').first),
          ['k1 b', 'k1 c']);
    });

    test('every alert being rejected still completes the pass', () async {
      fake.rejects = (_) => true;
      await run(KundliAlertService(scheduler: fake, events: withOnePastEvent));
      expect(fake.cancelAllCalls, 1);
      expect(fake.scheduled, isEmpty);
    });

    test('a concurrent request collapses into one extra pass', () async {
      final s = service();
      final first = run(s);
      final second = run(s); // arrives mid-pass
      await Future.wait([first, second]);
      // Two passes total (the queued rerun), never four.
      expect(fake.cancelAllCalls, 2);
      expect(fake.scheduled, hasLength(3));
    });

    test('a tapped alert routes to that chart', () async {
      final s = service();
      final routes = <String>[];
      s.onOpenRoute = routes.add;
      await s.init();
      fake.tapHandler!('k9');
      expect(routes, ['/kundli/k9']);
    });

    test('a cold start from an alert routes too', () async {
      fake.launchPayloadValue = 'k4';
      final s = service();
      final routes = <String>[];
      s.onOpenRoute = routes.add;
      await s.init();
      expect(routes, ['/kundli/k4']);
    });

    test('permission is asked once, and only when asked for', () async {
      final s = service();
      expect(fake.permissionRequests, 0);
      await s.ensurePermission();
      await s.ensurePermission();
      expect(fake.permissionRequests, 1);
    });

    group('diagnostics summary', () {
      test('round-trips what the pass handed to the OS', () async {
        final s = service();
        await run(s, followed: {'k1', 'k2'});
        final summary = await stored();

        expect(summary.hasRun, isTrue);
        // Stored as an epoch stamp, so it reads back as the same INSTANT
        // in local form — the screen renders it local anyway.
        expect(summary.computedAt!.isAtSameMomentAs(_t0), isTrue);
        expect(summary.alerts, hasLength(fake.scheduled.length));
        // Same records, same order, field for field.
        expect(
          summary.byTime.map((a) => (a.when, a.title, a.body, a.kundliId)),
          fake.scheduled.map((a) => (a.when, a.title, a.body, a.payload)),
        );
      });

      test('survives the JSON round trip unchanged', () async {
        await run(service());
        final first = await stored();
        // Read twice: the second read parses the same stored string, so
        // any lossy encode/decode shows up as a difference here.
        expect((await stored()).alerts, first.alerts);
      });

      test('an empty pass overwrites a previous one', () async {
        await run(service());
        expect((await stored()).alerts, isNotEmpty);

        await run(service(), followed: const {});
        final after = await stored();
        expect(after.hasRun, isTrue, reason: 'the empty pass still ran');
        expect(after.alerts, isEmpty);
      });

      test('a disabled master switch also records an empty pass', () async {
        await run(service(), settings: const AlertSettings(enabled: false));
        final summary = await stored();
        expect(summary.hasRun, isTrue);
        expect(summary.alerts, isEmpty);
      });

      test('records only what the OS accepted', () async {
        // A rejected alert is not scheduled, so claiming it on a
        // diagnostics screen would be the exact lie that screen exists
        // to prevent.
        fake.rejects = (a) => a.body.startsWith('k1 MD');
        await run(service());
        final summary = await stored();
        expect(summary.alerts, hasLength(2));
        expect(
          summary.alerts.any((a) => a.body.startsWith('k1 MD')),
          isFalse,
        );
      });

      test('no pass yet reads as "never run", not as "nothing scheduled"',
          () async {
        final summary = await stored();
        expect(summary.hasRun, isFalse);
        expect(summary.computedAt, isNull);
        expect(summary.alerts, isEmpty);
      });

      test('lastSchedule and pendingCount surface both sides', () async {
        final s = service();
        await run(s);
        fake.osPendingCount = 99;
        expect((await s.lastSchedule()).alerts, hasLength(3));
        expect(await s.pendingCount(), 99);
        fake.osPendingCount = null;
        expect(await s.pendingCount(), isNull);
      });
    });

    group('past-alert sweep', () {
      ScheduledAlertRecord rec(int id, Duration offset) => ScheduledAlertRecord(
            id: id,
            when: _t0.add(offset),
            title: 'k$id',
            body: 'body $id',
            kundliId: 'k1',
          );

      test('moves only what has passed', () {
        final swept = sweepPastAlerts(
          history: const [],
          scheduled: [
            rec(1, const Duration(days: -2)),
            rec(2, const Duration(hours: -1)),
            rec(3, const Duration(days: 5)),
          ],
          now: _t0,
        );
        expect(swept.map((r) => r.id), [2, 1], reason: 'newest first');
      });

      test('dedupes across repeated passes', () {
        // The summary is not trimmed as entries age, so the same record
        // is offered on every pass and every screen visit. Without the
        // dedupe, history would grow by one copy per resume.
        final scheduled = [rec(1, const Duration(days: -1))];
        var history =
            sweepPastAlerts(history: const [], scheduled: scheduled, now: _t0);
        for (var i = 0; i < 5; i++) {
          history =
              sweepPastAlerts(history: history, scheduled: scheduled, now: _t0);
        }
        expect(history, hasLength(1));
      });

      test('excludes the test alert', () {
        // A device check is not something that happened to a chart.
        final swept = sweepPastAlerts(
          history: const [],
          scheduled: [
            ScheduledAlertRecord(
              id: kTestAlertNotificationId,
              when: _t0.subtract(const Duration(minutes: 5)),
              title: 'Test alert',
              body: 'x',
              kundliId: '',
            ),
            rec(1, const Duration(days: -1)),
          ],
          now: _t0,
        );
        expect(swept.map((r) => r.id), [1]);
      });

      test('caps at kAlertHistoryCap, dropping the oldest', () {
        final many = [
          for (var i = 1; i <= kAlertHistoryCap + 40; i++)
            rec(i, Duration(days: -i)),
        ];
        final swept =
            sweepPastAlerts(history: const [], scheduled: many, now: _t0);
        expect(swept, hasLength(kAlertHistoryCap));
        expect(swept.first.id, 1, reason: 'newest kept');
        expect(swept.last.id, kAlertHistoryCap);
        expect(swept.map((r) => r.id), isNot(contains(kAlertHistoryCap + 40)));
      });

      test('respects an explicit smaller cap', () {
        final swept = sweepPastAlerts(
          history: const [],
          scheduled: [
            for (var i = 1; i <= 10; i++) rec(i, Duration(days: -i)),
          ],
          now: _t0,
          cap: 3,
        );
        expect(swept.map((r) => r.id), [1, 2, 3]);
      });

      test('legacy records with no id dedupe on their content', () {
        // A summary written before ids were stored reads back with id 0;
        // every such record must not collide into one entry.
        final a = ScheduledAlertRecord(
            when: _at(-12), title: 't', body: 'one', kundliId: 'k1');
        final b = ScheduledAlertRecord(
            when: _at(-11), title: 't', body: 'two', kundliId: 'k1');
        final swept =
            sweepPastAlerts(history: const [], scheduled: [a, b], now: _t0);
        expect(swept, hasLength(2));
      });

      test('a pass sweeps the previous summary into history', () async {
        // First pass schedules something already in the past relative to
        // the second pass's clock.
        final s = KundliAlertService(
          scheduler: fake,
          events: ({
            required kundli,
            required defaultAyanamsaId,
            required l10n,
            required settings,
            required from,
            required to,
          }) =>
              [
            FeedEvent(
              time: from.add(const Duration(days: 2)),
              label: '${kundli.id} MD',
              source: FeedSource.dasha,
              dashaLevel: 1,
            ),
          ],
        );
        await run(s);
        expect(await SettingsRepository().alertHistory(), isEmpty);

        // Second pass, a week later: the first pass's alert has passed.
        await s.reschedule(
          kundlis: [_kundli('k1', 'Asha')],
          followedIds: {'k1'},
          defaultAyanamsaId: 1,
          l10n: l10n,
          settings: const AlertSettings(),
          now: _t0.add(const Duration(days: 7)),
        );
        final history = await SettingsRepository().alertHistory();
        expect(history, hasLength(1));
        expect(history.single.body, startsWith('k1 MD'));
      });

      test('pastAlerts sweeps on read, without a pass', () async {
        // Alerts fire while the app is closed; the screen must not have
        // to wait for the next scheduling pass to show them.
        final s = service();
        await run(s);
        expect(await s.pastAlerts(now: _t0), isEmpty);
        // The fixture schedules at +3d/+5d/+9d, so a 10-day clock puts
        // every one of them behind us.
        final later =
            await s.pastAlerts(now: _t0.add(const Duration(days: 10)));
        expect(later, hasLength(3));
      });

      test('removePastAlert drops one entry; restore puts it back', () async {
        final s = service();
        await run(s);
        final history =
            await s.pastAlerts(now: _t0.add(const Duration(days: 10)));
        final victim = history.first;

        await s.removePastAlert(victim);
        expect(await SettingsRepository().alertHistory(), hasLength(2));

        await s.restorePastAlert(victim);
        final restored = await SettingsRepository().alertHistory();
        expect(restored, hasLength(3));
        expect(restored.first.dedupeKey, victim.dedupeKey,
            reason: 'restored in time order');
      });

      test('restore is idempotent', () async {
        final s = service();
        await run(s);
        final history =
            await s.pastAlerts(now: _t0.add(const Duration(days: 10)));
        await s.restorePastAlert(history.first);
        expect(await SettingsRepository().alertHistory(), hasLength(3));
      });
    });

    group('test alert', () {
      test('uses the reserved id, at a fixed delay, through the real path',
          () async {
        final s = service();
        final before = DateTime.now();
        expect(
          await s.sendTestAlert(
              title: 'Test alert', body: 'works', payload: 'k1'),
          isTrue,
        );
        expect(fake.scheduled, hasLength(1));
        final sent = fake.scheduled.single;
        expect(sent.id, kTestAlertNotificationId);
        expect(sent.payload, 'k1');
        // Inside the lead-time guard on purpose — the test path must
        // bypass it, or a delivery check would take a minute.
        expect(kTestAlertDelay, lessThan(kAlertLeadTime));
        expect(sent.when.isAfter(before), isTrue);
        expect(
          sent.when.isBefore(
              before.add(kTestAlertDelay + const Duration(seconds: 5))),
          isTrue,
        );
      });

      test('id is constant, so a repeat tap replaces rather than stacks',
          () async {
        final s = service();
        await s.sendTestAlert(title: 't', body: 'b');
        await s.sendTestAlert(title: 't', body: 'b');
        expect(fake.scheduled.map((a) => a.id).toSet(), {
          kTestAlertNotificationId,
        });
      });

      test('an empty payload is allowed (nothing followed)', () async {
        await service().sendTestAlert(title: 't', body: 'b');
        expect(fake.scheduled.single.payload, '');
      });

      test('a refused test alert reports false rather than throwing', () async {
        fake.rejects = (_) => true;
        expect(await service().sendTestAlert(title: 't', body: 'b'), isFalse);
      });

      test('the reserved id is outside alertNotificationId\'s range', () {
        // Not "unlikely to collide" — actually unreachable.
        expect(
          alertNotificationId('k', _t0, 'x'),
          isNot(kTestAlertNotificationId),
        );
        // The one hash value that would land on it steps aside instead.
        expect(
            kTestAlertNotificationId - 1, lessThan(kTestAlertNotificationId));
      });
    });
  });

  test('Android alarms stay inexact', () {
    // Exact alarms would mean declaring SCHEDULE_EXACT_ALARM /
    // USE_EXACT_ALARM — an alarm-clock-grade permission and a store
    // review — to buy minute precision on a month-out dasha change.
    expect(kAlertScheduleMode, AndroidScheduleMode.inexactAllowWhileIdle);
  });
}
