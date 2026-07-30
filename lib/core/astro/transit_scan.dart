/// Transit scanning engine: finds the exact instants a moving body
/// crosses a target longitude within a window — the shared core for
/// the Gochar timeline, Upcoming Events feed, and Sade Sati tracker.
///
/// Pure Dart and dependency-injected: callers pass a [LongitudeAt]
/// sampler, so the engine is unit-testable with synthetic motion and
/// production code wires in the Swiss Ephemeris (see
/// [ephemerisLongitude]). Retrograde-safe: a planet that crosses a
/// boundary, retrogrades back, and crosses again yields THREE events.
library;

import 'ephemeris_service.dart';
import 'models.dart';

/// Sidereal longitude of one body at instant [t] (UTC).
typedef LongitudeAt = double Function(DateTime t);

double _norm360(double x) => ((x % 360) + 360) % 360;

/// Signed shortest angular distance, in (-180, 180].
double _norm180(double x) {
  final n = _norm360(x);
  return n > 180 ? n - 360 : n;
}

/// Production sampler for [planet] — single-body ephemeris call, and
/// memoized per instant: scans walk the SAME coarse grid once per
/// crossing target (12 sign boundaries, plus every drishti × natal
/// point in [scanGochar]), so without the cache a year-long scan
/// recomputes identical samples ~50×. Together with the single-body
/// call (was: all nine bodies per sample) this took the dashboard's
/// first-mount scan load from ~10^6 swe_calc calls to ~10^3 — the
/// Sentry KAALJYOTI-PROD-4/5 main-thread hangs. Results are
/// bit-identical: same values, just not recomputed.
///
/// The cache lives inside the closure — hold one sampler per scan, not
/// globally (a global cache would pin every instant ever sampled).
LongitudeAt ephemerisLongitude(Planet planet, int ayanamsaId) {
  final svc = EphemerisService.instance;
  final cache = <int, double>{};
  return (t) {
    final utc = t.toUtc();
    return cache[utc.millisecondsSinceEpoch] ??=
        svc.planetLongitude(svc.julianDayUt(utc), ayanamsaId, planet);
  };
}

/// All instants in [from, to] where [f] crosses [target] (either
/// direction). Coarse sampling at [step] + bisection to ≤1 minute.
///
/// [step] must be small enough that the body cannot swing more than
/// ~180° between samples (1 day is safe for all grahas incl. Moon).
List<DateTime> findLongitudeCrossings(
  LongitudeAt f,
  double target,
  DateTime from,
  DateTime to, {
  Duration step = const Duration(hours: 24),
}) {
  // Parity-based detection (side = d < 0, zero counts as the positive
  // side) so an exact touch at a sample point can't double-count; any
  // residual near-duplicates are merged below.
  bool neg(double d) => d < 0;
  final out = <DateTime>[];
  var t0 = from;
  var d0 = _norm180(f(t0) - target);
  while (t0.isBefore(to)) {
    var t1 = t0.add(step);
    if (t1.isAfter(to)) t1 = to;
    final d1 = _norm180(f(t1) - target);
    if (neg(d0) != neg(d1) && (d0 - d1).abs() < 180) {
      // Side change without wrap → a crossing lies in (t0, t1].
      var a = t0, b = t1;
      final sideA = neg(d0);
      while (b.difference(a) > const Duration(minutes: 1)) {
        final mid = a.add(b.difference(a) ~/ 2);
        if (neg(_norm180(f(mid) - target)) == sideA) {
          a = mid;
        } else {
          b = mid;
        }
      }
      out.add(a.add(b.difference(a) ~/ 2));
    }
    if (!t1.isBefore(to)) break;
    t0 = t1;
    d0 = d1;
  }
  // Merge events closer than 2 minutes (touch detected from both sides).
  final deduped = <DateTime>[];
  for (final t in out) {
    if (deduped.isEmpty ||
        t.difference(deduped.last) > const Duration(minutes: 2)) {
      deduped.add(t);
    }
  }
  return deduped;
}

