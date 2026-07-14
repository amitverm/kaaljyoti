/// Shadbala — classical six-fold planetary strength (Sun through
/// Saturn; the lunar nodes are excluded, matching Parashara and this
/// codebase's existing dignity.dart scoping). Combines Sthana
/// (positional), Dig (directional), Kala (temporal), Cheshta
/// (motional), Naisargika (natural), and Drik (aspectual) bala into a
/// rupas total, checked against the classical required minimums.
///
/// SOURCES & CONVENTIONS — no printed reference (e.g. B.V. Raman's
/// "Graha and Bhava Balas") was fetchable in this environment, so the
/// formulas below follow Brihat Parashara Hora Shastra ch. 27 as
/// documented by the Saravali project (a from-source implementation
/// whose worked examples this file's tests reproduce) and cross-
/// checked against a second independent summary. Where sources
/// disagreed or a formula required a judgment call, the choice is
/// documented at the point of use.
///
/// ROUND 4 VALIDATION: every component was derived/validated against
/// Parashar Light 9's detailed per-component table for the fixture
/// chart (9 Apr 1981 01:45:00, Delhi Paharganj — Capricorn lagna),
/// reproduced in test/shadbala_test.dart. Component-level agreement:
/// Sthana EXACT (all sub-parts), Dig EXACT, Kala within 0.45 total
/// (nathonnata ±0.2, ayana ±0.25, lords exact), Naisargika exact,
/// Drik within 1.8, Cheshta within 2.8 (Mercury; others ≤1.5).
/// Planet TOTALS within ~3.5 shashtiamsas (<0.06 rupa) of PL9;
/// ratios match to ±0.01. Known residuals are documented at each
/// component. Validated with ONE chart — a second fixture chart
/// (different lagna/paksha/hemisphere) would harden the Saturn
/// drishti segment and the day/night branches.
///
/// Reuses existing engines rather than reimplementing: [divisional]
/// for the seven Saptavargaja vargas, [dignity]'s sign-level
/// exaltation for cross-reference, and [EphemerisService] for
/// sunrise/sunset (the Abda/Masa/Vara Kaala Bala lords no longer need
/// a Sun-ingress ephemeris scan as of Round 3 — see [_ahargana]).
library;

import 'dart:math' as math;

import 'dignity.dart' show exaltationSignOf;
import 'divisional.dart';
import 'ephemeris_service.dart';
import 'models.dart';

// A shashtiamsa ("Virupa") is 1/60 of a Rupa — the base Shadbala unit
// throughout this file; totals are converted to rupas only at the end.

/// The seven classical grahas Shadbala applies to (Rahu/Ketu excluded).
const List<Planet> kShadbalaPlanets = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
];

/// Classical required minimum total Shadbala, in shashtiamsas.
const Map<Planet, double> kShadbalaRequiredMinimum = {
  Planet.sun: 390,
  Planet.moon: 360,
  Planet.mars: 300,
  Planet.mercury: 420,
  Planet.jupiter: 390,
  Planet.venus: 330,
  Planet.saturn: 300,
};

double _norm360(double x) => ((x % 360) + 360) % 360;

/// Shortest angular distance between two longitudes, 0–180°.
double angularDistance(double a, double b) {
  var d = (a - b).abs() % 360;
  if (d > 180) d = 360 - d;
  return d;
}

// =============================================================================
// 1. Sthana Bala (positional) — Uccha + Saptavargaja + Ojayugma + Kendradi
//    + Drekkana. Formulas & worked examples: Saravali "Sthana Bala".
// =============================================================================

/// Exact classical exaltation DEGREE per graha (not just sign — needed
/// for Uccha Bala's proportional distance; dignity.dart intentionally
/// omits this precision since it only needs the sign-level check).
const Map<Planet, double> _exaltationDegreeInSign = {
  Planet.sun: 10,
  Planet.moon: 3,
  Planet.mars: 28,
  Planet.mercury: 15,
  Planet.jupiter: 5,
  Planet.venus: 27,
  Planet.saturn: 20,
};

double _exaltationPoint(Planet p) {
  final sign = exaltationSignOf(p)!;
  return sign.index * 30 + _exaltationDegreeInSign[p]!;
}

/// Uccha Bala: 60 Virupas at exact exaltation, 0 at exact debilitation,
/// proportional between (one third of the angular distance to the
/// debilitation point, which is always exactly opposite exaltation).
double uchchaBala(Planet planet, double longitude) {
  final debilitationPoint = _norm360(_exaltationPoint(planet) + 180);
  return angularDistance(longitude, debilitationPoint) / 3;
}

/// Moolatrikona sign per graha (Parashara — distinct from the
/// exaltation sign, and for the Moon also distinct from its own sign
/// Cancer; this is a classical peculiarity, not an error).
const Map<Planet, ZodiacSign> _moolatrikonaSign = {
  Planet.sun: ZodiacSign.leo,
  Planet.moon: ZodiacSign.taurus,
  Planet.mars: ZodiacSign.aries,
  Planet.mercury: ZodiacSign.virgo,
  Planet.jupiter: ZodiacSign.sagittarius,
  Planet.venus: ZodiacSign.libra,
  Planet.saturn: ZodiacSign.aquarius,
};

/// (startDegree, endDegree) of the moolatrikona WITHIN that sign —
/// only meaningful for the Rasi (D1) chart itself; the six higher
/// vargas only have a sign (no longitude), so Saptavargaja Bala checks
/// sign-equality alone there, per Saravali's documented convention.
const Map<Planet, (double, double)> _moolatrikonaRange = {
  Planet.sun: (0, 20),
  Planet.moon: (4, 30),
  Planet.mars: (0, 12),
  Planet.mercury: (16, 20),
  Planet.jupiter: (0, 10),
  Planet.venus: (0, 15),
  Planet.saturn: (0, 20),
};

