/// Core astrological domain models. Pure Dart — no Flutter imports —
/// so the calculation layer stays testable and portable.
library;

enum Planet {
  sun('Sun', 'Su'),
  moon('Moon', 'Mo'),
  mars('Mars', 'Ma'),
  mercury('Mercury', 'Me'),
  jupiter('Jupiter', 'Ju'),
  venus('Venus', 'Ve'),
  saturn('Saturn', 'Sa'),
  rahu('Rahu', 'Ra'),
  ketu('Ketu', 'Ke');

  const Planet(this.displayName, this.abbr);
  final String displayName;
  final String abbr;
}

enum ZodiacSign {
  aries('Aries', 'Mesha'),
  taurus('Taurus', 'Vrishabha'),
  gemini('Gemini', 'Mithuna'),
  cancer('Cancer', 'Karka'),
  leo('Leo', 'Simha'),
  virgo('Virgo', 'Kanya'),
  libra('Libra', 'Tula'),
  scorpio('Scorpio', 'Vrischika'),
  sagittarius('Sagittarius', 'Dhanu'),
  capricorn('Capricorn', 'Makara'),
  aquarius('Aquarius', 'Kumbha'),
  pisces('Pisces', 'Meena');

  const ZodiacSign(this.western, this.sanskrit);
  final String western;
  final String sanskrit;

  /// 0-based index (Aries = 0).
  int get index0 => index;

  static ZodiacSign fromLongitude(double siderealLongitude) =>
      ZodiacSign.values[(siderealLongitude ~/ 30) % 12];

  /// Traditional sign lord (Vedic — Rahu/Ketu not lords here).
  Planet get lord => switch (this) {
        aries || scorpio => Planet.mars,
        taurus || libra => Planet.venus,
        gemini || virgo => Planet.mercury,
        cancer => Planet.moon,
        leo => Planet.sun,
        sagittarius || pisces => Planet.jupiter,
        capricorn || aquarius => Planet.saturn,
      };

  bool get isOdd => index % 2 == 0; // Aries(0) is odd sign #1
  bool get isMovable => index % 3 == 0; // chara: Aries, Cancer, Libra, Cap
  bool get isFixed => index % 3 == 1;
  bool get isDual => index % 3 == 2;
}

/// A cardinal direction. Identity, not display text — the presentation
/// layer names it per locale (see Disha Shool on the Today screen).
enum Direction {
  east,
  north,
  south,
  west;

  /// English name, for the same reasons the other core enums keep one:
  /// stable identifier, tests, and the not-yet-localized OS widget.
  /// In-app UI must use the l10n extension instead.
  String get displayName => switch (this) {
        east => 'East',
        north => 'North',
        south => 'South',
        west => 'West',
      };
}

/// The 27 nakshatras. `index` is 0-based (Ashwini = 0).
enum Nakshatra {
  ashwini('Ashwini'),
  bharani('Bharani'),
  krittika('Krittika'),
  rohini('Rohini'),
  mrigashira('Mrigashira'),
  ardra('Ardra'),
  punarvasu('Punarvasu'),
  pushya('Pushya'),
  ashlesha('Ashlesha'),
  magha('Magha'),
  purvaPhalguni('Purva Phalguni'),
  uttaraPhalguni('Uttara Phalguni'),
  hasta('Hasta'),
  chitra('Chitra'),
  swati('Swati'),
  vishakha('Vishakha'),
  anuradha('Anuradha'),
  jyeshtha('Jyeshtha'),
  mula('Mula'),
  purvaAshadha('Purva Ashadha'),
  uttaraAshadha('Uttara Ashadha'),
  shravana('Shravana'),
  dhanishta('Dhanishta'),
  shatabhisha('Shatabhisha'),
  purvaBhadrapada('Purva Bhadrapada'),
  uttaraBhadrapada('Uttara Bhadrapada'),
  revati('Revati');

  const Nakshatra(this.displayName);
  final String displayName;

  /// Three-letter abbreviation for chart labels (27-scheme; matches
  /// [Nakshatra28.abbrs] minus Abhijit).
  String get abbr => const [
        'Ash', 'Bha', 'Kri', 'Roh', 'Mri', 'Ard', 'Pun', 'Pus', 'Asl', //
        'Mag', 'PPh', 'UPh', 'Has', 'Chi', 'Swa', 'Vis', 'Anu', 'Jye', //
        'Mul', 'PSh', 'USh', 'Shr', 'Dha', 'Sat', 'PBh', 'UBh', 'Rev',
      ][index];

  /// Vimshottari star lord (Ketu Venus Sun Moon Mars Rahu Jupiter
  /// Saturn Mercury, repeating from Ashwini). Also the KP star lord.
  Planet get lord => const [
        Planet.ketu, Planet.venus, Planet.sun, //
        Planet.moon, Planet.mars, Planet.rahu, //
        Planet.jupiter, Planet.saturn, Planet.mercury,
      ][index % 9];

  /// Each nakshatra spans 13°20' = 13.333…°
  static const double span = 360 / 27;

  static Nakshatra fromLongitude(double siderealLongitude) =>
      Nakshatra.values[(siderealLongitude / span).floor() % 27];

  /// Pada (quarter) 1–4 within the nakshatra.
  static int padaFromLongitude(double siderealLongitude) {
    final within = siderealLongitude % span;
    return (within / (span / 4)).floor() + 1;
  }
}

