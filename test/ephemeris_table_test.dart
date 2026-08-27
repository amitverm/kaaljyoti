/// The month-table builder behind Menu → Ephemeris.
///
/// The native Swiss Ephemeris cannot load under headless `flutter
/// test`, so these tests drive [computeEphemerisMonth]'s closure seam
/// with synthetic motion: known Julian days in, ingress/station/R
/// bookkeeping checked on the way out.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/ephemeris_table.dart';
import 'package:kaaljyoti/core/astro/models.dart';

PlanetPosition _pos(Planet p, double longitude, {double speed = 1}) =>
    PlanetPosition(planet: p, longitude: longitude, latitude: 0, speed: speed);

/// All nine grahas parked at 5° Aries, direct — overridden per test.
Map<Planet, PlanetPosition> _baseline() =>
    {for (final p in Planet.values) p: _pos(p, 5)};

void main() {
  test('tabulates one row per calendar day at 00:00 UT', () {
    final requested = <double>[];
    final month = computeEphemerisMonth(
      year: 2000,
      month: 1,
      system: EphemerisSystem.sayan,
      ayanamsaId: 1,
      positionsAt: (jd) {
        requested.add(jd);
        return _baseline();
      },
    );
    expect(month.days, hasLength(31));
    expect(month.days.first.day, 1);
    expect(month.days.last.day, 31);
    // JD of 2000-01-01T00:00Z is the textbook 2451544.5.
    expect(requested.first, closeTo(2451544.5, 1e-9));
    expect(requested[1], closeTo(2451545.5, 1e-9));
  });

  test('handles February length in leap and non-leap years', () {
    EphemerisMonth feb(int year) => computeEphemerisMonth(
          year: year,
          month: 2,
          system: EphemerisSystem.sayan,
          ayanamsaId: 1,
          positionsAt: (_) => _baseline(),
        );
    expect(feb(2026).days, hasLength(28));
    expect(feb(2028).days, hasLength(29));
  });

  test('records an ingress on the first day the sign differs', () {
    // Mercury walks 1°/day from 28° Aries: 28, 29, then 0° Taurus on
    // day 3.
    final month = computeEphemerisMonth(
      year: 2026,
      month: 4,
      system: EphemerisSystem.sayan,
      ayanamsaId: 1,
      positionsAt: (jd) {
        final day = (jd - jdFromUtc(DateTime.utc(2026, 4, 1))).round() + 1;
        return _baseline()
          ..[Planet.mercury] = _pos(Planet.mercury, 27.0 + day);
      },
    );
    final ingresses = month.events
        .where((e) => e.kind == EphemerisEventKind.ingress)
        .toList();
    expect(ingresses, hasLength(1));
    expect(ingresses.single.day, 3);
    expect(ingresses.single.planet, Planet.mercury);
    expect(ingresses.single.sign, ZodiacSign.taurus);
  });

  test('records stations for the five tara grahas, not the nodes', () {
    // Saturn: direct through day 9, retrograde days 10–19, direct from
    // day 20. Rahu's speed flips the same way but must stay silent.
    final month = computeEphemerisMonth(
      year: 2026,
      month: 6,
      system: EphemerisSystem.sayan,
      ayanamsaId: 1,
      positionsAt: (jd) {
        final day = (jd - jdFromUtc(DateTime.utc(2026, 6, 1))).round() + 1;
        final retro = day >= 10 && day < 20;
        return _baseline()
          ..[Planet.saturn] = _pos(Planet.saturn, 5, speed: retro ? -.05 : .05)
          ..[Planet.rahu] = _pos(Planet.rahu, 5, speed: retro ? -.05 : .05);
      },
    );
    final stations = month.events
        .where((e) => e.kind != EphemerisEventKind.ingress)
        .toList();
    expect(stations, hasLength(2));
    expect(stations[0].planet, Planet.saturn);
    expect(stations[0].kind, EphemerisEventKind.stationRetrograde);
    expect(stations[0].day, 10);
    expect(stations[1].kind, EphemerisEventKind.stationDirect);
    expect(stations[1].day, 20);
  });

  test('nirayan mode reports the ayanamsa on the 1st', () {
    final month = computeEphemerisMonth(
      year: 2026,
      month: 8,
      system: EphemerisSystem.nirayan,
      ayanamsaId: 1,
      positionsAt: (_) => _baseline(),
      ayanamsaAt: (jd) {
        expect(jd, closeTo(jdFromUtc(DateTime.utc(2026, 8, 1)), 1e-9));
        return 24.29;
      },
    );
    expect(month.ayanamsaOnFirst, 24.29);
  });

  test('tabulates the ascendant only when a place (or seam) is given', () {
    final withAsc = computeEphemerisMonth(
      year: 2026,
      month: 8,
      system: EphemerisSystem.nirayan,
      ayanamsaId: 1,
      positionsAt: (_) => _baseline(),
      ayanamsaAt: (_) => 24.0,
      ascendantAt: (jd) =>
          // Distinct per day so the mapping is checked, not just presence.
          (jd - jdFromUtc(DateTime.utc(2026, 8, 1))) + 100.0,
    );
    expect(withAsc.days.first.ascendant, 100.0);
    expect(withAsc.days.last.ascendant, 130.0);

    final withoutPlace = computeEphemerisMonth(
      year: 2026,
      month: 8,
      system: EphemerisSystem.nirayan,
      ayanamsaId: 1,
      positionsAt: (_) => _baseline(),
      ayanamsaAt: (_) => 24.0,
    );
    expect(withoutPlace.days.first.ascendant, isNull);
  });

  test('sayan mode never asks for an ayanamsa', () {
    final month = computeEphemerisMonth(
      year: 2026,
      month: 8,
      system: EphemerisSystem.sayan,
      ayanamsaId: 1,
      positionsAt: (_) => _baseline(),
      ayanamsaAt: (_) => fail('ayanamsa requested in sayan mode'),
    );
    expect(month.ayanamsaOnFirst, isNull);
  });
}
