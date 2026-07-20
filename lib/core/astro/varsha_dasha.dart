/// The three varsha (annual) dashas — Mudda, Yogini, Patyayini — per
/// Charak, "A Textbook of Varshaphala" ch. V, golden-tested against the
/// book's Example Chart (test/varsha_dasha_test.dart).
///
/// Mudda and Yogini are nakshatra dashas compressed into a 360-day
/// year (the book notes spreading over 365 is an acceptable variant; we
/// implement the standard 360). Both take their starting lord from the
/// NATAL Moon's nakshatra plus the completed years, and their opening
/// balance from its untraversed fraction — the consumed part returns as
/// a closing period at the year's end. Patyayini is degree-based on the
/// VARSHA chart (krishamshas = in-sign longitudes of the seven planets
/// AND the lagna, ascending), spans 365 days, and has no balance.
library;

import 'models.dart';

/// One varsha-dasha period. [lord] is null for Patyayini's Lagna
/// periods — the ascendant is a full dasha lord in that system.
class VarshaDashaPeriod {
  const VarshaDashaPeriod({
    required this.lord,
    required this.start,
    required this.end,
    this.subPeriods = const [],
  });

  final Planet? lord;
  final DateTime start;
  final DateTime end;
  final List<VarshaDashaPeriod> subPeriods;

  bool get isLagna => lord == null;
  Duration get length => end.difference(start);
  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

enum VarshaDashaSystem { mudda, yogini, patyayini }

const _nakshatraSpan = 360 / 27; // 13°20'

/// 1-based nakshatra number and the fraction of it already traversed.
(int, double) _nakshatraOf(double moonLongitude) {
  final idx = (moonLongitude % 360) ~/ _nakshatraSpan;
  final fraction = (moonLongitude % _nakshatraSpan) / _nakshatraSpan;
  return (idx + 1, fraction);
}

DateTime _addDays(DateTime t, double days) =>
    t.add(Duration(milliseconds: (days * 86400000).round()));

/// Builds the balance-wrapped sequence shared by Mudda and Yogini:
/// opening balance of the start lord, the full cycle, and the start
/// lord's consumed part closing the year.
List<VarshaDashaPeriod> _nakshatraDasha({
  required DateTime praveshUtc,
  required double natalMoonLongitude,
  required List<Planet> lords,
  required List<double> durations,
  required int startIndex,
  required double cycleDays,
}) {
  final (_, traversed) = _nakshatraOf(natalMoonLongitude);
  final n = lords.length;

  // (lord, days) sequence for the year.
  final seq = <(Planet, double)>[
    (lords[startIndex], durations[startIndex] * (1 - traversed)),
    for (var i = 1; i < n; i++)
      (lords[(startIndex + i) % n], durations[(startIndex + i) % n]),
    if (traversed > 0) (lords[startIndex], durations[startIndex] * traversed),
  ];

  var t = praveshUtc;
  final out = <VarshaDashaPeriod>[];
  for (final (lord, days) in seq) {
    final end = _addDays(t, days);
    // Sub-periods: first the MD lord itself, then the system's own
    // cyclic order, each proportional to its full-cycle share.
    final mdIdx = lords.indexOf(lord);
    var st = t;
    final subs = <VarshaDashaPeriod>[];
    for (var i = 0; i < n; i++) {
      final adLord = lords[(mdIdx + i) % n];
      final adDays = days * durations[(mdIdx + i) % n] / cycleDays;
      final adEnd = _addDays(st, adDays);
      subs.add(VarshaDashaPeriod(lord: adLord, start: st, end: adEnd));
      st = adEnd;
    }
    out.add(
        VarshaDashaPeriod(lord: lord, start: t, end: end, subPeriods: subs));
    t = end;
  }
  return out;
}

// --- Mudda (pp. 40-42): Vimshottari order × 3 days, 360-day year ----------

const _muddaLords = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.rahu,
  Planet.jupiter,
  Planet.saturn,
  Planet.mercury,
  Planet.ketu,
  Planet.venus,
];
const List<double> _muddaDays = [18, 30, 21, 54, 48, 57, 51, 21, 60]; // 360

