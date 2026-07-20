/// Ashtakoota Guna Milan — the classical 8-koota (36-point) marriage
/// compatibility match between two Moon positions.
///
/// SOURCES: all eight tables below are transcribed from the Saravali
/// project's from-source documentation of each koota (the same
/// project whose Shadbala pages this codebase's shadbala.dart cross-
/// checked against), itself citing the Maitreya implementation for
/// the handful of kootas (Vashya, Yoni, Gana) that have more than one
/// published variant. Cross-check totals against 2–3 published
/// matches (e.g. DrikPanchang) before trusting them — see
/// guna_milan_test.dart for what was checked in this environment.
library;

import 'dignity.dart' show PlanetDignity, dignityOf;
import 'models.dart';
import 'shadbala.dart' show PlanetaryRel, naturalRelOf;

// =============================================================================
// 1. Varna Koota (max 1) — social/spiritual matching by Moon rasi.
// =============================================================================

const Map<ZodiacSign, int> _varnaRank = {
  // 4 = Brahmin (highest) … 1 = Shudra (lowest).
  ZodiacSign.cancer: 4, ZodiacSign.scorpio: 4, ZodiacSign.pisces: 4,
  ZodiacSign.aries: 3, ZodiacSign.leo: 3, ZodiacSign.sagittarius: 3,
  ZodiacSign.gemini: 2, ZodiacSign.libra: 2, ZodiacSign.aquarius: 2,
  ZodiacSign.taurus: 1, ZodiacSign.virgo: 1, ZodiacSign.capricorn: 1,
};

const List<String> kVarnaNames = [
  '',
  'Shudra',
  'Vaishya',
  'Kshatriya',
  'Brahmin'
];

String varnaNameOf(ZodiacSign sign) => kVarnaNames[_varnaRank[sign]!];

/// Groom's Varna must be equal to or higher than the bride's.
double varnaKoota(ZodiacSign brideMoonSign, ZodiacSign groomMoonSign) =>
    _varnaRank[groomMoonSign]! >= _varnaRank[brideMoonSign]! ? 1 : 0;

// =============================================================================
// 2. Vashya Koota (max 2) — mutual control/amenability by Moon rasi.
// =============================================================================

enum VashyaGroup { quadruped, human, jalachara, leo, scorpio }

VashyaGroup vashyaGroupOf(ZodiacSign sign, double degreeInSign) {
  switch (sign) {
    case ZodiacSign.aries:
    case ZodiacSign.taurus:
      return VashyaGroup.quadruped;
    case ZodiacSign.gemini:
    case ZodiacSign.virgo:
    case ZodiacSign.libra:
    case ZodiacSign.aquarius:
      return VashyaGroup.human;
    case ZodiacSign.cancer:
    case ZodiacSign.pisces:
      return VashyaGroup.jalachara;
    case ZodiacSign.leo:
      return VashyaGroup.leo;
    case ZodiacSign.scorpio:
      return VashyaGroup.scorpio;
    case ZodiacSign.capricorn:
      return degreeInSign < 15 ? VashyaGroup.quadruped : VashyaGroup.jalachara;
    case ZodiacSign.sagittarius:
      // Sagittarius is not explicitly listed by Saravali's table (an
      // omission in the source) — classically it is half-quadruped
      // (Dhanu's front half, horse) / half-human (rear half); treated
      // as Human here (the more commonly cited default) since no
      // authoritative split degree was found in this environment.
      return VashyaGroup.human;
  }
}

const List<List<double>> _vashyaMatrix = [
  // Quadruped, Human, Jalachara, Leo, Scorpio  (row = bride, col = groom)
  [2, 0, 0, 0.5, 0],
  [1, 2, 1, 0.5, 1],
  [0.5, 1, 2, 1, 1],
  [0, 0, 0, 2, 0],
  [1, 1, 1, 0, 2],
];

double vashyaKoota(
  ZodiacSign brideSign,
  double brideDegreeInSign,
  ZodiacSign groomSign,
  double groomDegreeInSign,
) {
  final b = vashyaGroupOf(brideSign, brideDegreeInSign).index;
  final g = vashyaGroupOf(groomSign, groomDegreeInSign).index;
  return _vashyaMatrix[b][g];
}