/// Natural (Naisargika) friendship — the classical fixed table (BPHS
/// ch. 4), independent of any chart.
const Map<Planet, ({List<Planet> friends, List<Planet> enemies})>
    kNaturalPlanetaryRelation = {
  Planet.sun: (
    friends: [Planet.moon, Planet.mars, Planet.jupiter],
    enemies: [Planet.venus, Planet.saturn],
  ),
  Planet.moon: (friends: [Planet.sun, Planet.mercury], enemies: []),
  Planet.mars: (
    friends: [Planet.sun, Planet.moon, Planet.jupiter],
    enemies: [Planet.mercury],
  ),
  Planet.mercury: (
    friends: [Planet.sun, Planet.venus],
    enemies: [Planet.moon],
  ),
  Planet.jupiter: (
    friends: [Planet.sun, Planet.moon, Planet.mars],
    enemies: [Planet.mercury, Planet.venus],
  ),
  Planet.venus: (
    friends: [Planet.mercury, Planet.saturn],
    enemies: [Planet.sun, Planet.moon],
  ),
  Planet.saturn: (
    friends: [Planet.mercury, Planet.venus],
    enemies: [Planet.sun, Planet.moon, Planet.mars],
  ),
};

/// One-directional natural relationship — public: also used by
/// guna_milan.dart's Graha Maitri koota (the same classical table).
enum PlanetaryRel { friend, neutral, enemy }

PlanetaryRel naturalRelOf(Planet from, Planet to) {
  final r = kNaturalPlanetaryRelation[from]!;
  if (r.friends.contains(to)) return PlanetaryRel.friend;
  if (r.enemies.contains(to)) return PlanetaryRel.enemy;
  return PlanetaryRel.neutral;
}

/// Temporary (Tatkalika) friendship: [to] is a friend of [from] if it
/// sits 2/3/4/10/11/12 signs away from [from] in the RASI (D1) chart
/// (same-sign — "distance 1" — is classically an ENEMY house here).
/// Always computed from Rasi placements even when scoring a higher
/// varga — one of two documented conventions (Saravali's remark #4);
/// chosen for tractability, noted here rather than silently assumed.
///
/// Public: also the shared temporary-relationship primitive behind the
/// Panchadha Maitri widget (see core/astro/maitri.dart), which combines
/// it with [naturalRelOf] into the fivefold Ati-Mitra…Ati-Satru tier —
/// the same combination this file scores as Virupas below.
PlanetaryRel temporaryRelOf(ZodiacSign fromSign, ZodiacSign toSign) {
  final dist = ((toSign.index - fromSign.index) % 12) + 1; // 1..12
  return const {2, 3, 4, 10, 11, 12}.contains(dist)
      ? PlanetaryRel.friend
      : PlanetaryRel.enemy;
}

// ROUND 4 FIX (validated EXACTLY against all 7 PL9 fixture planets —
// e.g. Sun's 58.125 decomposes as 30+15+7.5+3.75+1.875): the compound
// dignity points are 22.5/15/7.5/3.75/1.875, not the 20/15/10/4/2 set
// a secondary source listed.
const Map<int, double> _compoundVirupas = {
  2: 22.5, // Ati Mitra
  1: 15, // Mitra
  0: 7.5, // Sama
  -1: 3.75, // Satru
  -2: 1.875, // Ati Satru
};

int _compoundScore(PlanetaryRel natural, PlanetaryRel temporary) {
  const val = {
    PlanetaryRel.friend: 1,
    PlanetaryRel.neutral: 0,
    PlanetaryRel.enemy: -1,
  };
  return val[natural]! + val[temporary]!;
}

double _vargaDignityScore({
  required Planet planet,
  required ZodiacSign vargaSign,
  required ZodiacSign planetRasiSign,
  required Map<Planet, ZodiacSign> rasiSignOf,
  bool checkMoolatrikonaRange = false,
  double? degreeInRasi,
}) {
  // ROUND 3 FIX (Task 12, validated against the PL9 fixture chart):
  // Moolatrikona's extra-strength band is a RASI (D1) peculiarity only
  // — it is degree-gated within a sign, a concept that doesn't exist in
  // a varga chart (which only ever has a sign placement, no "degree
  // within the varga sign"). Applying the flat 45 bonus whenever a
  // varga sign happened to equal the moolatrikona sign (the previous
  // behavior here) double-counted Sun's Hora-Leo and Mercury's
  // Navamsa/Trimsamsa-Virgo placements, since Leo/Virgo are ALSO those
  // planets' OWN sign — Sun and Mercury's Saptavargaja totals came out
  // 15 Virupas too high in EVERY such varga (73.125 vs PL9's 58.13 for
  // Sun; 120.0 vs PL9's 90.00 for Mercury). Gating this check on
  // [checkMoolatrikonaRange] (true only for D1) fixes both exactly and
  // leaves the other 5 planets (whose varga signs never coincide with
  // their moolatrikona sign in this fixture) unchanged.
  if (checkMoolatrikonaRange && _moolatrikonaSign[planet] == vargaSign) {
    final range = _moolatrikonaRange[planet]!;
    if (degreeInRasi != null &&
        degreeInRasi >= range.$1 &&
        degreeInRasi < range.$2) {
      return 45;
    }
    // Moolatrikona SIGN but outside the degree band (Rasi only) — the
    // remainder of the sign falls through to the own/friendship check
    // below, exactly like any other sign.
  }
  if (vargaSign.lord == planet) return 30;
  final lord = vargaSign.lord;
  final natural = naturalRelOf(planet, lord);
  final temporary = temporaryRelOf(planetRasiSign, rasiSignOf[lord]!);
  return _compoundVirupas[_compoundScore(natural, temporary)]!;
}

/// The seven Saptavargaja divisions, in Saravali's listed order.
const List<Varga> kSaptavargas = [
  Varga.d1,
  Varga.d2,
  Varga.d3,
  Varga.d7,
  Varga.d9,
  Varga.d12,
  Varga.d30,
];

