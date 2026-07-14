/// Lightweight "current sky" helper for overlaying live transits on a
/// natal chart. Deliberately skips houses/panchang/ascendant — a
/// transit overlay only needs sign placements, and the natal chart's
/// own lagna anchors the display.
library;

import 'ephemeris_service.dart';
import 'models.dart';

/// Sidereal positions of all nine grahas "right now" (or at [at], if
/// given), using the same ayanamsa as the natal chart being overlaid.
Map<Planet, PlanetPosition> currentTransitPositions({
  required int ayanamsaId,
  DateTime? at,
}) {
  final svc = EphemerisService.instance;
  final jd = svc.julianDayUt((at ?? DateTime.now()).toUtc());
  return svc.planetPositions(jd, ayanamsaId);
}

/// Groups transit positions by sign, mirroring the shape the chart
/// painters already expect for natal placements.
Map<ZodiacSign, List<Planet>> transitPlacements(
  Map<Planet, PlanetPosition> positions,
) {
  final out = <ZodiacSign, List<Planet>>{};
  for (final p in positions.values) {
    out.putIfAbsent(p.sign, () => []).add(p.planet);
  }
  return out;
}