List<VarshaDashaPeriod> muddaDasha({
  required DateTime praveshUtc,
  required double natalMoonLongitude,
  required int varshaYear,
}) {
  final (nak, _) = _nakshatraOf(natalMoonLongitude);
  // (years + nakshatra − 2) mod 9: remainder 1 → Sun … 0 → Venus.
  final r = (varshaYear + nak - 2) % 9;
  final startIndex = (r + 8) % 9;
  return _nakshatraDasha(
    praveshUtc: praveshUtc,
    natalMoonLongitude: natalMoonLongitude,
    lords: _muddaLords,
    durations: _muddaDays,
    startIndex: startIndex,
    cycleDays: 360,
  );
}

// --- Yogini (pp. 43-46): eight yoginis × 10-80 days, 360-day year ---------

const _yoginiLords = [
  Planet.moon, // Mangala
  Planet.sun, // Pingala
  Planet.jupiter, // Dhanya
  Planet.mars, // Bhramari
  Planet.mercury, // Bhadrika
  Planet.saturn, // Ulka
  Planet.venus, // Siddha
  Planet.rahu, // Sankata
];
const List<double> _yoginiDays = [10, 20, 30, 40, 50, 60, 70, 80]; // 360

/// Yogini names index-aligned with the lords above (for display).
const yoginiVarshaNames = [
  'Mangala',
  'Pingala',
  'Dhanya',
  'Bhramari',
  'Bhadrika',
  'Ulka',
  'Siddha',
  'Sankata',
];

int yoginiVarshaIndexOf(Planet lord) => _yoginiLords.indexOf(lord);

List<VarshaDashaPeriod> yoginiVarshaDasha({
  required DateTime praveshUtc,
  required double natalMoonLongitude,
  required int varshaYear,
}) {
  final (nak, _) = _nakshatraOf(natalMoonLongitude);
  // (years + nakshatra + 3) mod 8: remainder 1 → Mangala … 0 → Sankata.
  final r = (varshaYear + nak + 3) % 8;
  final startIndex = (r + 7) % 8;
  return _nakshatraDasha(
    praveshUtc: praveshUtc,
    natalMoonLongitude: natalMoonLongitude,
    lords: _yoginiLords,
    durations: _yoginiDays,
    startIndex: startIndex,
    cycleDays: 360,
  );
}

// --- Patyayini (pp. 46-49): krishamsha order over a 365-day year ----------

List<VarshaDashaPeriod> patyayiniDasha({
  required DateTime praveshUtc,
  required AstroSnapshot varsha,
}) {
  // Krishamshas: in-sign longitude of the seven planets and the lagna,
  // ascending. Null planet = the lagna.
  final entries = <(Planet?, double)>[
    for (final p in const [
      Planet.sun,
      Planet.moon,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ])
      (p, varsha.positions[p]!.longitude % 30),
    (null, varsha.ascendant % 30),
  ]..sort((a, b) => a.$2.compareTo(b.$2));

  final maxK = entries.last.$2;
  // Patyamsha: first = own krishamsha, then successive differences;
  // duration = 365 × patyamsha ÷ max krishamsha.
  final durations = <double>[
    for (var i = 0; i < entries.length; i++)
      365 * (entries[i].$2 - (i == 0 ? 0 : entries[i - 1].$2)) / maxK,
  ];

  var t = praveshUtc;
  final out = <VarshaDashaPeriod>[];
  for (var i = 0; i < entries.length; i++) {
    final end = _addDays(t, durations[i]);
    // Sub-periods: MD lord first, then the dasha order, wrapping;
    // AD = MD × AD-lord's own duration ÷ 365.
    var st = t;
    final subs = <VarshaDashaPeriod>[];
    for (var j = 0; j < entries.length; j++) {
      final k = (i + j) % entries.length;
      final adEnd = _addDays(st, durations[i] * durations[k] / 365);
      subs.add(VarshaDashaPeriod(lord: entries[k].$1, start: st, end: adEnd));
      st = adEnd;
    }
    out.add(VarshaDashaPeriod(
        lord: entries[i].$1, start: t, end: end, subPeriods: subs));
    t = end;
  }
  return out;
}