/// Saptavargaja Bala: sum of the dignity score (Moolatrikona 45 / Own
/// 30 / Ati Mitra 22.5 / Mitra 15 / Sama 7.5 / Satru 3.75 / Ati
/// Satru 1.875) across the 7 vargas. Max 315 (45×7).
double saptavargajaBala(Planet planet, AstroSnapshot snapshot) {
  final rasiSignOf = {
    for (final p in kShadbalaPlanets) p: snapshot.positions[p]!.sign,
  };
  final pos = snapshot.positions[planet]!;
  var total = 0.0;
  for (final v in kSaptavargas) {
    final isRasi = v == Varga.d1;
    total += _vargaDignityScore(
      planet: planet,
      vargaSign: vargaSign(v, pos.longitude),
      planetRasiSign: pos.sign,
      rasiSignOf: rasiSignOf,
      checkMoolatrikonaRange: isRasi,
      degreeInRasi: isRasi ? pos.degreesInSign : null,
    );
  }
  return total;
}

/// Ojayugmarasyamsa Bala: female grahas (Moon, Venus) score 15 per
/// EVEN sign (Rasi + Navamsa, checked separately); male (Sun, Mars,
/// Jupiter) and neutral (Mercury, Saturn) score 15 per ODD sign. Max 30.
double ojayugmaBala(Planet planet, ZodiacSign rasiSign, ZodiacSign navamsa) {
  final wantsOdd = planet != Planet.moon && planet != Planet.venus;
  double scoreFor(ZodiacSign s) => (wantsOdd ? s.isOdd : !s.isOdd) ? 15 : 0;
  return scoreFor(rasiSign) + scoreFor(navamsa);
}

/// Kendradi Bala: Kendra houses (1/4/7/10) → 60, Panaphara (2/5/8/11)
/// → 30, Apoklima (3/6/9/12) → 15.
double kendradiBala(int houseFromLagna1to12) {
  if (const {1, 4, 7, 10}.contains(houseFromLagna1to12)) return 60;
  if (const {2, 5, 8, 11}.contains(houseFromLagna1to12)) return 30;
  return 15;
}

// ROUND 3 FIX (Task 12, validated exactly against all 7 PL9 fixture
// planets): male grahas score in the 1st drekkana (0–10°) as before,
// but female (Moon/Venus) and neutral (Mercury/Saturn) were SWAPPED —
// PL9 awards female grahas the 3rd drekkana (20–30°) and neutral
// grahas the 2nd (10–20°), not the other way around as this file
// previously had it. Confirmed against all 7 fixture planets: e.g. the
// Moon (female, 3rd-drekkana degree) and Saturn (neutral, 2nd-drekkana
// degree) both score 15 only under this ordering.
int _drekkanaGroup(Planet p) => switch (p) {
      Planet.sun || Planet.mars || Planet.jupiter => 0, // male
      Planet.mercury || Planet.saturn => 1, // neutral
      Planet.moon || Planet.venus => 2, // female
      _ => -1,
    };

/// Drekkana Bala: male grahas score 15 in the 1st decanate (0–10° of
/// sign), female in the 2nd (10–20°), neutral in the 3rd (20–30°).
double drekkanaBala(Planet planet, double degreeInSign) {
  final part = (degreeInSign ~/ 10).clamp(0, 2);
  return part == _drekkanaGroup(planet) ? 15 : 0;
}

/// Total Sthana Bala for [planet] (max 165 Virupas theoretically:
/// 60 Uccha-ish + up to 315 Saptavargaja is the real ceiling, but
/// combined charts rarely approach it).
double sthanaBala(Planet planet, AstroSnapshot snapshot) {
  final pos = snapshot.positions[planet]!;
  final navamsa = navamsaSign(pos.longitude);
  return uchchaBala(planet, pos.longitude) +
      saptavargajaBala(planet, snapshot) +
      ojayugmaBala(planet, pos.sign, navamsa) +
      kendradiBala(snapshot.houseOfPlanet(planet)) +
      drekkanaBala(planet, pos.degreesInSign);
}

// =============================================================================
// 2. Dig Bala (directional) — Saravali "Dig Bala".
// =============================================================================

/// Dig Bala: angular distance from the graha's weakest direction,
/// divided by 3 (0 at the weakest point, 60 at the strongest —
/// exactly opposite it in every case).
///
/// ROUND 4 FIX (validated EXACTLY — all 7 PL9 fixture planets to
/// 0.01): the power/weakness points are the TRUE Ascendant and
/// Midheaven DEGREES (Placidus ascmc), not whole-sign cusp starts
/// (snapshot.houseCusps holds whole-sign fills, which broke this by
/// up to 20 Virupas). Strongest: Ju/Me at Asc, Su/Ma at MC, Sa at
/// Desc, Mo/Ve at IC.
double digBala(
  Planet planet,
  double longitude, {
  required double ascendant,
  required double midheaven,
}) {
  final power = switch (planet) {
    Planet.jupiter || Planet.mercury => ascendant,
    Planet.sun || Planet.mars => midheaven,
    Planet.saturn => _norm360(ascendant + 180),
    _ => _norm360(midheaven + 180), // Moon, Venus
  };
  return angularDistance(longitude, _norm360(power + 180)) / 3;
}

// =============================================================================
// 3. Kala Bala (temporal) — Nathonnata + Paksha + Tribhaga +
//    Varsha/Masa/Dina/Hora + Ayana (+ Yuddha as a post-hoc adjustment).
//    Saravali "Kala Bala" / "Ayana Bala".
// =============================================================================

