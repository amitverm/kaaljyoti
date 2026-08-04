/// The upcoming-events feed, as plain functions.
///
/// This is the assembly layer that merges three existing engines —
/// the dasha period tree, [scanGochar], and [sadeSatiPhases] — into one
/// sorted, localized timeline. It adds NO astrological math: every date
/// here comes from a calculator that already produced it.
///
/// Lifted out of `modules/upcoming_events_module.dart` so it can be
/// used headlessly, with no Riverpod, no ModuleContext and no
/// BuildContext: the module still renders the feed, and the local-
/// notification scheduler (`services/kundli_alert_service.dart`) builds
/// the very same events on a background pass. One source of truth for
/// "what happens next in this chart".
library;

import '../../l10n/astro_l10n.dart';
import 'dasha/dasha.dart';
import 'models.dart';
import 'transit_scan.dart';

enum FeedSource { dasha, transit, sadeSati }

class FeedEvent {
  const FeedEvent({
    required this.time,
    required this.label,
    required this.source,
    this.planet,
    this.dashaLevel,
    this.transitKind,
  });

  final DateTime time;
  final String label;
  final FeedSource source;
  final Planet? planet; // colors + filters the label, where known

  /// Dasha events only: 1 = mahadasha … 5 = pran. Carried so a consumer
  /// can rank a mahadasha change above a pratyantar one WITHOUT parsing
  /// the (localized) label back apart. Ignored by the feed UI.
  final int? dashaLevel;

  /// Transit events only: ingress vs. drishti hit — same reason.
  final TransitEventKind? transitKind;

  String sourceLabel(AppLocalizations l10n) => switch (source) {
        FeedSource.dasha => l10n.ueSourceDasha,
        FeedSource.transit => l10n.ueSourceTransit,
        FeedSource.sadeSati => l10n.ueSourceSadeSati,
      };
}

/// Short level tags used in dasha-change lines (1 = mahadasha … 5 = pran).
const kDashaLevelTag = {1: 'MD', 2: 'AD', 3: 'PD', 4: 'SD', 5: 'PrD'};

/// Walks the WHOLE dasha tree (not just the currently-active chain),
/// recursing only into branches that overlap [now, to], and emits an
/// event for every period at level <= [maxLevel] whose `end` falls
/// inside the window — this is the fix for the original bug, which
/// only ever looked at `chainAt(now)` (one period per level: whatever
/// is active RIGHT now) and so silently dropped every subsequent
/// change within a longer window (e.g. a 24-month window spanning two
/// antardasha changes only ever showed the first).
void walkDashaLevel(
  AppLocalizations l10n,
  List<DashaPeriod> siblings,
  DateTime now,
  DateTime to,
  int maxLevel,
  List<FeedEvent> out,
) {
  for (var i = 0; i < siblings.length; i++) {
    final p = siblings[i];
    final overlapsWindow = p.start.isBefore(to) && p.end.isAfter(now);
    if (!overlapsWindow) continue;
    if (p.level <= maxLevel && p.end.isAfter(now) && !p.end.isAfter(to)) {
      final next = i + 1 < siblings.length ? siblings[i + 1] : null;
      final tag = kDashaLevelTag[p.level] ?? p.levelName;
      out.add(FeedEvent(
        time: p.end,
        label: next == null
            ? l10n.ueDashaEnds(tag, dashaLordLabel(l10n, p))
            : l10n.ueDashaEndsBegins(
                tag, dashaLordLabel(l10n, p), dashaLordLabel(l10n, next)),
        source: FeedSource.dasha,
        planet: p.planet,
        dashaLevel: p.level,
      ));
    }
    if (p.level < maxLevel) {
      walkDashaLevel(l10n, p.children, now, to, maxLevel, out);
    }
  }
}

/// Dasha-change lines from an already-computed [result]. [fineLevels]
/// descends to sookshma/pran (5) instead of stopping at pratyantar (3).
List<FeedEvent> dashaChangeEvents(
  AppLocalizations l10n,
  DashaResult result,
  DateTime now,
  DateTime to, {
  required bool fineLevels,
}) {
  final maxLevel = fineLevels ? 5 : 3;
  final out = <FeedEvent>[];
  walkDashaLevel(l10n, result.periods, now, to, maxLevel, out);
  return out;
}

/// Sade Sati phase starts/ends clipped to [now, to] (callers pass the
/// full phase series — this just filters).
List<FeedEvent> sadeSatiFeedEvents(AppLocalizations l10n,
    List<SadeSatiPhase> phases, DateTime now, DateTime to) {
  final out = <FeedEvent>[];
  bool within(DateTime t) => !t.isBefore(now) && !t.isAfter(to);
  for (final ph in phases) {
    if (within(ph.start)) {
      out.add(FeedEvent(
          time: ph.start,
          label: l10n.ueSadeSatiBegins(ph.kind.label(l10n)),
          source: FeedSource.sadeSati));
    }
    if (within(ph.end)) {
      out.add(FeedEvent(
          time: ph.end,
          label: l10n.ueSadeSatiEnds(ph.kind.label(l10n)),
          source: FeedSource.sadeSati));
    }
  }
  return out;
}

/// Natal reference points for a transit scan: the 9 grahas + Lagna,
/// keyed by STABLE ENGLISH identifiers (`Planet.displayName` / 'Lagna')
/// — [natalPointLabel] maps them back for display. Lives here beside
/// the feed rather than in the provider layer so headless callers can
/// build a scan without pulling in Riverpod.
Map<String, double> natalPointsFor(AstroSnapshot s) => {
      for (final p in s.positions.values) p.planet.displayName: p.longitude,
      'Lagna': s.ascendant,
    };

