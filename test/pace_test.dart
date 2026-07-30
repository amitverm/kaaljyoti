/// PACE — Position, Aspect, Conjunction, Exchange. No ephemeris/FFI;
/// grahas are placed at chosen signs so every channel can be asserted.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/planet_token.dart' show dignityMark;
import 'package:kaaljyoti/core/astro/dignity.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/pace.dart';

Map<Planet, PlanetPosition> _at(Map<Planet, ZodiacSign> signs) => {
      for (final e in signs.entries)
        e.key: PlanetPosition(
          planet: e.key,
          longitude: e.value.index * 30 + 15,
          latitude: 0,
          speed: 1,
        ),
    };

PaceTable _table(
  Map<Planet, ZodiacSign> signs, {
  ZodiacSign lagna = ZodiacSign.aries,
  bool includeNodes = false,
}) =>
    PaceTable(
      positions: _at(signs),
      ascendant: lagna.index * 30 + 15,
      includeNodes: includeNodes,
    );

void main() {
  group('bhava nature', () {
    test('a house can be several natures at once', () {
      // The 1st is both kendra and trikona; the 10th kendra and upachaya.
      expect(bhavaNatureOf(1), {BhavaNature.kendra, BhavaNature.trikona});
      expect(bhavaNatureOf(10), {BhavaNature.kendra, BhavaNature.upachaya});
    });

    test('dusthanas and plain houses', () {
      expect(bhavaNatureOf(8), {BhavaNature.dusthana});
      expect(bhavaNatureOf(6), {BhavaNature.dusthana, BhavaNature.upachaya});
      expect(bhavaNatureOf(2), isEmpty);
    });
  });

  group('position', () {
    test('carries dignity and bhava nature, not bare coordinates', () {
      // Sun in Aries is exalted; with an Aries lagna that is house 1.
      final e = _table({Planet.sun: ZodiacSign.aries}).entryFor(Planet.sun)!;
      expect(e.position.dignity, PlanetDignity.exalted);
      expect(e.position.house, 1);
      expect(e.position.nature,
          {BhavaNature.kendra, BhavaNature.trikona});
    });

    test('debilitation is picked up', () {
      // Sun debilitated in Libra.
      final e = _table({Planet.sun: ZodiacSign.libra}).entryFor(Planet.sun)!;
      expect(e.position.dignity, PlanetDignity.debilitated);
    });

    test('own sign is picked up', () {
      final e = _table({Planet.mars: ZodiacSign.scorpio})
          .entryFor(Planet.mars)!;
      expect(e.position.dignity, PlanetDignity.ownSign);
    });

    test('houses count from the lagna, not from Aries', () {
      final e = _table(
        {Planet.sun: ZodiacSign.libra},
        lagna: ZodiacSign.cancer,
      ).entryFor(Planet.sun)!;
      expect(e.position.house, 4);
      expect(e.position.nature, contains(BhavaNature.kendra));
    });

    test('nodes carry no dignity, by design', () {
      final e = _table({Planet.rahu: ZodiacSign.aries}).entryFor(Planet.rahu)!;
      expect(e.position.dignity, PlanetDignity.none);
    });
  });

  group('lordship', () {
    test('a graha lords both of its signs', () {
      // Mars lords Aries (H1) and Scorpio (H8) from an Aries lagna.
      final e = _table({Planet.mars: ZodiacSign.leo}).entryFor(Planet.mars)!;
      expect(e.position.lordOf, [1, 8]);
    });

    test('the luminaries lord one house each', () {
      final t = _table({
        Planet.sun: ZodiacSign.aries,
        Planet.moon: ZodiacSign.aries,
      });
      // Leo is H5 and Cancer H4 from an Aries lagna.
      expect(t.entryFor(Planet.sun)!.position.lordOf, [5]);
      expect(t.entryFor(Planet.moon)!.position.lordOf, [4]);
    });

    test('lordship shifts with the lagna', () {
      final e = _table(
        {Planet.mars: ZodiacSign.leo},
        lagna: ZodiacSign.cancer,
      ).entryFor(Planet.mars)!;
      // From Cancer: Aries is H10, Scorpio H5.
      expect(e.position.lordOf, [5, 10]);
    });

    test('the nodes lord nothing', () {
      final e = _table({Planet.rahu: ZodiacSign.aries}).entryFor(Planet.rahu)!;
      expect(e.position.lordOf, isEmpty);
    });
  });

  group('bhava lords', () {
    Map<Planet, ZodiacSign> fullSet() => {
          Planet.sun: ZodiacSign.leo,
          Planet.moon: ZodiacSign.cancer,
          Planet.mars: ZodiacSign.aries,
          Planet.mercury: ZodiacSign.gemini,
          Planet.jupiter: ZodiacSign.pisces,
          Planet.venus: ZodiacSign.taurus,
          Planet.saturn: ZodiacSign.capricorn,
        };

    test('covers all twelve houses in order', () {
      final lords = _table(fullSet()).bhavaLords;
      expect(lords, hasLength(12));
      expect(lords.map((b) => b.house), List.generate(12, (i) => i + 1));
    });

    test('names the right lord for each house', () {
      final lords = _table(fullSet()).bhavaLords;
      // Aries lagna: H1 Aries/Mars, H2 Taurus/Venus, H7 Libra/Venus.
      expect(lords[0].lord, Planet.mars);
      expect(lords[1].lord, Planet.venus);
      expect(lords[6].lord, Planet.venus);
    });

    test('reports where the lord actually went', () {
      // Aries lagna, Mars in Aries → the 1st lord sits in the 1st.
      final lords = _table(fullSet()).bhavaLords;
      expect(lords[0].lordHouse, 1);
      expect(lords[0].isInOwnBhava, isTrue);
      // H2 Taurus, lord Venus in Taurus → also its own bhava.
      expect(lords[1].isInOwnBhava, isTrue);
    });

    test('a displaced lord is not flagged as being in its own bhava', () {
      final lords = _table({
        ...fullSet(),
        Planet.mars: ZodiacSign.libra, // 1st lord to the 7th
      }).bhavaLords;
      expect(lords[0].lordHouse, 7);
      expect(lords[0].isInOwnBhava, isFalse);
    });

    test('a lord missing from the chart is skipped, not guessed', () {
      // A partial chart must not crash the card.
      final lords = _table({Planet.mars: ZodiacSign.aries}).bhavaLords;
      expect(lords.map((b) => b.lord).toSet(), {Planet.mars});
      expect(lords, hasLength(2), reason: 'Mars lords H1 and H8');
    });

    test('agrees with the graha-first view', () {
      final t = _table(fullSet());
      for (final b in t.bhavaLords) {
        expect(t.entryFor(b.lord)!.position.lordOf, contains(b.house),
            reason: 'H${b.house} lord ${b.lord.name}');
      }
    });
  });

  group('conjunction', () {
    test('grahas sharing a sign are conjunct, both ways', () {
      final t = _table({
        Planet.sun: ZodiacSign.aries,
        Planet.moon: ZodiacSign.aries,
        Planet.saturn: ZodiacSign.libra,
      });
      expect(t.entryFor(Planet.sun)!.conjunctWith, [Planet.moon]);
      expect(t.entryFor(Planet.moon)!.conjunctWith, [Planet.sun]);
      expect(t.entryFor(Planet.saturn)!.conjunctWith, isEmpty);
    });

    test('three in a sign each see the other two', () {
      final t = _table({
        Planet.sun: ZodiacSign.aries,
        Planet.moon: ZodiacSign.aries,
        Planet.mercury: ZodiacSign.aries,
      });
      expect(t.entryFor(Planet.mercury)!.conjunctWith,
          containsAll([Planet.sun, Planet.moon]));
    });
  });

  group('exchange', () {
    test('parivartana is detected both ways', () {
      // Mars in Venus's Taurus, Venus in Mars's Aries.
      final t = _table({
        Planet.mars: ZodiacSign.taurus,
        Planet.venus: ZodiacSign.aries,
      });
      expect(t.entryFor(Planet.mars)!.exchangeWith, Planet.venus);
      expect(t.entryFor(Planet.venus)!.exchangeWith, Planet.mars);
      expect(t.hasExchange, isTrue);
    });

    test('each exchange pair is listed once', () {
      final t = _table({
        Planet.mars: ZodiacSign.taurus,
        Planet.venus: ZodiacSign.aries,
      });
      expect(t.exchanges, hasLength(1));
    });

    test('most charts have none', () {
      final t = _table({
        Planet.sun: ZodiacSign.aries,
        Planet.moon: ZodiacSign.taurus,
      });
      expect(t.hasExchange, isFalse);
      expect(t.exchanges, isEmpty);
      expect(t.entryFor(Planet.sun)!.exchangeWith, isNull);
    });
  });

  group('aspect channel', () {
    test('reuses graha drishti, including the aspect number', () {
      // Saturn in Aries throws its 3rd onto Gemini.
      final t = _table({
        Planet.saturn: ZodiacSign.aries,
        Planet.moon: ZodiacSign.gemini,
      });
      final moon = t.entryFor(Planet.moon)!;
      expect(moon.aspectedBy.single.from, Planet.saturn);
      expect(moon.aspectedBy.single.distance, 3);
    });

    test('nodes cast nothing by default but still receive', () {
      final t = _table({
        Planet.rahu: ZodiacSign.aries,
        Planet.saturn: ZodiacSign.libra,
      });
      expect(t.entryFor(Planet.rahu)!.aspectedBy.map((d) => d.from),
          [Planet.saturn]);
      expect(t.entryFor(Planet.saturn)!.aspectedBy, isEmpty);
    });

    test('opting in lets the nodes cast', () {
      final t = _table({
        Planet.rahu: ZodiacSign.aries,
        Planet.saturn: ZodiacSign.libra,
      }, includeNodes: true);
      expect(t.entryFor(Planet.saturn)!.aspectedBy.map((d) => d.from),
          [Planet.rahu]);
    });
  });

  group('entry summary', () {
    test('an untouched graha is flagged', () {
      // Sun alone in Aries: nothing to aspect it, nothing conjunct.
      final t = _table({Planet.sun: ZodiacSign.aries});
      expect(t.entryFor(Planet.sun)!.isUntouched, isTrue);
      expect(t.entryFor(Planet.sun)!.influenceCount, 0);
    });

    test('a busy graha counts every channel', () {
      // Moon in Aries: conjunct Sun, aspected by Saturn from Libra (7th),
      // and in exchange is not possible here — so 1 + 1.
      final t = _table({
        Planet.moon: ZodiacSign.aries,
        Planet.sun: ZodiacSign.aries,
        Planet.saturn: ZodiacSign.libra,
      });
      final moon = t.entryFor(Planet.moon)!;
      expect(moon.isUntouched, isFalse);
      expect(moon.conjunctWith, [Planet.sun]);
      expect(moon.aspectedBy.map((d) => d.from), [Planet.saturn]);
      expect(moon.influenceCount, 2);
    });

    test('exchange counts toward the influence total', () {
      final t = _table({
        Planet.mars: ZodiacSign.taurus,
        Planet.venus: ZodiacSign.aries,
      });
      // Taurus and Aries are adjacent — no aspect, no conjunction, so the
      // exchange is the only influence.
      expect(t.entryFor(Planet.mars)!.influenceCount, 1);
    });

    test('entries come back in canonical graha order', () {
      final t = _table({
        Planet.saturn: ZodiacSign.aries,
        Planet.sun: ZodiacSign.taurus,
        Planet.moon: ZodiacSign.gemini,
      });
      expect(t.entries.map((e) => e.graha),
          [Planet.sun, Planet.moon, Planet.saturn]);
    });
  });

  group('dignity glyphs', () {
    test('match the chart\'s own visual language', () {
      // Shared from planet_token.dart so the PACE card and the chart
      // can never show different marks for the same dignity.
      expect(dignityMark(PlanetDignity.exalted)?.glyph, '\u2191');
      expect(dignityMark(PlanetDignity.debilitated)?.glyph, '\u2193');
      expect(dignityMark(PlanetDignity.ownSign)?.glyph, '\u25cb');
      expect(dignityMark(PlanetDignity.none), isNull);
    });

    test('own sign inherits the surrounding muted colour', () {
      expect(dignityMark(PlanetDignity.ownSign)?.color, isNull);
      expect(dignityMark(PlanetDignity.exalted)?.color, isNotNull);
      expect(dignityMark(PlanetDignity.debilitated)?.color, isNotNull);
    });
  });
}
