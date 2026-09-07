/// Dasha system contract (brief §2.3): one [DashaCalculator] interface;
/// each system implements its own logic against the shared [AstroSnapshot]
/// and emits the same period-tree output shape.
library;

import '../models.dart';

enum DashaSystem {
  vimshottari('Vimshottari', 'Nakshatra-based · 120-year cycle · 9 lords'),
  yogini('Yogini', 'Nakshatra-based · 36-year cycle · 8 Yoginis'),
  jaimini('Jaimini Chara', 'Sign-based · rashi periods from lord placement'),
  sthira('Jaimini Sthira', 'Sign-based · fixed 7/8/9-year periods from Brahma'),
  mandook('Jaimini Mandook',
      'Sign-based · frog-leaps to the 4th sign · years counted to the lord');

  const DashaSystem(this.displayName, this.subtitle);
  final String displayName;
  final String subtitle;
}

/// Depth of the period tree: 1 = mahadasha … 5 = pran dasha.
const int kDashaMaxLevel = 5;

/// Display names per level (index = level - 1).
const List<String> kDashaLevelNames = [
  'Mahadasha',
  'Antardasha',
  'Pratyantardasha',
  'Sookshma dasha',
  'Pran dasha',
];

/// Plural forms for drill-down headers (index = level - 1).
const List<String> kDashaLevelNamesPlural = [
  'Mahadashas',
  'Antardashas',
  'Pratyantardashas',
  'Sookshma dashas',
  'Pran dashas',
];

/// One period in a dasha tree. `lordLabel` is a display label because
/// systems differ in lord type (planet for Vimshottari, Yogini name +
/// ruler for Yogini, rashi for Jaimini Chara).
///
/// Children are built LAZILY: a full eager tree to pran level would be
/// ~60k–270k nodes per system, so sub-periods materialize only when a
/// caller first reads [children] (and are then memoized). Drilling a
/// single path to pran therefore touches a few dozen nodes.
class DashaPeriod {
  DashaPeriod({
    required this.lordLabel,
    required this.start,
    required this.end,
    required this.level, // 1 = mahadasha … 5 = pran
    this.planet,
    this.sign,
    List<DashaPeriod> Function(DashaPeriod parent)? childBuilder,
  }) : _childBuilder = childBuilder;

  final String lordLabel;
  final DateTime start;
  final DateTime end;
  final int level;
  final Planet? planet;
  final ZodiacSign? sign;

  final List<DashaPeriod> Function(DashaPeriod parent)? _childBuilder;
  List<DashaPeriod>? _children;

  /// Sub-periods, computed on first access.
  List<DashaPeriod> get children =>
      _children ??= _childBuilder?.call(this) ?? const [];

  /// Whether this period can drill down without forcing a build.
  bool get hasChildren =>
      _childBuilder != null || (_children?.isNotEmpty ?? false);

  String get levelName => kDashaLevelNames[level - 1];

  Duration get length => end.difference(start);

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  /// Fraction elapsed at [t], clamped 0–1.
  double progressAt(DateTime t) {
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    return (t.difference(start).inSeconds / total).clamp(0.0, 1.0);
  }

  /// Copy with a corrected [end] (used to snap rounding drift to the
  /// parent's boundary) while preserving lazy children.
  DashaPeriod withEnd(DateTime newEnd) => DashaPeriod(
        lordLabel: lordLabel,
        planet: planet,
        sign: sign,
        start: start,
        end: newEnd,
        level: level,
        childBuilder: _childBuilder,
      );
}

class DashaResult {
  const DashaResult({required this.system, required this.periods});
  final DashaSystem system;
  final List<DashaPeriod> periods; // mahadashas, chronological

  DashaPeriod? currentMahadasha(DateTime t) =>
      periods.where((p) => p.contains(t)).firstOrNull;

  /// Active chain at [t], outermost first: [maha, antar, pratyantar,
  /// sookshma, pran]. Shorter (or empty) when [t] is out of range.
  List<DashaPeriod> chainAt(DateTime t) {
    final chain = <DashaPeriod>[];
    var current = currentMahadasha(t);
    while (current != null) {
      chain.add(current);
      current = current.children.where((p) => p.contains(t)).firstOrNull;
    }
    return chain;
  }

  /// (maha, antar, pratyantar) active at [t]; nulls where out of range.
  (DashaPeriod?, DashaPeriod?, DashaPeriod?) activeAt(DateTime t) {
    final chain = chainAt(t);
    return (
      chain.elementAtOrNull(0),
      chain.elementAtOrNull(1),
      chain.elementAtOrNull(2),
    );
  }
}

abstract interface class DashaCalculator {
  DashaSystem get system;

  /// Compute the period tree (lazy below mahadasha, [kDashaMaxLevel]
  /// levels deep) from the shared snapshot.
  DashaResult calculate(AstroSnapshot snapshot);
}

/// Where dasha listings stop: no period STARTS at or after this age.
/// Cyclic sign dashas (Chara, Sthira) repeat their cycle only this far —
/// a full second 96-year Sthira cycle would run to age 192, which reads
/// as noise past any lifespan. Vimshottari's single 120-year cycle and
/// Yogini's three 36-year cycles already sit inside the horizon.
const int kDashaHorizonYears = 120;

/// Solar year length used by classical dasha arithmetic.
const double kDashaYearDays = 365.25;

DateTime addYears(DateTime from, double years) =>
    from.add(Duration(seconds: (years * kDashaYearDays * 86400).round()));

/// [months] whole calendar months after [t], the day-of-month clamped to
/// the target month's length (a 31st birthday clamps in a 30-day month,
/// as calendars do). The K.N. Rao school's rashi dashas (Sthira,
/// Mandook) run birthday to birthday and month-day to month-day, so
/// their boundaries are calendar arithmetic rather than solar years.
DateTime addCalendarMonths(DateTime t, int months) {
  final zeroBased = t.month - 1 + months;
  final year = t.year + zeroBased ~/ 12;
  final month = zeroBased % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, t.day > lastDay ? lastDay : t.day, t.hour,
      t.minute, t.second);
}
