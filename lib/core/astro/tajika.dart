/// Tajika aspect & friendship rules (Charak, "A Textbook of
/// Varshaphala"): in the annual chart, a planet's relation to another
/// follows purely from the SIGN distance between them —
///
///   5, 9   → friendly aspect, open      (pratyaksha mitra)
///   3, 11  → friendly aspect, secret    (gupta mitra)
///   1, 7   → inimical aspect, open      (pratyaksha shatru)
///   4, 10  → inimical aspect, secret    (gupta shatru)
///   2, 6, 8, 12 → no aspect / neutral
///
/// The pairs (3,11), (5,9), (4,10) and 1/7 are mutual by construction —
/// if A is 5th from B, B is 9th from A — so positional friendship is
/// symmetric, unlike the natal naisargika table.
///
/// "Mutual enemies" here = pairs inimical BOTH by Tajika position AND
/// by the natural (naisargika) table in both directions — the pairs
/// whose enmity no layer softens. Definition to be verified against the
/// book's own usage; it is isolated in [areMutualEnemies] for easy
/// adjustment.
library;

import 'maitri.dart' show PlanetaryRel, naturalRelOf;
import 'models.dart';

/// The seven classical grahas Tajika maitri covers (nodes excluded).
const List<Planet> kTajikaPlanets = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
];

enum TajikaRelation {
  directFriend,
  hiddenFriend,
  directEnemy,
  hiddenEnemy,
  none;

  bool get isFriend => this == directFriend || this == hiddenFriend;
  bool get isEnemy => this == directEnemy || this == hiddenEnemy;

  /// Whether a Tajika aspect exists at all (friendly or inimical).
  bool get aspects => this != none;
}

/// 1-based sign distance counted from [from] to [to] inclusive.
int tajikaSignDistance(ZodiacSign from, ZodiacSign to) =>
    ((to.index - from.index + 12) % 12) + 1;

TajikaRelation tajikaRelationForDistance(int distance) => switch (distance) {
      5 || 9 => TajikaRelation.directFriend,
      3 || 11 => TajikaRelation.hiddenFriend,
      1 || 7 => TajikaRelation.directEnemy,
      4 || 10 => TajikaRelation.hiddenEnemy,
      _ => TajikaRelation.none,
    };

/// Positional relation between two planets in the varsha chart.
TajikaRelation tajikaRelationBetween(
        AstroSnapshot varsha, Planet a, Planet b) =>
    tajikaRelationForDistance(tajikaSignDistance(
        varsha.positions[a]!.sign, varsha.positions[b]!.sign));

/// Enemies by Tajika position AND natural enemies in both directions.
bool areMutualEnemies(AstroSnapshot varsha, Planet a, Planet b) =>
    tajikaRelationBetween(varsha, a, b).isEnemy &&
    naturalRelOf(a, b) == PlanetaryRel.enemy &&
    naturalRelOf(b, a) == PlanetaryRel.enemy;
