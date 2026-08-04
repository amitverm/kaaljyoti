/// On-device event alerts for followed kundlis.
///
/// Everything here is LOCAL. There is no server, no account and no
/// network call anywhere in this file: the app walks each followed
/// chart's own dasha tree and runs the same transit scan the Upcoming
/// Events feed uses, then hands the resulting instants to the OS as
/// scheduled local notifications. Nothing about a client's birth data
/// leaves the device to make an alert happen — which is the point, for
/// an audience whose "data" is other people's lives. (The unrelated
/// [PushService] is the server-driven pipe for Mahakosh/research
/// notifications, and stays build-time gated.)
///
/// SCOPE: sign ingresses are the sky's business, not a chart's, so they
/// are scheduled ONCE for the whole library — anonymously, with no
/// kundli attached — rather than once per followed kundli. Everything
/// else here is per-chart.
///
/// COPY RULE: notification text states what CHANGES and nothing else —
/// "Saturn enters Kumbha", "AD ends: Venus · begins: Sun". It never
/// says what a change means, is never framed as good or bad, and never
/// advises. The app computes; the astrologer interprets.
///
/// THREADING: sweph is not thread-safe, so every ephemeris call below
/// runs on the calling (main) isolate — see the note in transit_scan.
/// The pass yields between kundlis instead, so a 40-chart library does
/// not hold a frame hostage.
library;

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/astro/dasha/dasha.dart';
import '../core/astro/dasha/dasha_registry.dart';
import '../core/astro/ephemeris_service.dart';
import '../core/astro/event_feed.dart';
import '../core/astro/snapshot_builder.dart';
import '../core/astro/transit_scan.dart';
import '../data/models.dart';
import '../data/settings_repository.dart';
import '../l10n/astro_l10n.dart';

/// How far ahead alerts are scheduled. Re-run on every resume, so the
/// horizon keeps rolling forward; long enough to cover a consultation
/// booked a month out, short enough that a scan stays cheap.
const Duration kAlertWindow = Duration(days: 30);

/// Slack either side of the alert window when scanning Sade Sati.
///
/// [sadeSatiPhases] reports the occupancy interval it finds, CLIPPED to
/// the scan range — so scanning exactly [now, to] would report a phase
/// already in progress as "begins today" and fire a false alert. Saturn
/// takes ~2.5 years to cross a sign, so widening the scan by a year
/// either side puts both clipped ends comfortably outside the window,
/// where the feed's own filter discards them. ~150 extra samples.
const Duration _kSadeSatiMargin = Duration(days: 400);

/// Android channel for these alerts. One channel, so a user who wants
/// them quieter can do it in system settings without losing them.
const String kAlertChannelId = 'kundli_events';

/// How far ahead of the clock an event must still be to be worth
/// scheduling, checked at schedule time rather than scan time.
///
/// flutter_local_notifications throws on a past instant, so this is a
/// guard as much as a policy — but the policy stands on its own: an
/// alert for an instant that passed while the scan was running has
/// nothing left to tell anyone. A minute of margin absorbs the gap
/// between the last ephemeris call and the platform-channel round trip.
const Duration kAlertLeadTime = Duration(minutes: 1);

/// How Android is asked to fire a kundli alert.
///
/// DELIBERATELY INEXACT, and named rather than inlined so the decision
/// is assertable in a test: an exact alarm needs SCHEDULE_EXACT_ALARM —
/// a permission Google treats as alarm-clock-grade and reviews
/// accordingly — to buy minute precision on an event whose interest
/// lasts days. Delivery inside the OS's own batching window is the
/// right trade for "your client's antardasha changes today".
const AndroidScheduleMode kAlertScheduleMode =
    AndroidScheduleMode.inexactAllowWhileIdle;

/// The dasha system alerts are computed from. Vimshottari is the app's
/// default everywhere else and the only one in near-universal use; the
/// other three stay opt-in reading tools, not notification sources.
const DashaSystem kAlertDashaSystem = DashaSystem.vimshottari;

/// Notification id reserved for the "Send test alert" diagnostic.
///
/// FIXED, so tapping the button twice REPLACES the pending test rather
/// than stacking a second one — and reserved out of [alertNotificationId]'s
/// output range, so a real alert can never be silently overwritten by a
/// test (or vice versa).
const int kTestAlertNotificationId = 0x7FFFFFFF;

