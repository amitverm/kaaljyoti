/// Tajika planetary strengths and the Lord of the Year, per K.S.
/// Charak, "A Textbook of Varshaphala" (2nd ed.), chapters VI–VII —
/// the calibration source for the whole Varshphal suite. Every table
/// here is transcribed from the book and pinned by golden tests
/// reproducing its Example Chart (test/varshphal_bala_test.dart).
///
/// Relations throughout are the ANNUAL-chart positional ones
/// (core/astro/tajika.dart): houses 3/5/9/11 friendly, 1/4/7/10
/// inimical, 2/6/8/12 neutral — confirmed against Tables VI-2/5/7/9,
/// including the subtle cases (same sign = distance 1 = inimical;
/// distance 8 = neutral).
library;

import 'divisional.dart';
import 'models.dart';
import 'tajika.dart';

// ---------------------------------------------------------------------------
// Harsha Bala (book pp. 50-53)
// ---------------------------------------------------------------------------

/// House (from the varsha lagna, whole sign) in which each planet gets
/// the positional 'First' bala.
const Map<Planet, int> _harshaHouse = {
  Planet.sun: 9,
  Planet.moon: 3,
  Planet.mars: 6,
  Planet.mercury: 1,
  Planet.jupiter: 11,
  Planet.venus: 5,
  Planet.saturn: 12,
};

/// Feminine houses 1,2,3,7,8,9; the rest masculine (book p. 51).
const Set<int> _feminineHouses = {1, 2, 3, 7, 8, 9};

/// Female planets per the Harsha rule (Moon, Mercury, Venus, Saturn);
/// Sun, Mars, Jupiter are male.
const Set<Planet> _femalePlanets = {
  Planet.moon,
  Planet.mercury,
  Planet.venus,
  Planet.saturn,
};

class HarshaBalaResult {
  const HarshaBalaResult({
    required this.planet,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
  });

  final Planet planet;
  final int first; // positional
  final int second; // exaltation / own sign
  final int third; // gender-matching house
  final int fourth; // day/night
  int get total => first + second + third + fourth;
}

int _houseOf(AstroSnapshot varsha, Planet p) =>
    ((varsha.positions[p]!.sign.index - varsha.lagnaSign.index + 12) % 12) + 1;

/// Exaltation signs (classical; matches dignity.dart's table).
const Map<Planet, ZodiacSign> _exaltation = {
  Planet.sun: ZodiacSign.aries,
  Planet.moon: ZodiacSign.taurus,
  Planet.mars: ZodiacSign.capricorn,
  Planet.mercury: ZodiacSign.virgo,
  Planet.jupiter: ZodiacSign.cancer,
  Planet.venus: ZodiacSign.pisces,
  Planet.saturn: ZodiacSign.libra,
};

List<HarshaBalaResult> harshaBala(AstroSnapshot varsha,
    {required bool dayPravesha}) {
  return [
    for (final p in kTajikaPlanets)
      () {
        final sign = varsha.positions[p]!.sign;
        final house = _houseOf(varsha, p);
        final female = _femalePlanets.contains(p);
        return HarshaBalaResult(
          planet: p,
          first: _harshaHouse[p] == house ? 5 : 0,
          second: (sign.lord == p || _exaltation[p] == sign) ? 5 : 0,
          third: _feminineHouses.contains(house) == female ? 5 : 0,
          fourth: (dayPravesha != female) ? 5 : 0,
        );
      }(),
  ];
}

// ---------------------------------------------------------------------------
// Pancha-Vargiya Bala (book pp. 53-61)
// ---------------------------------------------------------------------------

/// Deep-debilitation longitudes (book p. 56); uchcha bala = circular
/// distance from here ÷ 9, max 20 units at deep exaltation.
const Map<Planet, double> _debilitation = {
  Planet.sun: 190,
  Planet.moon: 213,
  Planet.mars: 118,
  Planet.mercury: 345,
  Planet.jupiter: 275,
  Planet.venus: 177,
  Planet.saturn: 20,
};