/// Contiguous occupancy of signs by a body over [from, to]: which sign
/// it is in, from when to when. Retrograde re-entries produce separate
/// intervals. First interval starts at [from], last ends at [to].
List<({ZodiacSign sign, DateTime start, DateTime end})> signOccupancy(
  LongitudeAt f,
  DateTime from,
  DateTime to, {
  Duration step = const Duration(hours: 24),
}) {
  // Collect every 30°-boundary crossing, then walk them in order.
  final crossings = <DateTime>[
    for (var k = 0; k < 12; k++)
      ...findLongitudeCrossings(f, k * 30.0, from, to, step: step),
  ]..sort();
  final out = <({ZodiacSign sign, DateTime start, DateTime end})>[];
  var start = from;
  for (final c in crossings) {
    if (c.difference(start) < const Duration(minutes: 2)) continue;
    // Sample mid-interval to name the sign robustly.
    final mid = start.add(c.difference(start) ~/ 2);
    out.add((
      sign: ZodiacSign.fromLongitude(f(mid)),
      start: start,
      end: c,
    ));
    start = c;
  }
  final mid = start.add(to.difference(start) ~/ 2);
  out.add((sign: ZodiacSign.fromLongitude(f(mid)), start: start, end: to));
  return out;
}

// ---------------------------------------------------------------------------
// Gochar: transit hits to natal points
// ---------------------------------------------------------------------------

enum TransitEventKind { ingress, aspect }

class TransitEvent {
  const TransitEvent({
    required this.planet,
    required this.kind,
    required this.time,
    this.sign,
    this.natalPoint,
    this.drishti,
  });

  final Planet planet;
  final TransitEventKind kind;
  final DateTime time; // exact (≤1 min)

  /// Ingress: the sign entered.
  final ZodiacSign? sign;

  /// Aspect: which natal point is hit ('Moon', 'Lagna', …).
  final String? natalPoint;

  /// Aspect: 1 = conjunction, else the graha-drishti house (3/4/5/7/8/9/10).
  final int? drishti;

  String get label => switch (kind) {
        TransitEventKind.ingress =>
          '${planet.displayName} enters ${sign!.sanskrit} (${sign!.western})',
        TransitEventKind.aspect => drishti == 1
            ? '${planet.displayName} conjunct natal $natalPoint'
            : '${planet.displayName} ${drishti}th drishti on natal $natalPoint',
      };
}

/// Forward angle (degrees) of each Vedic drishti house from the planet.
const Map<int, double> drishtiAngle = {
  1: 0,
  3: 60,
  4: 90,
  5: 120,
  7: 180,
  8: 210,
  9: 240,
  10: 270,
};

/// Full drishti sets: Saturn 3/7/10, Jupiter 5/7/9, Mars 4/7/8, Rahu/
/// Ketu 5/7/9 (Jaimini-style node aspects; common professional
/// convention), everyone else conjunction + 7th.
List<int> drishtisOf(Planet p) => switch (p) {
      Planet.saturn => const [1, 3, 7, 10],
      Planet.jupiter => const [1, 5, 7, 9],
      Planet.mars => const [1, 4, 7, 8],
      Planet.rahu || Planet.ketu => const [1, 5, 7, 9],
      _ => const [1, 7],
    };

/// Slow movers whose hits are consultation-worthy by default.
const List<Planet> kGocharDefaultPlanets = [
  Planet.saturn,
  Planet.jupiter,
  Planet.rahu,
  Planet.ketu,
  Planet.mars,
];