/// Localized feed lines for a [scanGochar] result.
List<FeedEvent> transitFeedEvents(
        AppLocalizations l10n, List<TransitEvent> events) =>
    [
      for (final e in events)
        FeedEvent(
          time: e.time,
          label: transitEventLabel(l10n, e),
          source: FeedSource.transit,
          planet: e.planet,
          transitKind: e.kind,
        ),
    ];

// ---------------------------------------------------------------------------
// Alert selection
// ---------------------------------------------------------------------------

/// Priority bands for on-device alerts, most consequential first.
///
/// The ordering is the editorial judgement of the feature and the only
/// place it is expressed: a 30-day window across a working library can
/// easily hold several hundred feed events, and an astrologer notified
/// about all of them is notified about none. Bands are filled whole,
/// in this order, until the cap is reached — so a mahadasha change in
/// chart #40 always beats a Mars drishti in chart #1.
enum AlertBand {
  /// Mahadasha changes and Sade Sati phase boundaries — the two things
  /// a client is likely to ring about the week they happen.
  majorPeriod,

  /// Antardasha changes.
  antardasha,

  /// Pratyantardasha changes.
  pratyantardasha,

  /// Saturn / Jupiter / Rahu / Ketu ingresses: years apart, felt for
  /// months.
  slowIngress,

  /// Mars ingress — six-weekly, so common enough to rank below.
  marsIngress,

  /// Drishti hits on natal points. The most numerous by far.
  aspect,
}

/// Slow movers whose sign changes rank above Mars'.
const _kSlowIngressPlanets = {
  Planet.saturn,
  Planet.jupiter,
  Planet.rahu,
  Planet.ketu,
};

/// Which band [e] belongs to, or null when it is not alert-worthy at
/// all (sookshma/pran dasha changes, ingresses of the fast grahas).
AlertBand? alertBandOf(FeedEvent e) {
  switch (e.source) {
    case FeedSource.sadeSati:
      return AlertBand.majorPeriod;
    case FeedSource.dasha:
      return switch (e.dashaLevel) {
        1 => AlertBand.majorPeriod,
        2 => AlertBand.antardasha,
        3 => AlertBand.pratyantardasha,
        _ => null,
      };
    case FeedSource.transit:
      if (e.transitKind == TransitEventKind.aspect) return AlertBand.aspect;
      if (e.transitKind != TransitEventKind.ingress) return null;
      if (_kSlowIngressPlanets.contains(e.planet)) return AlertBand.slowIngress;
      return e.planet == Planet.mars ? AlertBand.marsIngress : null;
  }
}

/// Whether [e] is a fact about the SKY rather than about any one chart.
///
/// A sign ingress — "Mars enters Mithuna" — happens once, to everyone;
/// it carries no natal input at all, so the same instant and the same
/// label come back out of every followed chart's scan. A drishti hit is
/// the opposite: it is measured against that chart's natal points, and
/// two charts hit by the same transiting graha are two different events.
/// Dasha and Sade Sati are natal by construction.
///
/// The distinction is what lets the scheduler announce an ingress once,
/// anonymously, instead of once per followed kundli.
bool isGlobalAlertEvent(FeedEvent e) =>
    e.source == FeedSource.transit &&
    e.transitKind == TransitEventKind.ingress;

/// Collapses repeats of the same global event down to one.
///
/// Must run BEFORE [selectAlertEvents]: the cap is applied to whatever
/// it is handed, so N copies of one ingress would otherwise eat N slots
/// and crowd out per-chart alerts from later bands.
///
/// Keyed on instant + label, keeping the FIRST occurrence and leaving
/// order alone; non-global events pass straight through, untouched and
/// unexamined. A kundli carrying an ayanamsa override computes its
/// ingress at a genuinely different instant, so its event has a
/// different key and correctly survives as its own alert — the key is
/// not a heuristic for "same event", it IS the identity.
List<FeedEvent> dedupeGlobalAlertEvents(List<FeedEvent> events) {
  final seen = <String>{};
  final out = <FeedEvent>[];
  for (final e in events) {
    if (!isGlobalAlertEvent(e)) {
      out.add(e);
      continue;
    }
    if (seen.add('${e.time.toUtc().millisecondsSinceEpoch}|${e.label}')) {
      out.add(e);
    }
  }
  return out;
}

/// Total scheduled alerts across ALL followed kundlis. Both platforms
/// impose their own limits (iOS keeps only 64 pending local
/// notifications and silently drops the rest), and this sits under the
/// lowest of them with room to spare.
const int kAlertCap = 60;

/// Picks at most [cap] events to actually notify about, band by band in
/// [AlertBand] order, earliest first within a band — a pure function of
/// its input, so the policy can be tested without an ephemeris, a
/// plugin, or a clock.
///
/// The result is returned in TIME order: the caller schedules them, and
/// a scheduler reading them chronologically is easier to reason about
/// than one reading them by rank.
List<FeedEvent> selectAlertEvents(
  Iterable<FeedEvent> events, {
  int cap = kAlertCap,
}) {
  if (cap <= 0) return const [];
  final banded = <AlertBand, List<FeedEvent>>{};
  for (final e in events) {
    final band = alertBandOf(e);
    if (band == null) continue;
    (banded[band] ??= []).add(e);
  }

  final picked = <FeedEvent>[];
  for (final band in AlertBand.values) {
    final bucket = banded[band];
    if (bucket == null) continue;
    bucket.sort((a, b) => a.time.compareTo(b.time));
    for (final e in bucket) {
      if (picked.length >= cap) break;
      picked.add(e);
    }
    if (picked.length >= cap) break;
  }
  picked.sort((a, b) => a.time.compareTo(b.time));
  return picked;
}
