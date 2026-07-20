/// Bhava Bala — strength of each of the 12 whole-sign houses (not the
/// planets in them), per Parashara/Raman's five-component model. Each
/// component is in shashtiamsas (Virupas), matching [ShadbalaResult]'s
/// convention; house totals are read as rupas (total/60).
///
/// SOURCES & VALIDATION — no printed reference (B.V. Raman's "Graha
/// and Bhava Balas") was fetchable in this environment. This session
/// gained real Swiss Ephemeris access and computed Parashar Light 9's
/// published fixture chart (9 Apr 1981 01:45, Delhi Paharganj —
/// Capricorn lagna) by hand to reverse-engineer and cross-check each
/// component below against PL9's House 1 breakdown (fromLord 377, dig
/// 30, drishti 49, planetsIn 0, dayNight 15) and House 3's implied
/// planetsIn (-60, per the handoff brief). Per component:
///  - [bhavaDigBala]: EXACT match (H1 dig = 30, reproduced precisely
///    with a Nara/Jalachara/Chatushpada/Keeta peak-house model — see
///    that function's doc comment). High confidence.
///  - [planetsInBala]: EXACT match on TWO independent points (H1 = 0
///    with an unrelated node — Ketu — occupying it but no classical
///    graha; H3 = -60 with Sun/Mars/Mercury/Venus occupying it).
///    Confirms: only the 7 Shadbala grahas count (Rahu/Ketu don't),
///    Mercury alone is neutral (contributes 0), and malefic/benefic
///    contributions are ±60 each, summed. High confidence.
///  - [dayNightBala]: matches the single H1 data point (odd sign +
///    day birth, or even sign + night birth, scores 15) but this is
///    only ONE data point — moderate confidence.
///  - [bhavaDrishtiBala]: does NOT reproduce the fixture's H1 = 49
///    exactly (this whole-sign model gives 60 for H1, from Jupiter's
///    5th-house aspect alone). The gap almost certainly has the same
///    root cause already documented in shadbala.dart's [drikBala]:
///    Parashara's true Drishti Bala grades aspect strength
///    continuously by exact degree separation (Sputa Drishti) rather
///    than firing at full strength for every whole-sign aspect — that
///    continuous formula was not implemented here. LOW confidence on
///    magnitude; the sign/mechanism (benefic aspects add, malefic
///    subtract, net can go negative) is faithful to the brief.
///  - [bhavadhipatiBala]: a hard dependency on shadbala.dart's engine
///    (per the handoff brief), which this same validation pass found
///    does NOT yet reproduce PL9's totals (see shadbala.dart's own
///    header for the evidence) — so this component inherits that
///    engine's current inaccuracy.
///
/// **Bottom line: structurally complete and two of five components
/// are strongly validated, but the overall total is NOT yet numerically
/// reliable** — continuous Sputa Drishti (shared by both this file and
/// shadbala.dart's Drik Bala) is the highest-value follow-up fix.
library;

import 'models.dart';
import 'shadbala.dart'
    show
        ShadbalaResult,
        angularDistance,
        kShadbalaPlanets,
        signedSputaDrishtiOn;

// =============================================================================
// 1. Bhavadhipati Bala — the bhava lord's TOTAL Shadbala (hard
//    dependency on shadbala.dart, per the handoff brief; NOT
//    recomputed here — see [computeBhavaBala]).
// =============================================================================

double bhavadhipatiBala(
    ZodiacSign bhavaSign, Map<Planet, ShadbalaResult> shadbalaByPlanet) {
  final lordResult = shadbalaByPlanet[bhavaSign.lord];
  // The lord may be a node-adjacent placement never scored by Shadbala
  // (shouldn't happen for the 7 classical rasi lords, but guard
  // defensively rather than throw on an unexpected map shape).
  return lordResult?.total ?? 0;
}

// =============================================================================
// 2. Bhava Dig Bala — by sign "nature" (Nara/Jalachara/Chatushpada/
//    Keeta) vs. house number. EXACT match against the fixture's H1=30
//    (Capricorn, Chatushpada, house 1) — see the peak-house table.
// =============================================================================

enum BhavaSignNature { nara, jalachara, chatushpada, keeta }