/// Nathonnata Bala: diurnal/nocturnal strength from how close the
/// birth is to LOCAL midnight vs. midday.
///
/// ROUND 3 FIX (Task 12): the previous version used the raw TIMEZONE
/// clock time, off by ~2 Virupas against the PL9 fixture (8.75 vs its
/// 6.65 for the diurnal group). This uses LOCAL MEAN TIME instead —
/// the wall clock corrected for how far the birth longitude sits from
/// its timezone's own standard meridian — which brings both fixture
/// groups within 0.2–0.35 Virupas. Still a SIMPLIFICATION: it omits
/// the equation of time (the Sun's few-minutes-a-day irregularity
/// versus a perfectly uniform mean Sun), which needs the Sun's true
/// hour angle (apparent sidereal time − Sun's right ascension) to
/// correct fully — noted rather than silently assumed, since the
/// residual is well inside this component's ±0.75 tolerance but not
/// zero.
double nathonnataBala(Planet planet, BirthData birth) {
  if (planet == Planet.mercury) return 60;
  final standardMeridian = birth.utcOffsetMinutes / 60.0 * 15; // degrees
  final correctionHours = (birth.longitude - standardMeridian) * 4 / 60;
  final clock = birth.localDateTime;
  var hour = clock.hour +
      clock.minute / 60.0 +
      clock.second / 3600.0 +
      correctionHours +
      // ROUND 4: apply the equation of time (LMT → LOCAL APPARENT
      // TIME); the low-precision seasonal formula below is good to
      // ~±20s, i.e. ~0.1 Virupa — brings the PL9 fixture within 0.2.
      _equationOfTimeHours(clock);
  hour = ((hour % 24) + 24) % 24;
  final fromMidnight = hour <= 12 ? hour : 24 - hour; // 0..12
  final unnataGhatis = fromMidnight * 2.5; // 12h * 2.5 ghati/h = 30 ghatis max
  final nataGhatis = 30 - unnataGhatis;
  return switch (planet) {
    Planet.moon || Planet.mars || Planet.saturn => (2 * nataGhatis).clamp(0, 60),
    Planet.sun || Planet.jupiter || Planet.venus =>
      (2 * unnataGhatis).clamp(0, 60),
    _ => 0,
  };
}

/// Equation of time (apparent − mean solar time), in hours — the
/// classic low-precision seasonal formula (±20s), pure math so
/// callers stay unit-testable without an ephemeris.
double _equationOfTimeHours(DateTime localDate) {
  final startOfYear = DateTime(localDate.year);
  final dayOfYear = localDate.difference(startOfYear).inDays + 1;
  final b = 2 * math.pi * (dayOfYear - 81) / 364.0;
  final minutes =
      9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
  return minutes / 60.0;
}

double _pakshaV(double moonSunElongation) =>
    60 - (180 - moonSunElongation).abs() / 3;

/// Paksha Bala: benefics score high near Full Moon, malefics near New
/// Moon. The Moon uses whichever formula matches its OWN paksha
/// (Shukla=benefic-style, Krishna=malefic-style); Mercury is malefic-
/// style only when sharing a Rasi sign with Sun/Mars/Saturn.
double pakshaBala(
  Planet planet,
  double sunLongitude,
  double moonLongitude, {
  required bool mercuryWithMalefic,
}) {
  final elong = _norm360(moonLongitude - sunLongitude);
  final v = _pakshaV(elong);
  return switch (planet) {
    Planet.jupiter || Planet.venus => v,
    Planet.sun || Planet.mars || Planet.saturn => 60 - v,
    Planet.moon => elong <= 180 ? v : 60 - v,
    Planet.mercury => mercuryWithMalefic ? 60 - v : v,
    _ => 0,
  };
}

const Map<int, Planet> _tribhagaDayLord = {
  0: Planet.mercury,
  1: Planet.sun,
  2: Planet.saturn,
};
const Map<int, Planet> _tribhagaNightLord = {
  0: Planet.moon,
  1: Planet.venus,
  2: Planet.mars,
};

/// Tribhaga Bala: 60 Virupas to the ruling lord of the birth's
/// day/night third (see [_tribhagaDayLord]/[_tribhagaNightLord]) — and
/// ALWAYS to Jupiter as well, so every chart has exactly two 60s here.
double tribhagaBala(Planet planet, Planet periodLord) {
  if (planet == Planet.jupiter) return 60;
  return planet == periodLord ? 60 : 0;
}

/// Weekday → its classical ruling planet (`DateTime.weekday`: Mon=1…Sun=7).
const Map<int, Planet> _kWeekdayLordShadbala = {
  DateTime.monday: Planet.moon,
  DateTime.tuesday: Planet.mars,
  DateTime.wednesday: Planet.mercury,
  DateTime.thursday: Planet.jupiter,
  DateTime.friday: Planet.venus,
  DateTime.saturday: Planet.saturn,
  DateTime.sunday: Planet.sun,
};

/// Days elapsed since the Kali Yuga epoch (JD 588465.5 — midnight,
/// 18 Feb 3102 BCE Julian) for a UTC calendar day at midnight.
int _ahargana(DateTime utcDay) {
  final daysSinceUnixEpoch = utcDay.difference(DateTime.utc(1970)).inDays;
  // Unix epoch 1970-01-01 00:00 UT = JD 2440587.5.
  return (2440587.5 + daysSinceUnixEpoch - 588465.5).round();
}

/// Lord for an Abda/Masa index (the `(quotient×3+1)%7` /
/// `(quotient×2+1)%7` values used below). The cyclic offset was
/// solved from the PL9 fixture (9 Apr 1981 → Abda Mars, Masa Saturn)
/// and independently confirmed against B.V. Raman's Standard
/// Horoscope (16 Oct 1918 → Abda Saturn, Masa Mercury) — both charts
/// reproduce exactly.
const List<Planet> _aharganaLordOrder = [
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
  Planet.sun,
  Planet.moon,
  Planet.mars,
];
Planet _aharganaLord(int index) => _aharganaLordOrder[index % 7];

double varshaBala(Planet planet, Planet varshaLord) =>
    planet == varshaLord ? 15 : 0;
double masaBala(Planet planet, Planet masaLord) =>
    planet == masaLord ? 30 : 0;
double dinaBala(Planet planet, Planet dinaLord) =>
    planet == dinaLord ? 45 : 0;
