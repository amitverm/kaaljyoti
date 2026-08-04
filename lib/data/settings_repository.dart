import 'dart:convert';

import 'package:flutter/painting.dart' show FontWeight;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

/// Which kinds of change the user wants to hear about (Settings ▸
/// Notifications). [enabled] is the master switch — off means nothing
/// is scheduled at all, regardless of the categories.
class AlertSettings {
  const AlertSettings({
    this.enabled = true,
    this.dasha = true,
    this.transits = true,
    this.sadeSati = true,
  });

  final bool enabled;
  final bool dasha;
  final bool transits;
  final bool sadeSati;

  /// Nothing to schedule when every category is off, even with the
  /// master switch on — worth short-circuiting before any ephemeris
  /// work happens.
  bool get anyCategory => dasha || transits || sadeSati;

  AlertSettings copyWith({
    bool? enabled,
    bool? dasha,
    bool? transits,
    bool? sadeSati,
  }) =>
      AlertSettings(
        enabled: enabled ?? this.enabled,
        dasha: dasha ?? this.dasha,
        transits: transits ?? this.transits,
        sadeSati: sadeSati ?? this.sadeSati,
      );

  @override
  bool operator ==(Object other) =>
      other is AlertSettings &&
      other.enabled == enabled &&
      other.dasha == dasha &&
      other.transits == transits &&
      other.sadeSati == sadeSati;

  @override
  int get hashCode => Object.hash(enabled, dasha, transits, sadeSati);
}

/// One alert that a scheduling pass handed to the OS.
///
/// DISPLAY DATA ONLY. The OS owns the real schedule; this is what the
/// app *believes* it asked for, recorded so the Scheduled alerts screen
/// can show something without re-running a 30-day ephemeris scan. When
/// the two disagree, that disagreement is the interesting fact — the
/// screen surfaces both counts rather than trusting this one.
class ScheduledAlertRecord {
  const ScheduledAlertRecord({
    required this.when,
    required this.title,
    required this.body,
    required this.kundliId,
    this.id = 0,
  });

  final DateTime when;
  final String title;
  final String body;
  final String kundliId;

  /// The OS notification id. Carried so the past-alerts sweep can dedupe
  /// on it: an alert survives many rebuild passes with the same id, and
  /// would otherwise be appended to history once per pass.
  final int id;

  /// Stable identity for deduping. Falls back to the content tuple for
  /// records written before ids were stored — a summary persisted by an
  /// earlier build has no `id`, and reading it back must not make every
  /// legacy entry collide on 0.
  String get dedupeKey => id != 0
      ? 'id:$id'
      : 'c:${when.toUtc().millisecondsSinceEpoch}|$kundliId|$body';

  Map<String, Object?> toJson() => {
        'when': when.toUtc().toIso8601String(),
        'title': title,
        'body': body,
        'kundliId': kundliId,
        'id': id,
      };

  static ScheduledAlertRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final when = DateTime.tryParse('${raw['when']}');
    if (when == null) return null;
    return ScheduledAlertRecord(
      when: when,
      title: '${raw['title'] ?? ''}',
      body: '${raw['body'] ?? ''}',
      kundliId: '${raw['kundliId'] ?? ''}',
      id: switch (raw['id']) { final int i => i, _ => 0 },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ScheduledAlertRecord &&
      other.when.isAtSameMomentAs(when) &&
      other.title == title &&
      other.body == body &&
      other.kundliId == kundliId &&
      other.id == id;

  @override
  int get hashCode => Object.hash(when.toUtc(), title, body, kundliId, id);
}

/// What the last scheduling pass produced: when it ran, and what it
/// scheduled. [computedAt] null means no pass has ever run on this
/// device (distinct from a pass that ran and scheduled nothing).
class AlertScheduleSummary {
  const AlertScheduleSummary({this.computedAt, this.alerts = const []});

  final DateTime? computedAt;
  final List<ScheduledAlertRecord> alerts;

  bool get hasRun => computedAt != null;

  /// Soonest first — the order the screen wants and the order a reader
  /// expects; the pass already produces them this way, but a summary
  /// read back from disk should not have to trust that.
  List<ScheduledAlertRecord> get byTime =>
      [...alerts]..sort((a, b) => a.when.compareTo(b.when));
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

/// How the kundli list is ordered. [recent] is the default: with a
/// library in the hundreds, the charts you touched today ARE your
/// working set, and unlike a fixed "recents" strip it sizes itself.
enum KundliSort {
  recent,
  added,
  name,
  birth;

