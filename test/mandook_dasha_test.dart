// Jaimini Mandook dasha golden tests, pinned to K.N. Rao, "Predicting
// through Karakamsha & Jaimini's Mandook Dasha" (Vani Publications),
// Section II: Table I (p. 62–63, the sequence for all twelve lagnas)
// and the lagna-by-lagna worked examples (pp. 71–89), whose printed
// dasha years, dates and sub-period tables are asserted here chart by
// chart. Longitudes are the book's own printed degrees. Every printed
// year and boundary reproduces; the book has no errata on this dasha.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/dasha/mandook.dart';
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
      latitude: 28.6,
      longitude: 77.2,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
    ),
    ayanamsaId: 1,
    ayanamsaValue: 23.0,
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

/// Rahu/Ketu are always opposite; the book prints one of them.
Map<Planet, double> _withNodes(Map<Planet, double> longs) {
  final rahu = longs[Planet.rahu] ?? (longs[Planet.ketu]! + 180) % 360;
  return {...longs, Planet.rahu: rahu, Planet.ketu: (rahu + 180) % 360};
}

const _ar = ZodiacSign.aries;
const _ta = ZodiacSign.taurus;
const _ge = ZodiacSign.gemini;
const _cn = ZodiacSign.cancer;
const _le = ZodiacSign.leo;
const _vi = ZodiacSign.virgo;
const _li = ZodiacSign.libra;
const _sc = ZodiacSign.scorpio;
const _sg = ZodiacSign.sagittarius;
const _cp = ZodiacSign.capricorn;
const _aq = ZodiacSign.aquarius;
const _pi = ZodiacSign.pisces;

/// Mesha example (pp. 71–73) — male, 6 Feb 1962, 11:15 IST, 20N30 85E50.
final _mesha = _snapshot(
  birthUtc: DateTime.utc(1962, 2, 6, 5, 45),
  ascendant: _lon(_ar, 23, 43),
  longs: _withNodes({
    Planet.sun: _lon(_cp, 23, 27),
    Planet.moon: _lon(_aq, 10, 40),
    Planet.mars: _lon(_cp, 10, 18),
    Planet.mercury: _lon(_cp, 22, 2),
    Planet.jupiter: _lon(_cp, 25, 36),
    Planet.venus: _lon(_cp, 26, 1),
    Planet.saturn: _lon(_cp, 10, 39),
    Planet.ketu: _lon(_cp, 24, 46),
  }),
);

/// Vrisha example (pp. 74–75) — female, 1 Mar 1954 (time not printed;
/// a morning hour keeps the calendar day, which is all the dasha uses).
final _vrisha = _snapshot(
  birthUtc: DateTime.utc(1954, 3, 1, 3, 0),
  ascendant: _lon(_ta, 26, 20),
  longs: _withNodes({
    Planet.sun: _lon(_aq, 16, 55),
    Planet.moon: _lon(_sg, 25, 39),
    Planet.mars: _lon(_sc, 17, 19),
    Planet.mercury: _lon(_aq, 16, 25),
    Planet.jupiter: _lon(_ta, 23, 47),
    Planet.venus: _lon(_aq, 24, 18),
    Planet.saturn: _lon(_li, 16, 1),
    Planet.ketu: _lon(_ge, 29, 53),
  }),
);

/// Mithuna example (pp. 75–77) — female, 4 Nov 1951.
final _mithuna = _snapshot(
  birthUtc: DateTime.utc(1951, 11, 4, 3, 0),
  ascendant: _lon(_ge, 2, 21),
  longs: _withNodes({
    Planet.sun: _lon(_li, 16, 55),
    Planet.moon: _lon(_sg, 26, 9),
    Planet.mars: _lon(_le, 25, 21),
    Planet.mercury: _lon(_sc, 1, 28),
    Planet.jupiter: _lon(_pi, 12, 14),
    Planet.venus: _lon(_vi, 1, 48),
    Planet.saturn: _lon(_vi, 16, 37),
    Planet.rahu: _lon(_aq, 13, 18),
  }),
);

/// Karka example (pp. 77–79) — female, 1 Aug 1970.
final _karka = _snapshot(
  birthUtc: DateTime.utc(1970, 8, 1, 3, 0),
  ascendant: _lon(_cn, 4, 28),
  longs: _withNodes({
    Planet.sun: _lon(_cn, 14, 53),
    Planet.moon: _lon(_cn, 1, 18),
    Planet.mars: _lon(_cn, 15, 23),
    Planet.mercury: _lon(_le, 7, 27),
    Planet.jupiter: _lon(_li, 4, 46),
    Planet.venus: _lon(_le, 28, 8),
    Planet.saturn: _lon(_ar, 29, 19),
    Planet.rahu: _lon(_aq, 9, 26),
  }),
);

