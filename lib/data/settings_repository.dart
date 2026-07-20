import 'package:flutter/painting.dart' show FontWeight;
import 'package:shared_preferences/shared_preferences.dart';

import '../charts/chart_tuning.dart';
import '../core/astro/ayanamsa.dart';
import '../core/astro/vikram_samvat.dart';
import '../core/date_format.dart';

/// Appearance preferences — designed for an audience that includes
/// elderly users: text scale, simpler font option, high-contrast and
/// dark palettes.
class AppearanceSettings {
  const AppearanceSettings({
    this.textScale = 1.0, // 1.0–1.6
    this.serifHeadings = true, // false = "Simple" (all Plex Sans)
    this.paletteName = 'classic', // classic | contrast | dark
  });

  final double textScale;
  final bool serifHeadings;
  final String paletteName;

  AppearanceSettings copyWith({
    double? textScale,
    bool? serifHeadings,
    String? paletteName,
  }) =>
      AppearanceSettings(
        textScale: textScale ?? this.textScale,
        serifHeadings: serifHeadings ?? this.serifHeadings,
        paletteName: paletteName ?? this.paletteName,
      );
}

/// App-wide defaults (Profile screen 15). Per-kundli overrides live on
/// the Kundli record itself.
/// The place the "Today" screen computes panchang & lagna for.
class TodayPlace {
  const TodayPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

class SettingsRepository {
  static const _kAyanamsa = 'default_ayanamsa_id';
  static const _kChartStyle = 'default_chart_style';
  static const _kTextScale = 'appearance_text_scale';
  static const _kSerif = 'appearance_serif_headings';
  static const _kPalette = 'appearance_palette';
  static const _kTodayPlaceName = 'today_place_name';
  static const _kTodayLat = 'today_place_lat';
  static const _kTodayLon = 'today_place_lon';
  static const _kTodayChartDegrees = 'today_chart_degrees';
  static const _kMasaSystem = 'today_masa_system';
  static const _kDateFormat = 'date_format_pref';
  static const _kLanguage = 'app_language';
  static const _kLastRoute = 'last_route';
  static const _kLastRouteAt = 'last_route_at';
  static const _kChartTextBase = 'chart_text_base_scale';
  static const _kChartTextFloor = 'chart_text_min_font_scale';
  static const _kChartTextWeight = 'chart_text_weight'; // 400/500/600
  static const _kChartTextDegMin = 'chart_text_degree_minutes';
  static const _kChartTextAnnot = 'chart_text_annotation_scale';
  static const _kChartTextSign = 'chart_text_sign_scale';
  static const _kChartTextInflate = 'chart_text_content_inflate';

  /// Chart text rendering settings (Settings ▸ Chart text). Loaded in
  /// main() into the global [chartTuning] notifier the painters read.
  Future<ChartTuning> chartText() async {
    final prefs = await SharedPreferences.getInstance();
    const d = ChartTuning.defaults;
    final weight = prefs.getInt(_kChartTextWeight);
    return ChartTuning(
      baseScale: prefs.getDouble(_kChartTextBase) ?? d.baseScale,
      minFontScale: prefs.getDouble(_kChartTextFloor) ?? d.minFontScale,
      weight: switch (weight) {
        400 => FontWeight.w400,
        500 => FontWeight.w500,
        600 => FontWeight.w600,
        _ => d.weight,
      },
      degreeMinutes: prefs.getBool(_kChartTextDegMin) ?? d.degreeMinutes,
      annotationScale: prefs.getDouble(_kChartTextAnnot) ?? d.annotationScale,
      signScale: prefs.getDouble(_kChartTextSign) ?? d.signScale,
      contentInflate: prefs.getDouble(_kChartTextInflate) ?? d.contentInflate,
    );
  }

  Future<void> setChartText(ChartTuning t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kChartTextBase, t.baseScale);
    await prefs.setDouble(_kChartTextFloor, t.minFontScale);
    await prefs.setInt(_kChartTextWeight, t.weight.value);
    await prefs.setBool(_kChartTextDegMin, t.degreeMinutes);
    await prefs.setDouble(_kChartTextAnnot, t.annotationScale);
    await prefs.setDouble(_kChartTextSign, t.signScale);
    await prefs.setDouble(_kChartTextInflate, t.contentInflate);
  }