// =============================================================================
// 3. Tara / Dina Koota (max 3) — bidirectional 27-nakshatra count mod 9.
// =============================================================================

double _taraOneWay(Nakshatra from, Nakshatra to) {
  final count = ((to.index - from.index + 27) % 27) + 1;
  final tara = ((count - 1) % 9) + 1; // 1..9
  return const {3, 5, 7}.contains(tara) ? 0 : 1.5;
}

/// Counted groom→bride AND bride→groom (Saravali's stated rule);
/// each direction independently scores 0 or 1.5.
double taraKoota(Nakshatra brideNakshatra, Nakshatra groomNakshatra) =>
    _taraOneWay(groomNakshatra, brideNakshatra) +
    _taraOneWay(brideNakshatra, groomNakshatra);

// =============================================================================
// 4. Yoni Koota (max 4) — animal-symbol compatibility by nakshatra.
// =============================================================================

enum Yoni {
  horse,
  elephant,
  sheep,
  serpent,
  dog,
  cat,
  rat,
  cow,
  buffalo,
  tiger,
  deer,
  monkey,
  mongoose,
  lion;

  String get label => switch (this) {
        horse => 'Horse',
        elephant => 'Elephant',
        sheep => 'Sheep',
        serpent => 'Serpent',
        dog => 'Dog',
        cat => 'Cat',
        rat => 'Rat',
        cow => 'Cow',
        buffalo => 'Buffalo',
        tiger => 'Tiger',
        deer => 'Deer',
        monkey => 'Monkey',
        mongoose => 'Mongoose',
        lion => 'Lion',
      };
}

/// Nakshatra → Yoni. Each Yoni traditionally has a male AND a female
/// nakshatra; Mongoose's female pairing is Abhijit, which this app's
/// 27-nakshatra scheme (matching the rest of the codebase) doesn't
/// include, so Mongoose maps from only one nakshatra here.
const Map<Nakshatra, Yoni> _yoniOfNakshatra = {
  Nakshatra.ashwini: Yoni.horse,
  Nakshatra.shatabhisha: Yoni.horse,
  Nakshatra.bharani: Yoni.elephant,
  Nakshatra.revati: Yoni.elephant,
  Nakshatra.pushya: Yoni.sheep,
  Nakshatra.krittika: Yoni.sheep,
  Nakshatra.rohini: Yoni.serpent,
  Nakshatra.mrigashira: Yoni.serpent,
  Nakshatra.mula: Yoni.dog,
  Nakshatra.ardra: Yoni.dog,
  Nakshatra.ashlesha: Yoni.cat,
  Nakshatra.punarvasu: Yoni.cat,
  Nakshatra.magha: Yoni.rat,
  Nakshatra.purvaPhalguni: Yoni.rat,
  Nakshatra.uttaraPhalguni: Yoni.cow,
  Nakshatra.uttaraBhadrapada: Yoni.cow,
  Nakshatra.swati: Yoni.buffalo,
  Nakshatra.hasta: Yoni.buffalo,
  Nakshatra.vishakha: Yoni.tiger,
  Nakshatra.chitra: Yoni.tiger,
  Nakshatra.jyeshtha: Yoni.deer,
  Nakshatra.anuradha: Yoni.deer,
  Nakshatra.purvaAshadha: Yoni.monkey,
  Nakshatra.shravana: Yoni.monkey,
  Nakshatra.purvaBhadrapada: Yoni.lion,
  Nakshatra.dhanishta: Yoni.lion,
  Nakshatra.uttaraAshadha: Yoni.mongoose,
};

Yoni yoniOf(Nakshatra n) => _yoniOfNakshatra[n]!;