/// How far out the test alert is scheduled.
///
/// Deliberately inside [kAlertLeadTime] — the test path is a direct
/// schedule call, not a pass, so the lead-time guard does not apply and
/// must not: waiting a minute to find out whether notifications work at
/// all is the opposite of a diagnostic. It still goes out on
/// [kAlertScheduleMode], so what is exercised is the REAL delivery path,
/// inexact batching included. In practice Android fires a near-term
/// inexact alarm promptly; if a device's doze state delays it, that
/// delay is itself the diagnostic.
const Duration kTestAlertDelay = Duration(seconds: 10);

/// One notification, ready to hand to the OS.
class PendingAlert {
  const PendingAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;

  /// Absolute instant. Converted to the device's zone at schedule time.
  final DateTime when;

  /// Kundli id — the tap target. Empty when the alert belongs to no
  /// chart (a sign ingress, the test alert): the tap then just opens
  /// the app.
  final String payload;
}

/// The OS notification surface, behind an interface so the scheduling
/// logic can be tested without a platform channel.
abstract interface class AlertScheduler {
  Future<void> init({required void Function(String payload) onTap});

  /// Payload of the notification that cold-started the app, if any.
  Future<String?> launchPayload();

  /// Asks for the OS permission. Called lazily — the first time a user
  /// follows a chart or turns the master switch on — never at startup:
  /// a permission prompt on first launch, before the user has any idea
  /// what would be notified, is the reliable way to get a "no".
  Future<bool> requestPermissions();

  /// Whether the OS will actually show what we schedule. Unlike
  /// delivery, this the platform WILL tell us — so the Past list can
  /// stop guessing and say plainly that alerts are switched off.
  Future<bool> notificationsEnabled();

  Future<void> cancelAll();

  Future<void> schedule(PendingAlert alert);

  /// How many notifications the OS actually holds for us, or null when
  /// it cannot be asked. This is the only view of the REAL schedule the
  /// app has — the persisted summary is merely what we believe we
  /// requested — so the diagnostics screen shows both and lets a
  /// mismatch speak for itself.
  Future<int?> pendingCount();
}

