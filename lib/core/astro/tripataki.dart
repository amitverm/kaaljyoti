/// The Tri-Pataki Chakra — per Charak, "A Textbook of Varshaphala"
/// ch. VIII, golden-tested against both of the book's worked charts
/// (Figs. VIII-2 and VIII-3).
///
/// The varsha lagna sign sits at the central flag ('a'); the remaining
/// signs run ANTI-clockwise through the twelve points. NATAL planets
/// are progressed by the CURRENT year (completed years + 1):
///   • Moon: year mod 9 (0 → 9) houses from its natal sign;
///   • Sun, Mercury, Jupiter, Venus, Saturn: year mod 4 (0 → 4);
///   • Mars, Rahu, Ketu: year mod 6 (0 → 6) — the nodes counted in
///     REVERSE.
/// Vedha: three lines meet at every point; planets at the far ends of
/// those lines (and, practically, on the same point) pierce it. The
/// map below encodes exactly the book's figure — a↔{d,g,j},
/// b↔{c,f,i}, and the rest by the same geometry.
library;

import 'models.dart';

/// Vedha partners by point index (0 = 'a' = the lagna's point,
/// proceeding anti-clockwise b, c, … l).
const List<List<int>> tripatakiPartners = [
  [3, 6, 9], // a
  [2, 5, 8], // b
  [1, 7, 10], // c
  [0, 6, 9], // d
  [5, 8, 11], // e
  [1, 4, 10], // f
  [0, 3, 9], // g
  [2, 8, 11], // h
  [1, 4, 7], // i
  [0, 3, 6], // j
  [2, 5, 11], // k
  [4, 7, 10], // l
];

const _class4 = [
  Planet.sun,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
];

class TripatakiData {
  const TripatakiData({
    required this.lagna,
    required this.currentYear,
    required this.pointPlanets,
  });

  /// Varsha lagna sign, at point 'a'.
  final ZodiacSign lagna;
  final int currentYear;

  /// Progressed planets per point index (0-11).
  final List<List<Planet>> pointPlanets;

  ZodiacSign signOfPoint(int point) =>
      ZodiacSign.values[(lagna.index + point) % 12];

  int pointOfSign(ZodiacSign sign) => (sign.index - lagna.index + 12) % 12;

  /// Planets piercing [point]: occupants of its three line-ends plus
  /// (practically, per the book) co-occupants of the point itself.
  /// [except] excludes the queried planet from its own vedha list.
  List<Planet> vedhaToPoint(int point, {Planet? except}) => [
        for (final partner in tripatakiPartners[point])
          ...pointPlanets[partner],
        for (final p in pointPlanets[point])
          if (p != except) p,
      ];

  List<Planet> get vedhaToLagna => vedhaToPoint(0);

  List<Planet> get vedhaToMoon {
    final moonPoint = pointPlanets.indexWhere((ps) => ps.contains(Planet.moon));
    if (moonPoint < 0) return const [];
    return vedhaToPoint(moonPoint, except: Planet.moon);
  }
}

/// Progressed sign for [planet] in the [currentYear] (completed + 1).
ZodiacSign tripatakiProgressedSign(
    Planet planet, ZodiacSign natalSign, int currentYear) {
  if (planet == Planet.moon) {
    var r = currentYear % 9;
    if (r == 0) r = 9;
    return ZodiacSign.values[(natalSign.index + r - 1) % 12];
  }
  if (_class4.contains(planet)) {
    var r = currentYear % 4;
    if (r == 0) r = 4;
    return ZodiacSign.values[(natalSign.index + r - 1) % 12];
  }
  // Mars forward; Rahu/Ketu reverse.
  var r = currentYear % 6;
  if (r == 0) r = 6;
  final step = planet == Planet.mars ? (r - 1) : -(r - 1);
  return ZodiacSign.values[(natalSign.index + step + 24) % 12];
}

TripatakiData tripataki({
  required ZodiacSign varshaLagna,
  required Map<Planet, ZodiacSign> natalSigns,
  required int currentYear,
}) {
  final points = [for (var i = 0; i < 12; i++) <Planet>[]];
  natalSigns.forEach((planet, natal) {
    final sign = tripatakiProgressedSign(planet, natal, currentYear);
    points[(sign.index - varshaLagna.index + 12) % 12].add(planet);
  });
  return TripatakiData(
      lagna: varshaLagna, currentYear: currentYear, pointPlanets: points);
}
