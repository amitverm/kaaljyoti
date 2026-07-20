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