/// Simha example (pp. 79–81) — male, 3 Aug 1971.
final _simha = _snapshot(
  birthUtc: DateTime.utc(1971, 8, 3, 3, 0),
  ascendant: _lon(_le, 29, 25),
  longs: _withNodes({
    Planet.sun: _lon(_cn, 16, 42),
    Planet.moon: _lon(_sc, 29, 22),
    Planet.mars: _lon(_cp, 25, 23),
    Planet.mercury: _lon(_le, 13, 22),
    Planet.jupiter: _lon(_sc, 3, 16),
    Planet.venus: _lon(_cn, 9, 57),
    Planet.saturn: _lon(_ta, 11, 8),
    Planet.rahu: _lon(_cp, 20, 58),
  }),
);

/// Vrischika example (pp. 83–85) — male, 5 Dec 1941.
final _vrischika = _snapshot(
  birthUtc: DateTime.utc(1941, 12, 5, 3, 0),
  ascendant: _lon(_sc, 21, 40),
  longs: _withNodes({
    Planet.sun: _lon(_sc, 19, 29),
    Planet.moon: _lon(_ge, 2, 38),
    Planet.mars: _lon(_pi, 21, 44),
    Planet.mercury: _lon(_sc, 10, 9),
    Planet.jupiter: _lon(_ta, 23, 49),
    Planet.venus: _lon(_cp, 6, 8),
    Planet.saturn: _lon(_ta, 0, 39),
    Planet.ketu: _lon(_aq, 25, 37),
  }),
);

/// Dhanu example (pp. 84–87) — female, 26 Dec 1930, 06:39 IST, 22N35
/// 88E23. The Moon's printed degree is illegible in our copy; its sign
/// (Kumbha) is fixed by the chart and by the book's Karka period.
final _dhanu = _snapshot(
  birthUtc: DateTime.utc(1930, 12, 26, 1, 9),
  ascendant: _lon(_sg, 10, 2),
  longs: _withNodes({
    Planet.sun: _lon(_sg, 10, 38),
    Planet.moon: _lon(_aq, 15, 0),
    Planet.mars: _lon(_cn, 23, 33),
    Planet.mercury: _lon(_sg, 29, 3),
    Planet.jupiter: _lon(_ge, 24, 8),
    Planet.venus: _lon(_sc, 2, 11),
    Planet.saturn: _lon(_sg, 20, 7),
    Planet.rahu: _lon(_pi, 27, 33),
  }),
);

/// Makar example (pp. 87–89) — male, 25 Jan 1953.
final _makar = _snapshot(
  birthUtc: DateTime.utc(1953, 1, 25, 3, 0),
  ascendant: _lon(_cp, 18, 30),
  longs: _withNodes({
    Planet.sun: _lon(_cp, 11, 31),
    Planet.moon: _lon(_ta, 16, 20),
    Planet.mars: _lon(_aq, 20, 6),
    Planet.mercury: _lon(_cp, 5, 30),
    Planet.jupiter: _lon(_ar, 18, 26),
    Planet.venus: _lon(_aq, 28, 18),
    Planet.saturn: _lon(_li, 3, 59),
    Planet.rahu: _lon(_cp, 19, 15),
  }),
);

/// Kumbha example (pp. 88–91) — a boy, 28 Mar 1987.
final _kumbha = _snapshot(
  birthUtc: DateTime.utc(1987, 3, 28, 3, 0),
  ascendant: _lon(_aq, 10, 40),
  longs: _withNodes({
    Planet.sun: _lon(_pi, 13, 6),
    Planet.moon: _lon(_aq, 23, 21),
    Planet.mars: _lon(_ar, 0, 13),
    Planet.mercury: _lon(_aq, 15, 22),
    Planet.jupiter: _lon(_pi, 12, 26),
    Planet.venus: _lon(_aq, 5, 31),
    Planet.saturn: _lon(_sc, 27, 29),
    Planet.rahu: _lon(_pi, 17, 49),
  }),
);

