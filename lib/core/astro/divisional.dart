/// Divisional (varga) chart mappings — full Parashara D1–D60 set.
/// Each mapping takes a sidereal longitude and returns the varga sign;
/// adding a varga is one case in [vargaSign].
library;

import 'models.dart';

enum Varga {
  d1(1, 'Rashi', 'D1', 'birth chart'),
  d2(2, 'Hora', 'D2', 'wealth'),
  d3(3, 'Drekkana', 'D3', 'siblings & courage'),
  d4(4, 'Chaturthamsa', 'D4', 'property & fortune'),
  d7(7, 'Saptamsa', 'D7', 'children'),
  d9(9, 'Navamsa', 'D9', 'marriage & dharma'),
  d10(10, 'Dashamsa', 'D10', 'career'),
  d12(12, 'Dwadashamsa', 'D12', 'parents'),
  d16(16, 'Shodashamsa', 'D16', 'vehicles & comforts'),
  d20(20, 'Vimshamsa', 'D20', 'spiritual life'),
  d24(24, 'Chaturvimshamsa', 'D24', 'education'),
  d27(27, 'Bhamsa', 'D27', 'strengths & weaknesses'),
  d30(30, 'Trimshamsa', 'D30', 'misfortunes'),
  d40(40, 'Khavedamsa', 'D40', 'maternal legacy'),
  d45(45, 'Akshavedamsa', 'D45', 'paternal legacy'),
  d60(60, 'Shashtiamsa', 'D60', 'past karma');

  const Varga(this.divisions, this.sanskritName, this.code, this.theme);
  final int divisions;
  final String sanskritName;
  final String code; // 'D9'
  final String theme;

  String get displayName => '$sanskritName · $code';

  static Varga byName(String name) =>
      Varga.values.firstWhere((v) => v.name == name, orElse: () => Varga.d9);
}

/// Part index (0-based) of the longitude within its sign for an
/// n-fold division.
int _part(double longitude, int n) =>
    (((longitude % 30) / (30 / n)).floor()).clamp(0, n - 1);

ZodiacSign _sign(int index0) => ZodiacSign.values[((index0 % 12) + 12) % 12];

/// Navamsa (D9): movable signs count from themselves, fixed from the
/// 9th, dual from the 5th.
ZodiacSign navamsaSign(double longitude) {
  final sign = ZodiacSign.fromLongitude(longitude);
  final p = _part(longitude, 9);
  final start = sign.isMovable
      ? sign.index
      : sign.isFixed
          ? sign.index + 8
          : sign.index + 4;
  return _sign(start + p);
}

ZodiacSign vargaSign(Varga varga, double longitude) {
  final sign = ZodiacSign.fromLongitude(longitude);
  final deg = longitude % 30;

  switch (varga) {
    case Varga.d1:
      return sign;

    // Hora (D2): odd signs — first half Sun's hora (Leo), second half
    // Moon's (Cancer); even signs reversed.
    case Varga.d2:
      final firstHalf = deg < 15;
      if (sign.isOdd) {
        return firstHalf ? ZodiacSign.leo : ZodiacSign.cancer;
      }
      return firstHalf ? ZodiacSign.cancer : ZodiacSign.leo;

    // Drekkana (D3): parts fall in the sign itself, the 5th, the 9th.
    case Varga.d3:
      return _sign(sign.index + _part(longitude, 3) * 4);

    // Chaturthamsa (D4): sign, 4th, 7th, 10th.
    case Varga.d4:
      return _sign(sign.index + _part(longitude, 4) * 3);

    // Saptamsa (D7): odd signs count from the sign itself, even signs
    // from the 7th; 7 sequential parts.
    case Varga.d7:
      final start = sign.isOdd ? sign.index : sign.index + 6;
      return _sign(start + _part(longitude, 7));

    case Varga.d9:
      return navamsaSign(longitude);

    // Dashamsa (D10): odd from the sign itself, even from the 9th.
    case Varga.d10:
      final start = sign.isOdd ? sign.index : sign.index + 8;
      return _sign(start + _part(longitude, 10));

    // Dwadashamsa (D12): 12 sequential parts from the sign itself.
    case Varga.d12:
      return _sign(sign.index + _part(longitude, 12));

    // Shodashamsa (D16): movable from Aries, fixed from Leo, dual
    // from Sagittarius.
    case Varga.d16:
      final start = sign.isMovable ? 0 : (sign.isFixed ? 4 : 8);
      return _sign(start + _part(longitude, 16));

    // Vimshamsa (D20): movable from Aries, fixed from Sagittarius,
    // dual from Leo.
    case Varga.d20:
      final start = sign.isMovable ? 0 : (sign.isFixed ? 8 : 4);
      return _sign(start + _part(longitude, 20));

    // Chaturvimshamsa (D24): odd from Leo, even from Cancer.
    case Varga.d24:
      final start = sign.isOdd ? 4 : 3;
      return _sign(start + _part(longitude, 24));

    // Bhamsa / Nakshatramsa (D27): fiery from Aries, earthy from
    // Cancer, airy from Libra, watery from Capricorn.
    case Varga.d27:
      final start = (sign.index % 4) * 3;
      return _sign(start + _part(longitude, 27));

    // Trimshamsa (D30): unequal degree bands ruled by the five
    // tara-grahas; odd and even signs use different bands.
    case Varga.d30:
      if (sign.isOdd) {
        if (deg < 5) return ZodiacSign.aries; // Mars
        if (deg < 10) return ZodiacSign.aquarius; // Saturn
        if (deg < 18) return ZodiacSign.sagittarius; // Jupiter
        if (deg < 25) return ZodiacSign.gemini; // Mercury
        return ZodiacSign.libra; // Venus
      }
      if (deg < 5) return ZodiacSign.taurus; // Venus
      if (deg < 12) return ZodiacSign.virgo; // Mercury
      if (deg < 20) return ZodiacSign.pisces; // Jupiter
      if (deg < 25) return ZodiacSign.capricorn; // Saturn
      return ZodiacSign.scorpio; // Mars

    // Khavedamsa (D40): odd from Aries, even from Libra.
    case Varga.d40:
      final start = sign.isOdd ? 0 : 6;
      return _sign(start + _part(longitude, 40));

    // Akshavedamsa (D45): movable from Aries, fixed from Leo, dual
    // from Sagittarius.
    case Varga.d45:
      final start = sign.isMovable ? 0 : (sign.isFixed ? 4 : 8);
      return _sign(start + _part(longitude, 45));

    // Shashtiamsa (D60): 60 sequential parts counted from the sign
    // itself.
    case Varga.d60:
      return _sign(sign.index + _part(longitude, 60));
  }
}

/// Planets-by-sign map for rendering a varga chart.
Map<ZodiacSign, List<Planet>> vargaPlacements(
  AstroSnapshot snapshot,
  Varga varga,
) {
  final map = {for (final s in ZodiacSign.values) s: <Planet>[]};
  for (final pos in snapshot.positions.values) {
    map[vargaSign(varga, pos.longitude)]!.add(pos.planet);
  }
  // D1 boxes read in zodiacal progression (ascending natal degree — the
  // charts drawn from this map show natal degrees). Higher vargas keep
  // the traditional planet listing order: their boxes carry no real
  // internal progression, so a degree sort would imply one that the
  // displayed (natal) degrees contradict.
  if (varga == Varga.d1) {
    sortPlacementsByLongitude(map, snapshot.positions);
  }
  return map;
}

/// Lagna sign in the given varga.
ZodiacSign vargaLagna(AstroSnapshot snapshot, Varga varga) =>
    vargaSign(varga, snapshot.ascendant);