  static KundliSort byName(String? name) =>
      KundliSort.values.firstWhere((s) => s.name == name,
          orElse: () => KundliSort.recent);
}

/// How much of each kundli the list row shows. The name is the only
/// real identifier, so the default keeps it and the birth stamp and
/// sheds the rest.
enum KundliDensity {
  /// One line: avatar, name, relation, sync glyph.
  compact,

  /// Two lines: the above plus date · time, or the note when there is one.
  comfortable,

  /// Everything, including the lagna/moon quick reads (which cost one
  /// ephemeris computation per visible row).
  detailed;

  static KundliDensity byName(String? name) =>
      KundliDensity.values.firstWhere((d) => d.name == name,
          orElse: () => KundliDensity.comfortable);
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
  static const _kCompareSet = 'compare_set_refs';
  static const _kCompareDasha = 'compare_dasha_system';
  static const _kCompareView = 'compare_view_id';
  static const _kListSort = 'kundli_list_sort';
  static const _kListDensity = 'kundli_list_density';
  static const _kPinned = 'kundli_pinned_ids';
  static const _kFollowed = 'kundli_followed_ids';
  static const _kAlertsEnabled = 'alerts_enabled';
  static const _kAlertsDasha = 'alerts_dasha';
  static const _kAlertsTransits = 'alerts_transits';
  static const _kAlertsSadeSati = 'alerts_sade_sati';
  static const _kAlertsSummary = 'alerts_last_schedule';
  static const _kAlertsSummaryAt = 'alerts_last_schedule_at';
  static const _kAlertsHistory = 'alerts_history';
  static const _kDismissedNotifs = 'dismissed_notification_ids';
  static const _kRecent = 'kundli_recent_ids';
  static const _kRecentMahakosh = 'mahakosh_recent_codes';
  static const _kInstallId = 'analytics_install_id';
  static const _kCreatedTotal = 'analytics_kundlis_created_total';
  static const _kLastPingAt = 'analytics_last_ping_at';
  static const _kCountersDirty = 'analytics_counters_dirty';

  /// How many opened-kundli ids to remember. Deep enough to order a
  /// large library by recency, shallow enough that the list stays cheap
  /// to read and write on every chart open.
  static const recentCap = 200;

  /// Kundli list ordering, density, and pins. All three are deliberately
  /// device-local rather than columns on the kundli row: they describe
  /// how THIS device shows the library, so they need no migration and
  /// give the sync tombstone/LWW logic nothing new to reconcile. The
  /// trade-off is that pins don't follow the user to a new device.
  Future<KundliSort> kundliSort() async {
    final prefs = await SharedPreferences.getInstance();
    return KundliSort.byName(prefs.getString(_kListSort));
  }

  Future<void> setKundliSort(KundliSort sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kListSort, sort.name);
  }

  Future<KundliDensity> kundliDensity() async {
    final prefs = await SharedPreferences.getInstance();
    return KundliDensity.byName(prefs.getString(_kListDensity));
  }

