import 'package:intl/intl.dart';

/// User-selectable date formats — spelled-out (unambiguous) or numeric.
/// The chosen pattern is applied app-wide; the choice lives in Settings and
/// is stored locally (SharedPreferences) — it does not sync across devices.
enum DateFormatPref {
  /// 9 Jul 2026 — the default.
  dMMMy('d MMM yyyy', '9 Jul 2026'),

  /// 9 July 2026 — full month name.
  dMMMMy('d MMMM yyyy', '9 July 2026'),

  /// Jul 9, 2026 — month-first, spelled.
  mMMMdy('MMM d, yyyy', 'Jul 9, 2026'),

  /// 09/07/2026 — numeric, day-first.
  ddMMyyyy('dd/MM/yyyy', '09/07/2026'),

  /// 07/09/2026 — numeric, month-first.
  mmDDyyyy('MM/dd/yyyy', '07/09/2026');

  const DateFormatPref(this.datePattern, this.sample);

  /// The `intl` date pattern used for the day-precision date portion.
  final String datePattern;

  /// A human-readable example shown next to the option in Settings.
  final String sample;

  static DateFormatPref byName(String? name) => DateFormatPref.values
      .firstWhere((e) => e.name == name, orElse: () => DateFormatPref.dMMMy);
}

/// Global, context-free date formatting so every screen and module renders
/// dates in the user's chosen style.
///
/// [pref] is the single source of truth; it is loaded at startup and kept in
/// sync by `DateFormatNotifier` whenever the setting changes. The app root
/// rebuilds on change (its ValueKey includes the pref), so all dates re-render
/// — including those produced by module-level formatters, which read [pref]
/// lazily through the getters below.
class KJDate {
  KJDate._();

  static DateFormatPref pref = DateFormatPref.dMMMy;

  static String get _p => pref.datePattern;

  /// Full date, e.g. "9 Jul 2026".
  static String date(DateTime d) => DateFormat(_p).format(d);

  /// Date + 24h time separated by a middot, e.g. "9 Jul 2026 · 14:30".
  static String dateDotTime(DateTime d) => DateFormat('$_p · HH:mm').format(d);

  /// Date + 24h time separated by a comma, e.g. "9 Jul 2026, 14:30".
  static String dateCommaTime(DateTime d) => DateFormat('$_p, HH:mm').format(d);

  /// Date + 12h time separated by a comma, e.g. "9 Jul 2026, 2:30 PM".
  static String dateCommaTime12(DateTime d) =>
      DateFormat('$_p, h:mm a').format(d);
}
