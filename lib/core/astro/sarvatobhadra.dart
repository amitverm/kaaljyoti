/// Sarvatobhadra Chakra (SBC) — the fixed 9×9 = 81-cell transit grid:
/// 28 nakshatras (7 per border side, clockwise from the NE corner),
/// 16 vowels on the two diagonals, 20 consonants in the second ring,
/// 12 rashis in the fourth ring, and the 5 weekday+tithi-group cells
/// at the center.
///
/// Layout verified against the worked vedha examples in P.V.R.
/// Narasimha Rao's SBC chapter (Saturn in Punarvasu: across row → ha,
/// Cancer, au, Mon/Wed·Bhadra, am, Scorpio, ya, Mula; NW diagonal →
/// ka, Taurus, Aries, da, P.Bhadrapada; SW diagonal → Da, ma,
/// U.Phalguni) and the Wikipedia/Ojha table.
///
/// Vedha: a planet in a border nakshatra pierces three lines into the
/// grid — straight across, the forward (zodiacal) diagonal and the
/// rear (anti-zodiacal) diagonal. Across is strongest at normal
/// speed, forward when fast (always for Sun/Moon), rear when
/// retrograde (always for the nodes). v1 collects all three lines and
/// leaves the motion-weighting to the reader (noted per planet).
library;

import 'models.dart';
import 'nakshatra28.dart';

enum SbcCellType { nakshatra, rashi, vowel, consonant, tithiVara }

class SbcCell {
  const SbcCell.nak(this.nak28)
      : type = SbcCellType.nakshatra,
        label = '',
        rashi = null;
  const SbcCell.sign(this.rashi)
      : type = SbcCellType.rashi,
        label = '',
        nak28 = null;
  const SbcCell.vowel(this.label)
      : type = SbcCellType.vowel,
        nak28 = null,
        rashi = null;
  const SbcCell.consonant(this.label)
      : type = SbcCellType.consonant,
        nak28 = null,
        rashi = null;
  const SbcCell.tithiVara(this.label)
      : type = SbcCellType.tithiVara,
        nak28 = null,
        rashi = null;

  final SbcCellType type;
  final String label; // vowels/consonants romanized; tithiVara 'Fri·Rikta'
  final int? nak28;
  final ZodiacSign? rashi;

  String display() => switch (type) {
        SbcCellType.nakshatra => Nakshatra28.abbrs[nak28!],
        SbcCellType.rashi => rashi!.western.substring(0, 3),
        _ => label,
      };
}

// Nakshatra 28-indices by grid walk. Top row left→right c1..c7:
// Dhanishta(23) … Bharani(1); right col r1..r7: Krittika(2) …
// Ashlesha(8); bottom row c7..c1: Magha(9) … Vishakha(15); left col
// r7..r1: Anuradha(16) … Shravana(22).
const List<List<SbcCell>> sbcGrid = [
  // r0
  [
    SbcCell.vowel('ī'),
    SbcCell.nak(23),
    SbcCell.nak(24),
    SbcCell.nak(25),
    SbcCell.nak(26),
    SbcCell.nak(27),
    SbcCell.nak(0),
    SbcCell.nak(1),
    SbcCell.vowel('a'),
  ],
  // r1
  [
    SbcCell.nak(22),
    SbcCell.vowel('ṝ'),
    SbcCell.consonant('ga'),
    SbcCell.consonant('sa'),
    SbcCell.consonant('da'),
    SbcCell.consonant('cha'),
    SbcCell.consonant('la'),
    SbcCell.vowel('u'),
    SbcCell.nak(2),
  ],
  // r2  (r2c7 'chha': sources differ on this one consonant cell —
  // confirm against Parashar Light's SBC if it matters for name-vedha.)
  [
    SbcCell.nak(21),
    SbcCell.consonant('kha'),
    SbcCell.vowel('ai'),
    SbcCell.sign(ZodiacSign.aquarius),
    SbcCell.sign(ZodiacSign.pisces),
    SbcCell.sign(ZodiacSign.aries),
    SbcCell.vowel('ḷ'),
    SbcCell.consonant('chha'),
    SbcCell.nak(3),
  ],
  // r3
  [
    SbcCell.nak(20),
    SbcCell.consonant('ja'),
    SbcCell.sign(ZodiacSign.capricorn),
    SbcCell.vowel('aḥ'),
    SbcCell.tithiVara('Fri·Rikta'),
    SbcCell.vowel('o'),
    SbcCell.sign(ZodiacSign.taurus),
    SbcCell.consonant('va'),
    SbcCell.nak(4),
  ],
  // r4
  [
    SbcCell.nak(19),
    SbcCell.consonant('bha'),
    SbcCell.sign(ZodiacSign.sagittarius),
    SbcCell.tithiVara('Thu·Jaya'),
    SbcCell.tithiVara('Sat·Purna'),
    SbcCell.tithiVara('Sun/Tue·Nanda'),
    SbcCell.sign(ZodiacSign.gemini),
    SbcCell.consonant('ka'),
    SbcCell.nak(5),
  ],
  // r5
  [
    SbcCell.nak(18),
    SbcCell.consonant('ya'),
    SbcCell.sign(ZodiacSign.scorpio),
    SbcCell.vowel('aṁ'),
    SbcCell.tithiVara('Mon/Wed·Bhadra'),
    SbcCell.vowel('au'),
    SbcCell.sign(ZodiacSign.cancer),
    SbcCell.consonant('ha'),
    SbcCell.nak(6),
  ],
  // r6
  [
    SbcCell.nak(17),
    SbcCell.consonant('na'),
    SbcCell.vowel('e'),
    SbcCell.sign(ZodiacSign.libra),
    SbcCell.sign(ZodiacSign.virgo),
    SbcCell.sign(ZodiacSign.leo),
    SbcCell.vowel('ḹ'),
    SbcCell.consonant('Da'),
    SbcCell.nak(7),
  ],
  // r7
  [
    SbcCell.nak(16),
    SbcCell.vowel('ṛ'),
    SbcCell.consonant('ta'),
    SbcCell.consonant('ra'),
    SbcCell.consonant('pa'),
    SbcCell.consonant('Ta'),
    SbcCell.consonant('ma'),
    SbcCell.vowel('ū'),
    SbcCell.nak(8),
  ],
  // r8
  [
    SbcCell.vowel('i'),
    SbcCell.nak(15),
    SbcCell.nak(14),
    SbcCell.nak(13),
    SbcCell.nak(12),
    SbcCell.nak(11),
    SbcCell.nak(10),
    SbcCell.nak(9),
    SbcCell.vowel('ā'),
  ],
];

