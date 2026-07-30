// Jaimini Sthira dasha golden tests, pinned to Akhila Kumar,
// "Predicting through Jaimini's Sthira Dasha" (Vani Publications; the
// K.N. Rao / Bharatiya Vidya Bhawan method), Introduction pp. 10–27 and
// the Mesha Lagna example chapter (pp. 40–41).
//
// Two charts are verified END TO END against the book's own printed
// tables — Pt. Jawaharlal Nehru (pp. 14–21) and its Example 3
// (pp. 25–27) — graha bala per planet WITH component breakdown, rashi
// bala per sign, Brahma/Rudra/Maheshwara, and the dasha sequence. The
// Mesha Lagna chapter pins the deities and sequence for a third chart.
//
// Known book errata, deliberately NOT reproduced:
// - Nehru's printed Meena rashi bala (240) contradicts the book's own
//   drishti rules, which give 300 (Jupiter aspecting Meena from Dhanu
//   counts on both the lord channel and the Jupiter channel — exactly
//   the double-counting its Example 3 table applies throughout, e.g.
//   Mithuna 430 and Meena 410 there). We assert the rule-derived 300.
// - Its Example 2 is internally inconsistent (the stated karakas
//   contradict its own printed degrees) and is not used.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/dasha/sthira.dart';
import 'package:kaaljyoti/core/astro/jaimini_karaka.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