/// Table VI-4 — the Huddas (Egyptian bounds): per sign, five (span,
/// lord) segments summing to 30°. Transcribed from the book and
/// verified against the classical Egyptian terms.
const List<List<(int, Planet)>> _huddas = [
  // Aries
  [
    (6, Planet.jupiter),
    (6, Planet.venus),
    (8, Planet.mercury),
    (5, Planet.mars),
    (5, Planet.saturn)
  ],
  // Taurus
  [
    (8, Planet.venus),
    (6, Planet.mercury),
    (8, Planet.jupiter),
    (5, Planet.saturn),
    (3, Planet.mars)
  ],
  // Gemini
  [
    (6, Planet.mercury),
    (6, Planet.jupiter),
    (5, Planet.venus),
    (7, Planet.mars),
    (6, Planet.saturn)
  ],
  // Cancer
  [
    (7, Planet.mars),
    (6, Planet.venus),
    (6, Planet.mercury),
    (7, Planet.jupiter),
    (4, Planet.saturn)
  ],
  // Leo
  [
    (6, Planet.jupiter),
    (5, Planet.venus),
    (7, Planet.saturn),
    (6, Planet.mercury),
    (6, Planet.mars)
  ],
  // Virgo
  [
    (7, Planet.mercury),
    (10, Planet.venus),
    (4, Planet.jupiter),
    (7, Planet.mars),
    (2, Planet.saturn)
  ],
  // Libra
  [
    (6, Planet.saturn),
    (8, Planet.mercury),
    (7, Planet.jupiter),
    (7, Planet.venus),
    (2, Planet.mars)
  ],
  // Scorpio
  [
    (7, Planet.mars),
    (4, Planet.venus),
    (8, Planet.mercury),
    (5, Planet.jupiter),
    (6, Planet.saturn)
  ],
  // Sagittarius
  [
    (12, Planet.jupiter),
    (5, Planet.venus),
    (4, Planet.mercury),
    (5, Planet.mars),
    (4, Planet.saturn)
  ],
  // Capricorn
  [
    (7, Planet.mercury),
    (7, Planet.jupiter),
    (8, Planet.venus),
    (4, Planet.saturn),
    (4, Planet.mars)
  ],
  // Aquarius
  [
    (7, Planet.mercury),
    (6, Planet.venus),
    (7, Planet.jupiter),
    (5, Planet.mars),
    (5, Planet.saturn)
  ],
  // Pisces
  [
    (12, Planet.venus),
    (4, Planet.jupiter),
    (3, Planet.mercury),
    (9, Planet.mars),
    (2, Planet.saturn)
  ],
];

Planet huddaLordOf(double longitude) {
  final signIdx = (longitude ~/ 30) % 12;
  var inSign = longitude % 30;
  for (final (span, lord) in _huddas[signIdx]) {
    if (inSign < span) return lord;
    inSign -= span;
  }
  return _huddas[signIdx].last.$2; // 30.0 exactly → last segment
}

/// Table VI-6 — Panchavargiya-specific drekkana lords: the 36 decans,
/// walked first-decans-of-all-signs then second then third, cycle the
/// seven lords from Mars onward.
const List<Planet> _drekkanaCycle = [
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
  Planet.sun,
  Planet.moon,
];

Planet panchavargiyaDrekkanaLordOf(double longitude) {
  final signIdx = (longitude ~/ 30) % 12;
  final decan = ((longitude % 30) ~/ 10).clamp(0, 2);
  return _drekkanaCycle[(decan * 12 + signIdx) % 7];
}

/// Varga-lord relation → units, scaled per varga (Table VI-3): own
/// 1, friend 3/4, neutral 1/2, enemy 1/4 of the varga's full value.
double _relationFactor(AstroSnapshot varsha, Planet p, Planet lord) {
  if (lord == p) return 1.0;
  final rel = tajikaRelationBetween(varsha, p, lord);
  if (rel.isFriend) return 0.75;
  if (rel.isEnemy) return 0.25;
  return 0.5;
}

class PanchavargiyaResult {
  const PanchavargiyaResult({
    required this.planet,
    required this.griha,
    required this.uchcha,
    required this.hudda,
    required this.drekkana,
    required this.navamsha,
  });