/// Scan [from, to] for ingresses of [planets] and their drishti hits on
/// [natalPoints] (label → sidereal longitude). Returns events sorted by
/// time. [samplerFor] defaults to the live ephemeris; inject a fake in
/// tests.
List<TransitEvent> scanGochar({
  required Map<String, double> natalPoints,
  required DateTime from,
  required DateTime to,
  required int ayanamsaId,
  List<Planet> planets = kGocharDefaultPlanets,
  LongitudeAt Function(Planet)? samplerFor,
}) {
  final sampler = samplerFor ?? (p) => ephemerisLongitude(p, ayanamsaId);
  final out = <TransitEvent>[];
  for (final planet in planets) {
    final f = sampler(planet);
    // Ingresses.
    for (var k = 0; k < 12; k++) {
      for (final t in findLongitudeCrossings(f, k * 30.0, from, to)) {
        // Sample just after to know the sign actually entered
        // (a retrograde crossing "enters" the earlier sign).
        final after =
            ZodiacSign.fromLongitude(f(t.add(const Duration(hours: 6))));
        out.add(TransitEvent(
          planet: planet,
          kind: TransitEventKind.ingress,
          time: t,
          sign: after,
        ));
      }
    }
    // Drishti hits on natal points: f(t) + angle == natal
    // → crossing target = natal - angle.
    for (final d in drishtisOf(planet)) {
      final angle = drishtiAngle[d]!;
      for (final MapEntry(key: label, value: natal) in natalPoints.entries) {
        for (final t
            in findLongitudeCrossings(f, _norm360(natal - angle), from, to)) {
          out.add(TransitEvent(
            planet: planet,
            kind: TransitEventKind.aspect,
            time: t,
            natalPoint: label,
            drishti: d,
          ));
        }
      }
    }
  }
  out.sort((a, b) => a.time.compareTo(b.time));
  return out;
}

// ---------------------------------------------------------------------------
// Sade Sati
// ---------------------------------------------------------------------------

/// The phase of a Sade Sati occupancy, by Saturn's position relative to
/// the natal Moon: [rising] 12th, [peak] over the Moon, [setting] 2nd,
/// and [smallPanoti] the 4th/8th dhaiya (which is not part of the
/// seven-and-a-half years proper — modules filter on it).
///
/// Identity, not display text: modules filter, order, and colour by
/// phase, so this must not be a string the presentation layer
/// translates out from under them.
enum SadeSatiPhaseKind { rising, peak, setting, smallPanoti }

class SadeSatiPhase {
  const SadeSatiPhase({
    required this.kind,
    required this.sign,
    required this.start,
    required this.end,
  });

  final SadeSatiPhaseKind kind;
  final ZodiacSign sign;
  final DateTime start;
  final DateTime end;

  Duration get length => end.difference(start);
  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

/// Saturn-vs-natal-Moon phases over [from, to], including retrograde
/// re-entries (each occupancy interval is reported separately) and the
/// 4th/8th dhaiya. Sorted by start.
List<SadeSatiPhase> sadeSatiPhases({
  required ZodiacSign moonSign,
  required DateTime from,
  required DateTime to,
  required int ayanamsaId,
  LongitudeAt? saturn,
}) {
  final f = saturn ?? ephemerisLongitude(Planet.saturn, ayanamsaId);
  // 5-day steps are ample: Saturn needs ~2.5 months to cross a degree.
  final occ = signOccupancy(f, from, to, step: const Duration(days: 5));
  final m = moonSign.index;
  SadeSatiPhaseKind? kindFor(int signIdx) {
    final rel = (signIdx - m + 12) % 12;
    return switch (rel) {
      11 => SadeSatiPhaseKind.rising,
      0 => SadeSatiPhaseKind.peak,
      1 => SadeSatiPhaseKind.setting,
      3 || 7 => SadeSatiPhaseKind.smallPanoti,
      _ => null,
    };
  }

  return [
    for (final o in occ)
      if (kindFor(o.sign.index) case final k?)
        SadeSatiPhase(kind: k, sign: o.sign, start: o.start, end: o.end),
  ];
}

// ---------------------------------------------------------------------------
// Sade Sati — degree-based method
// ---------------------------------------------------------------------------

/// Half-width of the degree-based Sade Sati arc: Saturn counts as "in"
/// while it sits within this many degrees either side of the natal
/// Moon's EXACT longitude — a 90° arc centred on the Moon.
///
/// This is a second, independent reading of the same transit, not a
/// refinement of [sadeSatiPhases]: the classical method counts whole
/// SIGN occupancies (12th/1st/2nd from the Moon's rashi), so the two
/// disagree by up to a sign's worth of time at either end depending on
/// where in its rashi the Moon actually sits. Both are reported as-is;
/// neither is corrected against the other.
const double kSadeSatiDegreeOrb = 45.0;

/// Signed shortest separation Saturn − Moon, in (-180, 180]: negative
/// while Saturn is still approaching the Moon, positive once it has
/// passed. `abs() <= `[kSadeSatiDegreeOrb] is exactly what "inside the
/// arc" means, wrap included.
double sadeSatiSeparation(double saturnLon, double moonLon) =>
    _norm180(saturnLon - moonLon);

/// One maximal stretch of the degree-based Sade Sati arc: Saturn enters
/// at [start] and leaves at [end].
///
/// Retrograde Saturn can leave the arc and come back, so a single
/// "Sade Sati" in the classical sense may be reported here as several
/// windows — the same way [signOccupancy] lists a retrograde re-entry
/// as its own occupancy interval rather than papering over it.
class SadeSatiDegreeWindow {
  const SadeSatiDegreeWindow({
    required this.start,
    required this.end,
    this.conjunctions = const [],
    this.clippedStart = false,
    this.clippedEnd = false,
    this.approachingAtStart = true,
  });