/// Book Table I (pp. 62–63): the full sequence for every lagna.
const _tableOne = <ZodiacSign, List<ZodiacSign>>{
  _ar: [_ar, _cn, _li, _cp, _ta, _le, _sc, _aq, _ge, _vi, _sg, _pi],
  _ta: [_sc, _le, _ta, _aq, _li, _cn, _ar, _cp, _vi, _ge, _pi, _sg],
  _ge: [_ge, _vi, _sg, _pi, _cn, _li, _cp, _ar, _le, _sc, _aq, _ta],
  _cn: [_cp, _li, _cn, _ar, _sg, _vi, _ge, _pi, _sc, _le, _ta, _aq],
  _le: [_le, _sc, _aq, _ta, _vi, _sg, _pi, _ge, _li, _cp, _ar, _cn],
  _vi: [_pi, _sg, _vi, _ge, _aq, _sc, _le, _ta, _cp, _li, _cn, _ar],
  _li: [_li, _cp, _ar, _cn, _sc, _aq, _ta, _le, _sg, _pi, _ge, _vi],
  _sc: [_ta, _aq, _sc, _le, _ar, _cp, _li, _cn, _pi, _sg, _vi, _ge],
  _sg: [_sg, _pi, _ge, _vi, _cp, _ar, _cn, _li, _aq, _ta, _le, _sc],
  _cp: [_cn, _ar, _cp, _li, _ge, _pi, _sg, _vi, _ta, _aq, _sc, _le],
  _aq: [_aq, _ta, _le, _sc, _pi, _ge, _vi, _sg, _ar, _cn, _li, _cp],
  _pi: [_vi, _ge, _pi, _sg, _le, _ta, _aq, _sc, _cn, _ar, _cp, _li],
};

/// Years of the first [expected.length] mahadashas, in order.
void _expectYears(AstroSnapshot snap, List<(ZodiacSign, int)> expected) {
  final periods = MandookDashaCalculator().calculate(snap).periods;
  for (var i = 0; i < expected.length; i++) {
    final (sign, years) = expected[i];
    expect(periods[i].sign, sign, reason: 'maha $i sign');
    expect(mandookYears(sign, snap), years, reason: '$sign years');
    expect(periods[i].end, addCalendarMonthsUtc(periods[i].start, years * 12),
        reason: '$sign calendar span');
  }
}

DateTime addCalendarMonthsUtc(DateTime t, int months) {
  final zeroBased = t.month - 1 + months;
  return DateTime.utc(t.year + zeroBased ~/ 12, zeroBased % 12 + 1, t.day,
      t.hour, t.minute, t.second);
}

