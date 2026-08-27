/// Month-at-a-glance ephemeris tables (Menu → Ephemeris).
///
/// Daily graha longitudes tabulated at 00:00 UT — which IS 05:30 IST,
/// the reference moment printed Indian ephemerides use, so a
/// practitioner's book cross-checks agree to the arc-minute — in either
/// system: nirayan (sidereal, per chosen ayanamsa) or sayan (tropical,
/// ayanamsa-free).
///
/// The native Swiss Ephemeris cannot load under headless `flutter
/// test`, so [computeEphemerisMonth] takes its two lookups as
/// injectable closures (the same seam as `vedicDayWindow`).
library;

import 'ephemeris_service.dart';
import 'models.dart';

enum EphemerisSystem { nirayan, sayan }

enum EphemerisEventKind { ingress, stationRetrograde, stationDirect }

/// One footer line: a sign change or a station, day-accurate (detected
/// by comparing consecutive daily snapshots, not bisected to the hour —
/// this is a reference table, not a transit alert).
class EphemerisEvent {
  const EphemerisEvent({
    required this.day,
    required this.planet,
    required this.kind,
    this.sign,
  });

  /// 1-based day of month the change is first visible on.
  final int day;
  final Planet planet;
  final EphemerisEventKind kind;

  /// Ingress destination; null for stations.
  final ZodiacSign? sign;
}

class EphemerisDay {
  const EphemerisDay({
    required this.day,
    required this.positions,
    this.ascendant,
  });

  /// 1-based day of month.
  final int day;
  final Map<Planet, PlanetPosition> positions;

  /// Lagna longitude at the reference instant — null when no place was
  /// given (the ascendant, unlike the grahas, is place-dependent).
  final double? ascendant;
}

class EphemerisMonth {
  const EphemerisMonth({
    required this.year,
    required this.month,
    required this.system,
    required this.ayanamsaId,
    required this.ayanamsaOnFirst,
    required this.days,
    required this.events,
  });

  final int year;
  final int month;
  final EphemerisSystem system;

  /// Meaningful only when [system] is nirayan.
  final int ayanamsaId;

  /// Ayanamsa value at 00:00 UT on the 1st; null in sayan mode.
  final double? ayanamsaOnFirst;

  final List<EphemerisDay> days;
  final List<EphemerisEvent> events;
}

/// Julian day (UT) of a UTC instant — pure math, no FFI, so the
/// injectable-closure tests can assert the exact instants requested.
double jdFromUtc(DateTime utc) =>
    utc.millisecondsSinceEpoch / 86400000 + 2440587.5;

/// Grahas whose speed-sign flips count as stations. The nodes are
/// excluded: the true node's speed oscillates every few days, which
/// would flood the footer with meaningless "Rahu turns direct" lines
/// (and Sun/Moon never retrograde).
const _stationPlanets = {
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
};

EphemerisMonth computeEphemerisMonth({
  required int year,
  required int month,
  required EphemerisSystem system,
  required int ayanamsaId,
  double? latitude,
  double? longitude,
  Map<Planet, PlanetPosition> Function(double jdUt)? positionsAt,
  double Function(double jdUt)? ayanamsaAt,
  double Function(double jdUt)? ascendantAt,
}) {
  final eph = EphemerisService.instance;
  final nirayan = system == EphemerisSystem.nirayan;
  positionsAt ??= (jd) => nirayan
      ? eph.planetPositions(jd, ayanamsaId)
      : eph.planetPositionsTropical(jd);
  ayanamsaAt ??= (jd) => eph.ayanamsaValue(jd, ayanamsaId);
  if (ascendantAt == null && latitude != null && longitude != null) {
    final lat = latitude, lon = longitude;
    ascendantAt = (jd) => nirayan
        ? eph.housesAndAscendant(jd, lat, lon, ayanamsaId).ascendant
        : eph.ascendantTropical(jd, lat, lon);
  }

  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  final days = <EphemerisDay>[
    for (var d = 1; d <= daysInMonth; d++)
      EphemerisDay(
        day: d,
        positions: positionsAt(jdFromUtc(DateTime.utc(year, month, d))),
        ascendant: ascendantAt?.call(jdFromUtc(DateTime.utc(year, month, d))),
      ),
  ];

  final events = <EphemerisEvent>[];
  for (var i = 1; i < days.length; i++) {
    final prev = days[i - 1].positions;
    final cur = days[i].positions;
    for (final planet in Planet.values) {
      final p = prev[planet];
      final c = cur[planet];
      if (p == null || c == null) continue;
      if (p.sign != c.sign) {
        events.add(EphemerisEvent(
          day: days[i].day,
          planet: planet,
          kind: EphemerisEventKind.ingress,
          sign: c.sign,
        ));
      }
      if (_stationPlanets.contains(planet) &&
          p.isRetrograde != c.isRetrograde) {
        events.add(EphemerisEvent(
          day: days[i].day,
          planet: planet,
          kind: c.isRetrograde
              ? EphemerisEventKind.stationRetrograde
              : EphemerisEventKind.stationDirect,
        ));
      }
    }
  }

  return EphemerisMonth(
    year: year,
    month: month,
    system: system,
    ayanamsaId: ayanamsaId,
    ayanamsaOnFirst:
        nirayan ? ayanamsaAt(jdFromUtc(DateTime.utc(year, month, 1))) : null,
    days: days,
    events: events,
  );
}