AstroSnapshot _snapshot({
  required DateTime birthUtc,
  required double ascendant,
  required Map<Planet, double> longs,
}) {
  return AstroSnapshot(
    birth: BirthData(
      dateTimeUtc: birthUtc,
      latitude: 25.45,
      longitude: 81.85,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
    ),
    ayanamsaId: 1,
    ayanamsaValue: 22.5,
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

double _lon(ZodiacSign sign, int deg, int min) =>
    sign.index * 30 + deg + min / 60.0;

/// Pt. Jawaharlal Nehru — 14 Nov 1889, 23:03 IST, Allahabad (book
/// p. 14: chart, longitudes and karaka row printed in full).
final _nehru = _snapshot(
  birthUtc: DateTime.utc(1889, 11, 14, 17, 33),
  ascendant: _lon(ZodiacSign.cancer, 23, 7),
  longs: {
    Planet.sun: _lon(ZodiacSign.scorpio, 0, 15),
    Planet.moon: _lon(ZodiacSign.cancer, 17, 52),
    Planet.mars: _lon(ZodiacSign.virgo, 9, 59),
    Planet.mercury: _lon(ZodiacSign.libra, 17, 8),
    Planet.jupiter: _lon(ZodiacSign.sagittarius, 15, 10),
    Planet.venus: _lon(ZodiacSign.libra, 7, 21),
    Planet.saturn: _lon(ZodiacSign.leo, 10, 47),
    Planet.rahu: _lon(ZodiacSign.gemini, 11, 26),
    Planet.ketu: _lon(ZodiacSign.sagittarius, 11, 26),
  },
);

/// Book Example 3 — female, 1 Nov 1975, 11:35 IST, Sikhandrabad
/// (pp. 25–27: full graha and rashi tables printed).
final _example3 = _snapshot(
  birthUtc: DateTime.utc(1975, 11, 1, 6, 5),
  ascendant: _lon(ZodiacSign.sagittarius, 21, 1),
  longs: {
    Planet.sun: _lon(ZodiacSign.libra, 14, 41),
    Planet.moon: _lon(ZodiacSign.virgo, 12, 47),
    Planet.mars: _lon(ZodiacSign.gemini, 8, 56),
    Planet.mercury: _lon(ZodiacSign.virgo, 28, 32),
    Planet.jupiter: _lon(ZodiacSign.pisces, 23, 43),
    Planet.venus: _lon(ZodiacSign.leo, 28, 14),
    Planet.saturn: _lon(ZodiacSign.cancer, 9, 16),
    Planet.rahu: _lon(ZodiacSign.libra, 28, 16),
    Planet.ketu: _lon(ZodiacSign.aries, 28, 16),
  },
);

/// Mesha Lagna example chapter — male, 16 Nov 1946, 16:30 IST, Delhi
/// (pp. 40–41: karaka row, deities and dasha sequence printed).
final _meshaLagna = _snapshot(
  birthUtc: DateTime.utc(1946, 11, 16, 11, 0),
  ascendant: _lon(ZodiacSign.aries, 14, 10),
  longs: {
    Planet.sun: _lon(ZodiacSign.scorpio, 0, 22),
    Planet.moon: _lon(ZodiacSign.aquarius, 6, 50),
    Planet.mars: _lon(ZodiacSign.scorpio, 13, 54),
    Planet.mercury: _lon(ZodiacSign.scorpio, 11, 56),
    Planet.jupiter: _lon(ZodiacSign.libra, 18, 6),
    Planet.venus: _lon(ZodiacSign.scorpio, 2, 29),
    Planet.saturn: _lon(ZodiacSign.cancer, 15, 53),
    Planet.rahu: _lon(ZodiacSign.taurus, 18, 33),
    Planet.ketu: _lon(ZodiacSign.scorpio, 18, 33),
  },
);

void main() {
  group('Nehru (book pp. 14–21) — full working', () {
    final bala = computeSthiraBala(_nehru);

    test('karakas match the printed row', () {
      expect(bala.karakas[Planet.moon], Karaka.atmakaraka);
      expect(bala.karakas[Planet.mercury], Karaka.amatyakaraka);
      expect(bala.karakas[Planet.jupiter], Karaka.bhratrukaraka);
      expect(bala.karakas[Planet.saturn], Karaka.matrukaraka);
      expect(bala.karakas[Planet.mars], Karaka.putrakaraka);
      expect(bala.karakas[Planet.venus], Karaka.gnatikaraka);
      expect(bala.karakas[Planet.sun], Karaka.darakaraka);
    });

    test('graha bala components and totals match the printed table', () {
      // (Mulatrikonadi, Amsa, Kendradi, Total) per book p. 16 / p. 21.
      const expected = {
        Planet.sun: (40, 10, 40, 90), // friend's house, DK, panaphara
        Planet.moon: (50, 70, 60, 180), // own house, AK, kendra
        Planet.mars: (20, 30, 20, 70), // enemy's house, PK, apoklima
        Planet.mercury: (40, 60, 60, 160), // friend's house, AmK, kendra
        Planet.jupiter: (50, 50, 20, 120), // own sign PAST the
        // moolatrikona degrees — the book's own demonstrated edge case
        Planet.venus: (60, 20, 60, 140), // moolatrikona, GK, kendra
        Planet.saturn: (20, 40, 40, 100), // enemy's house, MK, panaphara
      };
      for (final e in expected.entries) {
        final (m, a, k, t) = e.value;
        expect(bala.mulatrikonadiBala[e.key], m, reason: '${e.key} mula');
        expect(bala.amsaBala[e.key], a, reason: '${e.key} amsa');
        expect(bala.kendradiBala[e.key], k, reason: '${e.key} kendradi');
        expect(bala.grahaBala[e.key], t, reason: '${e.key} total');
      }
    });

    test('rashi bala totals match the printed table (Meena erratum)', () {
      const expected = [
        90, 300, 280, 270, 200, 290, 300, 120, 310, 180, 200,
        // Book prints 240 for Meena, but its own drishti rules — the
        // double lord+Jupiter count its Example 3 applies throughout —
        // give 300. See the file header.
        300,
      ];
      for (var i = 0; i < 12; i++) {
        expect(bala.rashiBala[ZodiacSign.values[i]], expected[i],
            reason: ZodiacSign.values[i].name);
      }
    });

    test('deities: Brahma Mercury, Rudra Saturn, Maheshwara Saturn', () {
      // Lagna Karka 270 beats the 7th (Makara 180); of Karka's 6th/8th/
      // 12th lords, Saturn (8th) is rejected and Mercury 160 beats
      // Jupiter 120. Rudra: 8th lord Saturn 100 beats 2nd lord Sun 90.
      // Maheshwara: 8th from AK Moon's Karka is Kumbha → Saturn.
      expect(bala.brahma, Planet.mercury);
      expect(bala.rudra, Planet.saturn);
      expect(bala.maheshwara, Planet.saturn);
    });

    test('mahadashas run from Tula, direct, 7/8/9 years by modality', () {
      final result = SthiraDashaCalculator().calculate(_nehru);
      final first12 = result.periods.take(12).toList();
      expect(first12.first.start, _nehru.birth.dateTimeUtc);
      // Brahma Mercury sits in Tula; the book's table: Tula 7, Vrischika
      // 8, Dhanu 9, Makara 7, Kumbha 8, Meena 9, then Mesha onward.
      const signs = [
        ZodiacSign.libra, ZodiacSign.scorpio, ZodiacSign.sagittarius,
        ZodiacSign.capricorn, ZodiacSign.aquarius, ZodiacSign.pisces,
        ZodiacSign.aries, ZodiacSign.taurus, ZodiacSign.gemini,
        ZodiacSign.cancer, ZodiacSign.leo, ZodiacSign.virgo, //
      ];
      const years = [7, 8, 9, 7, 8, 9, 7, 8, 9, 7, 8, 9];
      for (var i = 0; i < 12; i++) {
        expect(first12[i].sign, signs[i], reason: 'maha $i');
        final len = first12[i].length.inSeconds / 86400.0 / 365.25;
        expect(len, closeTo(years[i], 0.01), reason: 'maha $i years');
      }
      // The second cycle repeats identically but stops at the 120-year
      // horizon: Tula (96–103), Vrischika (103–111), Dhanu (111–120),
      // and nothing starts at or past age 120 — 15 mahas, not 24.
      expect(result.periods.length, 15);
      expect(result.periods[12].sign, ZodiacSign.libra);
      expect(result.periods.last.sign, ZodiacSign.sagittarius);
      final horizon = DateTime.utc(2009, 11, 14, 17, 33); // birth + 120y
      expect(result.periods.last.end, horizon);
    });

    test('antardashas are whole calendar months from the maha sign', () {
      final result = SthiraDashaCalculator().calculate(_nehru);
      final tula = result.periods.first; // Tula, 7 years
      // Calendar boundaries, like the book's table: 14 Nov 1889 birth →
      // the maha ends 14 Nov 1896, and each 7-month antar runs
      // month-day to month-day (Tula: 14 Nov 1889 – 14 Jun 1890).
      expect(tula.end, DateTime.utc(1896, 11, 14, 17, 33));
      final antars = tula.children;
      expect(antars.length, 12);
      expect(antars.first.sign, ZodiacSign.libra); // own sign FIRST
      expect(antars[1].sign, ZodiacSign.scorpio);
      expect(antars.last.sign, ZodiacSign.virgo);
      expect(antars.last.end, tula.end); // tiles exactly
      expect(antars.first.end, DateTime.utc(1890, 6, 14, 17, 33));
      for (final a in antars) {
        expect(a.start.day, 14, reason: 'calendar month-day boundary');
      }
      // Pratyantars repeat the shape from the antardasha's own sign,
      // as twelve equal parts of the real antar.
      final praty = antars[1].children; // Vrischika antar
      expect(praty.first.sign, ZodiacSign.scorpio);
      expect(praty.length, 12);
      expect(praty.last.end, antars[1].end);
    });
  });

  group('Example 3 (book pp. 25–27) — full working', () {
    final bala = computeSthiraBala(_example3);

    test('graha bala matches, including the past-deep-fall Sun', () {
      // Sun 14°41' Libra is PAST the 10° deep-fall degree: the book
      // scores it enemy's-house 20 ("Exceeds Deepest debilitation
      // point"), not 10. Mercury 28°32' Virgo is past both the deep
      // exaltation degree and the moolatrikona range → own house 50.
      const expected = {
        Planet.sun: 100,
        Planet.moon: 130,
        Planet.mars: 90,
        Planet.mercury: 180,
        Planet.jupiter: 160,
        Planet.venus: 100,
        Planet.saturn: 80,
      };
      for (final e in expected.entries) {
        expect(bala.grahaBala[e.key], e.value, reason: '${e.key}');
      }
      expect(bala.mulatrikonadiBala[Planet.sun], 20);
      expect(bala.mulatrikonadiBala[Planet.mercury], 50);
    });

    test('rashi bala totals match the printed table, all twelve', () {
      const expected = [
        110,
        140,
        430,
        160,
        210,
        440,
        190,
        130,
        400,
        100,
        180,
        410,
      ];
      for (var i = 0; i < 12; i++) {
        expect(bala.rashiBala[ZodiacSign.values[i]], expected[i],
            reason: ZodiacSign.values[i].name);
      }
    });

    test(
        'the 7th house wins the anchor; Brahma Venus, Rudra Moon, '
        'Maheshwara Mars', () {
      // Lagna Dhanu 400 loses to the 7th, Mithuna 430 — the book's one
      // worked example of the 7th-house branch. From Mithuna: 6th lord
      // Mars 90, 8th lord Saturn rejected, 12th lord Venus 100 → Venus.
      expect(
          bala.rashiBala[ZodiacSign.gemini]! >
              bala.rashiBala[ZodiacSign.sagittarius]!,
          isTrue);
      expect(bala.brahma, Planet.venus);
      expect(bala.rudra, Planet.moon); // 8th lord Moon 130 > Saturn 80
      expect(bala.maheshwara, Planet.mars); // 8th from AK Mercury's Virgo
    });

    test('mahadashas run from Simha (Brahma Venus placed there)', () {
      final periods = SthiraDashaCalculator().calculate(_example3).periods;
      expect(periods.first.sign, ZodiacSign.leo);
      final len = periods.first.length.inSeconds / 86400.0 / 365.25;
      expect(len, closeTo(8, 0.01)); // fixed sign → 8 years
      expect(periods[1].sign, ZodiacSign.virgo); // then 9, per the book
    });
  });

  group('Mesha Lagna chapter (book pp. 40–41)', () {
    final bala = computeSthiraBala(_meshaLagna);

    test('karakas match the printed row', () {
      expect(bala.karakas[Planet.jupiter], Karaka.atmakaraka);
      expect(bala.karakas[Planet.saturn], Karaka.amatyakaraka);
      expect(bala.karakas[Planet.mars], Karaka.bhratrukaraka);
      expect(bala.karakas[Planet.mercury], Karaka.matrukaraka);
      expect(bala.karakas[Planet.moon], Karaka.putrakaraka);
      expect(bala.karakas[Planet.venus], Karaka.gnatikaraka);
      expect(bala.karakas[Planet.sun], Karaka.darakaraka);
    });

    test('deities: Brahma Jupiter, Rudra Mars, Maheshwara Venus', () {
      // The chapter's stated graha balas check out here too: 2nd lord
      // Venus 90, 8th lord Mars 140 → Mars is Rudra; Brahma is the 12th
      // lord Jupiter; Maheshwara the 8th from AK Jupiter's Tula → Venus.
      expect(bala.grahaBala[Planet.venus], 90);
      expect(bala.grahaBala[Planet.mars], 140);
      expect(bala.brahma, Planet.jupiter);
      expect(bala.rudra, Planet.mars);
      expect(bala.maheshwara, Planet.venus);
    });

    test(
        'sequence: Tula 7, Vrischika 8, Dhanu 9, Makara 7, Kumbha 8, '
        'Meena 9 — and Makara antars run Makara, Kumbha, Meena…', () {
      final periods = SthiraDashaCalculator().calculate(_meshaLagna).periods;
      const signs = [
        ZodiacSign.libra, ZodiacSign.scorpio, ZodiacSign.sagittarius,
        ZodiacSign.capricorn, ZodiacSign.aquarius, ZodiacSign.pisces, //
      ];
      const years = [7, 8, 9, 7, 8, 9];
      for (var i = 0; i < 6; i++) {
        expect(periods[i].sign, signs[i]);
        final len = periods[i].length.inSeconds / 86400.0 / 365.25;
        expect(len, closeTo(years[i], 0.01));
      }
      final makaraAntars = periods[3].children;
      expect(makaraAntars.first.sign, ZodiacSign.capricorn);
      expect(makaraAntars[1].sign, ZodiacSign.aquarius);
      expect(makaraAntars[2].sign, ZodiacSign.pisces);
      expect(makaraAntars[7].sign, ZodiacSign.leo); // book: "Simha
      // From Dec. 74 to July 75" — the 8th antar of Makara.
    });
  });

  group('mechanics', () {
    test('sthiraYears is 7/8/9 by modality', () {
      expect(sthiraYears(ZodiacSign.aries), 7);
      expect(sthiraYears(ZodiacSign.taurus), 8);
      expect(sthiraYears(ZodiacSign.gemini), 9);
      expect(sthiraYears(ZodiacSign.capricorn), 7);
      expect(sthiraYears(ZodiacSign.aquarius), 8);
      expect(sthiraYears(ZodiacSign.pisces), 9);
    });

    test('Saturn is never Brahma even when strongest', () {
      // Nehru: Saturn (8th lord from the Karka anchor) has 100 units to
      // Sun's 90 — but Brahma comes from the surviving candidates.
      final bala = computeSthiraBala(_nehru);
      expect(bala.brahma, isNot(Planet.saturn));
      // Saturn may still hold the other two posts (it holds both here).
      expect(bala.rudra, Planet.saturn);
      expect(bala.maheshwara, Planet.saturn);
    });
  });
}