/// (row, col) of each 28-nakshatra index in [sbcGrid].
final Map<int, (int, int)> sbcNakCell = () {
  final map = <int, (int, int)>{};
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final cell = sbcGrid[r][c];
      if (cell.type == SbcCellType.nakshatra) map[cell.nak28!] = (r, c);
    }
  }
  return map;
}();

/// (row, col) of each rashi in [sbcGrid].
final Map<ZodiacSign, (int, int)> sbcRashiCell = () {
  final map = <ZodiacSign, (int, int)>{};
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final cell = sbcGrid[r][c];
      if (cell.type == SbcCellType.rashi) map[cell.rashi!] = (r, c);
    }
  }
  return map;
}();

/// Weekday+tithi cell for a 0-based tithi index (0–29): groups repeat
/// Nanda, Bhadra, Jaya, Rikta, Purna.
(int, int) sbcTithiCell(int tithiIndex0) => switch (tithiIndex0 % 5) {
      0 => (4, 5), // Nanda (Sun/Tue)
      1 => (5, 4), // Bhadra (Mon/Wed)
      2 => (4, 3), // Jaya (Thu)
      3 => (3, 4), // Rikta (Fri)
      _ => (4, 4), // Purna (Sat)
    };

/// Weekday cell from the vara name used by PanchangData
/// ('Ravivara' … 'Shanivara').
(int, int)? sbcVaraCell(String vara) => switch (vara) {
      'Ravivara' || 'Mangalavara' => (4, 5), // Sun / Tue
      'Somavara' || 'Budhavara' => (5, 4), // Mon / Wed
      'Guruvara' => (4, 3),
      'Shukravara' => (3, 4),
      'Shanivara' => (4, 4),
      _ => null,
    };

/// The three vedha lines cast by a planet occupying the border
/// nakshatra at [cell]: across, forward (zodiacal) diagonal and rear
/// (anti-zodiacal) diagonal — every cell of each line until the grid's
/// opposite edge, excluding the origin.
List<(int, int)> sbcVedhaCells((int, int) cell) {
  final (r, c) = cell;
  List<(int, int)> walk(int dr, int dc) {
    final out = <(int, int)>[];
    var rr = r + dr, cc = c + dc;
    while (rr >= 0 && rr < 9 && cc >= 0 && cc < 9) {
      out.add((rr, cc));
      rr += dr;
      cc += dc;
    }
    return out;
  }

  // (across, fore, hind) directions per border. The zodiacal order
  // runs clockwise: left→right on top, downward on the right,
  // right→left on the bottom, upward on the left.
  final ((int, int), (int, int), (int, int)) dirs;
  if (r == 0) {
    dirs = ((1, 0), (1, 1), (1, -1));
  } else if (c == 8) {
    dirs = ((0, -1), (1, -1), (-1, -1));
  } else if (r == 8) {
    dirs = ((-1, 0), (-1, -1), (-1, 1));
  } else {
    dirs = ((0, 1), (-1, 1), (1, 1));
  }
  return [
    ...walk(dirs.$1.$1, dirs.$1.$2),
    ...walk(dirs.$2.$1, dirs.$2.$2),
    ...walk(dirs.$3.$1, dirs.$3.$2),
  ];
}

/// All vedha targets per transiting (or natal) planet, keyed by the
/// planet, from its sidereal longitude.
Map<Planet, List<(int, int)>> sbcVedhasByPlanet(
    Map<Planet, PlanetPosition> positions) {
  return {
    for (final p in positions.values)
      p.planet:
          sbcVedhaCells(sbcNakCell[Nakshatra28.fromLongitude(p.longitude)]!),
  };
}