/// Sagittarius and Capricorn are split down the middle between two
/// natures (the classical "half-human-half-horse" / "half-goat-half-
/// fish" imagery); every other sign is wholly one nature. [degreeInSign]
/// disambiguates the split signs — for a whole-sign BHAVA (as opposed
/// to a specific planet), the natural reference degree is the
/// ascendant's own degree-in-sign, carried forward unchanged into
/// every subsequent whole-sign house (this is what the fixture's H1
/// implicitly validates: the actual Ascendant degree, ~0°10' Capricorn,
/// selects Chatushpada — Capricorn's FIRST half).
BhavaSignNature bhavaSignNatureOf(ZodiacSign sign, double degreeInSign) {
  switch (sign) {
    case ZodiacSign.aries:
    case ZodiacSign.taurus:
    case ZodiacSign.leo:
      return BhavaSignNature.chatushpada;
    case ZodiacSign.gemini:
    case ZodiacSign.virgo:
    case ZodiacSign.libra:
    case ZodiacSign.aquarius:
      return BhavaSignNature.nara;
    case ZodiacSign.pisces:
      return BhavaSignNature.jalachara;
    case ZodiacSign.cancer:
    // ROUND 4 FIX: Cancer (the crab) is KEETA, not jalachara — the
    // PL9 fixture's Dig Bala row only reproduces 12/12 with Cancer
    // peaking at house 7 (H7 Cancer = 60 in the fixture; jalachara's
    // peak-4 model gave 30).
    case ZodiacSign.scorpio:
      return BhavaSignNature.keeta;
    case ZodiacSign.sagittarius:
      // Front half human (Nara), back half horse (Chatushpada).
      return degreeInSign < 15
          ? BhavaSignNature.nara
          : BhavaSignNature.chatushpada;
    case ZodiacSign.capricorn:
      // Front half goat (Chatushpada), back half fish (Jalachara).
      return degreeInSign < 15
          ? BhavaSignNature.chatushpada
          : BhavaSignNature.jalachara;
  }
}

/// The house (1–12) where each nature peaks at 60 Virupas — Nara at
/// the Lagna, Jalachara at the 4th, Chatushpada at the 10th, Keeta at
/// the 7th — falling away by 10 Virupas per house step to 0 at the
/// exactly opposite house, then symmetrically back up.
const Map<BhavaSignNature, int> _bhavaNaturePeakHouse = {
  BhavaSignNature.nara: 1,
  BhavaSignNature.jalachara: 4,
  BhavaSignNature.chatushpada: 10,
  BhavaSignNature.keeta: 7,
};

double bhavaDigBala(int house1to12, BhavaSignNature nature) {
  final peak = _bhavaNaturePeakHouse[nature]!;
  final forward = ((house1to12 - peak) % 12 + 12) % 12; // 0..11
  final circularDist = forward <= 6 ? forward : 12 - forward; // 0..6
  return (60 - 10 * circularDist).toDouble();
}

// =============================================================================
// 3. Bhava Drishti Bala — signed sum of the 7 grahas' whole-sign
//    aspects onto the bhava (benefic aspects add, malefic subtract;
//    can be net negative). See the library doc comment: magnitude is
//    NOT validated against the fixture (whole-sign vs. continuous
//    Sputa Drishti gap, same root cause as shadbala.dart's Drik Bala).
// =============================================================================

/// ROUND 4: continuous signed Sputa Drishti on the bhava madhya (the
/// whole-sign bhava's 0° point — the variant that best matches the
/// PL9 fixture row), shared with shadbala.dart's Drik Bala. Fixture
/// agreement: 8 of 12 houses within ~11 Virupas (5 within 3); houses
/// aspected by the fixture's four-planet Pisces stellium near
/// opposition (H6/H7/H10/H11) run more negative than PL9 by up to
/// ~56 — their exact weighting can't be pinned by one chart. Impact:
/// at most 1 rounded rupa on those houses' totals; refine against a
/// second reference chart when available.
double bhavaDrishtiBala(
  double bhavaMadhyaLongitude,
  Map<Planet, PlanetPosition> positions, {
  required bool moonIsShukla,
}) =>
    signedSputaDrishtiOn(bhavaMadhyaLongitude, positions,
        moonIsShukla: moonIsShukla);

// =============================================================================
// 4. Planets-in adjustment — EXACT match on two fixture data points
//    (see library doc comment). Only the 7 Shadbala grahas count;
//    Mercury alone is neutral; malefics -60, benefics +60, summed.
// =============================================================================

/// TWO-CHART CALIBRATION (1981 + 2005 PL9 tables), replacing the
/// round-4 single-chart rule. All 24 reference rows reproduce under:
///  - Su/Ma/Sa −60; Ju +60; Moon ALWAYS neutral (1981 H5, Moon alone,
///    shows 0 even though that Moon was bright/benefic for drik).
///  - Venus +60 but ZERO when COMBUST (within 10° of the Sun): PL9's
///    2005 H7 (Sun + combust Venus) reads −60, not 0. 1981's Venus was
///    also combust — masked there by the clamp below.
///  - Mercury +60 when NOT sharing a sign with Su/Ma/Sa (same
///    association rule as drik): PL9's 2005 H8 (Moon + lone Mercury)
///    reads +60. When malefic-associated it is neutral (1981 H3 cannot
///    discriminate 0 vs −60 — the clamp hides it; neutral kept).
///  - House total CLAMPED to ±60: 1981 H3 (Sun −60, Mars −60) displays
///    −60, not −120.
double planetsInBala(
  int house1to12,
  Map<Planet, int> houseOfPlanet,
  Map<Planet, PlanetPosition> positions,
) {
  final sunLon = positions[Planet.sun]!.longitude;
  final mercuryWithMalefic = const {Planet.sun, Planet.mars, Planet.saturn}
      .any((m) => positions[m]!.sign == positions[Planet.mercury]!.sign);
  var total = 0.0;
  for (final p in kShadbalaPlanets) {
    if (houseOfPlanet[p] != house1to12) continue;
    total += switch (p) {
      Planet.sun || Planet.mars || Planet.saturn => -60,
      Planet.jupiter => 60,
      Planet.venus =>
        angularDistance(positions[p]!.longitude, sunLon) < 10 ? 0 : 60,
      Planet.mercury => mercuryWithMalefic ? 0 : 60,
      _ => 0, // Moon — neutral
    };
  }
  return total.clamp(-60, 60).toDouble();
}

