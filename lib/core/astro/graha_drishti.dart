/// Parashari graha drishti — the planet-based aspects, as distinct from
/// the sign-based Jaimini rashi drishti in jaimini_aspect.dart.
///
/// Every graha aspects the 7th house from itself. Mars additionally
/// aspects the 4th and 8th, Jupiter the 5th and 9th, Saturn the 3rd and
/// 10th. Counting is whole-sign and inclusive: a graha's own sign is
/// house 1, so the "7th aspect" lands on the sign opposite it.
///
/// Rahu and Ketu cast NOTHING by default. Classical practice does not
/// reckon nodal drishti, so it is off unless a caller opts in — some
/// later schools grant the nodes 5/7/9, which [includeNodes] enables.
///
/// Pure Dart, no Flutter.
library;

import 'models.dart';

/// Extra aspects beyond the universal 7th, by casting graha.
const Map<Planet, List<int>> parashariSpecialAspects = {
  Planet.mars: [4, 8],
  Planet.jupiter: [5, 9],
  Planet.saturn: [3, 10],
};

/// The nodes. They receive aspects like any other body; whether they
/// cast is the [includeNodes] question.
const Set<Planet> lunarNodes = {Planet.rahu, Planet.ketu};

/// Aspects the nodes cast when a caller opts in — the same 5/7/9 as
/// Jupiter, which is the usual formulation where nodal drishti is
/// admitted at all.
const List<int> nodeAspectHouses = [5, 7, 9];

/// Whether [p] casts drishti at all.
bool castsDrishti(Planet p, {bool includeNodes = false}) =>
    !lunarNodes.contains(p) || includeNodes;

/// The house numbers (1–12, inclusive count from its own sign) that [p]
/// aspects. Empty when [p] casts nothing.
List<int> drishtiHousesOf(Planet p, {bool includeNodes = false}) {
  if (lunarNodes.contains(p)) {
    return includeNodes ? nodeAspectHouses : const [];
  }
  return [7, ...?parashariSpecialAspects[p]]..sort();
}

/// Inclusive whole-sign count from [fromSignIdx] to [toSignIdx] — the
/// graha's own sign is 1, the sign opposite is 7.
int drishtiDistance(int fromSignIdx, int toSignIdx) =>
    ((toSignIdx - fromSignIdx + 12) % 12) + 1;

/// One aspect cast by [from] onto a sign, and onto a planet when the
/// table was asked for planet targets.
class Drishti {
  const Drishti({
    required this.from,
    required this.toSignIdx,
    required this.distance,
    this.to,
  });

  /// The aspecting graha.
  final Planet from;

  /// The aspected graha, when this is a planet-to-planet aspect.
  final Planet? to;

  /// The aspected sign.
  final int toSignIdx;

  /// Which of the caster's aspects this is — 7 for the universal one,
  /// 4/8, 5/9 or 3/10 for the special ones.
  final int distance;

  ZodiacSign get toSign => ZodiacSign.values[toSignIdx];

  @override
  String toString() => '${from.name}->${to?.name ?? toSign.name} ($distance)';
}

/// Every Parashari aspect in a chart, queryable by direction.
///
/// A graha never aspects itself: the 7th from a sign is never that same
/// sign, but two grahas SHARING a sign would otherwise register as a
/// 1st-house "aspect" — conjunction is not drishti, so distance 1 is
/// excluded throughout.
class GrahaDrishtiTable {
  GrahaDrishtiTable({
    required this.positions,
    required double ascendant,
    this.includeNodes = false,
  }) : lagnaIdx = (ascendant ~/ 30) % 12 {
    for (final from in positions.keys) {
      final houses = drishtiHousesOf(from, includeNodes: includeNodes);
      if (houses.isEmpty) continue;
      final fromIdx = positions[from]!.sign.index;
      for (final h in houses) {
        final toIdx = (fromIdx + h - 1) % 12;
        _bySign.putIfAbsent(toIdx, () => []).add(Drishti(
              from: from,
              toSignIdx: toIdx,
              distance: h,
            ));
        for (final entry in positions.entries) {
          if (entry.key == from) continue;
          if (entry.value.sign.index != toIdx) continue;
          final d = Drishti(
            from: from,
            to: entry.key,
            toSignIdx: toIdx,
            distance: h,
          );
          _cast.putIfAbsent(from, () => []).add(d);
          _received.putIfAbsent(entry.key, () => []).add(d);
        }
      }
    }
  }

  final Map<Planet, PlanetPosition> positions;
  final int lagnaIdx;
  final bool includeNodes;

  final Map<Planet, List<Drishti>> _cast = {};
  final Map<Planet, List<Drishti>> _received = {};
  final Map<int, List<Drishti>> _bySign = {};

  /// Aspects falling ON [p] — "which grahas are looking at this one".
  List<Drishti> receivedBy(Planet p) => _received[p] ?? const [];

  /// Aspects [p] throws.
  List<Drishti> castBy(Planet p) => _cast[p] ?? const [];

  /// Aspects on a whole-sign house (1–12) counted from the lagna,
  /// whether or not anything occupies it — an aspect on an empty 7th is
  /// still a reading, which a planets-only view would silently drop.
  List<Drishti> onHouse(int house) =>
      _bySign[(lagnaIdx + house - 1) % 12] ?? const [];

  /// Whole-sign house (1–12) of a graha, from the lagna.
  int houseOf(Planet p) =>
      ((positions[p]!.sign.index - lagnaIdx + 12) % 12) + 1;

  /// True when [a] aspects [b].
  bool aspects(Planet a, Planet b) =>
      castBy(a).any((d) => d.to == b);

  bool mutual(Planet a, Planet b) => aspects(a, b) && aspects(b, a);
}