  /// Saturn crosses INTO the arc (or the scan range began with it
  /// already inside — see [clippedStart]).
  final DateTime start;

  /// Saturn crosses OUT of the arc (or the scan range ended with it
  /// still inside — see [clippedEnd]).
  final DateTime end;

  /// Exact Saturn-over-Moon instants inside this window — normally one,
  /// three when Saturn retrogrades back over the Moon and forward
  /// again. Empty for the rising/setting halves of a split window.
  final List<DateTime> conjunctions;

  /// True when [start] is the scan range's own beginning rather than a
  /// real ±orb crossing (Saturn was already inside at `from`).
  final bool clippedStart;

  /// True when [end] is the scan range's own end rather than a real
  /// ±orb crossing (Saturn was still inside at `to`).
  final bool clippedEnd;

  /// Which side of the natal Moon Saturn is on at [start]: true while
  /// the separation is negative (Saturn approaching the Moon), false
  /// once it is positive (past it).
  ///
  /// RECORDED HERE, not inferred later. The sign flips at conjunctions
  /// and nowhere else, so a consumer holding this plus [conjunctions]
  /// can derive the side at every instant of the window by alternating
  /// — but only if it knows where the alternation STARTS, and that it
  /// cannot deduce. "Approaching before the first conjunction" is right
  /// for a window entered at −45° and wrong for one Saturn retrograded
  /// into from the far side, or one the scan range clipped open with
  /// Saturn already past. The sampler knows; nothing downstream does.
  final bool approachingAtStart;

  Duration get length => end.difference(start);
  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

/// What a stretch of a degree passage is: Saturn inside the arc and
/// still approaching the natal Moon, inside and separating from it, or
/// outside altogether between two windows of the same passage.
enum DegreeSpanKind { approaching, separating, outOfArc }

/// One shaded stretch of a passage — see [degreeArcSpans].
class DegreeArcSpan {
  const DegreeArcSpan({
    required this.kind,
    required this.start,
    required this.end,
  });

  final DegreeSpanKind kind;
  final DateTime start;
  final DateTime end;