// Row = bride's Yoni, column = groom's Yoni; order matches [Yoni.values].
const List<List<int>> _yoniMatrix = [
  [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 3, 3, 2, 1], // Horse
  [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0], // Elephant
  [2, 3, 4, 2, 1, 2, 1, 3, 3, 1, 2, 0, 3, 1], // Sheep
  [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2], // Serpent
  [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1], // Dog
  [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1], // Cat
  [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2], // Rat
  [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1], // Cow
  [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 1], // Buffalo
  [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1], // Tiger
  [1, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1], // Deer
  [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2], // Monkey
  [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2], // Mongoose
  [1, 0, 1, 2, 1, 1, 2, 1, 2, 1, 1, 2, 2, 4], // Lion
];

double yoniKoota(Nakshatra brideNakshatra, Nakshatra groomNakshatra) =>
    _yoniMatrix[yoniOf(brideNakshatra).index][yoniOf(groomNakshatra).index]
        .toDouble();

// =============================================================================
// 5. Graha Maitri (max 5) — natural friendship of the Moon-rasi lords.
// =============================================================================

double grahaMaitriKoota(ZodiacSign brideMoonSign, ZodiacSign groomMoonSign) {
  final bLord = brideMoonSign.lord;
  final gLord = groomMoonSign.lord;
  if (bLord == gLord) return 5; // a lord is trivially its own great friend
  final rel1 = naturalRelOf(bLord, gLord);
  final rel2 = naturalRelOf(gLord, bLord);
  final friends = [rel1, rel2].where((r) => r == PlanetaryRel.friend).length;
  final enemies = [rel1, rel2].where((r) => r == PlanetaryRel.enemy).length;
  if (friends == 2) return 5;
  if (enemies == 2) return 0;
  if (friends == 1 && enemies == 1) return 2;
  if (friends == 1) return 4; // friend + neutral
  if (enemies == 1) return 1; // neutral + enemy
  return 3; // both neutral
}

// =============================================================================
// 6. Gana Koota (max 6) — temperament, by nakshatra.
// =============================================================================

enum Gana { deva, manushya, rakshasa }

const Map<Nakshatra, Gana> _ganaOfNakshatra = {
  Nakshatra.ashwini: Gana.deva,
  Nakshatra.mrigashira: Gana.deva,
  Nakshatra.punarvasu: Gana.deva,
  Nakshatra.pushya: Gana.deva,
  Nakshatra.hasta: Gana.deva,
  Nakshatra.swati: Gana.deva,
  Nakshatra.anuradha: Gana.deva,
  Nakshatra.shravana: Gana.deva,
  Nakshatra.revati: Gana.deva,
  Nakshatra.bharani: Gana.manushya,
  Nakshatra.rohini: Gana.manushya,
  Nakshatra.ardra: Gana.manushya,
  Nakshatra.purvaPhalguni: Gana.manushya,
  Nakshatra.uttaraPhalguni: Gana.manushya,
  Nakshatra.purvaAshadha: Gana.manushya,
  Nakshatra.uttaraAshadha: Gana.manushya,
  Nakshatra.purvaBhadrapada: Gana.manushya,
  Nakshatra.uttaraBhadrapada: Gana.manushya,
  Nakshatra.krittika: Gana.rakshasa,
  Nakshatra.ashlesha: Gana.rakshasa,
  Nakshatra.magha: Gana.rakshasa,
  Nakshatra.chitra: Gana.rakshasa,
  Nakshatra.vishakha: Gana.rakshasa,
  Nakshatra.jyeshtha: Gana.rakshasa,
  Nakshatra.mula: Gana.rakshasa,
  Nakshatra.dhanishta: Gana.rakshasa,
  Nakshatra.shatabhisha: Gana.rakshasa,
};

Gana ganaOf(Nakshatra n) => _ganaOfNakshatra[n]!;

// Row = bride's Gana, column = groom's Gana. The only asymmetric pair
// is Deva/Manushya (Manushya-groom + Deva-bride scores 6, but
// Deva-groom + Manushya-bride scores only 5) — Deva/Rakshasa and
// Manushya/Rakshasa are each symmetric. Verified against multiple
// independent published tables agreeing on this exact 3x3 shape
// (corrected here from an earlier transcription that had the
// Deva/Rakshasa cell wrong — see guna_milan_test.dart).
const List<List<int>> _ganaMatrix = [
  [6, 6, 1], // Deva
  [5, 6, 0], // Manushya
  [1, 0, 6], // Rakshasa
];

