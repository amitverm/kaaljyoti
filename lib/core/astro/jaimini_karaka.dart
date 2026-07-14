/// Jaimini Karakas — Sapta Karaka scheme.
///
/// Ranks the seven classical grahas (Sun through Saturn — no Rahu/Ketu)
/// by degree-within-sign, highest first, and assigns the seven karaka
/// roles. This is the traditional 7-karaka scheme; the alternative
/// 8-karaka scheme (which adds a node) is a different tradition and is
/// intentionally not implemented here.
library;

import 'models.dart';

enum Karaka {
  atmakaraka('AK', 'Atmakaraka', 'self, soul purpose'),
  amatyakaraka('AmK', 'Amatyakaraka', 'career, counsel'),
  bhratrukaraka('BK', 'Bhratrukaraka', 'siblings, courage'),
  matrukaraka('MK', 'Matrukaraka', 'mother, home'),
  pitrukaraka('PiK', 'Pitrukaraka', 'father, guru'),
  gnatikaraka('GK', 'Gnatikaraka', 'relatives, obstacles'),
  darakaraka('DK', 'Darakaraka', 'spouse, partnerships');

  const Karaka(this.code, this.displayName, this.signifies);

  /// Short chart label, e.g. 'AK'.
  final String code;
  final String displayName;

  /// Classical significator role — a factual label (like a varga's
  /// theme), not an interpretive reading.
  final String signifies;
}

const _saptaKarakaGrahas = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
];

/// Ranks the seven classical grahas by degree-within-sign (descending)
/// and assigns karaka roles. Ties (exact equal degree — vanishingly
/// rare with real ephemeris data) fall back to the classical order
/// Sun > Moon > Mars > Mercury > Jupiter > Venus > Saturn.
Map<Planet, Karaka> saptaKarakas(Map<Planet, PlanetPosition> positions) {
  final ranked = [..._saptaKarakaGrahas]
    ..sort((a, b) {
      final da = positions[a]!.degreesInSign;
      final db = positions[b]!.degreesInSign;
      final cmp = db.compareTo(da);
      if (cmp != 0) return cmp;
      return _saptaKarakaGrahas
          .indexOf(a)
          .compareTo(_saptaKarakaGrahas.indexOf(b));
    });
  return {
    for (var i = 0; i < ranked.length; i++) ranked[i]: Karaka.values[i],
  };
}
