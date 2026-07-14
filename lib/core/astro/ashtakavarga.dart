/// Ashtakavarga (BPHS, Parashari system).
///
/// Each of the seven grahas (Sun–Saturn) has a Bhinnashtakavarga
/// (BAV): eight contributors — the seven grahas plus the Lagna — each
/// donate benefic points (bindus) to specific houses COUNTED FROM THE
/// CONTRIBUTOR'S OWN SIGN (inclusive). A sign's BAV score is how many
/// contributors marked it benefic (0–8). The Sarvashtakavarga (SAV)
/// sums the seven BAVs per sign; across all twelve signs the classical
/// totals are fixed: Sun 48, Moon 49, Mars 39, Mercury 54, Jupiter 56,
/// Venus 52, Saturn 39 — SAV grand total 337.
library;

import 'models.dart';

/// The seven grahas that own a BAV (Rahu/Ketu have none in the
/// Parashari scheme).
const List<Planet> ashtakavargaPlanets = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
];

/// Benefic houses (1–12, counted inclusively from the contributor's
/// sign) donated to each target graha's BAV. Key `null` = the Lagna's
/// contribution.
const Map<Planet, Map<Planet?, List<int>>> _binduTables = {
  Planet.sun: {
    Planet.sun: [1, 2, 4, 7, 8, 9, 10, 11],
    Planet.moon: [3, 6, 10, 11],
    Planet.mars: [1, 2, 4, 7, 8, 9, 10, 11],
    Planet.mercury: [3, 5, 6, 9, 10, 11, 12],
    Planet.jupiter: [5, 6, 9, 11],
    Planet.venus: [6, 7, 12],
    Planet.saturn: [1, 2, 4, 7, 8, 9, 10, 11],
    null: [3, 4, 6, 10, 11, 12],
  },
  Planet.moon: {
    Planet.sun: [3, 6, 7, 8, 10, 11],
    Planet.moon: [1, 3, 6, 7, 10, 11],
    Planet.mars: [2, 3, 5, 6, 9, 10, 11],
    Planet.mercury: [1, 3, 4, 5, 7, 8, 10, 11],
    Planet.jupiter: [1, 4, 7, 8, 10, 11, 12],
    Planet.venus: [3, 4, 5, 7, 9, 10, 11],
    Planet.saturn: [3, 5, 6, 11],
    null: [3, 6, 10, 11],
  },
  Planet.mars: {
    Planet.sun: [3, 5, 6, 10, 11],
    Planet.moon: [3, 6, 11],
    Planet.mars: [1, 2, 4, 7, 8, 10, 11],
    Planet.mercury: [3, 5, 6, 11],
    Planet.jupiter: [6, 10, 11, 12],
    Planet.venus: [6, 8, 11, 12],
    Planet.saturn: [1, 4, 7, 8, 9, 10, 11],
    null: [1, 3, 6, 10, 11],
  },
  Planet.mercury: {
    Planet.sun: [5, 6, 9, 11, 12],
    Planet.moon: [2, 4, 6, 8, 10, 11],
    Planet.mars: [1, 2, 4, 7, 8, 9, 10, 11],
    Planet.mercury: [1, 3, 5, 6, 9, 10, 11, 12],
    Planet.jupiter: [6, 8, 11, 12],
    Planet.venus: [1, 2, 3, 4, 5, 8, 9, 11],
    Planet.saturn: [1, 2, 4, 7, 8, 9, 10, 11],
    null: [1, 2, 4, 6, 8, 10, 11],
  },
  Planet.jupiter: {
    Planet.sun: [1, 2, 3, 4, 7, 8, 9, 10, 11],
    Planet.moon: [2, 5, 7, 9, 11],
    Planet.mars: [1, 2, 4, 7, 8, 10, 11],
    Planet.mercury: [1, 2, 4, 5, 6, 9, 10, 11],
    Planet.jupiter: [1, 2, 3, 4, 7, 8, 10, 11],
    Planet.venus: [2, 5, 6, 9, 10, 11],
    Planet.saturn: [3, 5, 6, 12],
    null: [1, 2, 4, 5, 6, 7, 9, 10, 11],
  },
  Planet.venus: {
    Planet.sun: [8, 11, 12],
    Planet.moon: [1, 2, 3, 4, 5, 8, 9, 11, 12],
    Planet.mars: [3, 5, 6, 9, 11, 12],
    Planet.mercury: [3, 5, 6, 9, 11],
    Planet.jupiter: [5, 8, 9, 10, 11],
    Planet.venus: [1, 2, 3, 4, 5, 8, 9, 10, 11],
    Planet.saturn: [3, 4, 5, 8, 9, 10, 11],
    null: [1, 2, 3, 4, 5, 8, 9, 11],
  },
  Planet.saturn: {
    Planet.sun: [1, 2, 4, 7, 8, 10, 11],
    Planet.moon: [3, 6, 11],
    Planet.mars: [3, 5, 6, 10, 11, 12],
    Planet.mercury: [6, 8, 9, 10, 11, 12],
    Planet.jupiter: [5, 6, 11, 12],
    Planet.venus: [6, 11, 12],
    Planet.saturn: [3, 5, 6, 11],
    null: [1, 3, 4, 6, 10, 11],
  },
};

/// Computes and caches BAV/SAV bindu counts for one chart.
class Ashtakavarga {
  Ashtakavarga(this.snapshot);

  final AstroSnapshot snapshot;
  final Map<Planet, List<int>> _bavCache = {};
  List<int>? _savCache;

  /// Bindus per sign (index 0 = Aries … 11 = Pisces) in [planet]'s
  /// Bhinnashtakavarga. Each value is 0–8.
  List<int> bav(Planet planet) => _bavCache.putIfAbsent(planet, () {
        assert(_binduTables.containsKey(planet),
            'No ashtakavarga for ${planet.displayName}');
        final counts = List<int>.filled(12, 0);
        _binduTables[planet]!.forEach((contributor, houses) {
          final fromSign = contributor == null
              ? snapshot.lagnaSign.index
              : snapshot.positions[contributor]!.sign.index;
          for (final h in houses) {
            counts[(fromSign + h - 1) % 12]++;
          }
        });
        return counts;
      });

  /// Sarvashtakavarga: per-sign sum of the seven BAVs (grand total 337).
  List<int> sav() => _savCache ??= () {
        final totals = List<int>.filled(12, 0);
        for (final p in ashtakavargaPlanets) {
          final b = bav(p);
          for (var i = 0; i < 12; i++) {
            totals[i] += b[i];
          }
        }
        return totals;
      }();
}