double ganaKoota(Nakshatra brideNakshatra, Nakshatra groomNakshatra) =>
    _ganaMatrix[ganaOf(brideNakshatra).index][ganaOf(groomNakshatra).index]
        .toDouble();

// =============================================================================
// 7. Bhakoot / Rasi Koota (max 7) — mutual Moon-rasi distance.
// =============================================================================

/// Benefic distances (either direction is equivalent — see
/// guna_milan_test.dart): 1/3/4/7/10/11 score 7; 2/5/6/8/9/12 score 0
/// (the classical "2/12, 5/9, 6/8" zero configurations).
double bhakootKoota(ZodiacSign brideMoonSign, ZodiacSign groomMoonSign) {
  final dist = ((groomMoonSign.index - brideMoonSign.index + 12) % 12) + 1;
  return const {1, 3, 4, 7, 10, 11}.contains(dist) ? 7 : 0;
}

// =============================================================================
// 8. Nadi Koota (max 8) — physiological/offspring matching, by nakshatra.
// =============================================================================

enum Nadi { adi, madhya, antya }

const Map<Nakshatra, Nadi> _nadiOfNakshatra = {
  Nakshatra.ashwini: Nadi.adi,
  Nakshatra.ardra: Nadi.adi,
  Nakshatra.punarvasu: Nadi.adi,
  Nakshatra.uttaraPhalguni: Nadi.adi,
  Nakshatra.hasta: Nadi.adi,
  Nakshatra.jyeshtha: Nadi.adi,
  Nakshatra.mula: Nadi.adi,
  Nakshatra.shatabhisha: Nadi.adi,
  Nakshatra.purvaBhadrapada: Nadi.adi,
  Nakshatra.bharani: Nadi.madhya,
  Nakshatra.mrigashira: Nadi.madhya,
  Nakshatra.pushya: Nadi.madhya,
  Nakshatra.purvaPhalguni: Nadi.madhya,
  Nakshatra.chitra: Nadi.madhya,
  Nakshatra.anuradha: Nadi.madhya,
  Nakshatra.purvaAshadha: Nadi.madhya,
  Nakshatra.dhanishta: Nadi.madhya,
  Nakshatra.uttaraBhadrapada: Nadi.madhya,
  Nakshatra.krittika: Nadi.antya,
  Nakshatra.rohini: Nadi.antya,
  Nakshatra.ashlesha: Nadi.antya,
  Nakshatra.magha: Nadi.antya,
  Nakshatra.swati: Nadi.antya,
  Nakshatra.vishakha: Nadi.antya,
  Nakshatra.uttaraAshadha: Nadi.antya,
  Nakshatra.shravana: Nadi.antya,
  Nakshatra.revati: Nadi.antya,
};

Nadi nadiOf(Nakshatra n) => _nadiOfNakshatra[n]!;

double nadiKoota(Nakshatra brideNakshatra, Nakshatra groomNakshatra) =>
    nadiOf(brideNakshatra) == nadiOf(groomNakshatra) ? 0 : 8;

// =============================================================================
// Mangal Dosha (Kuja Dosha) — reuses the existing yoga engine's
// from-Lagna check (snapshot.yogas), adding the from-Moon half the
// engine doesn't compute.
// =============================================================================

int _houseFromMoon(AstroSnapshot s, Planet p) {
  final moonIdx = (s.positions[Planet.moon]!.longitude ~/ 30) % 12;
  final pIdx = (s.positions[p]!.longitude ~/ 30) % 12;
  return ((pIdx - moonIdx + 12) % 12) + 1;
}

/// Mars in 1/2/4/7/8/12 from EITHER the Lagna or the Moon. The
/// from-Lagna half reuses the yoga engine's own 'mangal_dosha' flag
/// (already computed into every [AstroSnapshot.yogas]); only the
/// from-Moon half is computed fresh here.
bool hasMangalDosha(AstroSnapshot s) {
  final fromLagna = s.yogas.any((y) => y.code == 'mangal_dosha');
  final fromMoon =
      const {1, 2, 4, 7, 8, 12}.contains(_houseFromMoon(s, Planet.mars));
  return fromLagna || fromMoon;
}

