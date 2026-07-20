/// Golden tests for the three varsha dashas against Charak's Example
/// Chart (A Textbook of Varshaphala ch. V): natal Moon 4s17°08'
/// (Poorva Phalguni, 3°48' traversed), 41st year (40 completed), and
/// the Example annual chart for Patyayini (Tables V-2, V-5, V-8/9).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/core/astro/varsha_dasha.dart';

const natalMoon = 137 + 8 / 60.0; // 4s 17°08'
final pravesh = DateTime.utc(1984, 8, 20);

double _days(VarshaDashaPeriod p) =>
    p.length.inMilliseconds / Duration.millisecondsPerDay;

void _near(double actual, double expected, String what, [double tol = 0.05]) {
  expect((actual - expected).abs() <= tol, true,
      reason: '$what: $actual vs $expected');
}

void main() {
  test('Mudda: Rahu start with 38.61-day balance, wraps to Rahu 15.39', () {
    final periods = muddaDasha(
        praveshUtc: pravesh, natalMoonLongitude: natalMoon, varshaYear: 40);
    expect(periods.length, 10);
    expect(periods.first.lord, Planet.rahu);
    _near(_days(periods.first), 38.61, 'Rahu balance');
    // Vimshottari order follows: Jupiter, Saturn, Mercury, Ketu,
    // Venus, Sun, Moon, Mars (Table V-2).
    expect(periods[1].lord, Planet.jupiter);
    _near(_days(periods[1]), 48, 'Jupiter');
    expect(periods[2].lord, Planet.saturn);
    expect(periods[3].lord, Planet.mercury);
    expect(periods[4].lord, Planet.ketu);
    expect(periods[5].lord, Planet.venus);
    expect(periods[6].lord, Planet.sun);
    expect(periods[7].lord, Planet.moon);
    expect(periods[8].lord, Planet.mars);
    expect(periods.last.lord, Planet.rahu);
    _near(_days(periods.last), 15.39, 'Rahu closing');
    // 360-day year, contiguous.
    final total = periods.fold(0.0, (a, p) => a + _days(p));
    _near(total, 360, 'total');
    for (var i = 1; i < periods.length; i++) {
      expect(periods[i].start, periods[i - 1].end);
    }
  });

  test('Mudda sub-periods start with the MD lord, proportional', () {
    final periods = muddaDasha(
        praveshUtc: pravesh, natalMoonLongitude: natalMoon, varshaYear: 40);
    final jupiter = periods[1];
    expect(jupiter.subPeriods.first.lord, Planet.jupiter);
    // AD = MD × AD-lord days / 360 (Table V-3: Jupiter/Jupiter 6d9.6h).
    _near(_days(jupiter.subPeriods.first), 48 * 48 / 360, 'Ju/Ju');
    expect(jupiter.subPeriods[1].lord, Planet.saturn);
    final subTotal = jupiter.subPeriods.fold(0.0, (a, p) => a + _days(p));
    _near(subTotal, 48, 'subs fill the MD');
  });

  test('Yogini: Ulka start with 42.9-day balance, wraps to Ulka 17.1', () {
    final periods = yoginiVarshaDasha(
        praveshUtc: pravesh, natalMoonLongitude: natalMoon, varshaYear: 40);
    expect(periods.length, 9);
    expect(periods.first.lord, Planet.saturn); // Ulka
    _near(_days(periods.first), 42.9, 'Ulka balance');
    // Table V-5 order: Siddha, Sankata, Mangala, Pingala, Dhanya,
    // Bhramari, Bhadrika, then Ulka's consumed part.
    expect(periods[1].lord, Planet.venus);
    _near(_days(periods[1]), 70, 'Siddha');
    expect(periods[2].lord, Planet.rahu);
    _near(_days(periods[2]), 80, 'Sankata');
    expect(periods[3].lord, Planet.moon);
    expect(periods.last.lord, Planet.saturn);
    _near(_days(periods.last), 17.1, 'Ulka closing');
    _near(periods.fold(0.0, (a, p) => a + _days(p)), 360, 'total');
  });

  test('Patyayini reproduces Table V-8 from the Example annual chart', () {
    final varsha = AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(1984, 8, 20),
        latitude: 28.65,
        longitude: 77.2,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
      ),
      ayanamsaId: 1,
      ayanamsaValue: 23.5,
      positions: {
        for (final e in {
          Planet.sun: 123 + 50 / 60.0, // Leo 3°50' → krish 3°50'
          Planet.moon: 39 + 40 / 60.0, // Taurus 9°40'
          Planet.mars: 217 + 42 / 60.0, // Scorpio 7°42'
          Planet.mercury: 138 + 20 / 60.0, // Leo 18°20' (Table V-6)
          Planet.jupiter: 249 + 38 / 60.0, // Sagittarius 9°38'
          Planet.venus: 141 + 45 / 60.0, // Leo 21°45'
          Planet.saturn: 197 + 13 / 60.0, // Libra 17°13'
          Planet.rahu: 100.0,
          Planet.ketu: 280.0,
        }.entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: 210 + 9 + 26 / 60.0, // Scorpio 9°26'
      houseCusps: [for (var i = 0; i < 12; i++) ((7 + i) % 12) * 30.0],
      panchang: computePanchang(
          sunLongitude: 123 + 50 / 60.0,
          moonLongitude: 39 + 40 / 60.0,
          localDateTime: DateTime(1984, 8, 20, 12)),
      yogas: const [],
    );

    final periods = patyayiniDasha(praveshUtc: pravesh, varsha: varsha);
    expect(periods.length, 8);
    // Table V-8: Sun, Mars, Lagna, Jupiter, Moon, Saturn, Mercury,
    // Venus with these durations.
    final expected = <(Planet?, double)>[
      (Planet.sun, 64.33),
      (Planet.mars, 64.89),
      (null, 29.09), // the Lagna
      (Planet.jupiter, 3.36),
      (Planet.moon, 0.56),
      (Planet.saturn, 126.70),
      (Planet.mercury, 18.74),
      (Planet.venus, 57.34),
    ];
    for (var i = 0; i < 8; i++) {
      expect(periods[i].lord, expected[i].$1, reason: 'lord $i');
      _near(_days(periods[i]), expected[i].$2, 'duration $i', 0.06);
    }
    _near(periods.fold(0.0, (a, p) => a + _days(p)), 365, 'total');

    // Sub-periods of the Sun MD (Table V-9): Sun first, 11d 8.1h.
    final sun = periods.first;
    expect(sun.subPeriods.first.lord, Planet.sun);
    _near(_days(sun.subPeriods.first), 11.34, 'Sun/Sun', 0.02);
    expect(sun.subPeriods[1].lord, Planet.mars);
    expect(sun.subPeriods[2].lord, null); // Lagna AD
  });
}
