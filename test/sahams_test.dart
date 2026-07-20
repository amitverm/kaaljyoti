/// Saham engine vs the book's worked examples (Charak ch. XI, Example
/// Chart, day Varshapravesha): Punya kept without correction at
/// 4s15°16', Raja corrected by one sign to 10s22°49'.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/core/astro/sahams.dart';

void main() {
  test('sahamValue applies the between-rule exactly as the book', () {
    const moon = 39 + 40 / 60.0; // 1s9°40'
    const sun = 123 + 50 / 60.0; // 4s3°50'
    const asc = 219 + 26 / 60.0; // 7s9°26'
    const saturn = 197 + 13 / 60.0; // 6s17°13'
    // Punya (day): Moon − Sun + Asc; Asc lies between Sun and Moon in
    // the regular order → no correction. 4s15°16'.
    final punya = sahamValue(moon, sun, asc);
    expect((punya - (135 + 16 / 60)).abs() < 0.01, true,
        reason: 'punya $punya');
    // Raja (day): Saturn − Sun + Asc; Asc does NOT lie between the Sun
    // and Saturn → +30°. 10s22°49'.
    final raja = sahamValue(saturn, sun, asc);
    expect((raja - (322 + 49 / 60)).abs() < 0.01, true, reason: 'raja $raja');
  });

  test('full run: 41 sahams, dependencies resolved, all normalized', () {
    final chart = AstroSnapshot(
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
          Planet.sun: 123 + 50 / 60.0,
          Planet.moon: 39 + 40 / 60.0,
          Planet.mars: 217 + 42 / 60.0,
          Planet.mercury: 138 + 20 / 60.0,
          Planet.jupiter: 249 + 38 / 60.0,
          Planet.venus: 141 + 45 / 60.0,
          Planet.saturn: 197 + 13 / 60.0,
          Planet.rahu: 100.0,
          Planet.ketu: 280.0,
        }.entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: 219 + 26 / 60.0,
      houseCusps: [
        for (var i = 0; i < 12; i++) (219 + 26 / 60.0 + 30.0 * i) % 360
      ],
      panchang: computePanchang(
          sunLongitude: 123 + 50 / 60.0,
          moonLongitude: 39 + 40 / 60.0,
          localDateTime: DateTime(1984, 8, 20, 12)),
      yogas: const [],
    );

    final results = sahams(chart, day: true);
    expect(results.length, 41);
    expect(results.map((r) => r.key).toSet().length, 41);
    for (final r in results) {
      expect(r.longitude >= 0 && r.longitude < 360, true, reason: r.key);
    }
    // The two book values surface in the full run too.
    final byKey = {for (final r in results) r.key: r.longitude};
    expect((byKey['punya']! - (135 + 16 / 60)).abs() < 0.01, true);
    expect((byKey['raja']! - (322 + 49 / 60)).abs() < 0.01, true);
    // Vidya = Guru by definition; Kshama = Kali; Roga uses the numbered
    // formula (not the Paneeya-Paata variant).
    expect(byKey['vidya'], byKey['guru']);
    expect(byKey['kshama'], byKey['kali']);
  });

  test('night pravesha flips the flip-marked sahams only', () {
    final chart = AstroSnapshot(
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
          Planet.sun: 123 + 50 / 60.0,
          Planet.moon: 39 + 40 / 60.0,
          Planet.mars: 217 + 42 / 60.0,
          Planet.mercury: 138 + 20 / 60.0,
          Planet.jupiter: 249 + 38 / 60.0,
          Planet.venus: 141 + 45 / 60.0,
          Planet.saturn: 197 + 13 / 60.0,
          Planet.rahu: 100.0,
          Planet.ketu: 280.0,
        }.entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: 219 + 26 / 60.0,
      houseCusps: [
        for (var i = 0; i < 12; i++) (219 + 26 / 60.0 + 30.0 * i) % 360
      ],
      panchang: computePanchang(
          sunLongitude: 123 + 50 / 60.0,
          moonLongitude: 39 + 40 / 60.0,
          localDateTime: DateTime(1984, 8, 20, 22)),
      yogas: const [],
    );
    final day = {for (final r in sahams(chart, day: true)) r.key: r.longitude};
    final night = {
      for (final r in sahams(chart, day: false)) r.key: r.longitude
    };
    // Punya flips day/night; Bhratri is the same either way.
    expect(day['punya'] != night['punya'], true);
    expect(day['bhratri'], night['bhratri']);
  });
}