/// Whether Mars is mitigated (own/exalted sign) — mirrors the yoga
/// engine's own mitigation note (dignity.dart's [dignityOf]).
bool isMangalDoshaMitigated(AstroSnapshot s) {
  final d = dignityOf(s.positions[Planet.mars]!);
  return d == PlanetDignity.ownSign || d == PlanetDignity.exalted;
}

// =============================================================================
// Putting it together
// =============================================================================

/// The eight kootas of Ashtakoota Guna Milan, in their conventional
/// order. Identity, not display text — the presentation layer maps these
/// to localized names, so a rename here is a compile error rather than a
/// screen that silently reverts to English.
enum Koota { varna, vashya, tara, yoni, grahaMaitri, gana, bhakoot, nadi }

/// Match-quality bands: <18 not recommended · 18–24 average · 25–32 good
/// · 33–36 excellent. An enum because callers switch on it for more than
/// display (the score dial picks its colour from the band).
enum GunaVerdict { notRecommended, average, good, excellent }

class KootaScore {
  const KootaScore({
    required this.koota,
    required this.points,
    required this.maxPoints,
    this.note,
  });

  final Koota koota;
  final double points;
  final double maxPoints;
  final String? note;
}

class GunaMilanResult {
  const GunaMilanResult({
    required this.kootas,
    required this.brideMangalDosha,
    required this.groomMangalDosha,
  });

  final List<KootaScore> kootas;
  final bool brideMangalDosha;
  final bool groomMangalDosha;

  static const double maxTotal = 36;

  double get total => kootas.fold(0.0, (a, k) => a + k.points);

  /// <18 not recommended · 18–24 average · 25–32 good · 33–36 excellent.
  GunaVerdict get verdict => switch (total) {
        < 18 => GunaVerdict.notRecommended,
        < 25 => GunaVerdict.average,
        < 33 => GunaVerdict.good,
        _ => GunaVerdict.excellent,
      };

  bool get mangalDoshaMismatch => brideMangalDosha != groomMangalDosha;
}

GunaMilanResult computeGunaMilan(AstroSnapshot bride, AstroSnapshot groom) {
  final bMoon = bride.positions[Planet.moon]!;
  final gMoon = groom.positions[Planet.moon]!;
  final bNak = bMoon.nakshatra;
  final gNak = gMoon.nakshatra;
  final bSign = bMoon.sign;
  final gSign = gMoon.sign;

  final kootas = [
    KootaScore(
      koota: Koota.varna,
      points: varnaKoota(bSign, gSign),
      maxPoints: 1,
      note: '${varnaNameOf(bSign)} · ${varnaNameOf(gSign)}',
    ),
    KootaScore(
      koota: Koota.vashya,
      points:
          vashyaKoota(bSign, bMoon.degreesInSign, gSign, gMoon.degreesInSign),
      maxPoints: 2,
    ),
    KootaScore(
      koota: Koota.tara,
      points: taraKoota(bNak, gNak),
      maxPoints: 3,
    ),
    KootaScore(
      koota: Koota.yoni,
      points: yoniKoota(bNak, gNak),
      maxPoints: 4,
      note: '${yoniOf(bNak).label} · ${yoniOf(gNak).label}',
    ),
    KootaScore(
      koota: Koota.grahaMaitri,
      points: grahaMaitriKoota(bSign, gSign),
      maxPoints: 5,
    ),
    KootaScore(
      koota: Koota.gana,
      points: ganaKoota(bNak, gNak),
      maxPoints: 6,
    ),
    KootaScore(
      koota: Koota.bhakoot,
      points: bhakootKoota(bSign, gSign),
      maxPoints: 7,
    ),
    KootaScore(
      koota: Koota.nadi,
      points: nadiKoota(bNak, gNak),
      maxPoints: 8,
    ),
  ];

  return GunaMilanResult(
    kootas: kootas,
    brideMangalDosha: hasMangalDosha(bride),
    groomMangalDosha: hasMangalDosha(groom),
  );
}
