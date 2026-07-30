/// Parashari graha drishti rules. No ephemeris/FFI — planets are placed
/// at chosen longitudes so each aspect can be asserted exactly.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/chart_facts.dart';
import 'package:kaaljyoti/core/astro/graha_drishti.dart';
import 'package:kaaljyoti/core/astro/models.dart';

/// Places each graha at 15° of the given sign.
Map<Planet, PlanetPosition> _at(Map<Planet, ZodiacSign> signs) => {
      for (final e in signs.entries)
        e.key: PlanetPosition(
          planet: e.key,
          longitude: e.value.index * 30 + 15,
          latitude: 0,
          speed: 1,
        ),
    };

/// Ascendant at 15° Aries unless a test needs otherwise, so whole-sign
/// house 1 is Aries.
const _ariesAsc = 15.0;

GrahaDrishtiTable _table(
  Map<Planet, ZodiacSign> signs, {
  bool includeNodes = false,
  double ascendant = _ariesAsc,
}) =>
    GrahaDrishtiTable(
      positions: _at(signs),
      ascendant: ascendant,
      includeNodes: includeNodes,
    );

void main() {
  group('which houses each graha aspects', () {
    test('everyone aspects the 7th', () {
      for (final p in [
        Planet.sun,
        Planet.moon,
        Planet.mercury,
        Planet.venus,
      ]) {
        expect(drishtiHousesOf(p), [7], reason: p.name);
      }
    });

    test('Mars adds 4 and 8', () {
      expect(drishtiHousesOf(Planet.mars), [4, 7, 8]);
    });

    test('Jupiter adds 5 and 9', () {
      expect(drishtiHousesOf(Planet.jupiter), [5, 7, 9]);
    });

    test('Saturn adds 3 and 10', () {
      expect(drishtiHousesOf(Planet.saturn), [3, 7, 10]);
    });

    test('Rahu and Ketu cast nothing by default', () {
      expect(drishtiHousesOf(Planet.rahu), isEmpty);
      expect(drishtiHousesOf(Planet.ketu), isEmpty);
      expect(castsDrishti(Planet.rahu), isFalse);
      expect(castsDrishti(Planet.ketu), isFalse);
    });

    test('opting in gives the nodes 5, 7 and 9', () {
      expect(drishtiHousesOf(Planet.rahu, includeNodes: true), [5, 7, 9]);
      expect(castsDrishti(Planet.ketu, includeNodes: true), isTrue);
    });
  });

  group('counting', () {
    test('is whole-sign and inclusive — own sign is 1, opposite is 7', () {
      expect(drishtiDistance(ZodiacSign.aries.index, ZodiacSign.aries.index), 1);
      expect(drishtiDistance(ZodiacSign.aries.index, ZodiacSign.libra.index), 7);
      expect(
          drishtiDistance(ZodiacSign.aries.index, ZodiacSign.cancer.index), 4);
    });

    test('wraps past Pisces', () {
      // Capricorn +7 → Cancer.
      expect(
          drishtiDistance(ZodiacSign.capricorn.index, ZodiacSign.cancer.index),
          7);
    });
  });

  group('planet-to-planet aspects', () {
    test('the 7th aspect is mutual', () {
      final t = _table({
        Planet.sun: ZodiacSign.aries,
        Planet.moon: ZodiacSign.libra,
      });
      expect(t.aspects(Planet.sun, Planet.moon), isTrue);
      expect(t.aspects(Planet.moon, Planet.sun), isTrue);
      expect(t.mutual(Planet.sun, Planet.moon), isTrue);
    });

    test("Saturn's 3rd and 10th are one-way", () {
      // Saturn in Aries aspects Gemini (3rd) and Capricorn (10th).
      final t = _table({
        Planet.saturn: ZodiacSign.aries,
        Planet.moon: ZodiacSign.gemini,
        Planet.venus: ZodiacSign.capricorn,
      });
      expect(t.aspects(Planet.saturn, Planet.moon), isTrue);
      expect(t.aspects(Planet.saturn, Planet.venus), isTrue);
      // The Moon only has the 7th, and Aries is not 7th from Gemini.
      expect(t.aspects(Planet.moon, Planet.saturn), isFalse);
      expect(t.mutual(Planet.saturn, Planet.moon), isFalse);
    });

    test("Jupiter's 5th and 9th land where expected", () {
      // Jupiter in Aries: 5th = Leo, 9th = Sagittarius.
      final t = _table({
        Planet.jupiter: ZodiacSign.aries,
        Planet.sun: ZodiacSign.leo,
        Planet.mercury: ZodiacSign.sagittarius,
        Planet.venus: ZodiacSign.taurus,
      });
      expect(t.aspects(Planet.jupiter, Planet.sun), isTrue);
      expect(t.aspects(Planet.jupiter, Planet.mercury), isTrue);
      expect(t.aspects(Planet.jupiter, Planet.venus), isFalse,
          reason: 'the 2nd is not a Jupiter aspect');
    });

    test("Mars's 4th and 8th land where expected", () {
      // Mars in Aries: 4th = Cancer, 8th = Scorpio.
      final t = _table({
        Planet.mars: ZodiacSign.aries,
        Planet.moon: ZodiacSign.cancer,
        Planet.saturn: ZodiacSign.scorpio,
        Planet.venus: ZodiacSign.leo,
      });
      expect(t.aspects(Planet.mars, Planet.moon), isTrue);
      expect(t.aspects(Planet.mars, Planet.saturn), isTrue);
      expect(t.aspects(Planet.mars, Planet.venus), isFalse);
    });

    test('conjunction is not drishti', () {
      // Two grahas sharing a sign are distance 1, which must not count.
      final t = _table({
        Planet.sun: ZodiacSign.aries,
        Planet.moon: ZodiacSign.aries,
      });
      expect(t.aspects(Planet.sun, Planet.moon), isFalse);
      expect(t.receivedBy(Planet.moon), isEmpty);
    });

    test('a graha never aspects itself', () {
      final t = _table({Planet.jupiter: ZodiacSign.aries});
      expect(t.castBy(Planet.jupiter), isEmpty);
    });

    test('the nodes receive aspects even though they cast none', () {
      final t = _table({
        Planet.rahu: ZodiacSign.aries,
        Planet.saturn: ZodiacSign.libra,
      });
      expect(t.receivedBy(Planet.rahu).map((d) => d.from), [Planet.saturn]);
      expect(t.castBy(Planet.rahu), isEmpty);
      expect(t.receivedBy(Planet.saturn), isEmpty,
          reason: 'Rahu casts nothing back');
    });

    test('opting in makes the nodes cast', () {
      final t = _table({
        Planet.rahu: ZodiacSign.aries,
        Planet.saturn: ZodiacSign.libra,
      }, includeNodes: true);
      expect(t.aspects(Planet.rahu, Planet.saturn), isTrue);
      expect(t.receivedBy(Planet.saturn).map((d) => d.from), [Planet.rahu]);
    });

    test('each aspect records which drishti it is', () {
      final t = _table({
        Planet.saturn: ZodiacSign.aries,
        Planet.moon: ZodiacSign.gemini,
      });
      // Saturn's 3rd, not its 7th or 10th — the number is the point.
      expect(t.castBy(Planet.saturn).single.distance, 3);
    });

    test('one graha can receive several aspects', () {
      // Moon in Libra receives Sun's 7th (Aries) and Jupiter's 9th
      // (from Aquarius: Aqu→Pis→Ari…→Lib is 9).
      final t = _table({
        Planet.moon: ZodiacSign.libra,
        Planet.sun: ZodiacSign.aries,
        Planet.jupiter: ZodiacSign.aquarius,
      });
      final received = t.receivedBy(Planet.moon);
      expect(received.map((d) => d.from).toSet(), {Planet.sun, Planet.jupiter});
      expect(received.firstWhere((d) => d.from == Planet.jupiter).distance, 9);
    });
  });

  group('house aspects', () {
    test('an empty house still reports the aspects on it', () {
      // Saturn in Aries (house 1) aspects house 10, Capricorn — empty.
      final t = _table({Planet.saturn: ZodiacSign.aries});
      final onTenth = t.onHouse(10);
      expect(onTenth.map((d) => d.from), [Planet.saturn]);
      expect(onTenth.single.distance, 10);
    });

    test('houses are counted from the lagna, not from Aries', () {
      // Ascendant in Cancer → house 1 is Cancer. Sun in Cancer aspects
      // Capricorn, which is house 7 from this lagna.
      final t = _table(
        {Planet.sun: ZodiacSign.cancer},
        ascendant: ZodiacSign.cancer.index * 30 + 15,
      );
      expect(t.onHouse(7).map((d) => d.from), [Planet.sun]);
      expect(t.onHouse(10), isEmpty);
    });

    test('houseOf places a graha correctly from the lagna', () {
      final t = _table(
        {Planet.sun: ZodiacSign.libra},
        ascendant: ZodiacSign.cancer.index * 30 + 15,
      );
      expect(t.houseOf(Planet.sun), 4);
    });
  });

  group('ChartFacts stays in step', () {
    // The yoga engine and the widget must never disagree; ChartFacts
    // delegates to the same rules.
    Map<Planet, PlanetPosition> positions() => _at({
          Planet.saturn: ZodiacSign.aries,
          Planet.moon: ZodiacSign.gemini,
          Planet.sun: ZodiacSign.libra,
          Planet.rahu: ZodiacSign.aries,
          Planet.venus: ZodiacSign.libra,
        });

    test('agrees with the table on every pair', () {
      final facts = ChartFacts(positions: positions(), ascendant: _ariesAsc);
      final table =
          GrahaDrishtiTable(positions: positions(), ascendant: _ariesAsc);
      for (final a in positions().keys) {
        for (final b in positions().keys) {
          expect(facts.aspects(a, b), table.aspects(a, b),
              reason: '${a.name} -> ${b.name}');
        }
      }
    });

    test('nodes cast nothing in the yoga engine', () {
      final facts = ChartFacts(positions: positions(), ascendant: _ariesAsc);
      // Rahu in Aries, Sun in Libra — a 7th that must NOT register.
      expect(facts.aspects(Planet.rahu, Planet.sun), isFalse);
      expect(facts.mutualAspect(Planet.rahu, Planet.sun), isFalse);
    });

    test('the classical aspects still register', () {
      final facts = ChartFacts(positions: positions(), ascendant: _ariesAsc);
      expect(facts.aspects(Planet.saturn, Planet.moon), isTrue,
          reason: "Saturn's 3rd");
      expect(facts.aspects(Planet.saturn, Planet.sun), isTrue,
          reason: "Saturn's 7th");
      expect(facts.mutualAspect(Planet.sun, Planet.saturn), isTrue);
    });
  });
}
