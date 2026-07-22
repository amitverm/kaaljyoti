/// Planets read in degree order within a chart box — sorted by the order
/// they sit ALONG the house, not by enum order. The interesting case is a
/// bhava that straddles a sign boundary: a late-Aquarius graha must come
/// before an early-Pisces one, even though 25° > 7° numerically.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/chalit.dart';
import 'package:kaaljyoti/core/astro/divisional.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

AstroSnapshot _snapshot(Map<Planet, double> longs, double ascendant) =>
    AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(1990, 1, 1),
        latitude: 28.6,
        longitude: 77.2,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
      ),
      ayanamsaId: 5,
      ayanamsaValue: 23.7,
      positions: {
        for (final e in longs.entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: ascendant,
      houseCusps: [for (var i = 0; i < 12; i++) (ascendant + 30.0 * i) % 360],
      panchang: computePanchang(
          sunLongitude: 10, moonLongitude: 100, localDateTime: DateTime(1990)),
      yogas: const [],
    );

// Degree-in-sign → absolute longitude for a given sign start.
double _at(double signStart, int deg, int min) => signStart + deg + min / 60;

void main() {
  const capricorn = 270.0, aquarius = 300.0, pisces = 330.0, aries = 0.0;

  test('cross-sign bhava: planets order along the house, not by raw degree',
      () {
    // Capricorn 0°11' Ascendant (Equal houses, so the maths is pure and
    // needs no ephemeris). House 3's madhya then sits at Pisces 0°11' and
    // the house spans Aquarius 15° → Pisces 15° — straddling the boundary.
    final asc = _at(capricorn, 0, 11);
    final snap = _snapshot({
      // The four grahas from the reference chart, all inside house 3.
      Planet.mercury: _at(pisces, 7, 11), // early Pisces, past the boundary
      Planet.mars: _at(aquarius, 23, 56), // late Aquarius, before the boundary
      Planet.sun: _at(aquarius, 25, 18),
      Planet.venus: _at(aquarius, 25, 40),
    }, asc);

    final d = computeChalit(snap, ChalitSystem.equal);

    // Along the bhava the three Aquarius grahas precede the Pisces one,
    // even though Mercury's 7° is the smallest number. Raw degree-in-sign
    // sorting would wrongly put Mercury first.
    expect(d.planetsInHouse[2],
        [Planet.mars, Planet.sun, Planet.venus, Planet.mercury]);
    // House-3 madhya is Pisces 0°11'. The three Aquarius grahas fall
    // before it, Mercury (Pisces 7°11') after — so the cusp line slots
    // between them: Ma, Su, Ve, [M], Me. This is the payoff of ordering
    // along the house: the divider lands correctly across the boundary.
    expect(d.madhyaRank[2], 3);
  });

  test('madhyaRank places the cusp between before- and after-madhya grahas',
      () {
    // House 3 madhya at Pisces 11°16' (Equal, so madhya = lagna degree in
    // each sign): Ascendant at Capricorn 11°16'.
    final asc = _at(capricorn, 11, 16);
    final snap = _snapshot({
      Planet.mercury: _at(pisces, 7, 11), // before madhya
      Planet.mars: _at(pisces, 23, 57), // after madhya
      Planet.sun: _at(pisces, 25, 19), // after madhya
      Planet.venus: _at(pisces, 25, 41), // after madhya
    }, asc);

    final d = computeChalit(snap, ChalitSystem.equal);
    expect(d.planetsInHouse[2],
        [Planet.mercury, Planet.mars, Planet.sun, Planet.venus]);
    // Exactly one graha (Mercury) precedes the madhya → cusp line renders
    // after index 0: Me, [M], Ma, Su, Ve.
    expect(d.madhyaRank[2], 1);
  });

  test('same-sign house reduces to plain ascending degree order', () {
    final asc = _at(aries, 15, 0); // House 1 madhya 15° Aries, spans 0°–30°.
    final snap = _snapshot({
      Planet.venus: _at(aries, 25, 40),
      Planet.mercury: _at(aries, 7, 11),
      Planet.sun: _at(aries, 15, 18),
    }, asc);

    final d = computeChalit(snap, ChalitSystem.equal);
    expect(d.planetsInHouse[0],
        [Planet.mercury, Planet.sun, Planet.venus]);
  });

  test('sortPlacementsByLongitude orders each sign bucket by degree', () {
    final positions = {
      for (final e in {
        Planet.venus: _at(aries, 25, 40),
        Planet.mercury: _at(aries, 7, 11),
        Planet.sun: _at(aries, 15, 18),
        Planet.moon: _at(pisces, 3, 0),
      }.entries)
        e.key:
            PlanetPosition(planet: e.key, longitude: e.value, latitude: 0, speed: 1),
    };
    final placements = <ZodiacSign, List<Planet>>{
      ZodiacSign.aries: [Planet.venus, Planet.mercury, Planet.sun],
      ZodiacSign.pisces: [Planet.moon],
    };

    final sorted = sortPlacementsByLongitude(placements, positions);
    expect(sorted[ZodiacSign.aries],
        [Planet.mercury, Planet.sun, Planet.venus]);
    expect(identical(sorted, placements), true); // mutates in place
  });

  test('higher vargas keep traditional planet order (no degree sort)', () {
    // Divisional (D2+) boxes carry no real internal progression — the
    // degrees shown are natal — so they list planets in the traditional
    // order, untouched by any longitude sort. Moon's natal longitude is
    // higher than Sun's; a degree sort would swap them.
    final snap = _snapshot({
      Planet.sun: 20.0, // Aries 20°  → Cancer hora
      Planet.moon: 33.0, // Taurus 3° → Cancer hora
    }, 0);
    final d2 = vargaPlacements(snap, Varga.d2);
    expect(d2[ZodiacSign.cancer], [Planet.sun, Planet.moon]);
  });

  test('D1 varga order reduces to natal degree order', () {
    final snap = _snapshot({
      Planet.venus: _at(aries, 25, 0),
      Planet.mercury: _at(aries, 7, 0),
    }, 0);
    final d1 = vargaPlacements(snap, Varga.d1);
    expect(d1[ZodiacSign.aries], [Planet.mercury, Planet.venus]);
  });
}