  final Planet planet;
  final double griha; // max 30
  final double uchcha; // max 20
  final double hudda; // max 15
  final double drekkana; // max 10
  final double navamsha; // max 5
  double get total => griha + uchcha + hudda + drekkana + navamsha;

  /// Vishwa Bala — total ÷ 4, max 20 units.
  double get vishwaBala => total / 4;
}

List<PanchavargiyaResult> panchavargiyaBala(AstroSnapshot varsha) {
  double circularDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  return [
    for (final p in kTajikaPlanets)
      () {
        final lon = varsha.positions[p]!.longitude;
        final sign = varsha.positions[p]!.sign;
        return PanchavargiyaResult(
          planet: p,
          griha: 30 * _relationFactor(varsha, p, sign.lord),
          uchcha: circularDistance(lon, _debilitation[p]!) / 9,
          hudda: 15 * _relationFactor(varsha, p, huddaLordOf(lon)),
          drekkana:
              10 * _relationFactor(varsha, p, panchavargiyaDrekkanaLordOf(lon)),
          navamsha: 5 * _relationFactor(varsha, p, navamsaSign(lon).lord),
        );
      }(),
  ];
}

// ---------------------------------------------------------------------------
// The Lord of the Year (book pp. 76-79)
// ---------------------------------------------------------------------------

/// Table VII-1 — Tri-Rashi Patis by varsha lagna, day/night.
const Map<ZodiacSign, (Planet day, Planet night)> _triRashiPati = {
  ZodiacSign.aries: (Planet.sun, Planet.jupiter),
  ZodiacSign.taurus: (Planet.venus, Planet.moon),
  ZodiacSign.gemini: (Planet.saturn, Planet.mercury),
  ZodiacSign.cancer: (Planet.venus, Planet.mars),
  ZodiacSign.leo: (Planet.jupiter, Planet.sun),
  ZodiacSign.virgo: (Planet.moon, Planet.venus),
  ZodiacSign.libra: (Planet.mercury, Planet.saturn),
  ZodiacSign.scorpio: (Planet.mars, Planet.venus),
  ZodiacSign.sagittarius: (Planet.saturn, Planet.saturn),
  ZodiacSign.capricorn: (Planet.mars, Planet.mars),
  ZodiacSign.aquarius: (Planet.jupiter, Planet.jupiter),
  ZodiacSign.pisces: (Planet.moon, Planet.moon),
};

enum OfficeBearerRole {
  munthaPati,
  janmaLagnaPati,
  varshaLagnaPati,
  triRashiPati,
  dinaRatriPati,
  maasaLagnaPati,
}

class OfficeBearer {
  const OfficeBearer({required this.role, required this.planet});
  final OfficeBearerRole role;
  final Planet planet;
}

class YearLordResult {
  const YearLordResult({
    required this.bearers,
    required this.yearLord,
    required this.byMunthaFallback,
  });

  final List<OfficeBearer> bearers;
  final Planet yearLord;

  /// True when the Muntha-lord special rules decided (no bearer
  /// aspecting the lagna / all weaker than 5 units).
  final bool byMunthaFallback;
}

/// Whether [p] Tajika-aspects the varsha lagna — friendly OR inimical
/// (the book: "no distinction is to be made… while deciding the
/// Varshesha"), i.e. any distance except 2, 6, 8, 12. A planet IN the
/// lagna aspects it (the Example Chart's Mars qualifies from the 1st).
bool aspectsVarshaLagna(AstroSnapshot varsha, Planet p) =>
    tajikaRelationForDistance(
            tajikaSignDistance(varsha.lagnaSign, varsha.positions[p]!.sign))
        .aspects;