  Future<void> setKundliDensity(KundliDensity density) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kListDensity, density.name);
  }

  Future<List<String>> pinnedKundliIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kPinned) ?? const [];
  }

  Future<void> setPinnedKundliIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPinned, ids);
  }

  /// Kundlis whose upcoming events raise LOCAL notifications on this
  /// device. Device-local for the same reasons as the pins above, plus
  /// one that is not optional: the alerts themselves are scheduled by
  /// THIS device's OS from THIS device's ephemeris run. Syncing the flag
  /// would promise alerts on a phone that has never computed them, and
  /// would silently opt a second device into notifications the user
  /// only ever asked one device for.
  Future<List<String>> followedKundliIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kFollowed) ?? const [];
  }

  Future<void> setFollowedKundliIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFollowed, ids);
  }

  /// Event-alert switches (Settings ▸ Notifications). Everything
  /// defaults ON, which costs nothing until the user follows a kundli:
  /// the follow-set is the real gate, so the categories are there to
  /// narrow alerts the user has already asked for, not to enable them.
  Future<AlertSettings> alertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AlertSettings(
      enabled: prefs.getBool(_kAlertsEnabled) ?? true,
      dasha: prefs.getBool(_kAlertsDasha) ?? true,
      transits: prefs.getBool(_kAlertsTransits) ?? true,
      sadeSati: prefs.getBool(_kAlertsSadeSati) ?? true,
    );
  }

  Future<void> setAlertSettings(AlertSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAlertsEnabled, s.enabled);
    await prefs.setBool(_kAlertsDasha, s.dasha);
    await prefs.setBool(_kAlertsTransits, s.transits);
    await prefs.setBool(_kAlertsSadeSati, s.sadeSati);
  }

  /// What the last scheduling pass handed to the OS — the Scheduled
  /// alerts screen's data source. Written on EVERY pass including an
  /// empty one, so the screen can distinguish "nothing is scheduled" from
  /// "nothing has run yet"; a corrupt or half-written value reads back as
  /// an empty summary rather than throwing on a diagnostics screen.
  Future<AlertScheduleSummary> alertScheduleSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final atMs = prefs.getInt(_kAlertsSummaryAt);
    if (atMs == null) return const AlertScheduleSummary();
    final raw = prefs.getString(_kAlertsSummary);
    var alerts = const <ScheduledAlertRecord>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          alerts = [
            for (final entry in decoded)
              if (ScheduledAlertRecord.fromJson(entry) case final r?) r,
          ];
        }
      } catch (_) {
        // Keep the timestamp: "a pass ran, its list is unreadable" is
        // still more useful than pretending none ever ran.
      }
    }
    return AlertScheduleSummary(
      computedAt: DateTime.fromMillisecondsSinceEpoch(atMs),
      alerts: alerts,
    );
  }

  Future<void> setAlertScheduleSummary(AlertScheduleSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAlertsSummary,
      jsonEncode([for (final a in summary.alerts) a.toJson()]),
    );
    await prefs.setInt(
      _kAlertsSummaryAt,
      (summary.computedAt ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  /// Alerts whose fire time has passed, newest first — the "Past" list.
  ///
  /// A rolling record kept BY THE APP, not read back from the OS, which
  /// offers no delivery receipt of any kind. That is why nothing in this
  /// feature says "delivered": all the app can honestly claim is that it
  /// asked for these and their moment has been and gone.
  Future<List<ScheduledAlertRecord>> alertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlertsHistory);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (ScheduledAlertRecord.fromJson(entry) case final r?) r,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> setAlertHistory(List<ScheduledAlertRecord> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAlertsHistory,
      jsonEncode([for (final a in history) a.toJson()]),
    );
  }

  /// Server notification ids the user has swiped away.
  ///
  /// DEVICE-LOCAL BECAUSE THE SERVER OFFERS NO ALTERNATIVE: public
  /// .notifications carries select and update policies only (0001_init),
  /// so a client DELETE is refused by RLS and the repository exposes no
  /// delete at all. Dismissing therefore hides the row here and marks it
  /// read upstream — which is the honest half of the job we can actually
  /// do, and it at least stops a dismissed item relighting the bell.
  /// The trade-off is that a dismissal does not follow the user to
  /// another device; same as pins and the alert follow-set.
  Future<List<String>> dismissedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kDismissedNotifs) ?? const [];
  }

  Future<void> setDismissedNotificationIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    // Bounded: the list only ever grows, and the server itself caps the
    // feed at 100 rows, so anything beyond a few hundred is dead weight
    // referring to notifications that can no longer be returned.
    await prefs.setStringList(
        _kDismissedNotifs, ids.take(500).toList(growable: false));
  }

  /// Opened-kundli ids, most recent first.
  Future<List<String>> recentKundliIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kRecent) ?? const [];
  }

  Future<void> setRecentKundliIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kRecent, ids.take(recentCap).toList(growable: false));
  }

  /// Opened Mahakosh chart codes, most recent first. Kept separate from
  /// the kundli recents: these are community charts identified by
  /// mk_code, they live server-side, and mixing the two id spaces would
  /// let a deleted community chart hold a slot in the kundli strip.
  Future<List<String>> recentMahakoshCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kRecentMahakosh) ?? const [];
  }

  Future<void> setRecentMahakoshCodes(List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kRecentMahakosh, codes.take(recentCap).toList(growable: false));
  }

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

  /// Kundli Compare session state (spec §3.3) — the ordered subject
  /// refs (local kundli id | 'mk:CODE'), the chosen dasha system, and
  /// the active dashboard view — all persisted so reopening /compare
  /// restores the last comparison. Refs are stored as a newline-joined
  /// list (kundli ids and MK codes never contain newlines).
  Future<List<String>> compareSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kCompareSet) ?? const [];
  }

  Future<void> setCompareSet(List<String> refs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCompareSet, refs);
  }

  Future<String> compareDashaSystem() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCompareDasha) ?? 'vimshottari';
  }

  Future<void> setCompareDashaSystem(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompareDasha, name);
  }

  Future<String?> compareViewId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCompareView);
  }

  Future<void> setCompareViewId(String? viewId) async {
    final prefs = await SharedPreferences.getInstance();
    if (viewId == null) {
      await prefs.remove(_kCompareView);
    } else {
      await prefs.setString(_kCompareView, viewId);
    }
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

  // --- Anonymous device analytics (0030) ------------------------------------
  //
  // The four prefs behind DevicePingService — the whole of this app's
  // telemetry, and all of it device-local until a ping sends the numbers.
  // Read device_ping_service.dart's header for what is and is not sent.

  /// This install's random identity — a uuid v4 minted on first read and
  /// stable for the life of the install.
  ///
  /// Derived from NOTHING: no hardware id, no advertising id, no account.
  /// It exists so the server can tell "the same phone pinged twice" from
  /// "two phones pinged once", and it can do nothing else. Reinstalling
  /// mints a fresh one, which is the intended (and only honest) outcome
  /// of an identifier that is a coin flip.
  Future<String> installId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kInstallId);
    if (existing != null && existing.isNotEmpty) return existing;
    final minted = const Uuid().v4();
    await prefs.setString(_kInstallId, minted);
    return minted;
  }

  /// How many kundlis have been created ON THIS DEVICE, ever — including
  /// ones since deleted. Counted locally because nothing else can: a
  /// chart that never syncs leaves no server trace at all.
  ///
  /// [seedIfAbsent] is consulted ONLY when the counter has never been
  /// written — on the first launch of a build that has this feature, on
  /// a device that may already hold a library. It should supply the
  /// current number of saved kundlis, and the caller supplies it because
  /// this repository has no database of its own (and should not grow
  /// one). The seed is the same estimate philosophy as 0029's backfill:
  /// it does not claim to be the true historical total, only "at least
  /// this many were created here". Deleted-before-today charts are lost
  /// to the count, exactly as they are server-side.
  Future<int> kundlisCreatedTotal(Future<int> Function() seedIfAbsent) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt(_kCreatedTotal);
    if (existing != null) return existing;
    final seed = await seedIfAbsent();
    final clamped = seed < 0 ? 0 : seed;
    await prefs.setInt(_kCreatedTotal, clamped);
    return clamped;
  }

  /// Record one creation, seeding the counter first if this is the first
  /// one we have ever seen. Returns the new total.
  Future<int> bumpKundlisCreatedTotal(
      Future<int> Function() seedIfAbsent) async {
    final next = await kundlisCreatedTotal(seedIfAbsent) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCreatedTotal, next);
    return next;
  }

  /// When this device last successfully sent its ping — null until one
  /// has succeeded. Only success is recorded, so an offline stretch
  /// leaves the next launch still due rather than swallowing a day.
  Future<DateTime?> lastPingAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastPingAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastPingAt(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastPingAt, at.millisecondsSinceEpoch);
  }

  /// Do the numbers on this device differ from what the server was last
  /// told? Set by [KundliRepository] whenever a local count changes,
  /// cleared by DevicePingService after a ping succeeds.
  ///
  /// Persisted rather than held in memory on purpose: a create followed
  /// by the user killing the app before the debounced ping fires would
  /// otherwise leave the server a day out of date with no record that
  /// anything was owed. On disk, the next launch simply sees the flag
  /// and pings straight away.
  Future<bool> countersDirty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCountersDirty) ?? false;
  }

  Future<void> setCountersDirty(bool dirty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCountersDirty, dirty);
  }
}
