/// Planetary dignity (classical exaltation / debilitation / own sign)
/// and combustion (proximity to the Sun).
///
/// Scoped to the seven classical grahas — Rahu/Ketu dignity rules are
/// disputed across traditions and are intentionally left unmarked here,
/// consistent with using the (node-free) Sapta Karaka scheme elsewhere
/// in the birth chart widget.
library;

import 'models.dart';

enum PlanetDignity { none, ownSign, exalted, debilitated }

/// Exaltation sign per classical graha (degree-in-sign omitted — the
/// sign-level check is what drives the on-chart marker).
const Map<Planet, ZodiacSign> _exaltationSign = {
  Planet.sun: ZodiacSign.aries,
  Planet.moon: ZodiacSign.taurus,
  Planet.mars: ZodiacSign.capricorn,
  Planet.mercury: ZodiacSign.virgo,
  Planet.jupiter: ZodiacSign.cancer,
  Planet.venus: ZodiacSign.pisces,
  Planet.saturn: ZodiacSign.libra,
};

/// Combustion orb in degrees from the Sun. Simplified — classical texts
/// vary the orb slightly for retrograde planets; a single orb per
/// graha is used here.
const Map<Planet, double> _combustionOrb = {
  Planet.moon: 12,
  Planet.mars: 17,
  Planet.mercury: 14,
  Planet.jupiter: 11,
  Planet.venus: 10,
  Planet.saturn: 15,
};

ZodiacSign _opposite(ZodiacSign s) => ZodiacSign.values[(s.index + 6) % 12];

/// Public sign-level exaltation lookup (null for the nodes) — used by
/// the yoga engine's Neecha Bhanga rules.
ZodiacSign? exaltationSignOf(Planet p) => _exaltationSign[p];

/// Sign-level debilitation lookup (null for the nodes).
ZodiacSign? debilitationSignOf(Planet p) {
  final e = _exaltationSign[p];
  return e == null ? null : _opposite(e);
}

/// Dignity of [position]. Only meaningful for the seven classical
/// grahas — always [PlanetDignity.none] for Rahu/Ketu.
PlanetDignity dignityOf(PlanetPosition position) {
  final exaltSign = _exaltationSign[position.planet];
  if (exaltSign == null) return PlanetDignity.none;
  if (position.sign == exaltSign) return PlanetDignity.exalted;
  if (position.sign == _opposite(exaltSign)) return PlanetDignity.debilitated;
  if (position.sign.lord == position.planet) return PlanetDignity.ownSign;
  return PlanetDignity.none;
}

/// True if [position] is combust — too close to the Sun to be
/// classically "visible". The Sun and the lunar nodes are never
/// combust.
bool isCombust(PlanetPosition position, PlanetPosition sun) {
  final orb = _combustionOrb[position.planet];
  if (orb == null) return false;
  var diff = (position.longitude - sun.longitude).abs() % 360;
  if (diff > 180) diff = 360 - diff;
  return diff <= orb;
}