double horaBala(Planet planet, Planet horaLord) =>
    planet == horaLord ? 60 : 0;

/// Ayana (equinoctial) Bala — declination ("kranti") based.
/// [tropicalLongitude] = sidereal longitude + ayanamsa (Ayana Bala is
/// a tropical strength; the ayanamsa correction is deliberately
/// re-applied).
///
/// ROUND 4 (replaces the Khanda-table proxy; validated against ALL 7
/// PL9 fixture planets within 0.25 Virupas, including the Moon that
/// the Khanda method missed by ~1): kranti is derived from the
/// tropical longitude with the classical obliquity 23.87°
/// (δ = asin(sin ε · sin λ)), then
/// ayana = 60 × (23.87 ± δ) / 47.74 — plus-sign planets are the
/// north-strong Su/Ma/Me/Ju/Ve; Moon and Saturn are south-strong.
/// PL9 does NOT double the Sun's ayana bala; neither does this.
double ayanaBala(Planet planet, double tropicalLongitude) {
  const eps = 23.87;
  const epsRad = eps * math.pi / 180;
  final lamRad = _norm360(tropicalLongitude) * math.pi / 180;
  final decl =
      math.asin(math.sin(epsRad) * math.sin(lamRad)) * 180 / math.pi;
  // Mercury gains from BOTH ayanas — its declination counts positive
  // whether north or south (classical rule; confirmed blind by the
  // 1969 reference chart, where Mercury sits at southern declination
  // and PL9 reads exactly 5.00 above the signed-declination value).
  final effective = switch (planet) {
    Planet.mercury => decl.abs(),
    Planet.moon || Planet.saturn => -decl,
    _ => decl,
  };
  return ((eps + effective) / (2 * eps) * 60).clamp(0.0, 60.0);
}

/// Yuddha (planetary war): when two of the five non-luminaries are
/// within 1° of each other, the Kala Bala accumulated so far is
/// redistributed — the difference is added to the higher-longitude
/// "winner" and deducted from the loser. Saravali places Yuddha as a
/// Kala Bala sub-part (adjusting Kala Bala specifically); some
/// summaries instead redistribute the full Shadbala total — this
/// file follows Saravali's more specific placement.
Map<Planet, double> applyYuddhaBala(
  Map<Planet, double> kalaBalaSoFar,
  Map<Planet, double> longitudes,
) {
  const warPlanets = [
    Planet.mars,
    Planet.mercury,
    Planet.jupiter,
    Planet.venus,
    Planet.saturn,
  ];
  final out = Map<Planet, double>.from(kalaBalaSoFar);
  for (var i = 0; i < warPlanets.length; i++) {
    for (var j = i + 1; j < warPlanets.length; j++) {
      final a = warPlanets[i], b = warPlanets[j];
      if (angularDistance(longitudes[a]!, longitudes[b]!) > 1.0) continue;
      final winner = longitudes[a]! >= longitudes[b]! ? a : b;
      final loser = winner == a ? b : a;
      final diff = (out[winner]! - out[loser]!).abs();
      out[winner] = out[winner]! + diff;
      out[loser] = out[loser]! - diff;
    }
  }
  return out;
}

// =============================================================================
// 4. Cheshta Bala (motional) — Saravali "Cheshta Bala".
// =============================================================================

/// Mean Sun (geocentric, TROPICAL) longitude — Meeus 25.2, the
/// Sighrochcha/Madhya reference for Cheshta Bala. [t] = Julian
/// centuries since J2000.0.
double meanSunTropicalLongitude(double t) =>
    _norm360(280.46646 + 36000.76983 * t);

/// Cheshta Bala for the five tara grahas. The Sun and Moon have no
/// Cheshta of their own — the Sun's Ayana Bala and the Moon's Paksha
/// Bala stand in for it.
///
/// ROUND 4 (validated against the PL9 fixture, max error 2.8 Virupas
/// with four of five within 1.5): the Chesta Kendra is the arc between
/// the graha's TRUE HELIOCENTRIC tropical longitude (its effective
/// Sighrochcha position — sweph computes it directly, no mean-element
/// series needed) and the MEAN Sun's tropical longitude; bala =
/// kendra/3 (folded to ≤180°). This single rule covers superior AND
/// inferior grahas: near superior conjunction (Venus 1.49, Mars 1.68
/// in the fixture) the arc collapses; near opposition/retrograde
/// (Jupiter 55.69, Saturn 55.36) it approaches 180°.
double cheshtaBala({
  required Planet planet,
  required double sunAyanaBala,
  required double moonPakshaBala,
  double? helioTropicalLongitude,
  double? meanSunTropical,
}) {
  if (planet == Planet.sun) return sunAyanaBala;
  if (planet == Planet.moon) return moonPakshaBala;
  if (helioTropicalLongitude == null || meanSunTropical == null) return 0;
  return angularDistance(helioTropicalLongitude, meanSunTropical) / 3;
}

// =============================================================================
// 5. Naisargika Bala (natural, fixed) — Saravali "Naisargika Bala".
// =============================================================================

const Map<Planet, double> kNaisargikaBala = {
  Planet.sun: 60,
  Planet.moon: 51.43,
  Planet.venus: 42.86,
  Planet.jupiter: 34.29,
  Planet.mercury: 25.71,
  Planet.mars: 17.14,
  Planet.saturn: 8.57,
};

