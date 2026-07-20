/// Bhava Chalit — cusp-bounded houses, as distinct from the whole-sign
/// houses every rashi chart in the app uses. A planet late in a sign
/// often "shifts" (chalit) into the next bhava, which changes house
/// readings; practitioners consult both side by side.
///
/// Two conventions, one rule: the computed cusps are the bhava MADHYAS
/// (house middles) and each house runs sandhi-to-sandhi, where a sandhi
/// is the circular midpoint of neighbouring madhyas.
///  • Sripati (default): madhyas are the Porphyry cusps — the classical
///    North-Indian chalit.
///  • Placidus: madhyas are the Placidus cusps (already on the
///    snapshot) — the convention used by cusp-based schools.
library;

import 'ephemeris_service.dart';
import 'models.dart';

/// Which madhyas the chalit is built from. Sandhis are ALWAYS the
/// circular midpoints of adjacent madhyas — for [equal]'s 30°-spaced
/// madhyas that reduces exactly to the traditional "madhya + 15° is
/// the next sandhi" rule; for the unequal systems the midpoint is the
/// general form of the same rule.
enum ChalitSystem {
  /// Porphyry madhyas (quadrants trisected) — classical Sripati.
  sripati,

  /// Placidus madhyas — the cusp-based schools' convention.
  placidus,

  /// Equal bhavas: madhya = the lagna degree in every sign, each house
  /// exactly 30° wide (samabhava, common in North Indian panchangas).
  equal,
}

class ChalitData {
  const ChalitData({
    required this.system,
    required this.madhya,
    required this.sandhi,
    required this.planetsInHouse,
  });

  final ChalitSystem system;

  /// Bhava madhya longitudes; index 0 = house 1.
  final List<double> madhya;

  /// House START boundaries; sandhi[i] begins house i+1 (midpoint of
  /// madhya[i-1] → madhya[i]).
  final List<double> sandhi;

  /// index 0 = house 1. Two houses may share a sign; a sign may have
  /// no house — exactly why this cannot be a Map<ZodiacSign, …>.
  final List<List<Planet>> planetsInHouse;

  /// Sign occupying house [house]'s madhya (1-based house).
  ZodiacSign signOfHouse(int house) =>
      ZodiacSign.fromLongitude(madhya[house - 1]);

  /// 1-based house containing [longitude] (sandhi-bounded, inclusive
  /// of its own start).
  int houseOf(double longitude) => houseOfIn(sandhi, longitude);
}

double _norm360(double x) => ((x % 360) + 360) % 360;

/// Forward circular midpoint of [a] → [b].
double circularMidpoint(double a, double b) =>
    _norm360(a + _norm360(b - a) / 2);

/// Sandhi list from 12 madhyas: sandhi[i] = midpoint of the arc from
/// madhya[i-1] forward to madhya[i], i.e. the start of house i+1.
List<double> sandhisFromMadhyas(List<double> madhya) => [
      for (var i = 0; i < 12; i++)
        circularMidpoint(madhya[(i + 11) % 12], madhya[i]),
    ];

/// 1-based house whose [sandhi]-bounded span contains [longitude].
int houseOfIn(List<double> sandhi, double longitude) {
  for (var i = 0; i < 12; i++) {
    final start = sandhi[i];
    final end = sandhi[(i + 1) % 12];
    final span = _norm360(end - start);
    if (_norm360(longitude - start) < span) return i + 1;
  }
  return 12; // unreachable for a well-formed sandhi ring
}

/// Chalit for a chart. Placidus madhyas ride the snapshot's own cusps;
/// Sripati asks the ephemeris for Porphyry cusps (one cheap call).
ChalitData computeChalit(AstroSnapshot s, ChalitSystem system) {
  final madhya = switch (system) {
    ChalitSystem.placidus => s.houseCusps,
    ChalitSystem.equal => [
        for (var i = 0; i < 12; i++) _norm360(s.ascendant + 30.0 * i),
      ],
    ChalitSystem.sripati => EphemerisService.instance.porphyryCusps(
        EphemerisService.instance.julianDayUt(s.birth.dateTimeUtc),
        s.birth.latitude,
        s.birth.longitude,
        s.ayanamsaId,
      ),
  };
  final sandhi = sandhisFromMadhyas(madhya);
  final houses = [for (var i = 0; i < 12; i++) <Planet>[]];
  for (final p in s.positions.values) {
    houses[houseOfIn(sandhi, p.longitude) - 1].add(p.planet);
  }
  return ChalitData(
    system: system,
    madhya: madhya,
    sandhi: sandhi,
    planetsInHouse: houses,
  );
}