/// flutter_local_notifications, wrapped.
class LocalAlertScheduler implements AlertScheduler {
  LocalAlertScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init({required void Function(String payload) onTap}) async {
    if (_initialized) return;
    _initialized = true;

    // zonedSchedule needs a real local zone; the database itself is
    // loaded in main(). Without this tz.local is UTC, which still
    // denotes the right instant but makes every scheduled time read
    // wrong in logs and in the plugin's own iOS date components.
    try {
      tz.setLocalLocation(
          tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // Unknown/absent zone name — UTC is a correct-instant fallback.
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // All three false: permissions are requested lazily, on the
        // first follow, not as a side effect of initialization.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTap(payload);
      },
    );

    await _android?.createNotificationChannel(const AndroidNotificationChannel(
      kAlertChannelId,
      'Kundli alerts',
      description: 'Upcoming dasha changes, transits and Sade Sati phases '
          'for the kundlis you follow.',
      importance: Importance.defaultImportance,
    ));
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  @override
  Future<bool> requestPermissions() async {
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            sound: true,
            // No badge: a count of unread astrological events is a
            // nag, not information.
            badge: false,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> notificationsEnabled() async {
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    final ios = _ios;
    if (ios != null) {
      return (await ios.checkPermissions())?.isEnabled ?? true;
    }
    // Neither platform object resolves (tests, desktop). Default TRUE:
    // accusing a working OS of blocking alerts is the worse error.
    return true;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<int?> pendingCount() async {
    try {
      return (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> schedule(PendingAlert alert) => _plugin.zonedSchedule(
        alert.id,
        alert.title,
        alert.body,
        tz.TZDateTime.from(alert.when.toLocal(), tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            kAlertChannelId,
            'Kundli alerts',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(presentBadge: false),
        ),
        androidScheduleMode: kAlertScheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: alert.payload,
      );
}

/// Stable 31-bit notification id for one (kundli, instant, label).
///
/// Must be a PURE function of the event, not a counter: every
/// reschedule cancels and re-adds the whole set, and an event that
/// survives the rebuild has to land on the same id or the OS would
/// treat it as a new notification. FNV-1a rather than [Object.hash]
/// because it has to be identical across app restarts, which a hash
/// built on `String.hashCode` is not guaranteed to be.
int alertNotificationId(String kundliId, DateTime time, String label) {
  var h = 0x811c9dc5;
  void mix(String s) {
    for (final unit in s.codeUnits) {
      h = (h ^ unit) & 0xFFFFFFFF;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
  }

  mix(kundliId);
  mix('|${time.toUtc().millisecondsSinceEpoch}|');
  mix(label);
  final id = h & 0x7FFFFFFF;
  // Step off the diagnostic's reserved id rather than merely hoping the
  // hash misses it. One value in 2^31 maps to its neighbour, which costs
  // nothing and makes "reserved" true instead of probable.
  return id == kTestAlertNotificationId ? id - 1 : id;
}

/// How many past alerts are kept. Deep enough to answer "did anything
/// fire last month?", shallow enough that the list stays cheap to encode
/// on every pass.
const int kAlertHistoryCap = 200;

/// Moves alerts whose moment has passed out of [scheduled] and into
/// [history] — a pure function, so the rolling record can be tested
/// without a clock, a plugin, or prefs.
///
/// Deduped by [ScheduledAlertRecord.dedupeKey]: a surviving alert keeps
/// its id across every rebuild pass, and the summary is not trimmed when
/// entries age out, so the same record is offered to this sweep again
/// and again. Without the dedupe, history would grow by one copy per
/// resume.
///
/// Newest first, capped at [cap] with the OLDEST dropped: a diagnostics
/// list is read from the top.
List<ScheduledAlertRecord> sweepPastAlerts({
  required List<ScheduledAlertRecord> history,
  required List<ScheduledAlertRecord> scheduled,
  required DateTime now,
  int cap = kAlertHistoryCap,
}) {
  final byKey = <String, ScheduledAlertRecord>{};
  void take(ScheduledAlertRecord r) => byKey.putIfAbsent(r.dedupeKey, () => r);

  for (final r in history) {
    take(r);
  }
  for (final r in scheduled) {
    // A test alert is a device check, not something that happened to a
    // chart — it has no business in a record of a client's timeline.
    if (r.id == kTestAlertNotificationId) continue;
    if (r.when.isAfter(now)) continue;
    take(r);
  }

  final out = byKey.values.toList()..sort((a, b) => b.when.compareTo(a.when));
  return out.length <= cap ? out : out.sublist(0, cap);
}

/// Produces one chart's in-window feed events. The production
/// implementation is [KundliAlertService.ephemerisEvents]; tests inject
/// synthetic events instead, the same way [scanGochar] takes a
/// `samplerFor` — sweph needs native assets that no unit test has.
typedef KundliEventsBuilder = List<FeedEvent> Function({
  required Kundli kundli,
  required int defaultAyanamsaId,
  required AppLocalizations l10n,
  required AlertSettings settings,
  required DateTime from,
  required DateTime to,
});

class KundliAlertService {
  KundliAlertService({
    AlertScheduler? scheduler,
    KundliEventsBuilder? events,
    SettingsRepository? settingsRepo,
  })  : scheduler = scheduler ?? LocalAlertScheduler(),
        _events = events ?? ephemerisEvents,
        _needsEphemeris = events == null,
        _settings = settingsRepo ?? SettingsRepository();

  final AlertScheduler scheduler;
  final KundliEventsBuilder _events;
  final bool _needsEphemeris;
  final SettingsRepository _settings;

  /// Set by the root app widget, exactly as [PushService.onOpenRoute]
  /// is: a tapped alert navigates through the same router as everything
  /// else, so this service never needs a BuildContext.
  void Function(String route)? onOpenRoute;

  bool _initialized = false;
  bool _running = false;
  bool _rerunQueued = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await scheduler.init(onTap: _open);
    // Cold start FROM a notification: the tap callback above never
    // fires in that case, the payload arrives through launch details.
    final payload = await scheduler.launchPayload();
    if (payload != null && payload.isNotEmpty) _open(payload);
  }

  void _open(String kundliId) => onOpenRoute?.call('/kundli/$kundliId');

  Future<bool> requestPermissions() => scheduler.requestPermissions();

  /// Whether alerts can reach the user at all. Optimistic on failure for
  /// the same reason as [LocalAlertScheduler.notificationsEnabled].
  Future<bool> notificationsEnabled() async {
    try {
      return await scheduler.notificationsEnabled();
    } catch (_) {
      return true;
    }
  }

  /// Ask for the notification permission at the moment the user first
  /// asks for a notification — following a kundli, or switching the
  /// master toggle on — and never before. Best-effort: a refusal (or a
  /// platform with nothing to ask) just means no alerts appear, and
  /// everything else in the app carries on.
  ///
  /// Once per app run: the OS itself caches the answer, so re-asking on
  /// every follow would be a no-op on iOS and a silent no-op on Android
  /// after two refusals.
  Future<void> ensurePermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    try {
      await init();
      await requestPermissions();
    } catch (_) {
      // Notifications are an accessory; never let this reach the user.
    }
  }

  bool _permissionAsked = false;

  /// Rebuilds the whole schedule from scratch: cancel everything, then
  /// re-derive it from the current follow-set and settings.
  ///
  /// Rebuild-all rather than diff, because the source data moves under
  /// us constantly — an edited birth time, a changed default ayanamsa
  /// or simply the passage of time all change which events fall in the
  /// window. Ids are a pure function of the event ([alertNotificationId]),
  /// so a surviving event keeps its slot regardless.
  ///
  /// Concurrent calls collapse: a request arriving mid-pass sets a flag
  /// and the pass re-runs once at the end, so a burst of follow toggles
  /// costs one extra scan, not one per toggle.
  Future<void> reschedule({
    required List<Kundli> kundlis,
    required Set<String> followedIds,
    required int defaultAyanamsaId,
    required AppLocalizations l10n,
    required AlertSettings settings,
    DateTime? now,
  }) async {
    if (_running) {
      _rerunQueued = true;
      return;
    }
    _running = true;
    try {
      do {
        _rerunQueued = false;
        await _pass(
          kundlis: kundlis,
          followedIds: followedIds,
          defaultAyanamsaId: defaultAyanamsaId,
          l10n: l10n,
          settings: settings,
          now: now,
        );
      } while (_rerunQueued);
    } finally {
      _running = false;
    }
  }

  Future<void> _pass({
    required List<Kundli> kundlis,
    required Set<String> followedIds,
    required int defaultAyanamsaId,
    required AppLocalizations l10n,
    required AlertSettings settings,
    DateTime? now,
  }) async {
    await scheduler.cancelAll();
    if (!settings.enabled || !settings.anyCategory || followedIds.isEmpty) {
      // An empty pass still records itself. "Alerts are off / you follow
      // nothing" and "the scheduler has never run" look identical on the
      // diagnostics screen otherwise, and they are very different bugs.
      await _record(const [], now);
      return;
    }

    final from = (now ?? DateTime.now()).toUtc();
    final to = from.add(kAlertWindow);

    // Identity map, not a field on FeedEvent: which chart an event came
    // from is a fact about THIS pass, and the feed type is shared with
    // the single-chart UI where the question doesn't arise.
    final owner = <FeedEvent, Kundli>{};
    final all = <FeedEvent>[];

    if (_needsEphemeris) await EphemerisService.init();

    for (final kundli in kundlis) {
      if (!followedIds.contains(kundli.id)) continue;
      // Ephemeral (unkept Prashna) charts are not part of the library
      // the user follows; a Mahakosh id never reaches this list, but
      // guarding is free.
      if (kundli.isEphemeral) continue;
      try {
        for (final event in _events(
          kundli: kundli,
          defaultAyanamsaId: defaultAyanamsaId,
          l10n: l10n,
          settings: settings,
          from: from,
          to: to,
        )) {
          owner[event] = kundli;
          all.add(event);
        }
      } catch (_) {
        // One unbuildable chart (corrupt row, out-of-range date) must
        // not cost every other chart its alerts.
      }
      // Yield: the whole pass is main-isolate by necessity, so give the
      // frame scheduler a gap between charts.
      await Future<void>.delayed(Duration.zero);
    }

    // Re-read the clock AFTER the scan, not before it. The loop above
    // is main-isolate ephemeris work over the whole followed library
    // and can take seconds; `from` is by then a stale reading, and an
    // event that sat a moment ahead of it may now be behind us. (An
    // injected `now` is honoured so tests stay hermetic.)
    final cutoff = (now ?? DateTime.now()).toUtc().add(kAlertLeadTime);

    // What the OS actually accepted — not what we selected. The skipped
    // and the rejected are exactly the entries a diagnostics screen must
    // not claim are scheduled.
    final accepted = <ScheduledAlertRecord>[];

    // Deduped BEFORE selection: a library of 40 charts produces 40
    // copies of every ingress, and the cap is applied to whatever it is
    // given — unfiltered, one sign change would spend 40 of the 60
    // slots that per-chart alerts need.
    for (final event in selectAlertEvents(dedupeGlobalAlertEvents(all))) {
      // The plugin REJECTS a past instant outright, and because the
      // list is in time order the offender is the first iteration —
      // one slipped event would otherwise abort the loop and silently
      // cost every later alert its schedule until the next resume.
      // Nothing is lost by dropping it: an alert for a moment that has
      // already passed has no value to deliver.
      if (!event.time.toUtc().isAfter(cutoff)) continue;

      // A global event names no chart, so it gets none: empty kundli id
      // throughout — the tap handler ignores an empty payload and just
      // opens the app, the alerts screen renders such a record without a
      // destination, and the id is hashed with '' so all N charts land
      // on the one slot. `owner` is only meaningful on the other branch.
      final global = isGlobalAlertEvent(event);
      final kundli = global ? null : owner[event]!;
      final kundliId = kundli?.id ?? '';
      // "what changed · where it came from" — no reading, no advice.
      // A global alert has nowhere to put the chart name, so the change
      // itself becomes the title and the source stands alone as body.
      final title = global ? event.label : kundli!.name;
      final body = global
          ? event.sourceLabel(l10n)
          : '${event.label} · ${event.sourceLabel(l10n)}';
      final id = alertNotificationId(kundliId, event.time, event.label);
      try {
        await scheduler.schedule(PendingAlert(
          id: id,
          title: title,
          body: body,
          when: event.time,
          payload: kundliId,
        ));
        accepted.add(ScheduledAlertRecord(
          id: id,
          when: event.time,
          title: title,
          body: body,
          kundliId: kundliId,
        ));
      } catch (_) {
        // Per alert, for the same reason: a single rejection (a
        // platform limit hit, a zone the OS dislikes) must cost that
        // one alert and nothing else. Silent by design — the user
        // asked to hear about their charts, not about the scheduler.
      }
    }

    await _record(accepted, now);
  }

  /// Persist what this pass scheduled, for the alerts screen.
  ///
  /// Sweeps the PREVIOUS summary into history first: overwriting it is
  /// the moment those entries would otherwise be lost, and an alert
  /// whose moment has passed is exactly what the Past list is for.
  ///
  /// Best-effort throughout: failing to write a display cache must never
  /// fail the pass that actually scheduled the notifications.
  Future<void> _record(List<ScheduledAlertRecord> alerts, DateTime? now) async {
    final at = now ?? DateTime.now();
    try {
      await _sweepHistory(at);
      await _settings.setAlertScheduleSummary(
          AlertScheduleSummary(computedAt: at, alerts: alerts));
    } catch (_) {
      // Display cache only — the OS still holds the real schedule.
    }
  }

  Future<List<ScheduledAlertRecord>> _sweepHistory(DateTime now) async {
    final previous = await _settings.alertScheduleSummary();
    final history = await _settings.alertHistory();
    final swept = sweepPastAlerts(
      history: history,
      scheduled: previous.alerts,
      now: now,
    );
    // Only write when it actually changed — this runs on every pass AND
    // on every visit to the Past list, and re-encoding 200 records to
    // store the identical string is pure waste.
    final before = [for (final r in history) r.dedupeKey].join(',');
    final after = [for (final r in swept) r.dedupeKey].join(',');
    if (before != after) await _settings.setAlertHistory(swept);
    return swept;
  }

  /// The last pass's schedule as recorded, for display.
  Future<AlertScheduleSummary> lastSchedule() =>
      _settings.alertScheduleSummary();

  /// Past alerts, newest first — sweeping the current summary first so
  /// the list is right when the screen opens without a pass having run
  /// (the common case: alerts fire while the app is closed).
  Future<List<ScheduledAlertRecord>> pastAlerts({DateTime? now}) async {
    try {
      return await _sweepHistory(now ?? DateTime.now());
    } catch (_) {
      return const [];
    }
  }

  /// Drop one past alert (the user swiped it away).
  ///
  /// Note this cannot be undone BY THE SWEEP: the entry is gone from
  /// history, and the summary it originally came from is only re-offered
  /// while that pass's record survives. [restorePastAlert] exists for
  /// the undo action rather than relying on a re-sweep.
  Future<void> removePastAlert(ScheduledAlertRecord record) async {
    try {
      final history = await _settings.alertHistory();
      await _settings.setAlertHistory([
        for (final r in history)
          if (r.dedupeKey != record.dedupeKey) r,
      ]);
    } catch (_) {
      // A failed dismissal just means it is still there next time.
    }
  }

  Future<void> restorePastAlert(ScheduledAlertRecord record) async {
    try {
      final history = await _settings.alertHistory();
      if (history.any((r) => r.dedupeKey == record.dedupeKey)) return;
      final next = [...history, record]
        ..sort((a, b) => b.when.compareTo(a.when));
      await _settings.setAlertHistory(next.length <= kAlertHistoryCap
          ? next
          : next.sublist(0, kAlertHistoryCap));
    } catch (_) {
      // Undo is a courtesy; failing it must not throw at the user.
    }
  }

  /// How many notifications the OS is actually holding, or null when it
  /// won't say. Compared against [lastSchedule] on the diagnostics
  /// screen; a difference means the two have drifted, which is the
  /// single most useful thing that screen can tell anyone.
  Future<int?> pendingCount() async {
    try {
      return await scheduler.pendingCount();
    } catch (_) {
      return null;
    }
  }

  /// Fire one real notification [kTestAlertDelay] from now, through the
  /// ordinary schedule path — same channel, same details, same
  /// (inexact) Android mode — so that what it proves is that REAL
  /// alerts can be delivered on this device, not merely that a test
  /// code path runs.
  ///
  /// Deliberately bypasses [kAlertLeadTime]: this is a direct schedule
  /// call rather than a pass, and a diagnostic you must wait a minute
  /// for is not one. Returns false if the platform refused it.
  Future<bool> sendTestAlert({
    required String title,
    required String body,
    String payload = '',
  }) async {
    try {
      await init();
      await scheduler.schedule(PendingAlert(
        id: kTestAlertNotificationId,
        title: title,
        body: body,
        when: DateTime.now().add(kTestAlertDelay),
        // An empty payload is the honest value when nothing is
        // followed: the tap handler ignores it and the notification
        // just opens the app.
        payload: payload,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// All in-window feed events for one chart, in the enabled
  /// categories — the production [KundliEventsBuilder]. Synchronous:
  /// every ephemeris call must stay on this isolate, and the arithmetic
  /// between them is trivial.
  static List<FeedEvent> ephemerisEvents({
    required Kundli kundli,
    required int defaultAyanamsaId,
    required AppLocalizations l10n,
    required AlertSettings settings,
    required DateTime from,
    required DateTime to,
  }) {
    final ayanamsaId = kundli.ayanamsaOverrideId ?? defaultAyanamsaId;
    final snapshot =
        SnapshotBuilder().buildSync(kundli.toBirthData(), ayanamsaId);
    final out = <FeedEvent>[];

    if (settings.dasha) {
      // Pure arithmetic once the snapshot exists — no ephemeris.
      final result = dashaCalculators[kAlertDashaSystem]!.calculate(snapshot);
      out.addAll(dashaChangeEvents(l10n, result, from, to, fineLevels: false));
    }

    if (settings.transits) {
      out.addAll(transitFeedEvents(
        l10n,
        scanGochar(
          natalPoints: natalPointsFor(snapshot),
          from: from,
          to: to,
          ayanamsaId: ayanamsaId,
        ),
      ));
    }

    if (settings.sadeSati) {
      out.addAll(sadeSatiFeedEvents(
        l10n,
        sadeSatiPhases(
          moonSign: snapshot.moonSign,
          from: from.subtract(_kSadeSatiMargin),
          to: to.add(_kSadeSatiMargin),
          ayanamsaId: ayanamsaId,
        ),
        from,
        to,
      ));
    }

    // The window opens at `now`, but a scan boundary can land on it.
    return [
      for (final e in out)
        if (e.time.isAfter(from)) e
    ];
  }
}
