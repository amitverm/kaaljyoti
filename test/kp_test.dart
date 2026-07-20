// KP engine tests (pure Dart, no plugins / FFI): 249-sub table
// integrity, known sub-lord fixtures, Placidus-span house occupancy,
// and A–D significators on a synthetic chart.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/kp.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

AstroSnapshot _snapshot({
  required Map<Planet, double> longs,
  required double ascendant,
  required List<double> cusps,
}) =>
    AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(1992, 3, 14, 6, 30),
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
      houseCusps: cusps,
      panchang: computePanchang(
          sunLongitude: 10, moonLongitude: 100, localDateTime: DateTime(1992)),
      yogas: const [],
    );

void main() {
  group('KpLords sub-lord table', () {
    test('0° Aries: Ashwini — Ketu star, Ketu sub, Ketu sub-sub', () {
      final l = KpLords.fromLongitude(0);
      expect(l.nakshatra, Nakshatra.ashwini);
      expect(l.signLord, Planet.mars);
      expect(l.starLord, Planet.ketu);
      expect(l.subLord, Planet.ketu);
      expect(l.subSubLord, Planet.ketu);
    });

    test('sub boundaries inside Ashwini follow Vimshottari proportions', () {
      // Ketu sub spans 7/120 · 13°20' = 0°46'40" (0.7777…°); Venus next.
      expect(KpLords.fromLongitude(0.77).subLord, Planet.ketu);
      expect(KpLords.fromLongitude(0.78).subLord, Planet.venus);
      // Venus sub ends at (7+20)/120 · 13.333… = 3.0°; Sun next.
      expect(KpLords.fromLongitude(2.99).subLord, Planet.venus);
      expect(KpLords.fromLongitude(3.01).subLord, Planet.sun);
    });

    test('star lord changes at 13°20′ (Bharani), sub starts from Venus', () {
      final l = KpLords.fromLongitude(Nakshatra.span + 1e-9);
      expect(l.nakshatra, Nakshatra.bharani);
      expect(l.starLord, Planet.venus);
      expect(l.subLord, Planet.venus);
    });

    test('each nakshatra yields all 9 sub lords in Vimshottari order', () {
      for (var nak = 0; nak < 27; nak++) {
        final seen = <Planet>[];
        for (var i = 0; i < 4000; i++) {
          // Half-step offset keeps every sample strictly inside the
          // nakshatra: nak * span itself can land a float-ulp below
          // the boundary (e.g. 3 · 360/27 < 40.0) and register a
          // spurious run from the previous nakshatra's last sub.
          final lon =
              nak * Nakshatra.span + ((i + 0.5) / 4000) * Nakshatra.span;
          final sub = KpLords.fromLongitude(lon).subLord;
          if (seen.isEmpty || seen.last != sub) seen.add(sub);
        }
        expect(seen.length, 9, reason: 'nakshatra $nak');
        expect(seen.toSet().length, 9, reason: 'nakshatra $nak');
        expect(seen.first, Nakshatra.values[nak].lord,
            reason: 'nakshatra $nak starts from its own star lord');
      }
    });

    test('sub lord is continuous across the 360°→0° wrap', () {
      expect(KpLords.fromLongitude(359.999).starLord,
          KpLords.fromLongitude(-0.001).starLord);
    });
  });

  group('KpChart houses & significators', () {
    // Synthetic Placidus-like cusps: unequal spans, asc 95° (Cancer).
    final cusps = <double>[
      95, 122, 152, 185, 218, 249, 275, 302, 332, 5, 38, 69, //
    ];
    final snap = _snapshot(
      longs: {
        Planet.sun: 100.0, // house 1 (95–122)
        Planet.moon: 130.0, // house 2
        Planet.mars: 10.0, // house 10 (5–38)
        Planet.mercury: 121.0, // house 1 — same sign as 130° but earlier span
        Planet.jupiter: 200.0, // house 4
        Planet.venus: 355.0, // house 9 (332–5, wraps)
        Planet.saturn: 300.0, // house 7
        Planet.rahu: 180.0, // house 3
        Planet.ketu: 0.0, // house 9 (332–5, wraps)
      },
      ascendant: 95.0,
      cusps: cusps,
    );
    final kp = KpChart(snap);

    test('cusp-span occupancy, including the 0° wrap', () {
      int houseOfPlanet(Planet p) =>
          kp.planets.firstWhere((e) => e.planet == p).house;
      expect(houseOfPlanet(Planet.sun), 1);
      expect(houseOfPlanet(Planet.mercury), 1);
      expect(houseOfPlanet(Planet.moon), 2);
      expect(houseOfPlanet(Planet.mars), 10);
      expect(houseOfPlanet(Planet.venus), 9); // wrap: 332→5
      expect(houseOfPlanet(Planet.ketu), 9); // wrap: exactly 0°
      expect(houseOfPlanet(Planet.saturn), 7);
    });

    test('KP house differs from whole-sign where cusps demand it', () {
      // Mercury 121° is Cancer (sign of the 1st) but so is the Sun at
      // 100° — both share the whole-sign house. Moon at 130° (Leo,
      // whole-sign 2nd) stays 2nd; Jupiter 200° is whole-sign 4th
      // (Libra from Cancer lagna) and cusp-span 4th here. The
      // interesting case: 121° vs 122° cusp boundary.
      expect(kp.houseOf(121.9), 1);
      expect(kp.houseOf(122.0), 2);
    });

    test('significators: B = occupants, D = cusp-sign lord', () {
      final h1 = kp.significators[0];
      expect(h1.occupants.toSet(), {Planet.sun, Planet.mercury});
      expect(h1.owner, Planet.moon); // cusp 95° in Cancer
      final h7 = kp.significators[6];
      expect(h7.occupants, [Planet.saturn]);
      expect(h7.owner, Planet.saturn); // cusp 275° in Capricorn
    });

    test('A-level: planets in the star of a house occupant', () {
      // Sun occupies house 1. Planets in the Sun's stars (Krittika,
      // U.Phalguni, U.Ashadha) signify house 1 at A level.
      final h1 = kp.significators[0];
      for (final p in kp.planets) {
        final inStarOfOccupant = h1.occupants.contains(p.lords.starLord);
        expect(h1.inStarOfOccupants.contains(p.planet), inStarOfOccupant,
            reason: p.planet.displayName);
      }
    });

    test('housesSignifiedBy is sorted, de-duplicated, and non-empty', () {
      for (final p in Planet.values) {
        final houses = kp.housesSignifiedBy(p);
        expect(houses, isNotEmpty, reason: p.displayName);
        expect(houses, orderedEquals(houses.toSet().toList()..sort()),
            reason: p.displayName);
        expect(houses.every((h) => h >= 1 && h <= 12), true);
      }
    });
  });

  group('KpRulingPlanets', () {
    test('day lord mapping and lagna/moon chains', () {
      final rp = KpRulingPlanets.compute(
        ascendant: 0, // Aries / Ashwini / Ketu sub
        moonLongitude: 100, // Cancer / Pushya (Saturn star)
        localWeekday: DateTime.thursday,
      );
      expect(rp.dayLord, Planet.jupiter);
      expect(rp.lagnaSignLord, Planet.mars);
      expect(rp.lagnaStarLord, Planet.ketu);
      expect(rp.lagnaSubLord, Planet.ketu);
      expect(rp.moonSignLord, Planet.moon);
      expect(rp.moonStarLord, Planet.saturn);
      expect(rp.distinct.toSet().length, rp.distinct.length);
    });
  });

  group('Nakshatra additions', () {
    test('abbr covers all 27 uniquely', () {
      final abbrs = Nakshatra.values.map((n) => n.abbr).toSet();
      expect(abbrs.length, 27);
    });

    test('lord follows the Vimshottari 9-cycle', () {
      expect(Nakshatra.ashwini.lord, Planet.ketu);
      expect(Nakshatra.bharani.lord, Planet.venus);
      expect(Nakshatra.magha.lord, Planet.ketu); // index 9 wraps
      expect(Nakshatra.revati.lord, Planet.mercury);
    });
  });
}
