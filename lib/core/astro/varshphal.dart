/// Varshphal (Tajika annual horoscopy) — the varsha begins at the
/// SIDEREAL solar return: the instant the transiting Sun's sidereal
/// longitude equals the natal Sun's, once per year near the birthday.
/// The chart cast for that instant at the BIRTH place (the traditional
/// convention) governs the year; the Muntha is the natal lagna advanced
/// one sign per completed year.
///
/// Only the instant search and Muntha live here (pure/sweph-only). The
/// varsha chart itself is a plain [AstroSnapshot] built for the return
/// instant — see varshphalProvider, which also resolves the birth
/// place's UTC offset at that instant for the panchang.
library;

import 'models.dart';
import 'transit_scan.dart' show LongitudeAt, ephemerisLongitude;

/// Mean sidereal year, days — anchors the search window near the true
/// return (anchor error is minutes; the bracket below is ±3 days).
const double kSiderealYearDays = 365.256363;

double _norm180(double x) {
  final n = ((x % 360) + 360) % 360;
  return n > 180 ? n - 360 : n;
}

/// UTC instant of the [varshaYear]-th sidereal solar return after
/// birth (varshaYear = completed years, so 1 = the return near the
/// first birthday; 0 is the birth instant's own year and returns a
/// crossing at/near birth itself).
///
/// Bisection runs to ≤1 second — NOT the transit scanner's 1 minute:
/// the varsha lagna moves 1° per 4 minutes, so a minute of slop is a
/// quarter-degree of ascendant, visible against desktop software.
/// [sun] is injectable for tests; defaults to the live ephemeris.
DateTime solarReturnUtc({
  required DateTime birthUtc,
  required double natalSunLongitude,
  required int varshaYear,
  required int ayanamsaId,
  LongitudeAt? sun,
}) {
  final f = sun ?? ephemerisLongitude(Planet.sun, ayanamsaId);
  double d(DateTime t) => _norm180(f(t) - natalSunLongitude);

  final anchor = birthUtc
      .add(Duration(seconds: (varshaYear * kSiderealYearDays * 86400).round()));
  // The Sun is always direct (~0.95–1.02°/day), so the signed distance
  // rises through zero exactly once in the bracket. Widen defensively
  // if the anchor ever lands outside it.
  var a = anchor.subtract(const Duration(days: 3));
  var b = anchor.add(const Duration(days: 3));
  var guard = 0;
  while (d(a) > 0 && guard++ < 8) {
    a = a.subtract(const Duration(days: 2));
  }
  guard = 0;
  while (d(b) < 0 && guard++ < 8) {
    b = b.add(const Duration(days: 2));
  }
  while (b.difference(a) > const Duration(seconds: 1)) {
    final mid = a.add(b.difference(a) ~/ 2);
    if (d(mid) < 0) {
      a = mid;
    } else {
      b = mid;
    }
  }
  return a.add(b.difference(a) ~/ 2);
}

/// The varsha (completed years) running at [now] — which solar return
/// governs today. Uses the mean sidereal year, consistent with the
/// anchor in [solarReturnUtc]; the day-scale error near the exact
/// birthday moment is irrelevant for picking a default year to show.
int currentVarshaYear(DateTime birthUtc, DateTime now) {
  final n =
      now.difference(birthUtc).inSeconds ~/ (kSiderealYearDays * 86400).round();
  return n < 0 ? 0 : n;
}

/// Muntha sign for the [varshaYear]-th varsha: natal lagna advanced one
/// sign per completed year (at birth the Muntha IS the lagna).
ZodiacSign munthaSign(ZodiacSign natalLagna, int varshaYear) =>
    ZodiacSign.values[(natalLagna.index + varshaYear) % 12];

/// UTC instant of the [month]-th maasa pravesha within a varsha
/// (1 = the varsha pravesha itself; 2-12 = the Sun gaining successive
/// 30° over its natal longitude). Bisected to ≤1 second like the
/// annual return — the monthly lagna is just as time-sensitive.
DateTime maasaPraveshUtc({
  required DateTime varshaPraveshUtc,
  required double natalSunLongitude,
  required int month,
  required int ayanamsaId,
  LongitudeAt? sun,
}) {
  if (month <= 1) return varshaPraveshUtc;
  final f = sun ?? ephemerisLongitude(Planet.sun, ayanamsaId);
  final target = (natalSunLongitude + 30.0 * (month - 1)) % 360;
  double d(DateTime t) => _norm180(f(t) - target);

  final anchor = varshaPraveshUtc.add(Duration(
      seconds: ((month - 1) * kSiderealYearDays / 12 * 86400).round()));
  var a = anchor.subtract(const Duration(days: 3));
  var b = anchor.add(const Duration(days: 3));
  var guard = 0;
  while (d(a) > 0 && guard++ < 8) {
    a = a.subtract(const Duration(days: 2));
  }
  guard = 0;
  while (d(b) < 0 && guard++ < 8) {
    b = b.add(const Duration(days: 2));
  }
  while (b.difference(a) > const Duration(seconds: 1)) {
    final mid = a.add(b.difference(a) ~/ 2);
    if (d(mid) < 0) {
      a = mid;
    } else {
      b = mid;
    }
  }
  return a.add(b.difference(a) ~/ 2);
}
