/// Special (Vishesha) Lagnas — the five auxiliary ascendants used
/// alongside the Rashi lagna:
///
/// * Bhava Lagna (BL) — the "mean" lagna: starts at the Sun's position
///   at sunrise and advances one full zodiac per day (360°/day, i.e.
///   one sign per 5 ghatis). Physical wellbeing / general results.
/// * Hora Lagna (HL) — same start, one zodiac per 12 hours (720°/day,
///   30° per hour). Wealth and financial prosperity.
/// * Ghati Lagna (GL) — same start, one sign per ghati (1800°/day).
///   Power, authority, status.
/// * Indu Lagna (IL) — wealth lagna: sum the kalas of the lords of the
///   9th from Lagna and the 9th from Moon; the remainder mod 12,
///   counted from the Moon's sign (remainder 0 → 12), is the IL sign.
///   Sign-level only — no degree is defined.
/// * Sree Lagna (SL) — Lakshmi point: the fraction of the Moon's
///   nakshatra already traversed, applied to the whole zodiac and
///   added to the Lagna's longitude.
///
/// BL/HL/GL need the sunrise instant and the Sun's longitude at that
/// sunrise — the caller obtains both from EphemerisService (kept out
/// of here so this file stays pure Dart and unit-testable).
library;

import 'models.dart';

enum SpecialLagnaKind {
  bhava('BL', 'Bhava Lagna', 'Physical self & general results'),
  hora('HL', 'Hora Lagna', 'Wealth & financial prosperity'),
  ghati('GL', 'Ghati Lagna', 'Power, authority & status'),
  indu('IL', 'Indu Lagna', 'Wealth & fortune (from Moon)'),
  sree('SL', 'Sree Lagna', 'Prosperity & grace (Lakshmi point)');

  const SpecialLagnaKind(this.code, this.displayName, this.meaning);
  final String code;
  final String displayName;
  final String meaning;
}

class SpecialLagnaPoint {
  const SpecialLagnaPoint({
    required this.kind,
    required this.sign,
    this.longitude,
  });

  final SpecialLagnaKind kind;
  final ZodiacSign sign;

  /// Sidereal longitude, when the lagna has one (all but Indu).
  final double? longitude;
}

double _norm(double deg) {
  var d = deg % 360;
  if (d < 0) d += 360;
  return d;
}

/// Classical kala (ray) values used by the Indu Lagna sum.
const Map<Planet, int> induKalas = {
  Planet.sun: 30,
  Planet.moon: 16,
  Planet.mars: 6,
  Planet.mercury: 8,
  Planet.jupiter: 10,
  Planet.venus: 12,
  Planet.saturn: 1,
};

/// Indu Lagna (sign-level).
ZodiacSign induLagnaSign(AstroSnapshot s) {
  final ninthFromLagna =
      ZodiacSign.values[(s.lagnaSign.index + 8) % 12].lord;
  final ninthFromMoon =
      ZodiacSign.values[(s.moonSign.index + 8) % 12].lord;
  final sum = induKalas[ninthFromLagna]! + induKalas[ninthFromMoon]!;
  var r = sum % 12;
  if (r == 0) r = 12;
  return ZodiacSign.values[(s.moonSign.index + r - 1) % 12];
}

/// Sree Lagna longitude.
double sreeLagnaLongitude(AstroSnapshot s) {
  final moonLon = s.positions[Planet.moon]!.longitude;
  final fraction = (moonLon % Nakshatra.span) / Nakshatra.span;
  return _norm(s.ascendant + fraction * 360);
}

/// Bhava Lagna: 360°/day from the Sun's sunrise position.
double bhavaLagnaLongitude(
        {required double sunAtSunrise, required double daysSinceSunrise}) =>
    _norm(sunAtSunrise + daysSinceSunrise * 360);

/// Hora Lagna: 720°/day (30° per hour).
double horaLagnaLongitude(
        {required double sunAtSunrise, required double daysSinceSunrise}) =>
    _norm(sunAtSunrise + daysSinceSunrise * 720);

/// Ghati Lagna: 1800°/day (30° per ghati of 24 minutes).
double ghatiLagnaLongitude(
        {required double sunAtSunrise, required double daysSinceSunrise}) =>
    _norm(sunAtSunrise + daysSinceSunrise * 1800);

/// The two sunrise-independent lagnas, always computable from the
/// snapshot alone.
List<SpecialLagnaPoint> positionalSpecialLagnas(AstroSnapshot s) {
  final sree = sreeLagnaLongitude(s);
  return [
    SpecialLagnaPoint(kind: SpecialLagnaKind.indu, sign: induLagnaSign(s)),
    SpecialLagnaPoint(
        kind: SpecialLagnaKind.sree,
        sign: ZodiacSign.fromLongitude(sree),
        longitude: sree),
  ];
}

/// The three time-based lagnas, given sunrise data from the ephemeris.
List<SpecialLagnaPoint> timeBasedSpecialLagnas({
  required double sunAtSunrise,
  required double daysSinceSunrise,
}) {
  SpecialLagnaPoint point(SpecialLagnaKind kind, double lon) =>
      SpecialLagnaPoint(
          kind: kind, sign: ZodiacSign.fromLongitude(lon), longitude: lon);
  return [
    point(
        SpecialLagnaKind.bhava,
        bhavaLagnaLongitude(
            sunAtSunrise: sunAtSunrise,
            daysSinceSunrise: daysSinceSunrise)),
    point(
        SpecialLagnaKind.hora,
        horaLagnaLongitude(
            sunAtSunrise: sunAtSunrise,
            daysSinceSunrise: daysSinceSunrise)),
    point(
        SpecialLagnaKind.ghati,
        ghatiLagnaLongitude(
            sunAtSunrise: sunAtSunrise,
            daysSinceSunrise: daysSinceSunrise)),
  ];
}