// =============================================================================
// 5. Day-Night (Divaratri) Bala — single fixture point validated:
//    odd sign + day birth, or even sign + night birth, scores 15.
// =============================================================================

/// TWO-CHART CALIBRATION: PRISHTODAYA signs (rear-rising: Aries,
/// Taurus, Cancer, Sagittarius, Capricorn) score 15 in a NIGHT birth;
/// SIRSHODAYA signs (head-rising: Gemini, Leo, Virgo, Libra, Scorpio,
/// Aquarius) score 15 in a DAY birth. PISCES (ubhayodaya,
/// both-rising) scores 0 ALWAYS — PL9 gives it 0 in the 1981 night
/// birth AND the 2005 day birth.
const _prishtodaya = {
  ZodiacSign.aries,
  ZodiacSign.taurus,
  ZodiacSign.cancer,
  ZodiacSign.sagittarius,
  ZodiacSign.capricorn,
};

double dayNightBala(ZodiacSign bhavaSign, {required bool isDayBirth}) {
  if (bhavaSign == ZodiacSign.pisces) return 0; // ubhayodaya
  final nocturnal = _prishtodaya.contains(bhavaSign);
  return nocturnal != isDayBirth ? 15 : 0;
}

// =============================================================================
// Putting it together
// =============================================================================

class BhavaBalaResult {
  const BhavaBalaResult({
    required this.house,
    required this.sign,
    required this.fromLord,
    required this.dig,
    required this.drishti,
    required this.planetsIn,
    required this.dayNight,
  });

  final int house; // 1..12
  final ZodiacSign sign;
  final double fromLord;
  final double dig;
  final double drishti;
  final double planetsIn;
  final double dayNight;

  /// Total, in shashtiamsas (Virupas) — CAN be negative if
  /// [bhavaDrishtiBala] and/or [planetsInBala] outweigh the rest.
  double get total => fromLord + dig + drishti + planetsIn + dayNight;

  double get rupas => total / 60;
}

/// The full Bhava Bala computation for all 12 houses. Takes the
/// ALREADY-COMPUTED Shadbala results (e.g. from `shadbalaProvider` —
/// see the library doc comment on why this is a hard dependency, not
/// a recompute) rather than an [AstroSnapshot] plus its own internal
/// Shadbala call.
List<BhavaBalaResult> computeBhavaBala(
  AstroSnapshot snapshot,
  List<ShadbalaResult> shadbala,
) {
  final shadbalaByPlanet = {for (final r in shadbala) r.planet: r};
  final lagnaSign = snapshot.lagnaSign;
  final ascDegreeInSign = snapshot.ascendant % 30;
  final houseOfPlanet = {
    for (final p in kShadbalaPlanets) p: snapshot.houseOfPlanet(p),
  };
  final moonIsShukla = snapshot.panchang.paksha == 'Shukla';

  // Local sunrise/sunset aren't part of AstroSnapshot's stored fields
  // (only the panchang's own vara), so day/night birth is read off the
  // Sun's own house: classically, the Sun is "above the horizon" (day)
  // in houses 7-12 (from the Ascendant to the Descendant's far side)
  // and "below" (night) in houses 1-6 — i.e. whole-sign-consistent
  // with the Sun's placement relative to the Ascendant/Descendant axis
  // ONLY as an approximation (the true horizon crossing is a
  // continuous event, not a whole-sign boundary); a direct
  // sunrise/sunset lookup (as shadbala.dart's Kala Bala performs)
  // would be more precise but isn't available from the snapshot alone.
  final sunHouse = houseOfPlanet[Planet.sun]!;
  final isDayBirth = sunHouse >= 7 && sunHouse <= 12;

  return [
    for (var house = 1; house <= 12; house++)
      () {
        final sign = ZodiacSign.values[(lagnaSign.index + house - 1) % 12];
        final nature = bhavaSignNatureOf(sign, ascDegreeInSign);
        return BhavaBalaResult(
          house: house,
          sign: sign,
          fromLord: bhavadhipatiBala(sign, shadbalaByPlanet),
          dig: bhavaDigBala(house, nature),
          drishti: bhavaDrishtiBala(
              (sign.index * 30).toDouble(), snapshot.positions,
              moonIsShukla: moonIsShukla),
          planetsIn: planetsInBala(house, houseOfPlanet, snapshot.positions),
          dayNight: dayNightBala(sign, isDayBirth: isDayBirth),
        );
      }(),
  ];
}