// =============================================================================
// 6. Drik Bala (aspectual) — Saravali "Drig Bala" / "Sphuta Drishti".
//
// TWO-CHART CALIBRATION (2026-07-14): Parashara's continuous Sputa
// Drishti, with per-planet curves and benefic/malefic classification
// fitted against TWO independent PL9 reference tables (a 1981
// Capricorn-lagna chart and a 2005 Leo-lagna chart — 14 planet Drig
// constraints total). Result: all 14 within ±2.8 (12 within ±1.8).
// Malefic contributions are SIGNED (subtracted) at unit weight —
// PL9's deeply negative Jupiter/Saturn rows cannot arise otherwise.
//
// Calibration notes (see the individual curve functions):
//  - Mars's 4th-aspect approach (60–90°) grades at HALF the generic
//    slope; the former full 4th/8th peak boosts never fired on a
//    constrained angle and were removed.
//  - Saturn keeps NO 3rd-aspect boost (plain generic below 150°), a
//    LOW dampened 150–235° segment, and a dead 235–265° zone.
//  - Jupiter's 9th-aspect zone extends to 280°.
//  - The Moon counts malefic while within 30° of the Sun even when
//    technically waxing.
// Known residual: the 2005 Sun row is off by −2.75 (all levers for it
// are pinned by other constraints); segments no reference angle
// exercises (Mars 102–150°, Saturn ≥265°, Jupiter ≥280°) remain
// unconstrained smoothing — refine with a third chart if a
// discrepancy surfaces.
// =============================================================================

/// General-graha Sputa Drishti curve (Su/Mo/Me/Ve): 0 below 30°,
/// rising to 15 at 60°, 45 at 90°, easing to 30 at 120°, 0 at 150°,
/// full 60 at 180° (the 7th), then tapering (300−θ)/2 to 0 at 300°.
double _drishtiGeneric(double a) {
  if (a < 30 || a >= 300) return 0;
  if (a < 60) return (a - 30) / 2;
  if (a < 90) return a - 45;
  if (a < 120) return 45 - (a - 90) / 2;
  if (a < 150) return 30 - (a - 120);
  if (a < 180) return 2 * (a - 150);
  return (300 - a) / 2;
}

/// Mars — TWO-CHART CALIBRATION (1981 + 2005 PL9 tables): the 4th-
/// aspect APPROACH (60–90°) grades at HALF the generic slope
/// (observed 19.6 @72.1° and 21.9 @75.8°, both ≈ 15+(a−60)/2, where
/// the generic a−45 overshoots by ~8). The former full-strength 4th/
/// 8th peak boosts never fired on a constrained angle in either chart
/// and are removed; 90–102° linearly rejoins the generic curve
/// (unconstrained smoothing — refine when a chart exercises it).
double _drishtiMars(double a) {
  if (a >= 60 && a < 90) return 15 + (a - 60) / 2;
  if (a >= 90 && a < 102) return 30 + 1.25 * (a - 90);
  return _drishtiGeneric(a);
}

/// Jupiter: generic plus full 5th (120°) and 9th (240°) peaks. The
/// 9th-aspect zone extends past the classical 270° cutoff: PL9's 2005
/// Saturn row needs 26.3 @273.7° (generic gives 13.1); 280–300°
/// tapers back to the generic falloff (unconstrained smoothing).
double _drishtiJupiter(double a) {
  var v = _drishtiGeneric(a);
  if (a >= 90 && a < 150) v = math.max(v, 60 - (a - 120).abs());
  if (a >= 210 && a < 280) v = math.max(v, 60 - (a - 240).abs());
  if (a >= 280 && a < 300) v = math.max(v, 20 - (a - 280));
  return v;
}

/// Saturn — TWO-CHART CALIBRATION: generic below 150° (the former
/// 3rd-aspect boost and 60–90 plateau are removed — PL9's 2005
/// Jupiter row needs the plain generic 41.3 @86.3°); 150–250° stays
/// the LOW dampened segment fitted in round 4 (now re-confirmed by
/// four 2005 constraints: 16.1 @182.8°, 17.5 @177.2°); 250–265° is
/// DEAD (PL9 gives ≈0 @249.5°, @255.0°, @258.6° across both charts —
/// the 10th-aspect peak is much narrower than classical summaries
/// suggest); a steep narrow 10th peak at 265–270° (unconstrained),
/// then the classical falloff.
double _drishtiSaturn(double a) {
  if (a <= 30 || a >= 300) return 0;
  if (a < 150) return _drishtiGeneric(a);
  // Slope refitted on six constraints across both charts (16.1 @182.8°,
  // 17.5 @177.2°, 17.9 @175.3°, 13.6 @193.4°, 13.9 @192.1°, ≈0 @235.5°).
  if (a < 235) return 0.309 * (235 - a);
  if (a < 265) return 0;
  if (a < 270) return 12 * (a - 265);
  return 2 * (300 - a);
}

/// Sputa Drishti of [aspecting] on a point [angleForward] degrees
/// ahead of it (0–60 Virupas).
double sputaDrishtiVirupas(Planet aspecting, double angleForward) {
  final a = _norm360(angleForward);
  return switch (aspecting) {
    Planet.mars => _drishtiMars(a),
    Planet.jupiter => _drishtiJupiter(a),
    Planet.saturn => _drishtiSaturn(a),
    _ => _drishtiGeneric(a),
  };
}

bool _isBeneficForDrik(
  Planet p, {
  required bool moonIsShukla,
  required bool moonNearSun,
  required bool mercuryWithMalefic,
}) =>
    switch (p) {
      Planet.jupiter || Planet.venus => true,
      // TWO-CHART CALIBRATION: a waxing Moon still counts MALEFIC while
      // dark (close to the Sun). PL9's 1981 table (elongation 56°)
      // needs a benefic Moon; its 2005 table (elongation 14.5°, Shukla
      // Dwitiya) needs a malefic one. Threshold set at 30° — the exact
      // classical cutoff between those two observations is unknown.
      Planet.moon => moonIsShukla && !moonNearSun,
      Planet.mercury => !mercuryWithMalefic,
      _ => false, // Sun, Mars, Saturn
    };