YearLordResult yearLord({
  required AstroSnapshot varsha,
  required ZodiacSign natalLagna,
  required ZodiacSign muntha,
  required bool dayPravesha,
}) {
  final tri = _triRashiPati[varsha.lagnaSign]!;
  final bearers = [
    OfficeBearer(role: OfficeBearerRole.munthaPati, planet: muntha.lord),
    OfficeBearer(
        role: OfficeBearerRole.janmaLagnaPati, planet: natalLagna.lord),
    OfficeBearer(
        role: OfficeBearerRole.varshaLagnaPati, planet: varsha.lagnaSign.lord),
    OfficeBearer(
        role: OfficeBearerRole.triRashiPati,
        planet: dayPravesha ? tri.$1 : tri.$2),
    OfficeBearer(
        role: OfficeBearerRole.dinaRatriPati,
        planet: dayPravesha
            ? varsha.positions[Planet.sun]!.sign.lord
            : varsha.positions[Planet.moon]!.sign.lord),
  ];

  final vb = {
    for (final r in panchavargiyaBala(varsha)) r.planet: r.vishwaBala,
  };
  final munthaLord = bearers.first.planet;
  final distinct = bearers.map((b) => b.planet).toSet();

  // Muntha-lord fallbacks: no bearer aspects the lagna, or all are
  // weaker than 5 units (book p. 79, rules 4a/4b).
  final aspecting =
      distinct.where((p) => aspectsVarshaLagna(varsha, p)).toList();
  if (aspecting.isEmpty || distinct.every((p) => (vb[p] ?? 0) < 5)) {
    return YearLordResult(
        bearers: bearers, yearLord: munthaLord, byMunthaFallback: true);
  }

  // Strongest aspecting bearer; ties broken by portfolio count, then
  // the Muntha lord (rules 1-3 and 4c).
  int portfolios(Planet p) => bearers.where((b) => b.planet == p).length;
  aspecting.sort((a, b) {
    final byStrength = (vb[b] ?? 0).compareTo(vb[a] ?? 0);
    if (byStrength != 0) return byStrength;
    final byPortfolios = portfolios(b).compareTo(portfolios(a));
    if (byPortfolios != 0) return byPortfolios;
    if (a == munthaLord) return -1;
    if (b == munthaLord) return 1;
    return 0;
  });
  return YearLordResult(
      bearers: bearers, yearLord: aspecting.first, byMunthaFallback: false);
}

/// The Maasesha — Lord of the Month (book p. 205): the year's five
/// office-bearers PLUS the monthly chart's own lagna lord as a sixth;
/// strength from the MONTHLY chart's Panchavargiya, aspect judged on
/// the monthly lagna, selection by the same rules as the Varshesha
/// (including the Muntha-lord fallbacks).
YearLordResult monthLord({
  required AstroSnapshot varsha,
  required AstroSnapshot maasa,
  required ZodiacSign natalLagna,
  required ZodiacSign muntha,
  required bool dayPraveshaAnnual,
}) {
  final annual = yearLord(
    varsha: varsha,
    natalLagna: natalLagna,
    muntha: muntha,
    dayPravesha: dayPraveshaAnnual,
  );
  final bearers = [
    ...annual.bearers,
    OfficeBearer(
        role: OfficeBearerRole.maasaLagnaPati, planet: maasa.lagnaSign.lord),
  ];
  final vb = {
    for (final r in panchavargiyaBala(maasa)) r.planet: r.vishwaBala,
  };
  final munthaLord = muntha.lord;
  final distinct = bearers.map((b) => b.planet).toSet();
  final aspecting =
      distinct.where((p) => aspectsVarshaLagna(maasa, p)).toList();
  if (aspecting.isEmpty || distinct.every((p) => (vb[p] ?? 0) < 5)) {
    return YearLordResult(
        bearers: bearers, yearLord: munthaLord, byMunthaFallback: true);
  }
  int portfolios(Planet p) => bearers.where((b) => b.planet == p).length;
  aspecting.sort((a, b) {
    final byStrength = (vb[b] ?? 0).compareTo(vb[a] ?? 0);
    if (byStrength != 0) return byStrength;
    final byPortfolios = portfolios(b).compareTo(portfolios(a));
    if (byPortfolios != 0) return byPortfolios;
    if (a == munthaLord) return -1;
    if (b == munthaLord) return 1;
    return 0;
  });
  return YearLordResult(
      bearers: bearers, yearLord: aspecting.first, byMunthaFallback: false);
}
