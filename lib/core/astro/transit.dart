/// Lightweight "current sky" helper for overlaying live transits on a
/// natal chart. Deliberately skips houses/panchang — a transit overlay
/// only needs sign placements, and the natal chart's own lagna anchors
/// the display. The one location-bound extra is [transitAscendant]:
/// the Udaya Lagna (the sign rising at the transit instant), wanted as
/// a reference mark and for verifying against desktop software.
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

/// Sidereal ascendant longitude rising at [at] over the given place —
/// the transit chart's Udaya Lagna. Unlike the graha positions this IS
/// location-bound; callers pass the kundli's birth place, consistent
/// with the varshphal convention. Returns null in degenerate (polar)
/// cases where the house computation fails.
double? transitAscendant({
  required DateTime at,
  required double latitude,
  required double longitude,
  required int ayanamsaId,
}) {
  final svc = EphemerisService.instance;
  final jd = svc.julianDayUt(at.toUtc());
  try {
    return svc
        .housesAndAscendant(jd, latitude, longitude, ayanamsaId)
        .ascendant;
  } catch (_) {
    return null;
  }
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
  return sortPlacementsByLongitude(out, positions);
}