  Duration get length => end.difference(start);
}

/// Decomposes one passage (consecutive windows of a single lap past the
/// Moon) into contiguous spans of a single kind: each window cut at its
/// exact conjunctions, plus the retrograde gaps between windows.
///
/// The cut rule is the whole point and is exact, not heuristic: the
/// separation's sign changes ONLY at a conjunction, so within a window
/// the side alternates at each conjunction instant, starting from the
/// window's own recorded [SadeSatiDegreeWindow.approachingAtStart].
/// A window with no conjunction is therefore a single span on the side
/// it began — which is exactly right for a grazing pass that turns back
/// before reaching the Moon, and for a re-entry window that trails the
/// last conjunction of the passage.
///
/// The spans tile the passage end to end, so a renderer can size them
/// proportionally without gaps.
List<DegreeArcSpan> degreeArcSpans(List<SadeSatiDegreeWindow> passage) {
  final out = <DegreeArcSpan>[];
  for (var i = 0; i < passage.length; i++) {
    final w = passage[i];
    var approaching = w.approachingAtStart;
    var cursor = w.start;
    for (final c in w.conjunctions) {
      if (!c.isAfter(cursor) || !c.isBefore(w.end)) continue;
      out.add(DegreeArcSpan(
        kind: approaching
            ? DegreeSpanKind.approaching
            : DegreeSpanKind.separating,
        start: cursor,
        end: c,
      ));
      approaching = !approaching;
      cursor = c;
    }
    out.add(DegreeArcSpan(
      kind:
          approaching ? DegreeSpanKind.approaching : DegreeSpanKind.separating,
      start: cursor,
      end: w.end,
    ));
    if (i + 1 < passage.length) {
      out.add(DegreeArcSpan(
        kind: DegreeSpanKind.outOfArc,
        start: w.end,
        end: passage[i + 1].start,
      ));
    }
  }
  return out;
}

/// Degree-based Sade Sati over [from, to]: every stretch where Saturn's
/// sidereal longitude is within [orb] of [natalMoonLon], with the exact
/// conjunction instants marked inside each.
///
/// Same plumbing as [sadeSatiPhases] — the injected [saturn] sampler
/// (defaulting to the memoized [ephemerisLongitude]), the same 5-day
/// coarse [step], and [findLongitudeCrossings] for the bisection — so
/// the two methods scan the same range at the same precision and can be
/// shown side by side. Like every scan in this file it runs on the
/// CALLING isolate: sweph is not thread-safe, so this must never be
/// handed to `Isolate.run`.
///
/// Boundaries are the two crossing targets `moon ± orb`. Crossing one
/// always flips inside/outside (a mere touch changes no side and yields
/// no crossing), so the intervals between consecutive boundary
/// crossings alternate and each "inside" interval is already maximal —
/// no merging pass is needed or wanted.
List<SadeSatiDegreeWindow> sadeSatiDegreeWindows({
  required double natalMoonLon,
  required DateTime from,
  required DateTime to,
  required int ayanamsaId,
  LongitudeAt? saturn,
  double orb = kSadeSatiDegreeOrb,
  Duration step = const Duration(days: 5),
}) {
  final f = saturn ?? ephemerisLongitude(Planet.saturn, ayanamsaId);
  final moon = _norm360(natalMoonLon);
  final edges = <DateTime>[
    ...findLongitudeCrossings(f, _norm360(moon - orb), from, to, step: step),
    ...findLongitudeCrossings(f, _norm360(moon + orb), from, to, step: step),
  ]..sort();
  final conjunctions = findLongitudeCrossings(f, moon, from, to, step: step);

  final out = <SadeSatiDegreeWindow>[];
  var start = from;
  void emit(DateTime segStart, DateTime segEnd) {
    // Sample mid-interval — the same robustness trick [signOccupancy]
    // uses, so a sample sitting exactly ON a boundary can't decide it.
    final mid = segStart.add(segEnd.difference(segStart) ~/ 2);
    if (sadeSatiSeparation(f(mid), moon).abs() > orb) return;
    out.add(SadeSatiDegreeWindow(
      start: segStart,
      end: segEnd,
      conjunctions: [
        for (final c in conjunctions)
          if (!c.isBefore(segStart) && !c.isAfter(segEnd)) c,
      ],
      clippedStart: segStart == from,
      clippedEnd: segEnd == to,
      // Sampled AT the entry instant: negative separation means Saturn
      // has not reached the Moon yet. Unambiguous in practice — an
      // entry sits at ±orb (or wherever the range clipped it), never
      // at the zero the sign turns on.
      approachingAtStart: sadeSatiSeparation(f(segStart), moon) < 0,
    ));
  }

  for (final c in edges) {
    if (c.difference(start) < const Duration(minutes: 2)) continue;
    emit(start, c);
    start = c;
  }
  if (to.isAfter(start)) emit(start, to);
  return out;
}
