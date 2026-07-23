// Jaimini Chara dasha golden tests, pinned to K.N. Rao, "Predicting
// through Jaimini's Chara Dasha" (Vani Publications), chapters 3, 4, 6:
// - ch. 3: mahadasha ORDER direction per lagna (direct lagna group =
//   Aries, Leo, Virgo, Libra, Aquarius, Pisces; rest indirect).
// - ch. 6: period years = inclusive count from rashi to its lord minus
//   one (forward for Aries, Taurus, Gemini, Libra, Scorpio, Sagittarius;
//   backward for the rest); lord in own rashi → 12; Scorpio/Aquarius
//   dual-lordship special rules (a)–(d).
// - ch. 4: antardasha direction = mahadasha rashi's order group, own
//   rashi last, equal 1/12 division.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/dasha/dasha.dart';
import 'package:kaaljyoti/core/astro/dasha/jaimini.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

AstroSnapshot _snapshot({
  required double ascendant,
  required Map<Planet, double> longs,
}) {
  return AstroSnapshot(
    birth: BirthData(
      dateTimeUtc: DateTime.utc(1990, 1, 1, 6, 0),
      latitude: 28.6,
      longitude: 77.2,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
    ),
    ayanamsaId: 1,
    ayanamsaValue: 24.1,
    positions: {
      for (final e in longs.entries)
        e.key: PlanetPosition(
            planet: e.key, longitude: e.value, latitude: 0, speed: 1),
    },
    ascendant: ascendant,
    houseCusps: List.filled(12, 0.0),
    panchang: computePanchang(
        sunLongitude: 10, moonLongitude: 100, localDateTime: DateTime(1990)),
    yogas: const [],
  );
}

/// Reference chart: every mahadasha length hand-derived from the ch. 6
/// rules (see expectations inline).
const _refLongs = {
  Planet.sun: 135.0, // Leo 15°
  Planet.moon: 195.0, // Libra 15°
  Planet.mars: 45.0, // Taurus 15°
  Planet.mercury: 345.0, // Pisces 15°
  Planet.jupiter: 255.0, // Sagittarius 15°
  Planet.venus: 50.0, // Taurus 20°
  Planet.saturn: 285.0, // Capricorn 15°
  Planet.rahu: 160.0, // Virgo 10°
  Planet.ketu: 350.0, // Pisces 20°
};

int _years(DashaPeriod p) {
  final days = p.length.inSeconds / 86400.0;
  return (days / 365.25).round();
}

