/// Tajika yoga scan vs Charak's Example Chart (X-1: Scorpio lagna,
/// forty-first year) — the chapter's own worked findings: Sun–Mars
/// Vartamana Ithasala, Moon ahead of Mars and the Sun in Ishrafa,
/// Moon–Venus distance-Bhavishyat, Sun–Saturn NOT a Bhavishyat (gap
/// under the Sun's individual deeptamsha), and the "best form" Nakta
/// between Mars and Jupiter through the Sun.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/core/astro/tajika_yoga.dart';

AstroSnapshot _exampleChart() => AstroSnapshot(
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
        for (final e in <Planet, (double, double)>{
          Planet.sun: (123 + 50 / 60, 1),
          Planet.moon: (39 + 40 / 60, 1),
          Planet.mars: (217 + 42 / 60, 1),
          Planet.mercury: (138 + 19 / 60, -1), // retrograde
          Planet.jupiter: (249 + 38 / 60, -1), // retrograde
          Planet.venus: (141 + 45 / 60, 1),
          Planet.saturn: (197 + 13 / 60, 1),
          Planet.rahu: (98 + 55 / 60, -1),
          Planet.ketu: (278 + 55 / 60, -1),
        }.entries)
          e.key: PlanetPosition(
              planet: e.key,
              longitude: e.value.$1,
              latitude: 0,
              speed: e.value.$2),
      },
      ascendant: 219 + 26 / 60,
      houseCusps: [
        for (var i = 0; i < 12; i++) (219 + 26 / 60 + 30.0 * i) % 360
      ],
      panchang: computePanchang(
          sunLongitude: 123 + 50 / 60,
          moonLongitude: 39 + 40 / 60,
          localDateTime: DateTime(1984, 8, 20, 12)),
      yogas: const [],
    );

void main() {
  final s = _exampleChart();
  final scan = scanTajikaYogas(s, karyeshaHouse: 10);

  TajikaYoga? find(TajikaYogaType type, Set<Planet> planets) => scan.pairYogas
      .where((y) => y.type == type && y.planets.toSet().containsAll(planets))
      .firstOrNull;

  test('lagnesha and karyesha are Mars and the Sun', () {
    expect(scan.lagnesha, Planet.mars);
    expect(scan.karyesha, Planet.sun); // 10th from Scorpio = Leo
  });

  test('Sun–Mars Vartamana Ithasala (the chapter\'s key example)', () {
    final y = find(TajikaYogaType.vartamanaIthasala, {Planet.sun, Planet.mars});
    expect(y, isNotNull);
    expect(y!.planets.first, Planet.sun); // the faster, behind
    expect((y.orb! - (7 + 42 / 60 - (3 + 50 / 60))).abs() < 0.01, true);
  });

  test('Moon in Ishrafa with Mars and with the Sun', () {
    expect(find(TajikaYogaType.ishrafa, {Planet.moon, Planet.mars}), isNotNull);
    expect(find(TajikaYogaType.ishrafa, {Planet.moon, Planet.sun}), isNotNull);
  });

  test('Moon–Venus distance Bhavishyat; Sun–Saturn is NOT one', () {
    expect(find(TajikaYogaType.bhavishyatIthasala, {Planet.moon, Planet.venus}),
        isNotNull);
    // 13°23' gap is inside the Sun's own 15° deeptamsha → no yoga
    // (book p. 126).
    expect(find(TajikaYogaType.bhavishyatIthasala, {Planet.sun, Planet.saturn}),
        isNull);
    expect(find(TajikaYogaType.vartamanaIthasala, {Planet.sun, Planet.saturn}),
        isNull);
  });

  test('Mars–Jupiter Nakta through the Sun (best form)', () {
    final y = find(TajikaYogaType.nakta, {Planet.mars, Planet.jupiter});
    expect(y, isNotNull);
    expect(y!.linker, Planet.sun);
  });

  test('retrograde fast-mover forms no Ithasala (Jupiter–Saturn)', () {
    // Jupiter (R) is the faster of Jupiter/Saturn, behind and within
    // range — but retrograde, so no Ithasala (book p. 126).
    expect(
        find(TajikaYogaType.vartamanaIthasala, {Planet.jupiter, Planet.saturn}),
        isNull);
  });

  test('no false chart-level yogas on the Example Chart', () {
    // Scorpio lagna: Saturn sits in the 12th (apoklima) — so no full
    // Ikabala; the other six ARE in kendras/panapharas → partial.
    expect(scan.chartYogas.any((y) => y.type == TajikaYogaType.ikabala), false);
    expect(scan.chartYogas.any((y) => y.type == TajikaYogaType.ikabalaPartial),
        true);
  });
}