void main() {
  group('sequence (Table I)', () {
    test('mandookOrder reproduces the book table for all twelve lagnas', () {
      for (final e in _tableOne.entries) {
        final lagna = e.key;
        final start =
            lagna.isOdd ? lagna : ZodiacSign.values[(lagna.index + 6) % 12];
        expect(mandookOrder(start, direct: lagna.isOdd), e.value,
            reason: '${lagna.western} lagna');
      }
    });

    test('context: odd lagna starts at lagna direct, even at 7th indirect', () {
      final odd = computeMandookContext(_mesha);
      expect(odd.startSign, _ar);
      expect(odd.direct, true);
      final even = computeMandookContext(_vrisha);
      expect(even.startSign, _sc);
      expect(even.direct, false);
    });
  });

  group('applicability (four of seven grahas in kendras)', () {
    test('counts only the seven grahas in the 1st/4th/7th/10th', () {
      // Mesha: six grahas in the 10th (Ketu with them does not count).
      expect(computeMandookContext(_mesha).kendraGrahas, 6);
      // Vrisha: Jupiter in the 1st, Sun/Mercury/Venus in the 10th, Mars
      // in the 7th; Saturn in the 6th and the Moon in the 8th do not.
      expect(computeMandookContext(_vrisha).kendraGrahas, 5);
      // Exactly four still qualifies (Mithuna, Simha, Vrischika, Dhanu,
      // Makar and Kumbha examples all sit at the threshold).
      for (final snap in [
        _mithuna,
        _simha,
        _vrischika,
        _dhanu,
        _makar,
        _kumbha
      ]) {
        expect(computeMandookContext(snap).kendraGrahas, 4);
        expect(computeMandookContext(snap).applicable, true);
      }
      expect(computeMandookContext(_karka).kendraGrahas, 5);
    });

    test('a chart with fewer than four is flagged but still computed', () {
      // Move the Mesha chart's stellium out of the kendra: only the Moon
      // remains, in the 11th, so nothing qualifies.
      final sparse = _snapshot(
        birthUtc: _mesha.birth.dateTimeUtc,
        ascendant: _mesha.ascendant,
        longs: {
          for (final e in _mesha.positions.entries)
            e.key: e.key == Planet.moon ||
                    e.key == Planet.rahu ||
                    e.key == Planet.ketu
                ? e.value.longitude
                : _lon(_sg, 10, 0),
        },
      );
      final ctx = computeMandookContext(sparse);
      expect(ctx.kendraGrahas, 0);
      expect(ctx.applicable, false);
      expect(MandookDashaCalculator().calculate(sparse).periods, isNotEmpty);
    });
  });

  group('Mesha example (odd lagna, direct)', () {
    test('years: Mesha 10, Karka 6, Tula 4, Makar 12 (pp. 72–73)', () {
      _expectYears(_mesha, [(_ar, 10), (_cn, 6), (_li, 4), (_cp, 12)]);
      final periods = MandookDashaCalculator().calculate(_mesha).periods;
      expect(periods[0].start, DateTime.utc(1962, 2, 6, 5, 45));
      expect(periods[0].end, DateTime.utc(1972, 2, 6, 5, 45));
      expect(periods[1].end, DateTime.utc(1978, 2, 6, 5, 45));
      expect(periods[2].end, DateTime.utc(1982, 2, 6, 5, 45));
      expect(periods[3].end, DateTime.utc(1994, 2, 6, 5, 45));
    });

    test('Tula antardashas: 4 months each, frog-leaps from Tula, direct', () {
      final tula = MandookDashaCalculator().calculate(_mesha).periods[2];
      final antars = tula.children;
      expect(antars.map((a) => a.sign).toList(),
          [_li, _cp, _ar, _cn, _sc, _aq, _ta, _le, _sg, _pi, _ge, _vi]);
      // Book: Tula Feb–Jun 1978, Makar to Oct 1978, Mesha to Feb 1979,
      // Karka to Jun 1979, … Simha to Oct 1980, Dhanu from Oct 1980.
      expect(antars[0].end, DateTime.utc(1978, 6, 6, 5, 45));
      expect(antars[1].end, DateTime.utc(1978, 10, 6, 5, 45));
      expect(antars[2].end, DateTime.utc(1979, 2, 6, 5, 45));
      expect(antars[7].end, DateTime.utc(1980, 10, 6, 5, 45));
      expect(antars[8].start, DateTime.utc(1980, 10, 6, 5, 45));
      expect(antars.last.end, tula.end);
    });

    test('Makar antardashas run DIRECT (lagna parity), one year each', () {
      // The book's own table: Makar 1982–83, Mesha 83–84, Karka 84–85,
      // Tula 85–86, Kumbha 86–87 — direct although Makar is even.
      final makar = MandookDashaCalculator().calculate(_mesha).periods[3];
      final antars = makar.children;
      expect(antars.take(5).map((a) => a.sign).toList(),
          [_cp, _ar, _cn, _li, _aq]);
      expect(antars[0].end, DateTime.utc(1983, 2, 6, 5, 45));
      expect(antars[3].end, DateTime.utc(1986, 2, 6, 5, 45));
    });
  });

  group('Vrisha example (even lagna, from the 7th, indirect)', () {
    test('Vrischika 12 (own), Simha 10 (7th rule), Vrisha 4 (pp. 74–75)', () {
      _expectYears(_vrisha, [(_sc, 12), (_le, 10), (_ta, 4)]);
      final periods = MandookDashaCalculator().calculate(_vrisha).periods;
      expect(periods[0].start.year, 1954);
      expect(periods[1].start.year, 1966);
      expect(periods[2].start.year, 1976);
      expect(periods[3].start.year, 1980);
      expect(periods[3].sign, _aq);
    });
  });

  group('Mithuna example (odd lagna)', () {
    test('Mithuna 6, Kanya 11, Dhanu 4, Meena 12, Karka 8 (p. 76)', () {
      _expectYears(
          _mithuna, [(_ge, 6), (_vi, 11), (_sg, 4), (_pi, 12), (_cn, 8)]);
      final periods = MandookDashaCalculator().calculate(_mithuna).periods;
      expect([for (final p in periods.take(5)) p.start.year],
          [1951, 1957, 1968, 1972, 1984]);
      expect(periods[4].end.year, 1992);
    });

    test('Dhanu sub-periods: 4 months each, Dhanu → Meena → … → Vrischika', () {
      final dhanu = MandookDashaCalculator().calculate(_mithuna).periods[2];
      final antars = dhanu.children;
      expect(antars.map((a) => a.sign).toList(),
          [_sg, _pi, _ge, _vi, _cp, _ar, _cn, _li, _aq, _ta, _le, _sc]);
      // Book: Dhanu from Nov 1968, Meena from Mar 1969, Mithuna from Jul
      // 1969, … Vrischika from Jul 1972, ends Nov 1972.
      expect(antars[1].start, DateTime.utc(1969, 3, 4, 3, 0));
      expect(antars[2].start, DateTime.utc(1969, 7, 4, 3, 0));
      expect(antars[11].start, DateTime.utc(1972, 7, 4, 3, 0));
      expect(antars[11].end, DateTime.utc(1972, 11, 4, 3, 0));
    });
  });

  group('Karka example (even lagna)', () {
    test('Makar 10, Tula 11, Karka 12, then Mesha 4 (p. 78)', () {
      // Mesha is not printed: Mars in Karka, the 4th from Mesha → 4.
      _expectYears(_karka, [(_cp, 10), (_li, 11), (_cn, 12), (_ar, 4)]);
      final periods = MandookDashaCalculator().calculate(_karka).periods;
      expect(
          [for (final p in periods.take(3)) p.start.year], [1970, 1980, 1991]);
      expect(periods[2].end.year, 2003);
    });

    test('Karka antardashas run INDIRECT: Karka, then Mesha (p. 79)', () {
      final karka = MandookDashaCalculator().calculate(_karka).periods[2];
      final antars = karka.children;
      expect(antars.take(4).map((a) => a.sign).toList(), [_cn, _ar, _cp, _li]);
      expect(antars[0].start.year, 1991);
      expect(antars[1].start.year, 1992);
    });
  });

  group('Simha example (odd lagna)', () {
    test('Simha 12 (lord in the 12th), Vrischika 11 (p. 79)', () {
      _expectYears(_simha, [(_le, 12), (_sc, 11)]);
    });

    test('Vrischika sub-periods: 11 months each, to Tula Aug 1994 (p. 80)', () {
      final sc = MandookDashaCalculator().calculate(_simha).periods[1];
      final antars = sc.children;
      expect(antars.map((a) => a.sign).toList(),
          [_sc, _aq, _ta, _le, _sg, _pi, _ge, _vi, _cp, _ar, _cn, _li]);
      // Book: Vrischika upto July 1984, Kumbha upto June 1985, … Tula
      // upto August 1994.
      expect(antars[0].end, DateTime.utc(1984, 7, 3, 3, 0));
      expect(antars[1].end, DateTime.utc(1985, 6, 3, 3, 0));
      expect(antars[11].end, DateTime.utc(1994, 8, 3, 3, 0));
    });
  });

  group('Vrischika example (even lagna)', () {
    test('nine printed periods 1941 → 2001 (p. 84)', () {
      _expectYears(_vrischika, [
        (_ta, 5),
        (_aq, 4),
        (_sc, 9),
        (_le, 4),
        (_ar, 12), // Mars in Pisces, the 12th from Aries — 12 years
        (_cp, 9),
        (_li, 4),
        (_cn, 2),
        (_pi, 11),
      ]);
      final periods = MandookDashaCalculator().calculate(_vrischika).periods;
      expect([for (final p in periods.take(9)) p.start.year],
          [1941, 1946, 1950, 1959, 1963, 1975, 1984, 1988, 1990]);
      expect(periods[8].end.year, 2001);
    });
  });

  group('Dhanu example (odd lagna)', () {
    test('7th-house rule twice (Dhanu, Mithuna = 10) and the rest (p. 85)', () {
      _expectYears(_dhanu, [
        (_sg, 10), // Jupiter in Mithuna, the 7th → 10 not 7
        (_pi, 10),
        (_ge, 10), // Mercury in Dhanu, the 7th → 10 not 7
        (_vi, 10),
        (_cp, 2),
        (_ar, 4),
        (_cn, 6),
        (_li, 2),
        (_aq, 11),
      ]);
      final periods = MandookDashaCalculator().calculate(_dhanu).periods;
      expect([for (final p in periods.take(9)) p.start.year],
          [1930, 1940, 1950, 1960, 1970, 1972, 1976, 1982, 1984]);
      expect(periods[8].end.year, 1995);
    });

    test('Meena sub-periods run DIRECT though Meena is even (p. 85)', () {
      final meena = MandookDashaCalculator().calculate(_dhanu).periods[1];
      final antars = meena.children;
      // The fifth leaps from the sign AFTER Meena — Mesha — exactly as
      // the book's Mithuna column continues Ge, Vi, Sg, Pi with Karka.
      expect(antars.take(5).map((a) => a.sign).toList(),
          [_pi, _ge, _vi, _sg, _ar]);
      // Book: Meena upto Oct 1941, Mithuna to Aug 1942, Kanya to June
      // 1943, Dhanu to Apr 1944 — ten months each from Dec 1940.
      expect(antars[0].end, DateTime.utc(1941, 10, 26, 1, 9));
      expect(antars[1].end, DateTime.utc(1942, 8, 26, 1, 9));
      expect(antars[2].end, DateTime.utc(1943, 6, 26, 1, 9));
      expect(antars[3].end, DateTime.utc(1944, 4, 26, 1, 9));
    });
  });

  group('Makar example (even lagna)', () {
    test('Karka 3, Mesha 11, Makar 4, Tula 5, Mithuna 8 (p. 89)', () {
      // Mesha 11: Mars (not the Jupiter sitting in Mesha) is in Kumbha,
      // the 11th counted direct.
      _expectYears(_makar, [(_cn, 3), (_ar, 11), (_cp, 4), (_li, 5), (_ge, 8)]);
      final periods = MandookDashaCalculator().calculate(_makar).periods;
      expect([for (final p in periods.take(5)) p.start.year],
          [1953, 1956, 1967, 1971, 1976]);
      expect(periods[4].end.year, 1984);
    });
  });

  group('Kumbha example (odd lagna)', () {
    test('Kumbha 10 with 10-month sub-periods (p. 89)', () {
      _expectYears(_kumbha, [(_aq, 10)]);
      final kumbha = MandookDashaCalculator().calculate(_kumbha).periods[0];
      final antars = kumbha.children;
      expect(antars.take(6).map((a) => a.sign).toList(),
          [_aq, _ta, _le, _sc, _pi, _ge]);
      // Book: Kumbha March 1987 to January 1988, Vrisha upto November
      // 1988, Simha upto September 1989, Vrischika upto July 1990, Meena
      // upto May 1991, Mithuna upto March 1992.
      expect(antars[0].end, DateTime.utc(1988, 1, 28, 3, 0));
      expect(antars[1].end, DateTime.utc(1988, 11, 28, 3, 0));
      expect(antars[2].end, DateTime.utc(1989, 9, 28, 3, 0));
      expect(antars[3].end, DateTime.utc(1990, 7, 28, 3, 0));
      expect(antars[4].end, DateTime.utc(1991, 5, 28, 3, 0));
      expect(antars[5].end, DateTime.utc(1992, 3, 28, 3, 0));
    });
  });

  group('tree shape', () {
    test('cycle repeats to the 120-year horizon and tiles exactly', () {
      final result = MandookDashaCalculator().calculate(_vrischika);
      final periods = result.periods;
      // First cycle: 5+4+9+4+12+9+4+2+11+6+11+6 = 83 years; the second
      // cycle then runs until a maha would start at or past age 120.
      expect(periods[12].sign, _ta);
      expect(periods[12].start, DateTime.utc(2024, 12, 5, 3, 0));
      final horizon = DateTime.utc(2061, 12, 5, 3, 0);
      expect(periods.last.start.isBefore(horizon), true);
      expect(periods.last.end.isBefore(horizon), false);
      for (var i = 1; i < periods.length; i++) {
        expect(periods[i].start, periods[i - 1].end, reason: 'gap at $i');
      }
    });

    test('pratyantars split the antardasha into twelfths, same order', () {
      final tula = MandookDashaCalculator().calculate(_mesha).periods[2];
      final antar = tula.children[1]; // Makar antardasha
      final pratyantars = antar.children;
      expect(pratyantars.length, 12);
      expect(pratyantars.map((p) => p.sign).take(4).toList(),
          [_cp, _ar, _cn, _li]);
      expect(pratyantars.first.start, antar.start);
      expect(pratyantars.last.end, antar.end);
      expect(pratyantars[11].children.first.children.first.hasChildren, false);
    });
  });
}
