/// Feeds the OS home-screen widgets (Daily Panchang + Live Transit).
///
/// Home-screen widgets cannot run Flutter or the ephemeris — so the
/// app PRECOMPUTES everything and hands the native side plain strings
/// plus, for iOS, a JSON timeline of future entries (WidgetKit renders
/// scheduled entries without waking the app; Android re-reads the
/// shared data on its periodic update).
///
/// Data flows through the `home_widget` package: SharedPreferences on
/// Android, an App Group UserDefaults suite on iOS. Pushed every time
/// the Today screen computes (app open / minute tick), so widget data
/// is at most one app-session stale — both widgets also show their
/// "as of" date so staleness is visible, never misleading.
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

import '../core/astro/daily_panchang.dart';
import '../core/astro/ephemeris_service.dart';
import '../core/astro/models.dart';
import '../data/settings_repository.dart';

class OsWidgetService {
  OsWidgetService._();

  /// Must match the App Group configured on BOTH the Runner and the
  /// widget extension targets in Xcode (see docs/os-widgets-setup.md).
  static const appGroupId = 'group.com.kaaljyoti';

  static String _hm(DateTime? t) => t == null
      ? '—'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _window(TimeWindow? w) =>
      w == null ? '—' : '${_hm(w.start)}–${_hm(w.end)}';

  /// One-line sky summary: "Su Pis · Mo Tau · Ma Pis® · …".
  static String _skyLine(Map<Planet, PlanetPosition> positions) =>
      Planet.values.map((p) {
        final pos = positions[p]!;
        final retro =
            pos.isRetrograde && p != Planet.rahu && p != Planet.ketu ? '®' : '';
        return '${p.abbr} ${pos.sign.western.substring(0, 3)}$retro';
      }).join(' · ');

  /// Sign-indexed planet groups for the widget chart: 12 groups
  /// (Aries…Pisces) separated by '|', planets comma-separated, '®'
  /// suffix for retrograde — e.g. "Su,Ma®||Mo|…". Sign-indexed (not
  /// house-indexed) so the native side can lay out either chart style.
  static String _chartSigns(Map<Planet, PlanetPosition> positions) {
    final groups = List.generate(12, (_) => <String>[]);
    for (final p in Planet.values) {
      final pos = positions[p]!;
      final retro =
          pos.isRetrograde && p != Planet.rahu && p != Planet.ketu ? '®' : '';
      groups[pos.sign.index].add('${p.abbr}$retro');
    }
    return groups.map((g) => g.join(',')).join('|');
  }

  /// Push today's data to both widgets. Safe to call often; no-op off
  /// mobile and swallows platform errors (widgets are best-effort).
  static Future<void> pushToday({
    required DailyPanchang data,
    required TodayPlace place,
    required int ayanamsaId,
    String chartStyle = 'north',
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      final d = data;
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      // ---- Panchang widget (valid for the Vedic day) ----
      await HomeWidget.saveWidgetData<String>('pw_title',
          '${weekdays[d.at.weekday - 1]} · ${d.at.day}.${d.at.month}');
      await HomeWidget.saveWidgetData<String>('pw_tithi',
          '${d.panchang.paksha} ${d.panchang.tithiName} · till ${_hm(d.tithiEnds)}');
      await HomeWidget.saveWidgetData<String>('pw_nakshatra',
          '${d.panchang.nakshatra.displayName} p${d.panchang.pada} · till ${_hm(d.nakshatraEnds)}');
      await HomeWidget.saveWidgetData<String>(
          'pw_sun', '☀ ${_hm(d.sunrise)} – ${_hm(d.sunset)}');
      await HomeWidget.saveWidgetData<String>(
          'pw_rahu', 'Rahu Kaal ${_window(d.rahuKalam)}');
      await HomeWidget.saveWidgetData<String>(
          'pw_abhijit',
          'Abhijit ${_window(d.abhijitMuhurta)}'
          '${d.at.weekday == DateTime.wednesday ? ' (avoid)' : ''}');
      await HomeWidget.saveWidgetData<String>('pw_disha',
          d.dishaShool == null ? '—' : 'Disha Shool · ${d.dishaShool}');
      await HomeWidget.saveWidgetData<String>(
          'pw_place', place.name.split(',').first);
      // iOS timeline hint: rebuild the panchang entry when the tithi
      // (or failing that, the nakshatra) rolls over. Epoch millis —
      // Dart's toIso8601String has no timezone suffix, which Swift's
      // ISO8601DateFormatter rejects.
      final refreshAt = d.tithiEnds ?? d.nakshatraEnds;
      await HomeWidget.saveWidgetData<String>('pw_refresh_at',
          (refreshAt ?? d.at).millisecondsSinceEpoch.toString());

      // ---- Transit widget: now + a 12-hour precomputed timeline ----
      await HomeWidget.saveWidgetData<String>('tw_asc',
          'Rising ${d.lagnaSign.western} ${formatDegreeInSign(d.ascendant)}');
      await HomeWidget.saveWidgetData<String>('tw_line', _skyLine(d.positions));
      await HomeWidget.saveWidgetData<String>('tw_updated', _hm(d.at));
      // Chart style for the widget's native chart drawing.
      await HomeWidget.saveWidgetData<String>('tw_style', chartStyle);

      final svc = EphemerisService.instance;
      final entries = <Map<String, String>>[];
      for (var i = 0; i < 24; i++) {
        final t = d.at.add(Duration(minutes: 30 * i));
        final jd = svc.julianDayUt(t.toUtc());
        final asc = svc
            .housesAndAscendant(jd, place.latitude, place.longitude, ayanamsaId)
            .ascendant;
        final positions = svc.planetPositions(jd, ayanamsaId);
        entries.add({
          't': t.millisecondsSinceEpoch.toString(),
          'asc':
              'Rising ${ZodiacSign.fromLongitude(asc).western} ${formatDegreeInSign(asc)}',
          'line': _skyLine(positions),
          // Chart data: ascendant sign (1–12) + sign-indexed planet
          // groups; all string-valued to keep old parsers happy.
          'a': '${ZodiacSign.fromLongitude(asc).index + 1}',
          's': _chartSigns(positions),
        });
      }
      await HomeWidget.saveWidgetData<String>(
          'tw_timeline', jsonEncode(entries));

      await HomeWidget.updateWidget(
        androidName: 'PanchangWidgetProvider',
        iOSName: 'PanchangWidget',
      );
      await HomeWidget.updateWidget(
        androidName: 'TransitWidgetProvider',
        iOSName: 'TransitWidget',
      );
    } catch (_) {
      // Widgets are auxiliary — never let them break the app.
    }
  }
}
