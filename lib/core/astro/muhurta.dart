/// Muhurta (auspicious-timing) calculations: Choghadiya, Hora, the
/// inauspicious eighths (Rahu Kaal / Yamaganda / Gulika Kaal), Abhijit
/// muhurta, and the personalized Tara bala / Chandra bala checks.
///
/// Pure Dart, no ephemeris dependency: callers supply sunrise / sunset
/// / next-sunrise (from [EphemerisService.sunRiseSet]) as local
/// DateTimes, so every function here is unit-testable with fixed
/// inputs — matching the transit-scan engine's inject-don't-call
/// convention.
library;

import 'daily_panchang.dart' show TimeWindow;
import 'models.dart';

/// One Choghadiya or Hora timeline slot.
class MuhurtaSegment {
  const MuhurtaSegment({
    required this.name,
    required this.start,
    required this.end,
    this.good,
    this.planet,
  });

  final String name;
  final DateTime start;
  final DateTime end;

  /// Auspicious/inauspicious for Choghadiya; null for Hora, whose
  /// favorability is purpose-dependent rather than fixed per slot.
  final bool? good;

  /// Set for Hora slots (the ruling graha); null for Choghadiya.
  final Planet? planet;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

// ---------------------------------------------------------------------------
// Choghadiya
// ---------------------------------------------------------------------------

/// Traditional cyclic order of the 7 Choghadiya names.
const List<String> kChoghadiyaCycle = [
  'Udveg', 'Char', 'Labh', 'Amrit', 'Kaal', 'Shubh', 'Rog',
];

/// Amrit / Shubh / Labh / Char are auspicious; the rest are not.
const Set<String> kChoghadiyaGood = {'Amrit', 'Shubh', 'Labh', 'Char'};

/// The day's first Choghadiya name by weekday (`DateTime.weekday`:
/// Mon=1 … Sun=7).
const Map<int, String> kChoghadiyaFirstByWeekday = {
  DateTime.sunday: 'Udveg',
  DateTime.monday: 'Amrit',
  DateTime.tuesday: 'Rog',
  DateTime.wednesday: 'Labh',
  DateTime.thursday: 'Shubh',
  DateTime.friday: 'Char',
  DateTime.saturday: 'Kaal',
};

/// Day (sunrise→sunset) and night (sunset→next sunrise) Choghadiya,
/// 8 segments each. The night's first segment is the 5th name from
/// the day's first, counted around the 7-name cycle.
({List<MuhurtaSegment> day, List<MuhurtaSegment> night}) choghadiyaSegments({
  required DateTime sunrise,
  required DateTime sunset,
  required DateTime nextSunrise,
}) {
  final firstName = kChoghadiyaFirstByWeekday[sunrise.weekday]!;
  final dayStartIdx = kChoghadiyaCycle.indexOf(firstName);
  final nightStartIdx = (dayStartIdx + 4) % 7; // "5th from the day's first"

  List<MuhurtaSegment> build(DateTime from, DateTime to, int cycleStart) {
    final len = to.difference(from) ~/ 8;
    return [
      for (var i = 0; i < 8; i++)
        MuhurtaSegment(
          name: kChoghadiyaCycle[(cycleStart + i) % 7],
          start: from.add(len * i),
          end: i == 7 ? to : from.add(len * (i + 1)),
          good: kChoghadiyaGood.contains(kChoghadiyaCycle[(cycleStart + i) % 7]),
        ),
    ];
  }

  return (
    day: build(sunrise, sunset, dayStartIdx),
    night: build(sunset, nextSunrise, nightStartIdx),
  );
}

// ---------------------------------------------------------------------------
// Hora
// ---------------------------------------------------------------------------

/// Chaldean cyclic order used for Hora, rotated to start at the Sun
/// (Sun → Venus → Mercury → Moon → Saturn → Jupiter → Mars → …).
const List<Planet> kHoraCycle = [
  Planet.sun,
  Planet.venus,
  Planet.mercury,
  Planet.moon,
  Planet.saturn,
  Planet.jupiter,
  Planet.mars,
];

/// The weekday's ruling planet — also the day's first Hora lord.
const Map<int, Planet> kWeekdayLord = {
  DateTime.sunday: Planet.sun,
  DateTime.monday: Planet.moon,
  DateTime.tuesday: Planet.mars,
  DateTime.wednesday: Planet.mercury,
  DateTime.thursday: Planet.jupiter,
  DateTime.friday: Planet.venus,
  DateTime.saturday: Planet.saturn,
};

/// 24 Hora slots (12 across the day, 12 across the night), cycling
/// continuously through [kHoraCycle] from the weekday lord — there is
/// no reset at sunset.
List<MuhurtaSegment> horaSegments({
  required DateTime sunrise,
  required DateTime sunset,
  required DateTime nextSunrise,
}) {
  final startIdx = kHoraCycle.indexOf(kWeekdayLord[sunrise.weekday]!);
  final dayLen = sunset.difference(sunrise) ~/ 12;
  final nightLen = nextSunrise.difference(sunset) ~/ 12;

  final out = <MuhurtaSegment>[];
  for (var i = 0; i < 12; i++) {
    final p = kHoraCycle[(startIdx + i) % 7];
    out.add(MuhurtaSegment(
      name: p.displayName,
      start: sunrise.add(dayLen * i),
      end: i == 11 ? sunset : sunrise.add(dayLen * (i + 1)),
      planet: p,
    ));
  }
  for (var i = 0; i < 12; i++) {
    final p = kHoraCycle[(startIdx + 12 + i) % 7];
    out.add(MuhurtaSegment(
      name: p.displayName,
      start: sunset.add(nightLen * i),
      end: i == 11 ? nextSunrise : sunset.add(nightLen * (i + 1)),
      planet: p,
    ));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Rahu Kaal / Yamaganda / Gulika Kaal / Abhijit (weekday-eighths of daylight)
// ---------------------------------------------------------------------------

/// 1-based eighth-of-daylight segment for Rahu Kaal, by weekday.
const Map<int, int> kRahuKaalSegment = {1: 2, 2: 7, 3: 5, 4: 6, 5: 4, 6: 3, 7: 8};

/// 1-based eighth-of-daylight segment for Yamaganda, by weekday.
const Map<int, int> kYamagandaSegment = {1: 4, 2: 3, 3: 2, 4: 1, 5: 7, 6: 6, 7: 5};

/// 1-based eighth-of-daylight segment for Gulika Kaal, by weekday.
const Map<int, int> kGulikaKaalSegment = {1: 6, 2: 5, 3: 4, 4: 3, 5: 2, 6: 1, 7: 7};

TimeWindow _eighthWindow(DateTime sunrise, DateTime sunset, int segment1to8) {
  final len = sunset.difference(sunrise) ~/ 8;
  final start = sunrise.add(len * (segment1to8 - 1));
  return TimeWindow(start, start.add(len));
}

TimeWindow rahuKaalWindow(DateTime sunrise, DateTime sunset) =>
    _eighthWindow(sunrise, sunset, kRahuKaalSegment[sunrise.weekday]!);

TimeWindow yamagandaWindow(DateTime sunrise, DateTime sunset) =>
    _eighthWindow(sunrise, sunset, kYamagandaSegment[sunrise.weekday]!);

TimeWindow gulikaKaalWindow(DateTime sunrise, DateTime sunset) =>
    _eighthWindow(sunrise, sunset, kGulikaKaalSegment[sunrise.weekday]!);

/// The 8th of 15 day-muhurtas — centered on local midday, i.e.
/// midday ± 1/30 of the daylight span. Traditionally skipped on
/// Wednesdays ([abhijitApplies]).
TimeWindow abhijitMuhurtaWindow(DateTime sunrise, DateTime sunset) {
  final muhurta = sunset.difference(sunrise) ~/ 15;
  final start = sunrise.add(muhurta * 7);
  return TimeWindow(start, start.add(muhurta));
}

bool abhijitApplies(DateTime sunrise) =>
    sunrise.weekday != DateTime.wednesday;

// ---------------------------------------------------------------------------
// Personalize: Tara bala / Chandra bala (require a natal reference)
// ---------------------------------------------------------------------------

/// The 9 taras counted cyclically from a person's janma nakshatra.
enum TaraBalaResult {
  janma,
  sampat,
  vipat,
  kshema,
  pratyari,
  sadhaka,
  vadha,
  mitra,
  ativadha;

  static const _labels = [
    'Janma', 'Sampat', 'Vipat', 'Kshema', 'Pratyari', 'Sadhaka', 'Vadha',
    'Mitra', 'Ati-Mitra',
  ];

  String get label => _labels[index];

  /// Janma(1) / Vipat(3) / Pratyari(5) / Vadha(7) are unfavorable; the
  /// rest are favorable.
  bool get favorable => !const {0, 2, 4, 6}.contains(index);
}

/// Counts from the person's [janmaNakshatra] to [dayNakshatra]
/// (1-based, mod 9 of the 27-nakshatra count) to find the active tara.
TaraBalaResult taraBala({
  required Nakshatra janmaNakshatra,
  required Nakshatra dayNakshatra,
}) {
  final count = (dayNakshatra.index - janmaNakshatra.index + 27) % 27 + 1;
  return TaraBalaResult.values[(count - 1) % 9];
}

/// Chandra bala verdict for the day's Moon sign against the natal
/// (janma) rashi.
enum ChandraBalaResult { favorable, neutral, unfavorable }

/// Counts the day's Moon sign from the natal [janmaRashi] (1-based).
/// 1/3/6/7/10/11 favorable, 4/8/12 unfavorable, 2/5/9 neutral.
ChandraBalaResult chandraBala({
  required ZodiacSign janmaRashi,
  required ZodiacSign dayMoonSign,
}) {
  final count = (dayMoonSign.index - janmaRashi.index + 12) % 12 + 1;
  if (const {1, 3, 6, 7, 10, 11}.contains(count)) {
    return ChandraBalaResult.favorable;
  }
  if (const {4, 8, 12}.contains(count)) return ChandraBalaResult.unfavorable;
  return ChandraBalaResult.neutral;
}