/// Signed sputa-drishti sum of all seven grahas on [targetLongitude]:
/// benefic aspects add the full virupa value, malefic subtract it
/// (×1, NOT the 1.25/0.75 rectification some summaries list — the
/// PL9 fixture magnitudes only reproduce with unit weights). Shared
/// by planet Drik Bala and Bhava Drishti Bala.
///
/// ROUND 4 VALIDATION: all 7 fixture planets within 1.8 Virupas
/// (Su/Ma/Ve exact to 0.3); bhava-madhya rows follow the same rule
/// with larger residuals on houses opposite a stellium (documented in
/// bhava_bala.dart).
double signedSputaDrishtiOn(
  double targetLongitude,
  Map<Planet, PlanetPosition> positions, {
  required bool moonIsShukla,
  Planet? exclude,
}) {
  final mercuryWithMalefic = const {Planet.sun, Planet.mars, Planet.saturn}
      .any((m) =>
          positions[m]!.sign == positions[Planet.mercury]!.sign);
  final moonNearSun = angularDistance(positions[Planet.moon]!.longitude,
          positions[Planet.sun]!.longitude) <
      30;
  var total = 0.0;
  for (final p in kShadbalaPlanets) {
    if (p == exclude) continue;
    final angle = targetLongitude - positions[p]!.longitude;
    if (angularDistance(targetLongitude, positions[p]!.longitude) < 0.001) {
      continue;
    }
    final sputa = sputaDrishtiVirupas(p, angle);
    if (sputa == 0) continue;
    final benefic = _isBeneficForDrik(p,
        moonIsShukla: moonIsShukla,
        moonNearSun: moonNearSun,
        mercuryWithMalefic: mercuryWithMalefic);
    total += benefic ? sputa : -sputa;
  }
  return total;
}

double drikBala(
  Planet target,
  AstroSnapshot snapshot, {
  required bool moonIsShukla,
}) =>
    signedSputaDrishtiOn(
      snapshot.positions[target]!.longitude,
      snapshot.positions,
      moonIsShukla: moonIsShukla,
      exclude: target,
    );

// =============================================================================
// Putting it together
// =============================================================================

class ShadbalaResult {
  const ShadbalaResult({
    required this.planet,
    required this.sthana,
    required this.dig,
    required this.kala,
    required this.cheshta,
    required this.naisargika,
    required this.drik,
  });

  final Planet planet;
  final double sthana;
  final double dig;
  final double kala;
  final double cheshta;
  final double naisargika;
  final double drik;

  /// Total, in shashtiamsas (Virupas).
  double get total => sthana + dig + kala + cheshta + naisargika + drik;

  double get rupas => total / 60;

  double get requiredMinimum => kShadbalaRequiredMinimum[planet]!;

  /// total / required — > 1 means the graha exceeds its classical
  /// minimum ("strong").
  double get ratio => total / requiredMinimum;
}

/// The full Shadbala computation for every graha in [snapshot].
/// Performs a sunrise/sunset lookup around the birth instant — not
/// free, so callers should memoize this per kundli (see
/// `shadbalaProvider` in state/providers.dart) rather than call it
/// from a widget's build(). Async only to guarantee
/// [EphemerisService.init]; PDF export (synchronous by contract) uses
/// [computeShadbalaSync] instead, safe because a snapshot can only
/// exist once [SnapshotBuilder] has already awaited init().
Future<List<ShadbalaResult>> computeShadbala(AstroSnapshot snapshot) async {
  await EphemerisService.init();
  return computeShadbalaSync(snapshot);
}

