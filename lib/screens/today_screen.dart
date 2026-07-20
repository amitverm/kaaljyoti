import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../charts/chart_style.dart';
import '../charts/chart_view.dart';
import '../charts/planet_token.dart';
import '../core/astro/daily_panchang.dart';
import '../core/astro/models.dart';
import '../core/astro/vikram_samvat.dart';
import '../modules/common.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/settings_repository.dart';
import '../services/current_location_service.dart';
import '../services/os_widget_service.dart';
import '../services/place_lookup_service.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../ui/common.dart';

/// "Today" — the app's landing screen: live panchang (five limbs with
/// end times, sunrise/sunset) and the current transit sky with the
/// rising lagna, for a user-chosen place. Refreshes each minute.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Timer? _timer;
  TodayPlace? _place;
  bool _placeSet = true; // no nudge until we know otherwise
  int? _ayanamsaId;
  String _chartStyle = 'north';
  bool _showChartDegrees = true;
  MasaSystem _masaSystem = MasaSystem.purnimanta;
  DailyPanchang? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // The lagna moves ~1° every 4 minutes; a minute tick keeps the
    // clock line and rising sign honest without meaningful cost.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _compute());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepoProvider);
    final place = await settings.todayPlace();
    final placeSet = await settings.todayPlaceIsSet();
    final ayanamsa = await settings.defaultAyanamsaId();
    final style = await settings.defaultChartStyle();
    final chartDegrees = await settings.todayChartDegrees();
    final masaSystem = await settings.masaSystem();
    if (!mounted) return;
    setState(() {
      _place = place;
      _placeSet = placeSet;
      _ayanamsaId = ayanamsa;
      _chartStyle = style;
      _showChartDegrees = chartDegrees;
      _masaSystem = masaSystem;
    });
    _compute();

    // First run: try the phone's own location (compute has already
    // rendered with the default, so the UI never waits on GPS). If
    // permission is refused the nudge banner stays.
    if (!placeSet) {
      final detected = await CurrentLocationService.detect();
      if (detected != null && mounted) {
        await settings.setTodayPlace(detected);
        setState(() {
          _place = detected;
          _placeSet = true;
        });
        _compute();
      }
    }
  }

  void _compute() {
    final place = _place;
    final ayanamsa = _ayanamsaId;
    if (place == null || ayanamsa == null) return;
    try {
      final data = computeDailyPanchang(
        now: DateTime.now(),
        latitude: place.latitude,
        longitude: place.longitude,
        ayanamsaId: ayanamsa,
        masaSystem: _masaSystem,
      );
      if (mounted) setState(() => _data = data);
      // Keep the OS home-screen widgets fed (fire-and-forget).
      OsWidgetService.pushToday(
          data: data,
          place: place,
          ayanamsaId: ayanamsa,
          chartStyle: _chartStyle);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _pickPlace() async {
    final picked = await showDialog<TodayPlace>(
      context: context,
      builder: (_) => const _PlacePickerDialog(),
    );
    if (picked == null) return;
    await ref.read(settingsRepoProvider).setTodayPlace(picked);
    setState(() {
      _place = picked;
      _placeSet = true;
    });
    _compute();
  }

  void _toggleChartDegrees() {
    final next = !_showChartDegrees;
    setState(() => _showChartDegrees = next);
    ref.read(settingsRepoProvider).setTodayChartDegrees(next);
  }

  /// Tap the Maasa row to flip the naming convention (Purnimanta ⇄
  /// Amanta) — the month name and, on a waning day, the label can
  /// differ between the two, so recompute.
  void _toggleMasaSystem() {
    final next = _masaSystem == MasaSystem.purnimanta
        ? MasaSystem.amanta
        : MasaSystem.purnimanta;
    setState(() => _masaSystem = next);
    ref.read(settingsRepoProvider).setMasaSystem(next);
    _compute();
  }

  /// The transit card's '···' options sheet — same visual language as the
  /// dashboard widget menu (paper sheet, drag handle, DISPLAY section of
  /// selectable pills, pinned Done).
  Future<void> _showTransitOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: KJColors.paper,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.tdTransitNow, style: KJTheme.serif(size: 18)),
                const SizedBox(height: 14),
                KJSectionLabel(context.l10n.tdDisplaySection),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(context.l10n.cfgPlanetDegrees,
                          style: const TextStyle(fontSize: 12.5)),
                      selected: _showChartDegrees,
                      checkmarkColor: KJColors.paper,
                      labelStyle: TextStyle(
                          fontSize: 12.5,
                          color: _showChartDegrees
                              ? KJColors.paper
                              : KJColors.ink),
                      onSelected: (_) {
                        _toggleChartDegrees();
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.l10n.done),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _hm(DateTime? t) => t == null
      ? '—'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// " · till 14:32" or " · till tomorrow 02:10".
  String _till(AppLocalizations l10n, DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final tomorrow = t.day != now.day;
    return tomorrow ? l10n.tdTillTomorrow(_hm(t)) : l10n.tdTill(_hm(t));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = _data;
    final place = _place;
    return KJScaffold(
      section: KJSection.today,
      appBar: AppBar(title: Text(l10n.tdTitle)),
      body: d == null
          ? Center(
              child: _error != null
                  ? Text(l10n.tdCalcFailed('$_error'))
                  : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _compute(),
              child: ListView(
                padding: formPadding(context),
                children: [
                  // First-run nudge: sunrise (and every muhurta derived
                  // from it) shifts ~4 min per degree of longitude, so
                  // a silent default city would quietly mislead.
                  if (!_placeSet) ...[
                    InkWell(
                      onTap: _pickPlace,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KJColors.maroon.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: KJColors.maroon.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 18, color: KJColors.maroon),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.tdPlaceNudge(
                                    place?.name.split(',').first ??
                                        'New Delhi'),
                                style: TextStyle(
                                    fontSize: 12.5, color: KJColors.maroon),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Date + place line.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          // Civil weekday (the Sanskrit vara stays in
                          // kundli panchang contexts).
                          l10n.tdDateLine(weekdayLabel(l10n, d.at.weekday),
                              KJDate.date(d.at)),
                          style: KJTheme.serif(size: 18),
                        ),
                      ),
                      InkWell(
                        onTap: _pickPlace,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_outlined,
                                  size: 14, color: KJColors.maroon),
                              const SizedBox(width: 3),
                              Text(
                                place?.name.split(',').first ?? '',
                                style: KJTheme.mono(
                                    size: 11.5, color: KJColors.maroon),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Panchang card.
                  ModuleCard(
                    title: l10n.modulePanchangTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vikram Samvat month + year. Tap to switch the
                        // naming convention (Purnimanta ⇄ Amanta).
                        InkWell(
                          onTap: _toggleMasaSystem,
                          borderRadius: BorderRadius.circular(8),
                          child: _row(
                            l10n.labelMaasa,
                            l10n.tdMaasaValue(
                              () {
                                final month =
                                    masaLabelForIndex(l10n, d.masa.monthIndex);
                                return d.masa.isAdhik
                                    ? l10n.masaAdhik(month)
                                    : month;
                              }(),
                              '${d.masa.samvatYear}',
                              d.masa.system == MasaSystem.purnimanta
                                  ? l10n.masaPurnimanta
                                  : l10n.masaAmanta,
                            ),
                          ),
                        ),
                        _row(l10n.labelPaksha,
                            pakshaLabelForIndex(l10n, d.panchang.tithiIndex)),
                        // One row per tithi touching today (sunrise →
                        // next sunrise): a transition day shows both,
                        // each with the moment it hands over.
                        for (var i = 0; i < d.tithis.length; i++)
                          _row(
                              i == 0 ? l10n.labelTithi : '',
                              '${tithiLabelForIndex(l10n, d.tithis[i].index)}'
                              '${_till(l10n, d.tithis[i].ends)}'),
                        _row(
                            l10n.labelNakshatra,
                            '${l10n.tdNakshatraValue(d.panchang.nakshatra.label(l10n), '${d.panchang.pada}')}'
                            '${_till(l10n, d.nakshatraEnds)}'),
                        _row(
                            l10n.labelYoga,
                            '${yogaLabelForIndex(l10n, d.panchang.yogaIndex)}'
                            '${_till(l10n, d.yogaEnds)}'),
                        _row(
                            l10n.labelKarana,
                            '${karanaLabelForIndex(l10n, d.panchang.karanaIndex)}'
                            '${_till(l10n, d.karanaEnds)}'),
                        _row(l10n.tdSunriseSunset,
                            '${_hm(d.sunrise)} / ${_hm(d.sunset)}'),
                        _row(
                            l10n.planetMoon,
                            '${d.positions[Planet.moon]!.sign.label(l10n)} · '
                            '${formatDegreeInSign(d.positions[Planet.moon]!.degreesInSign)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Muhurta / timings card: auspicious in green,
                  // inauspicious in maroon, all local math from the
                  // sunrise-sunset span.
                  ModuleCard(
                    title: l10n.tdTimingsCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _timeRow(l10n.mhBrahmaMuhurta, d.brahmaMuhurta,
                            good: true),
                        _timeRow(
                            '${l10n.mhAbhijitMuhurta}'
                            '${d.at.weekday == DateTime.wednesday ? l10n.mhAbhijitAvoidWednesday : ''}',
                            d.abhijitMuhurta,
                            good: d.at.weekday != DateTime.wednesday),
                        _timeRow(l10n.mhRahuKaal, d.rahuKalam, good: false),
                        _timeRow(l10n.mhYamaganda, d.yamaganda, good: false),
                        _timeRow(l10n.mhGulikaKaal, d.gulikaKalam, good: false),
                        if (d.dishaShool != null)
                          _row(
                              l10n.mhDishaShool,
                              l10n.mhDishaShoolValue(
                                  d.dishaShool!.label(l10n))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live transit card.
                  ModuleCard(
                    title: l10n.tdTransitNow,
                    // Degrees also live in the positions table below, so
                    // the wheel labels are optional — the '···' sheet
                    // toggles them, mirroring the dashboard widget menu.
                    onSettings: _showTransitOptions,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChartView(
                          placements: d.placements,
                          lagna: d.lagnaSign,
                          trueAscendantSign: d.lagnaSign,
                          ascendantDegree: d.ascendant,
                          style: ChartStyle.values.firstWhere(
                            (s) => s.name == _chartStyle,
                            orElse: () => ChartStyle.north,
                          ),
                          retrograde: {
                            for (final p in d.positions.values)
                              p.planet: p.isRetrograde,
                          },
                          // When on, annotate each graha with its
                          // degree-in-sign so the wheel matches the table;
                          // when off, no tokens => the original plain chart.
                          tokens: _showChartDegrees
                              ? {
                                  for (final p in d.positions.values)
                                    p.planet: PlanetToken(
                                      planet: p.planet,
                                      retrograde: p.isRetrograde,
                                      degreeInSign: p.degreesInSign,
                                    ),
                                }
                              : const {},
                          showDegrees: _showChartDegrees,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tdRisingLine(d.lagnaSign.label(l10n),
                              formatDegreeInSign(d.ascendant), _hm(d.at)),
                          style:
                              KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: KJColors.hairline),
                        const SizedBox(height: 12),
                        Text(l10n.transitPositionsHeading,
                            style: KJTheme.serif(size: 16)),
                        const SizedBox(height: 8),
                        TransitPositionsTable(
                          positions: d.positions,
                          ascendant: d.ascendant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // Label/value rows share the dashboard Panchang widget's style — label
  // left in soft ink, value right-aligned — so the Today cards read the
  // same as the kundli dashboard widgets.
  Widget _timeRow(String label, TimeWindow? w, {required bool good}) =>
      w == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(label,
                        style:
                            TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_hm(w.start)} – ${_hm(w.end)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: good ? KJColors.forest : KJColors.maroon,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
}

/// Minimal place typeahead over the existing Open-Meteo geocoding
/// service (the same one Birth Entry uses).
class _PlacePickerDialog extends ConsumerStatefulWidget {
  const _PlacePickerDialog();

  @override
  ConsumerState<_PlacePickerDialog> createState() => _PlacePickerDialogState();
}

class _PlacePickerDialogState extends ConsumerState<_PlacePickerDialog> {
  final _controller = TextEditingController();
  List<PlaceResult> _results = const [];
  Timer? _debounce;
  bool _locating = false;
  bool _locateFailed = false;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _locateFailed = false;
    });
    final detected = await CurrentLocationService.detect();
    if (!mounted) return;
    if (detected != null) {
      Navigator.pop(context, detected);
    } else {
      setState(() {
        _locating = false;
        _locateFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await ref.read(placeLookupProvider).search(q);
      if (mounted) setState(() => _results = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.tdPanchangLocation),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.my_location, color: KJColors.maroon),
              title: Text(
                _locating
                    ? context.l10n.tdLocating
                    : context.l10n.tdUseCurrentLocation,
                style: TextStyle(color: KJColors.maroon, fontSize: 14),
              ),
              subtitle: _locateFailed
                  ? Text(
                      context.l10n.tdLocateFailed,
                      style: const TextStyle(fontSize: 11),
                    )
                  : null,
              onTap: _locating ? null : _useCurrentLocation,
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(hintText: context.l10n.tdSearchCity),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 8),
            for (final r in _results.take(6))
              ListTile(
                dense: true,
                title: Text(r.displayName),
                onTap: () => Navigator.pop(
                  context,
                  TodayPlace(
                    name: r.displayName,
                    latitude: r.latitude,
                    longitude: r.longitude,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}