  Future<DateFormatPref> dateFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return DateFormatPref.byName(prefs.getString(_kDateFormat));
  }

  Future<void> setDateFormat(DateFormatPref pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDateFormat, pref.name);
  }

  /// App language override — a language code ('en', 'hi') or 'system'
  /// (default) to follow the device locale. Kept as a plain string so
  /// adding a language never touches this file: the choices offered in
  /// Settings come from AppLocalizations.supportedLocales.
  Future<String> language() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguage) ?? 'system';
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }

  /// Last route + when it was recorded — the foreground state-loss fix.
  /// Android/iOS kill the backgrounded process freely (the state-loss
  /// bug: users came back to a fresh app on the Today screen); the app
  /// root re-opens the saved route on cold start IF it was recorded
  /// recently (a next-morning launch should land on Today as designed,
  /// not on last week's kundli).
  Future<({String route, DateTime at})?> lastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_kLastRoute);
    final atMs = prefs.getInt(_kLastRouteAt);
    if (route == null || atMs == null) return null;
    return (route: route, at: DateTime.fromMillisecondsSinceEpoch(atMs));
  }

  Future<void> setLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastRoute, route);
    await prefs.setInt(_kLastRouteAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<AppearanceSettings> appearance() async {
    final prefs = await SharedPreferences.getInstance();
    return AppearanceSettings(
      textScale: prefs.getDouble(_kTextScale) ?? 1.0,
      serifHeadings: prefs.getBool(_kSerif) ?? true,
      paletteName: prefs.getString(_kPalette) ?? 'classic',
    );
  }

  Future<void> setAppearance(AppearanceSettings a) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScale, a.textScale);
    await prefs.setBool(_kSerif, a.serifHeadings);
    await prefs.setString(_kPalette, a.paletteName);
  }

  Future<int> defaultAyanamsaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAyanamsa) ?? Ayanamsa.lahiri.id;
  }

  Future<void> setDefaultAyanamsaId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAyanamsa, id);
  }

  Future<String> defaultChartStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kChartStyle) ?? 'north';
  }

  Future<void> setDefaultChartStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kChartStyle, style);
  }

  /// True once the user has explicitly picked a city (drives the
  /// "set your city" nudge on Today — sunrise moves ~4 min per degree
  /// of longitude, so the silent default would mislead).
  Future<bool> todayPlaceIsSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTodayPlaceName) != null;
  }

  /// Defaults to New Delhi until the user picks their city on the
  /// Today screen.
  Future<TodayPlace> todayPlace() async {
    final prefs = await SharedPreferences.getInstance();
    return TodayPlace(
      name: prefs.getString(_kTodayPlaceName) ?? 'New Delhi, India',
      latitude: prefs.getDouble(_kTodayLat) ?? 28.6139,
      longitude: prefs.getDouble(_kTodayLon) ?? 77.2090,
    );
  }

  Future<void> setTodayPlace(TodayPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTodayPlaceName, place.name);
    await prefs.setDouble(_kTodayLat, place.latitude);
    await prefs.setDouble(_kTodayLon, place.longitude);
  }

  /// Whether the Today "Transit now" wheel labels each graha with its
  /// degree. Defaults to on; the exact degrees also live in the positions
  /// table below the wheel, so users who want a cleaner chart can turn
  /// this off.
  Future<bool> todayChartDegrees() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTodayChartDegrees) ?? true;
  }

  Future<void> setTodayChartDegrees(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTodayChartDegrees, value);
  }

  /// Lunar-month naming convention for the Vikram Samvat maasa shown on
  /// Today. Defaults to Purnimanta (the North-Indian norm for V.S.).
  Future<MasaSystem> masaSystem() async {
    final prefs = await SharedPreferences.getInstance();
    return MasaSystem.byName(prefs.getString(_kMasaSystem));
  }

  Future<void> setMasaSystem(MasaSystem system) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMasaSystem, system.name);
  }
}