/// Synchronous core of [computeShadbala] — see its doc for when it's
/// safe to call this directly instead.
List<ShadbalaResult> computeShadbalaSync(AstroSnapshot snapshot) {
  final svc = EphemerisService.instance;
  final birth = snapshot.birth;
  final sunPos = snapshot.positions[Planet.sun]!;
  final moonPos = snapshot.positions[Planet.moon]!;
  final moonIsShukla = snapshot.panchang.paksha == 'Shukla';
  final mercuryWithMalefic = const {Planet.sun, Planet.mars, Planet.saturn}
      .any((m) => snapshot.positions[m]!.sign == snapshot.positions[Planet.mercury]!.sign);

  // --- Sunrise / sunset bracketing the birth instant (Tribhaga & Hora),
  // mirroring daily_panchang.dart's "sunrise at/before now, sunset
  // after that" pattern — but kept in UTC + the birth's own stored
  // utcOffsetMinutes throughout, NEVER DateTime.toLocal() (which would
  // silently use the running DEVICE's zone instead of the birth PLACE's).
  final jdBirth = svc.julianDayUt(birth.dateTimeUtc);
  final riseJd = svc.sunriseBefore(jdBirth, birth.latitude, birth.longitude)!;
  final setJd =
      svc.sunEventAfter(riseJd, birth.latitude, birth.longitude, rise: false)!;
  final nextRiseJd =
      svc.sunEventAfter(setJd, birth.latitude, birth.longitude, rise: true)!;
  DateTime placeLocal(double jd) => EphemerisService.dateTimeFromJdUt(jd)
      .add(Duration(minutes: birth.utcOffsetMinutes));
  final sunrise = placeLocal(riseJd);
  final sunset = placeLocal(setJd);
  final nextSunrise = placeLocal(nextRiseJd);
  final birthLocal = birth.localDateTime;
  final isDay = !birthLocal.isBefore(sunrise) && birthLocal.isBefore(sunset);

  // --- Tribhaga Bala's period lord. By construction [sunrise] is the
  // rise at-or-before birth and [nextSunrise] the following one, so
  // birthLocal always falls in [sunrise, nextSunrise) — the night
  // third (if any) is always measured from [sunset] onward.
  final Planet tribhagaLord;
  if (isDay) {
    final frac = birthLocal.difference(sunrise).inSeconds /
        sunset.difference(sunrise).inSeconds;
    tribhagaLord = _tribhagaDayLord[(frac * 3).floor().clamp(0, 2)]!;
  } else {
    final frac = birthLocal.difference(sunset).inSeconds /
        nextSunrise.difference(sunset).inSeconds;
    tribhagaLord = _tribhagaNightLord[(frac * 3).floor().clamp(0, 2)]!;
  }

  // --- Hora Bala's period lord: 24 slots cycling continuously from the
  // weekday lord (Chaldean order) — reuses the exact same convention
  // as the Muhurta screen's Hora band (kHoraCycle/kWeekdayLord in
  // muhurta.dart; duplicated here as a small fixed table rather than
  // importing a screen-layer file from the core engine).
  const horaCycle = [
    Planet.sun, Planet.venus, Planet.mercury, Planet.moon,
    Planet.saturn, Planet.jupiter, Planet.mars,
  ];
  final horaStartIdx = horaCycle.indexOf(_kWeekdayLordShadbala[sunrise.weekday]!);
  final Planet horaLord;
  if (isDay) {
    final dayLen = sunset.difference(sunrise).inSeconds / 12;
    final slot = (birthLocal.difference(sunrise).inSeconds / dayLen)
        .floor()
        .clamp(0, 11);
    horaLord = horaCycle[(horaStartIdx + slot) % 7];
  } else {
    final nightLen = nextSunrise.difference(sunset).inSeconds / 12;
    final slot = (birthLocal.difference(sunset).inSeconds / nightLen)
        .floor()
        .clamp(0, 11);
    horaLord = horaCycle[(horaStartIdx + 12 + slot) % 7];
  }

  // --- Abda (year) / Masa (month) / Vara (weekday) lords: BPHS's
  // Ahargana ("elapsed day count") method — see [_ahargana]/
  // [_aharganaLord] — anchored to the VEDIC day (the calendar date of
  // the last sunrise at-or-before birth), matching the sunrise-
  // anchored Hora Bala above.
  //
  // ROUND 3 FIX (Task 12): the previous version found Varsha/Masa
  // lords via the WEEKDAY the Sun most recently crossed into Aries/
  // its current sign — an entirely different (and wrong) classical
  // rule; it also required two backward ephemeris scans this
  // replacement no longer needs. Validated against BOTH B.V. Raman's
  // own worked "Standard Horoscope" example (16 Oct 1918 → Abda
  // Saturn, Masa Mercury, Vara Mercury) and the PL9 fixture (9 Apr
  // 1981 → Abda Mars, Masa Saturn, Vara Mercury). The previous
  // version's Vara (weekday) lord was ALSO wrong on its own: it used
  // birthLocal's CALENDAR weekday rather than the sunrise-anchored
  // Vedic day, so a birth after midnight but before sunrise (like this
  // fixture, 01:45 on a calendar Thursday) landed on the wrong weekday
  // (Thursday/Jupiter) instead of the Vedic Wednesday/Mercury.
  final vedicDay = DateTime.utc(sunrise.year, sunrise.month, sunrise.day);
  final ahargana = _ahargana(vedicDay);
  final varshaLord = _aharganaLord(((ahargana ~/ 360) * 3 + 1) % 7);
  final masaLord = _aharganaLord(((ahargana ~/ 30) * 2 + 1) % 7);
  final dinaLord = _kWeekdayLordShadbala[sunrise.weekday]!;

  // --- Sun's Cheshta stand-in (Ayana Bala) & Moon's (Paksha Bala),
  // computed once and reused for both their own Kala Bala AND as the
  // Cheshta Bala inputs below.
  final sunAyana = ayanaBala(Planet.sun, sunPos.longitude + snapshot.ayanamsaValue);
  final moonPaksha = pakshaBala(Planet.moon, sunPos.longitude, moonPos.longitude,
      mercuryWithMalefic: mercuryWithMalefic);

  // --- Dig Bala reference points: the TRUE Ascendant/Midheaven
  // degrees (snapshot.houseCusps holds whole-sign fills — see
  // digBala's ROUND 4 note).
  final houses = svc.housesAndAscendant(
      jdBirth, birth.latitude, birth.longitude, snapshot.ayanamsaId);
  final trueAsc = houses.ascendant;
  final trueMc = houses.cusps[9];

  // --- Cheshta inputs: true heliocentric tropical longitudes +
  // the mean Sun (see cheshtaBala's ROUND 4 note).
  final helio = svc.helioTropicalLongitudes(jdBirth);
  final meanSun = meanSunTropicalLongitude((jdBirth - 2451545.0) / 36525.0);

  // --- Per-planet Kala Bala (pre-Yuddha) and Cheshta Bala.
  final kalaPreYuddha = <Planet, double>{};
  final cheshta = <Planet, double>{};
  for (final p in kShadbalaPlanets) {
    final pos = snapshot.positions[p]!;
    final tropicalLon = pos.longitude + snapshot.ayanamsaValue;
    kalaPreYuddha[p] = nathonnataBala(p, birth) +
        pakshaBala(p, sunPos.longitude, moonPos.longitude,
            mercuryWithMalefic: mercuryWithMalefic) +
        tribhagaBala(p, tribhagaLord) +
        varshaBala(p, varshaLord) +
        masaBala(p, masaLord) +
        dinaBala(p, dinaLord) +
        horaBala(p, horaLord) +
        ayanaBala(p, tropicalLon);
    cheshta[p] = cheshtaBala(
      planet: p,
      sunAyanaBala: sunAyana,
      moonPakshaBala: moonPaksha,
      helioTropicalLongitude: helio[p],
      meanSunTropical: meanSun,
    );
  }
  final longitudes = {
    for (final p in kShadbalaPlanets) p: snapshot.positions[p]!.longitude,
  };
  final kala = applyYuddhaBala(kalaPreYuddha, longitudes);

  return [
    for (final p in kShadbalaPlanets)
      ShadbalaResult(
        planet: p,
        sthana: sthanaBala(p, snapshot),
        dig: digBala(p, snapshot.positions[p]!.longitude,
            ascendant: trueAsc, midheaven: trueMc),
        kala: kala[p]!,
        cheshta: cheshta[p]!,
        naisargika: kNaisargikaBala[p]!,
        drik: drikBala(p, snapshot, moonIsShukla: moonIsShukla),
      ),
  ];
}