/// A single body's computed position.
class PlanetPosition {
  const PlanetPosition({
    required this.planet,
    required this.longitude, // sidereal, 0–360
    required this.latitude,
    required this.speed, // deg/day; negative = retrograde
  });

  final Planet planet;
  final double longitude;
  final double latitude;
  final double speed;

  bool get isRetrograde => speed < 0;
  ZodiacSign get sign => ZodiacSign.fromLongitude(longitude);
  double get degreesInSign => longitude % 30;
  Nakshatra get nakshatra => Nakshatra.fromLongitude(longitude);
  int get pada => Nakshatra.padaFromLongitude(longitude);
}

/// Birth (or Prashna) input data.
class BirthData {
  const BirthData({
    required this.dateTimeUtc,
    required this.latitude,
    required this.longitude,
    required this.timezoneName,
    required this.utcOffsetMinutes,
    this.placeName = '',
  });

  final DateTime dateTimeUtc;
  final double latitude;
  final double longitude;
  final String timezoneName; // IANA, e.g. Asia/Kolkata
  final int utcOffsetMinutes; // offset at the birth instant
  final String placeName;

  DateTime get localDateTime =>
      dateTimeUtc.add(Duration(minutes: utcOffsetMinutes));
}

/// Panchang elements at a given instant.
class PanchangData {
  const PanchangData({
    required this.tithiIndex, // 0–29
    required this.tithiName,
    required this.paksha, // Shukla / Krishna
    required this.nakshatra,
    required this.pada,
    required this.yogaIndex, // 0–26
    required this.yogaName,
    required this.karanaIndex, // 0–59 within the lunation
    required this.karanaName,
    required this.varaIndex, // 0 = Somavara … 6 = Ravivara
    required this.vara, // weekday name
  });

  final int tithiIndex;
  final String tithiName;
  final String paksha;
  final Nakshatra nakshatra;
  final int pada;
  final int yogaIndex;
  final String yogaName;
  final int karanaIndex;
  final String karanaName;
  final int varaIndex;
  final String vara;
}

/// A detected yoga/dosha for the searchable index.
///
/// [category] and [participants] were added with the rule-engine
/// rebuild — both additive: [code] semantics are frozen (Mahakosh
/// index compatibility) and old call sites compile unchanged.
class DetectedYoga {
  const DetectedYoga({
    required this.code,
    required this.name,
    this.detail,
    this.category = 'Other',
    this.participants = const [],
  });

  final String code; // stable machine code, e.g. 'gaja_kesari'
  final String name;
  final String? detail;

  /// Display grouping: 'Raj', 'Dhana', 'Vipreet Raj', 'Parivartana',
  /// 'Mahapurusha', 'Chandra', 'Dosha', 'Other'.
  final String category;

  /// The grahas forming the yoga — the Yogas widget intersects these
  /// with the running dasha lords to flag "active" yogas.
  final List<Planet> participants;
}

/// The shared per-chart astrological snapshot: computed ONCE per chart
/// via Swiss Ephemeris, consumed by every widget, dasha system, the PDF
/// exporter, and the Mahakosh index builder.
class AstroSnapshot {
  const AstroSnapshot({
    required this.birth,
    required this.ayanamsaId,
    required this.ayanamsaValue,
    required this.positions,
    required this.ascendant, // sidereal longitude of lagna
    required this.houseCusps, // 12 sidereal cusp longitudes (whole-sign fills equal cusps)
    required this.panchang,
    required this.yogas,
  });

  final BirthData birth;
  final int ayanamsaId; // sweph sidereal mode id
  final double ayanamsaValue;
  final Map<Planet, PlanetPosition> positions;
  final double ascendant;
  final List<double> houseCusps;
  final PanchangData panchang;
  final List<DetectedYoga> yogas;

  ZodiacSign get lagnaSign => ZodiacSign.fromLongitude(ascendant);
  ZodiacSign get moonSign => positions[Planet.moon]!.sign;
  Nakshatra get moonNakshatra => positions[Planet.moon]!.nakshatra;

  /// Whole-sign house (1–12) a sidereal longitude falls in, counted
  /// from the lagna sign (Vedic default).
  int houseOf(double longitude) {
    final signIdx = (longitude ~/ 30) % 12;
    return ((signIdx - lagnaSign.index + 12) % 12) + 1;
  }

  int houseOfPlanet(Planet p) => houseOf(positions[p]!.longitude);
}

String formatDegree(double longitude) {
  final inSign = longitude % 30;
  final deg = inSign.floor();
  final minTotal = (inSign - deg) * 60;
  final min = minTotal.floor();
  final sec = ((minTotal - min) * 60).round();
  return "$deg°${min.toString().padLeft(2, '0')}'"
      '${sec.toString().padLeft(2, '0')}"';
}

/// Compact degree+minutes (no seconds) for a 0–30 degree-in-sign value —
/// used for on-chart annotations (planet tokens, Ascendant marker) where
/// [formatDegree]'s extra seconds would be more precision than the
/// space allows. Accepts any longitude-like value and reduces it mod 30
/// itself, so callers can pass either a degree-in-sign or a full
/// sidereal longitude.
String formatDegreeInSign(double degreeInSign) {
  final inSign = degreeInSign % 30;
  var deg = inSign.floor();
  var min = ((inSign - deg) * 60).round();
  if (min == 60) {
    min = 0;
    deg += 1;
  }
  return "$deg°${min.toString().padLeft(2, '0')}'";
}