void main() {
  final calc = JaiminiCharaCalculator();

  group('mahadasha order direction (ch. 3, Table 1)', () {
    List<ZodiacSign> orderFor(double asc) => calc
        .calculate(_snapshot(ascendant: asc, longs: _refLongs))
        .periods
        .map((p) => p.sign!)
        .toList();

    test('Aries lagna → direct: Aries, Taurus, Gemini…', () {
      expect(orderFor(15).take(4), [
        ZodiacSign.aries,
        ZodiacSign.taurus,
        ZodiacSign.gemini,
        ZodiacSign.cancer,
      ]);
    });

    test('Taurus lagna → indirect: Taurus, Aries, Pisces…', () {
      expect(orderFor(45).take(4), [
        ZodiacSign.taurus,
        ZodiacSign.aries,
        ZodiacSign.pisces,
        ZodiacSign.aquarius,
      ]);
    });

    test('Virgo lagna → direct: Virgo, Libra, Scorpio… (book ill. 2)', () {
      expect(orderFor(165).take(4), [
        ZodiacSign.virgo,
        ZodiacSign.libra,
        ZodiacSign.scorpio,
        ZodiacSign.sagittarius,
      ]);
    });

    test('Leo lagna → direct: Leo, Virgo, Libra…', () {
      expect(orderFor(135).take(3),
          [ZodiacSign.leo, ZodiacSign.virgo, ZodiacSign.libra]);
    });

    test('Scorpio lagna → indirect: Scorpio, Libra, Virgo…', () {
      expect(orderFor(225).take(3),
          [ZodiacSign.scorpio, ZodiacSign.libra, ZodiacSign.virgo]);
    });

    test('Aquarius lagna → direct: Aquarius, Pisces, Aries…', () {
      expect(orderFor(315).take(3),
          [ZodiacSign.aquarius, ZodiacSign.pisces, ZodiacSign.aries]);
    });

    test('Capricorn lagna → indirect: Capricorn, Sagittarius, Scorpio…', () {
      expect(orderFor(285).take(3), [
        ZodiacSign.capricorn,
        ZodiacSign.sagittarius,
        ZodiacSign.scorpio,
      ]);
    });
  });

  group('mahadasha years (ch. 6 counting rules)', () {
    // Reference chart, Aries lagna → direct order. Derivations:
    //   Aries   (fwd)  Mars in Taurus: 2 incl − 1        = 1
    //   Taurus  (fwd)  Venus in own rashi                = 12
    //   Gemini  (fwd)  Mercury in Pisces: 10 incl − 1    = 9
    //   Cancer  (bwd)  Moon in Libra: 10 incl − 1        = 9
    //   Leo     (bwd)  Sun in own rashi                  = 12
    //   Virgo   (bwd)  Mercury in Pisces: 7 incl − 1     = 6
    //   Libra   (fwd)  Venus in Taurus: 8 incl − 1       = 7
    //   Scorpio (fwd)  Mars+1 comp 15° vs Ketu+1 comp 20°
    //                  → Ketu (higher degrees), in Pisces:
    //                  5 incl − 1                        = 4
    //   Sagitt. (fwd)  Jupiter in own rashi              = 12
    //   Capric. (bwd)  Saturn in own rashi               = 12
    //   Aquar.  (bwd)  Saturn alone 15° vs Rahu alone 10°
    //                  → Saturn, in Capricorn: 2 incl − 1 = 1
    //   Pisces  (bwd)  Jupiter in Sagittarius: 4 incl − 1 = 3
    test('reference chart matches hand-computed table', () {
      final result =
          calc.calculate(_snapshot(ascendant: 15, longs: _refLongs));
      final years = {
        for (final p in result.periods) p.sign!: _years(p),
      };
      expect(years, {
        ZodiacSign.aries: 1,
        ZodiacSign.taurus: 12,
        ZodiacSign.gemini: 9,
        ZodiacSign.cancer: 9,
        ZodiacSign.leo: 12,
        ZodiacSign.virgo: 6,
        ZodiacSign.libra: 7,
        ZodiacSign.scorpio: 4,
        ZodiacSign.sagittarius: 12,
        ZodiacSign.capricorn: 12,
        ZodiacSign.aquarius: 1,
        ZodiacSign.pisces: 3,
      });
    });

    test('every rashi gets 1–12 years, never 0 (ch. 6 note 1)', () {
      final result =
          calc.calculate(_snapshot(ascendant: 15, longs: _refLongs));
      for (final p in result.periods) {
        expect(_years(p), inInclusiveRange(1, 12), reason: '${p.sign}');
      }
    });
  });

  group('book model horoscopes (ch. 6 illustrations)', () {
    // Charts reconstructed from the illustration tables: each row gives
    // the lord's counted placement, so the signs are fully determined
    // (cross-checked: shared lords like Mercury/Venus/Jupiter must
    // satisfy both their rashis' rows, and the Scorpio/Aquarius notes
    // must match the resulting occupancies — all consistent).

    Map<ZodiacSign, int> yearsFor(double asc, Map<Planet, double> longs) {
      final result = calc.calculate(_snapshot(ascendant: asc, longs: longs));
      return {for (final p in result.periods) p.sign!: _years(p)};
    }

    test('Illustration One: Aries lagna, 1940+… year table (p. 41-42)', () {
      // Sun/Jupiter/Saturn Aries, Mars+Venus Taurus, Moon Libra,
      // Mercury Pisces, Ketu Pisces 26°32' (> Mars → Ketu seen for
      // Scorpio), Rahu Virgo (alone → Saturn, with 2 companions, seen
      // for Aquarius).
      final years = yearsFor(15, {
        Planet.sun: 15.0,
        Planet.moon: 195.0,
        Planet.mars: 40.0, // Taurus 10°
        Planet.mercury: 335.0,
        Planet.jupiter: 20.0,
        Planet.venus: 35.0,
        Planet.saturn: 10.0,
        Planet.rahu: 165.0,
        Planet.ketu: 356.53, // Pisces 26°32'
      });
      expect(years, {
        ZodiacSign.aries: 1,
        ZodiacSign.taurus: 12,
        ZodiacSign.gemini: 9,
        ZodiacSign.cancer: 9,
        ZodiacSign.leo: 4,
        ZodiacSign.virgo: 6,
        ZodiacSign.libra: 7,
        ZodiacSign.scorpio: 4,
        ZodiacSign.sagittarius: 4,
        ZodiacSign.capricorn: 9,
        ZodiacSign.aquarius: 10,
        ZodiacSign.pisces: 11,
      });
      // Book: 1940→1941→1953→…→2026, i.e. one 86-year cycle.
      expect(years.values.reduce((a, b) => a + b), 86);
    });

    test('Illustration Two: Virgo lagna, 1951+… year table (p. 42-43)', () {
      // Sun Cancer, Moon+Jupiter Pisces, Mars Gemini (alone),
      // Mercury+Venus+Ketu Leo (Ketu stronger for Scorpio),
      // Saturn Virgo, Rahu in Aquarius ITSELF → ignored, count to
      // Saturn (occupancy rule b).
      final years = yearsFor(165, {
        Planet.sun: 105.0,
        Planet.moon: 345.0,
        Planet.mars: 75.0,
        Planet.mercury: 125.0,
        Planet.jupiter: 340.0,
        Planet.venus: 130.0,
        Planet.saturn: 165.0,
        Planet.rahu: 315.0,
        Planet.ketu: 145.0,
      });
      expect(years, {
        ZodiacSign.virgo: 1,
        ZodiacSign.libra: 10,
        ZodiacSign.scorpio: 9,
        ZodiacSign.sagittarius: 3,
        ZodiacSign.capricorn: 4,
        ZodiacSign.aquarius: 5,
        ZodiacSign.pisces: 12,
        ZodiacSign.aries: 2,
        ZodiacSign.taurus: 3,
        ZodiacSign.gemini: 2,
        ZodiacSign.cancer: 4,
        ZodiacSign.leo: 1,
      });
      // Virgo lagna is a DIRECT lagna: Virgo, Libra, Scorpio…
      final order = calc
          .calculate(_snapshot(ascendant: 165, longs: {
            Planet.sun: 105.0,
            Planet.moon: 345.0,
            Planet.mars: 75.0,
            Planet.mercury: 125.0,
            Planet.jupiter: 340.0,
            Planet.venus: 130.0,
            Planet.saturn: 165.0,
            Planet.rahu: 315.0,
            Planet.ketu: 145.0,
          }))
          .periods
          .map((p) => p.sign!)
          .toList();
      expect(order.take(3),
          [ZodiacSign.virgo, ZodiacSign.libra, ZodiacSign.scorpio]);
      expect(order.last, ZodiacSign.leo);
    });

    test('Illustration Three: Virgo lagna year table (p. 43-44)', () {
      // Sun+Mercury+Venus Aquarius, Moon+Mars Taurus (Mars stronger
      // than lone Ketu for Scorpio), Jupiter Scorpio, Saturn
      // Sagittarius 10° alone, Rahu Virgo 15° alone (higher degree →
      // Rahu seen for Aquarius), Ketu Pisces.
      final years = yearsFor(165, {
        Planet.sun: 315.0,
        Planet.moon: 40.0,
        Planet.mars: 45.0,
        Planet.mercury: 310.0,
        Planet.jupiter: 220.0,
        Planet.venus: 320.0,
        Planet.saturn: 250.0, // Sagittarius 10°
        Planet.rahu: 165.0, // Virgo 15°
        Planet.ketu: 345.0,
      });
      expect(years, {
        ZodiacSign.virgo: 7,
        ZodiacSign.libra: 4,
        ZodiacSign.scorpio: 6,
        ZodiacSign.sagittarius: 11,
        ZodiacSign.capricorn: 1,
        ZodiacSign.aquarius: 5,
        ZodiacSign.pisces: 4,
        ZodiacSign.aries: 1,
        ZodiacSign.taurus: 9,
        ZodiacSign.gemini: 8,
        ZodiacSign.cancer: 2,
        ZodiacSign.leo: 6,
      });
    });
  });

  group('Scorpio/Aquarius special rules (ch. 6)', () {
    int scorpioYears(Map<Planet, double> overrides) {
      final longs = Map<Planet, double>.from(_refLongs)..addAll(overrides);
      final result = calc.calculate(_snapshot(ascendant: 15, longs: longs));
      return _years(
          result.periods.firstWhere((p) => p.sign == ZodiacSign.scorpio));
    }

    test('(a) Mars in Scorpio, Ketu elsewhere → count to Ketu', () {
      // Ketu in Cancer; Scorpio counts forward: 9 incl − 1 = 8.
      expect(
          scorpioYears({Planet.mars: 220.0, Planet.ketu: 105.0}), 8);
    });

    test('(b) Ketu in Scorpio, Mars elsewhere → count to Mars', () {
      // Mars in Cancer; forward: 9 incl − 1 = 8.
      expect(
          scorpioYears({Planet.ketu: 225.0, Planet.mars: 100.0}), 8);
    });

    test('(c) both in Scorpio → full 12 years', () {
      expect(
          scorpioYears({Planet.mars: 220.0, Planet.ketu: 225.0}), 12);
    });

    test('(d) both outside → stronger co-lord counts', () {
      // Reference chart already exercises the tie-break by degrees
      // (Ketu 20° beats Mars 15°, both with one companion) → 4 years.
      expect(scorpioYears(const {}), 4);
    });

    test('Aquarius (a): Saturn in Aquarius → count to Rahu', () {
      final longs = Map<Planet, double>.from(_refLongs)
        ..addAll({Planet.saturn: 315.0, Planet.rahu: 75.0});
      final result = calc.calculate(_snapshot(ascendant: 15, longs: longs));
      // Rahu in Gemini; Aquarius counts backward: 9 incl − 1 = 8.
      expect(
          _years(result.periods
              .firstWhere((p) => p.sign == ZodiacSign.aquarius)),
          8);
    });
  });

  group('antardasha order (ch. 4)', () {
    List<ZodiacSign> subsOf(ZodiacSign maha) {
      final result =
          calc.calculate(_snapshot(ascendant: 15, longs: _refLongs));
      return result.periods
          .firstWhere((p) => p.sign == maha)
          .children
          .map((p) => p.sign!)
          .toList();
    }

    test('Leo maha (direct) → Virgo first … Leo last', () {
      final subs = subsOf(ZodiacSign.leo);
      expect(subs.first, ZodiacSign.virgo);
      expect(subs[1], ZodiacSign.libra);
      expect(subs.last, ZodiacSign.leo);
    });

    test('Taurus maha (indirect) → Aries, Pisces … Taurus last', () {
      final subs = subsOf(ZodiacSign.taurus);
      expect(subs.first, ZodiacSign.aries);
      expect(subs[1], ZodiacSign.pisces);
      expect(subs.last, ZodiacSign.taurus);
    });

    test('own rashi always last, 12 equal sub-periods', () {
      final result =
          calc.calculate(_snapshot(ascendant: 15, longs: _refLongs));
      for (final maha in result.periods) {
        final subs = maha.children;
        expect(subs.length, 12);
        expect(subs.last.sign, maha.sign, reason: '${maha.sign}');
        final expected = maha.length.inSeconds / 12;
        for (final s in subs) {
          expect(s.length.inSeconds, closeTo(expected, 2),
              reason: '${maha.sign} > ${s.sign}');
        }
      }
    });
  });
}
