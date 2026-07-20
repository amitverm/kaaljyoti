/// Varshphal engine: solar-return search precision, varsha numbering,
/// and Muntha. All with a synthetic Sun (no ephemeris needed) — the
/// engine takes an injectable [LongitudeAt] like the transit scanner.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/varshphal.dart';

void main() {
  // Synthetic direct Sun: exactly [rate] deg/day from the birth
  // instant. The true return is then analytic: n * 360 / rate days.
  final birth = DateTime.utc(1990, 8, 15, 5, 0);
  const natalSun = 118.437;
  const rate = 0.9856473; // deg/day, mean solar motion

  double sun(DateTime t) {
    final days = t.difference(birth).inMilliseconds / 86400000.0;
    return (natalSun + rate * days) % 360;
  }

  DateTime analyticReturn(int n) =>
      birth.add(Duration(milliseconds: (n * 360 / rate * 86400000).round()));

  test('solar return found to ≤2 s of the analytic instant', () {
    for (final n in [1, 5, 36, 100]) {
      final found = solarReturnUtc(
        birthUtc: birth,
        natalSunLongitude: natalSun,
        varshaYear: n,
        ayanamsaId: 1,
        sun: sun,
      );
      expect(
        found.difference(analyticReturn(n)).inSeconds.abs() <= 2,
        true,
        reason: 'varsha $n: found $found vs ${analyticReturn(n)}',
      );
    }
  });

  test('varsha 0 returns the birth instant itself', () {
    final found = solarReturnUtc(
      birthUtc: birth,
      natalSunLongitude: natalSun,
      varshaYear: 0,
      ayanamsaId: 1,
      sun: sun,
    );
    expect(found.difference(birth).inSeconds.abs() <= 2, true);
  });

  test('currentVarshaYear picks the running varsha', () {
    expect(currentVarshaYear(birth, birth), 0);
    expect(currentVarshaYear(birth, birth.add(const Duration(days: 200))), 0);
    expect(currentVarshaYear(birth, birth.add(const Duration(days: 400))), 1);
    // Just before vs just after the 36th sidereal-year mark.
    final y36 =
        birth.add(Duration(seconds: (36 * kSiderealYearDays * 86400).round()));
    expect(currentVarshaYear(birth, y36.subtract(const Duration(days: 1))), 35);
    expect(currentVarshaYear(birth, y36.add(const Duration(days: 1))), 36);
  });

  test('muntha advances one sign per completed year', () {
    expect(munthaSign(ZodiacSign.scorpio, 0), ZodiacSign.scorpio);
    expect(munthaSign(ZodiacSign.scorpio, 1), ZodiacSign.sagittarius);
    expect(munthaSign(ZodiacSign.scorpio, 12), ZodiacSign.scorpio);
    expect(munthaSign(ZodiacSign.scorpio, 14), ZodiacSign.capricorn);
    expect(munthaSign(ZodiacSign.pisces, 1), ZodiacSign.aries); // wrap
  });

  test('maasa pravesha lands at each +30° of the synthetic sun', () {
    final pravesh = solarReturnUtc(
      birthUtc: birth,
      natalSunLongitude: natalSun,
      varshaYear: 5,
      ayanamsaId: 1,
      sun: sun,
    );
    for (final m in [2, 7, 12]) {
      final t = maasaPraveshUtc(
        varshaPraveshUtc: pravesh,
        natalSunLongitude: natalSun,
        month: m,
        ayanamsaId: 1,
        sun: sun,
      );
      final expected = pravesh.add(
          Duration(milliseconds: ((m - 1) * 30 / rate * 86400000).round()));
      expect(t.difference(expected).inSeconds.abs() <= 2, true,
          reason: 'month $m: $t vs $expected');
    }
    expect(
        maasaPraveshUtc(
          varshaPraveshUtc: pravesh,
          natalSunLongitude: natalSun,
          month: 1,
          ayanamsaId: 1,
          sun: sun,
        ),
        pravesh);
  });
}
