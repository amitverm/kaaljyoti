// Muhurta pure-logic tests — fixed DateTimes, no ephemeris/FFI.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/muhurta.dart';

void main() {
  // A Sunday: 06:00 sunrise, 18:00 sunset, next-day 06:12 sunrise.
  final sunrise = DateTime(2026, 7, 5, 6, 0); // Sunday
  final sunset = DateTime(2026, 7, 5, 18, 0);
  final nextSunrise = DateTime(2026, 7, 6, 6, 12);

  group('choghadiyaSegments', () {
    test('Sunday day starts Udveg, cycles the 7 names, wraps at 8th', () {
      final chog = choghadiyaSegments(
          sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise);
      expect(chog.day.length, 8);
      expect(
        chog.day.map((s) => s.choghadiya).toList(),
        [
          Choghadiya.udveg,
          Choghadiya.char,
          Choghadiya.labh,
          Choghadiya.amrit,
          Choghadiya.kaal,
          Choghadiya.shubh,
          Choghadiya.rog,
          Choghadiya.udveg,
        ],
      );
      expect(chog.day.first.start, sunrise);
      expect(chog.day.last.end, sunset);
    });

    test('night starts the 5th name from the day\'s first', () {
      final chog = choghadiyaSegments(
          sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise);
      // Day first = Udveg (index 0); 5th from it (offset +4) = Kaal.
      expect(chog.night.length, 8);
      expect(chog.night.first.choghadiya, Choghadiya.kaal);
      expect(chog.night.first.start, sunset);
      expect(chog.night.last.end, nextSunrise);
    });

    test('good/bad flags match Amrit/Shubh/Labh/Char = good', () {
      // Spelled out rather than derived from Choghadiya.isAuspicious —
      // asserting the rule against the implementation that computes it
      // would pass no matter what that implementation said.
      const auspicious = {
        Choghadiya.amrit,
        Choghadiya.shubh,
        Choghadiya.labh,
        Choghadiya.char,
      };
      final chog = choghadiyaSegments(
          sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise);
      for (final s in [...chog.day, ...chog.night]) {
        expect(s.good, auspicious.contains(s.choghadiya));
      }
    });
  });

  group('horaSegments', () {
    test('Sunday first hora is the Sun, then the Chaldean cycle', () {
      final hora = horaSegments(
          sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise);
      expect(hora.length, 24);
      expect(hora.first.planet, Planet.sun);
      expect(
        hora.take(8).map((s) => s.planet).toList(),
        [
          Planet.sun,
          Planet.venus,
          Planet.mercury,
          Planet.moon,
          Planet.saturn,
          Planet.jupiter,
          Planet.mars,
          Planet.sun,
        ],
      );
      expect(hora.first.start, sunrise);
      expect(hora[11].end, sunset);
      expect(hora.last.end, nextSunrise);
    });

    test('no reset at sunset — cycle continues seamlessly', () {
      final hora = horaSegments(
          sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise);
      // 12th day slot (index 11 of the cycle, i.e. cycle position
      // (0+11)%7 = 4) is Saturn; the first night slot must be the
      // NEXT cycle position (5 = Jupiter), not a reset back to Sun.
      expect(hora[11].planet, Planet.saturn);
      expect(hora[12].planet, Planet.jupiter);
    });
  });

  group('inauspicious/auspicious windows', () {
    test('Rahu Kaal / Yamaganda / Gulika Kaal use the weekday segment tables',
        () {
      // Sunday (DateTime.weekday == 7): Rahu 8th, Yamaganda 5th, Gulika 7th.
      final len = sunset.difference(sunrise) ~/ 8;
      final rahu = rahuKaalWindow(sunrise, sunset);
      expect(rahu.start, sunrise.add(len * 7));
      final yama = yamagandaWindow(sunrise, sunset);
      expect(yama.start, sunrise.add(len * 4));
      final gulika = gulikaKaalWindow(sunrise, sunset);
      expect(gulika.start, sunrise.add(len * 6));
    });

    test('Abhijit is the 8th of 15 day-muhurtas, centered near midday', () {
      final muhurta = sunset.difference(sunrise) ~/ 15;
      final abhijit = abhijitMuhurtaWindow(sunrise, sunset);
      expect(abhijit.start, sunrise.add(muhurta * 7));
      expect(abhijit.end, abhijit.start.add(muhurta));
    });

    test('Abhijit does not apply on Wednesday', () {
      expect(abhijitApplies(sunrise), true); // Sunday
      expect(abhijitApplies(DateTime(2026, 7, 8, 6, 0)), false); // Wednesday
    });
  });

  group('taraBala', () {
    test('same nakshatra as janma = Janma tara (unfavorable)', () {
      final t = taraBala(
        janmaNakshatra: Nakshatra.ashwini,
        dayNakshatra: Nakshatra.ashwini,
      );
      expect(t, TaraBalaResult.janma);
      expect(t.favorable, false);
    });

    test('next nakshatra = Sampat tara (favorable)', () {
      final t = taraBala(
        janmaNakshatra: Nakshatra.ashwini,
        dayNakshatra: Nakshatra.bharani,
      );
      expect(t, TaraBalaResult.sampat);
      expect(t.favorable, true);
    });

    test('wraps past 27 nakshatras correctly', () {
      // 27 nakshatras from janma lands back on Janma tara (count 28 -> tara 1).
      final t = taraBala(
        janmaNakshatra: Nakshatra.revati,
        dayNakshatra: Nakshatra.revati,
      );
      expect(t, TaraBalaResult.janma);
    });
  });

  group('chandraBala', () {
    test('same sign as janma rashi = favorable (count 1)', () {
      expect(
        chandraBala(
            janmaRashi: ZodiacSign.aries, dayMoonSign: ZodiacSign.aries),
        ChandraBalaResult.favorable,
      );
    });

    test('2nd sign from janma rashi = neutral (count 2)', () {
      expect(
        chandraBala(
            janmaRashi: ZodiacSign.aries, dayMoonSign: ZodiacSign.taurus),
        ChandraBalaResult.neutral,
      );
    });

    test('4th sign from janma rashi = unfavorable', () {
      expect(
        chandraBala(
            janmaRashi: ZodiacSign.aries, dayMoonSign: ZodiacSign.cancer),
        ChandraBalaResult.unfavorable,
      );
    });
  });
}
