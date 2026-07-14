/// Kota Chakra ("the fort") — 28 nakshatras counted from the Janma
/// nakshatra arranged in four concentric enclosures:
///
/// * Stambha (pillar / innermost): 4th, 11th, 18th, 25th
/// * Madhya / Durgantara:          3rd, 5th, 10th, 12th, 17th, 19th,
///                                 24th, 26th
/// * Prakara (rampart):            2nd, 6th, 9th, 13th, 16th, 20th,
///                                 23rd, 27th
/// * Bahya (exterior):             1st, 7th, 8th, 14th, 15th, 21st,
///                                 22nd, 28th
///
/// The Janma nakshatra sits at the NE corner of the Bahya. Nakshatras
/// enter the fort along the intercardinal diagonals (NE, SE, SW, NW —
/// the "entry paths") and exit along the cardinal directions (E, S, W,
/// N — the "exit paths"): each direction takes a group of 7
/// (bahya→prakara→madhya→stambha in, then madhya→prakara→bahya out).
///
/// Kota Swami = lord of the Moon's rashi; Kota Pala = lord of the
/// Moon's navamsa (pada) sign. Broad reading: malefics moving inward
/// (entry path) toward Stambha/Madhya besiege the fort; benefics
/// there defend it. Kota Swami transiting Madhya and Kota Pala
/// transiting Bahya are protective.
library;

import 'divisional.dart';
import 'models.dart';
import 'nakshatra28.dart';

enum KotaRing {
  stambha('Stambha'),
  madhya('Madhya'),
  prakara('Prakara'),
  bahya('Bahya');

  const KotaRing(this.displayName);
  final String displayName;
}

/// Ring for the [offset1]-th nakshatra (1-based) counted from Janma.
KotaRing kotaRing(int offset1) {
  final pos = ((offset1 - 1) % 7) + 1; // 1..7 within a direction group
  return switch (pos) {
    1 || 7 => KotaRing.bahya,
    2 || 6 => KotaRing.prakara,
    3 || 5 => KotaRing.madhya,
    _ => KotaRing.stambha,
  };
}

/// True for the inward (entry-path) cells: positions 1–4 of each
/// direction group (the intercardinal diagonals).
bool kotaIsEntry(int offset1) => ((offset1 - 1) % 7) < 4;

/// Direction group 0..3 (NE/E, SE/S, SW/W, NW/N) of the offset.
int kotaDirection(int offset1) => (offset1 - 1) ~/ 7;

class KotaChakraData {
  const KotaChakraData({
    required this.janmaNak28,
    required this.kotaSwami,
    required this.kotaPala,
    required this.natal,
    required this.transit,
  });

  final int janmaNak28;
  final Planet kotaSwami;
  final Planet kotaPala;

  /// Natal planets by 1-based offset from janma nakshatra.
  final Map<int, List<Planet>> natal;

  /// Transiting planets by 1-based offset from janma nakshatra.
  final Map<int, List<Planet>> transit;
}

Map<int, List<Planet>> _byOffset(
    Map<Planet, PlanetPosition> positions, int janma) {
  final out = <int, List<Planet>>{};
  for (final p in positions.values) {
    final off =
        Nakshatra28.countFrom(janma, Nakshatra28.fromLongitude(p.longitude));
    (out[off] ??= []).add(p.planet);
  }
  return out;
}

KotaChakraData kotaChakra(
  AstroSnapshot snapshot,
  Map<Planet, PlanetPosition> transitPositions,
) {
  final moon = snapshot.positions[Planet.moon]!;
  final janma = Nakshatra28.fromLongitude(moon.longitude);
  return KotaChakraData(
    janmaNak28: janma,
    kotaSwami: moon.sign.lord,
    kotaPala: navamsaSign(moon.longitude).lord,
    natal: _byOffset(snapshot.positions, janma),
    transit: _byOffset(transitPositions, janma),
  );
}

/// Natural malefics for chakra work (Sun counted malefic here, per the
/// transit texts). Mercury/Moon conditional natures are simplified to
/// benefic in v1.
bool isChakraMalefic(Planet p) => const {
      Planet.sun,
      Planet.mars,
      Planet.saturn,
      Planet.rahu,
      Planet.ketu,
    }.contains(p);
