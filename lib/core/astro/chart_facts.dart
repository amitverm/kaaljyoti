/// Shared structural facts the yoga rule engine reads — computed once
/// per chart so individual rules stay declarative: whole-sign houses
/// from the lagna, house lords, graha drishti (with the special Mars /
/// Jupiter / Saturn aspects), conjunctions and sign exchanges.
///
/// Pure Dart, no Flutter.
library;

import 'models.dart';

class ChartFacts {
  ChartFacts({required this.positions, required double ascendant})
      : lagnaIdx = (ascendant ~/ 30) % 12;

  final Map<Planet, PlanetPosition> positions;
  final int lagnaIdx;

  static const kendras = {1, 4, 7, 10};
  static const trikonas = {1, 5, 9};
  static const dusthanas = {6, 8, 12};

  /// Whole-sign house (1–12) of a sign index, counted from the lagna.
  int houseOfSignIdx(int signIdx) => ((signIdx - lagnaIdx + 12) % 12) + 1;

  int houseOf(Planet p) => houseOfSignIdx(positions[p]!.sign.index);

  ZodiacSign signOfHouse(int house) =>
      ZodiacSign.values[(lagnaIdx + house - 1) % 12];

  Planet lordOf(int house) => signOfHouse(house).lord;

  bool conjunct(Planet a, Planet b) =>
      a != b && positions[a]!.sign == positions[b]!.sign;

  /// Graha drishti (whole-sign): every graha aspects the 7th from
  /// itself; Mars adds 4/8, Jupiter 5/9, Saturn 3/10.
  static const Map<Planet, List<int>> _special = {
    Planet.mars: [4, 8],
    Planet.jupiter: [5, 9],
    Planet.saturn: [3, 10],
  };

  bool aspects(Planet a, Planet b) {
    if (a == b) return false;
    final from = positions[a]!.sign.index;
    final to = positions[b]!.sign.index;
    final count = ((to - from + 12) % 12) + 1;
    if (count == 7) return true;
    return (_special[a] ?? const []).contains(count);
  }

  bool mutualAspect(Planet a, Planet b) => aspects(a, b) && aspects(b, a);

  /// Parivartana: each sits in a sign the other lords.
  bool exchange(Planet a, Planet b) =>
      a != b && positions[a]!.sign.lord == b && positions[b]!.sign.lord == a;

  /// How two grahas are linked for yoga formation, strongest first —
  /// or null if unlinked. Exchange outranks conjunction outranks
  /// mutual aspect in the classical ordering of sambandha.
  String? connection(Planet a, Planet b) {
    if (a == b) return null;
    if (exchange(a, b)) return 'exchange';
    if (conjunct(a, b)) return 'conjunction';
    if (mutualAspect(a, b)) return 'mutual aspect';
    return null;
  }

  /// House (1–12) of [p] counted from an arbitrary anchor sign.
  int houseFrom(int anchorSignIdx, Planet p) =>
      ((positions[p]!.sign.index - anchorSignIdx + 12) % 12) + 1;

  /// True when [p] occupies a kendra counted from [anchorSignIdx].
  bool inKendraFrom(int anchorSignIdx, Planet p) =>
      kendras.contains(houseFrom(anchorSignIdx, p));

  // --- Conditional benefic/malefic status --------------------------------

  /// Waxing = Moon ahead of the Sun by less than 180° (Shukla side).
  bool get moonWaxing =>
      ((positions[Planet.moon]!.longitude -
              positions[Planet.sun]!.longitude +
              360) %
          360) <
      180;

  /// Mercury turns malefic in classical usage when it shares a sign
  /// with a natural malefic.
  bool get mercuryAfflicted => const [
        Planet.saturn,
        Planet.mars,
        Planet.rahu,
        Planet.ketu,
      ].any((m) => positions[Planet.mercury]!.sign == positions[m]!.sign);

  /// Benefics under the conditional rules: Jupiter, Venus, an
  /// unafflicted Mercury and a waxing Moon.
  List<Planet> get yogaBenefics => [
        Planet.jupiter,
        Planet.venus,
        if (!mercuryAfflicted) Planet.mercury,
        if (moonWaxing) Planet.moon,
      ];

  bool isYogaMalefic(Planet p) => switch (p) {
        Planet.sun ||
        Planet.mars ||
        Planet.saturn ||
        Planet.rahu ||
        Planet.ketu =>
          true,
        Planet.mercury => mercuryAfflicted,
        Planet.moon => !moonWaxing,
        _ => false,
      };
}
