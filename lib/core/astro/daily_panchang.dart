/// "Today" panchang: the five limbs for the current moment at a
/// chosen place, WITH their end times (found by stepping + bisection
/// over the ephemeris), sunrise/sunset, and the live transit sky
/// (positions + rising lagna) for the same instant.
///
/// All times returned in the device's local zone.
library;

import 'ephemeris_service.dart';
import 'models.dart';
import 'panchang.dart';
import 'vikram_samvat.dart';

/// A clock-time window (local), e.g. Rahu Kaal.
class TimeWindow {
  const TimeWindow(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

/// One tithi occupying part of the Vedic day (sunrise → next sunrise).
/// A single date usually holds one or two of these; on a short-tithi
/// (kshaya) day it can hold three.
class TithiSpan {
  const TithiSpan({
    required this.index,
    required this.name,
    required this.paksha,
    required this.starts,
    required this.ends,
  });

  /// 0-based lunar-day index (0 = Shukla Pratipada … 29 = Amavasya).
  final int index;
  final String name;
  final String paksha;

  /// When this tithi began, or null if it was already running at the
  /// window's start (i.e. began before sunrise on the previous day).
  final DateTime? starts;

  /// When this tithi ends. May fall after the window (i.e. tomorrow).
  /// Null only if the ephemeris boundary search failed.
  final DateTime? ends;
}

class DailyPanchang {
  const DailyPanchang({
    required this.at,
    required this.panchang,
    required this.masa,
    required this.sunrise,
    required this.sunset,
    required this.tithis,
    required this.tithiEnds,
    required this.nakshatraEnds,
    required this.yogaEnds,
    required this.karanaEnds,
    required this.positions,
    required this.ascendant,
    this.rahuKalam,
    this.yamaganda,
    this.gulikaKalam,
    this.abhijitMuhurta,
    this.brahmaMuhurta,
    this.dishaShool,
  });

  final DateTime at;
  final PanchangData panchang;

  /// Vikram Samvat lunar month + year for [at].
  final VikramMasa masa;

  final DateTime? sunrise;
  final DateTime? sunset;

  /// Every tithi that touches the current Vedic day (sunrise → next
  /// sunrise), in order. Falls back to a single entry (the live tithi)
  /// when the sunrise window can't be resolved.
  final List<TithiSpan> tithis;

  /// End of the tithi live at [at] — kept for the OS widget and any
  /// single-value consumer. Equivalent to the span in [tithis] that
  /// contains [at].
  final DateTime? tithiEnds;
  final DateTime? nakshatraEnds;
  final DateTime? yogaEnds;
  final DateTime? karanaEnds;

  /// Live transit positions (sidereal) at [at].
  final Map<Planet, PlanetPosition> positions;

  /// Rising lagna longitude at [at] for the chosen place.
  final double ascendant;

  /// Inauspicious eighths of the daylight span (weekday-indexed).
  final TimeWindow? rahuKalam;
  final TimeWindow? yamaganda;
  final TimeWindow? gulikaKalam;

  /// The 8th of the 15 day-muhurtas (avoid on Wednesdays, per
  /// tradition) and the pre-dawn Brahma muhurta.
  final TimeWindow? abhijitMuhurta;
  final TimeWindow? brahmaMuhurta;

  /// Direction to avoid setting out toward today (weekday rule).
  final Direction? dishaShool;

  ZodiacSign get lagnaSign => ZodiacSign.fromLongitude(ascendant);

  Map<ZodiacSign, List<Planet>> get placements {
    final map = <ZodiacSign, List<Planet>>{};
    for (final p in positions.values) {
      (map[p.sign] ??= []).add(p.planet);
    }
    return map;
  }
}

double _norm(double d) {
  var x = d % 360;
  if (x < 0) x += 360;
  return x;
}

/// Finds when the integer bucket of [value] next changes after
/// [fromJd]: coarse 30-minute steps (36 h horizon), then bisection to
/// half-minute precision. Returns null if no change found (shouldn't
/// happen for lunar quantities).
double? _nextChange(double Function(double jd) bucket, double fromJd) {
  final start = bucket(fromJd);
  const step = 30 / 1440; // 30 minutes in days
  double? hi;
  var lo = fromJd;
  for (var i = 1; i <= 72; i++) {
    final t = fromJd + i * step;
    if (bucket(t) != start) {
      hi = t;
      break;
    }
    lo = t;
  }
  if (hi == null) return null;
  var hiV = hi;
  while ((hiV - lo) > 0.5 / 1440) {
    final mid = (lo + hiV) / 2;
    if (bucket(mid) == start) {
      lo = mid;
    } else {
      hiV = mid;
    }
  }
  return hiV;
}

DailyPanchang computeDailyPanchang({
  required DateTime now,
  required double latitude,
  required double longitude,
  required int ayanamsaId,
  MasaSystem masaSystem = MasaSystem.purnimanta,
}) {
  final svc = EphemerisService.instance;
  final jd = svc.julianDayUt(now.toUtc());

  final positions = svc.planetPositions(jd, ayanamsaId);
  final asc =
      svc.housesAndAscendant(jd, latitude, longitude, ayanamsaId).ascendant;

  final sun = positions[Planet.sun]!.longitude;
  final moon = positions[Planet.moon]!.longitude;
  final panchang = computePanchang(
    sunLongitude: sun,
    moonLongitude: moon,
    localDateTime: now,
  );

  final masa = computeVikramMasa(
    svc,
    jd,
    ayanamsaId,
    krishnaPaksha: panchang.paksha == 'Krishna',
    system: masaSystem,
  );

  // Bucket functions — each returns the integer index of the limb at
  // a given instant; the boundary search finds when it next changes.
  (double, double) sunMoon(double t) {
    final p = svc.planetPositions(t, ayanamsaId);
    return (p[Planet.sun]!.longitude, p[Planet.moon]!.longitude);
  }

  double tithiBucket(double t) {
    final (s, m) = sunMoon(t);
    return (_norm(m - s) / 12).floorToDouble();
  }

  double nakshatraBucket(double t) {
    final (_, m) = sunMoon(t);
    return (m / Nakshatra.span).floorToDouble();
  }

  double yogaBucket(double t) {
    final (s, m) = sunMoon(t);
    return (_norm(s + m) / (360 / 27)).floorToDouble();
  }

  double karanaBucket(double t) {
    final (s, m) = sunMoon(t);
    return (_norm(m - s) / 6).floorToDouble();
  }

  DateTime? local(double? jdUt) =>
      jdUt == null ? null : EphemerisService.dateTimeFromJdUt(jdUt).toLocal();

  // Vedic day anchor: the sunrise at/before now, and the following
  // sunset.
  final rise = svc.sunriseBefore(jd, latitude, longitude);
  final set =
      svc.sunEventAfter(rise ?? (jd - 0.5), latitude, longitude, rise: false);
  final riseL = local(rise);
  final setL = local(set);

  // Every tithi spanning the Vedic day (this sunrise → next sunrise).
  // Walk the tithi bucket from the window start, hopping boundary to
  // boundary, so a transition day naturally yields two (or, on a
  // kshaya day, three) entries rather than only the live one.
  final nextRise =
      svc.sunEventAfter(rise ?? (jd - 0.5), latitude, longitude, rise: true);
  final tithis = <TithiSpan>[];
  if (rise != null && nextRise != null && nextRise > rise) {
    var cursor = rise;
    DateTime? spanStart; // first span began before the window
    for (var guard = 0; cursor < nextRise && guard < 40; guard++) {
      final idx = tithiBucket(cursor).toInt();
      final endJd = _nextChange(tithiBucket, cursor);
      tithis.add(TithiSpan(
        index: idx,
        name: tithiNameFor(idx),
        paksha: pakshaFor(idx),
        starts: spanStart,
        ends: local(endJd),
      ));
      if (endJd == null) break;
      cursor = endJd + 0.5 / 1440; // step just past the boundary
      spanStart = local(endJd);
    }
  }
  if (tithis.isEmpty) {
    // Polar / unresolved sunrise: fall back to the live tithi alone.
    tithis.add(TithiSpan(
      index: panchang.tithiIndex,
      name: panchang.tithiName,
      paksha: panchang.paksha,
      starts: null,
      ends: local(_nextChange(tithiBucket, jd)),
    ));
  }

  // Daylight eighths, indexed by weekday of the (Vedic) day's sunrise.
  // Segment tables are 1-based; DateTime.weekday is Mon=1 … Sun=7.
  TimeWindow? eighth(Map<int, int> segByWeekday) {
    if (riseL == null || setL == null || !setL.isAfter(riseL)) return null;
    final seg = segByWeekday[riseL.weekday]!;
    final len = setL.difference(riseL) ~/ 8;
    final start = riseL.add(len * (seg - 1));
    return TimeWindow(start, start.add(len));
  }

  const rahuSeg = {1: 2, 2: 7, 3: 5, 4: 6, 5: 4, 6: 3, 7: 8};
  const yamaSeg = {1: 4, 2: 3, 3: 2, 4: 1, 5: 7, 6: 6, 7: 5};
  const gulikaSeg = {1: 6, 2: 5, 3: 4, 4: 3, 5: 2, 6: 1, 7: 7};
  const dishaShoolOf = {
    1: Direction.east,
    2: Direction.north,
    3: Direction.north,
    4: Direction.south,
    5: Direction.west,
    6: Direction.east,
    7: Direction.west,
  };

  TimeWindow? abhijit;
  TimeWindow? brahma;
  if (riseL != null && setL != null && setL.isAfter(riseL)) {
    // Abhijit = the 8th of 15 day-muhurtas.
    final muhurta = setL.difference(riseL) ~/ 15;
    final aStart = riseL.add(muhurta * 7);
    abhijit = TimeWindow(aStart, aStart.add(muhurta));
    // Brahma muhurta: 96 to 48 minutes before sunrise.
    brahma = TimeWindow(
      riseL.subtract(const Duration(minutes: 96)),
      riseL.subtract(const Duration(minutes: 48)),
    );
  }

  return DailyPanchang(
    at: now,
    panchang: panchang,
    masa: masa,
    sunrise: riseL,
    sunset: setL,
    tithis: tithis,
    tithiEnds: local(_nextChange(tithiBucket, jd)),
    nakshatraEnds: local(_nextChange(nakshatraBucket, jd)),
    yogaEnds: local(_nextChange(yogaBucket, jd)),
    karanaEnds: local(_nextChange(karanaBucket, jd)),
    positions: positions,
    ascendant: asc,
    rahuKalam: eighth(rahuSeg),
    yamaganda: eighth(yamaSeg),
    gulikaKalam: eighth(gulikaSeg),
    abhijitMuhurta: abhijit,
    brahmaMuhurta: brahma,
    dishaShool: riseL == null ? null : dishaShoolOf[riseL.weekday],
  );
}
