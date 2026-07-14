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
      backgroundColor: TEColors.paper,
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
                Text('Transit now', style: TETheme.serif(size: 18)),
                const SizedBox(height: 14),
                const TESectionLabel('Display'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Planet degrees',
                          style: TextStyle(fontSize: 12.5)),
                      selected: _showChartDegrees,
                      checkmarkColor: TEColors.paper,
                      labelStyle: TextStyle(
                          fontSize: 12.5,
                          color: _showChartDegrees
                              ? TEColors.paper
                              : TEColors.ink),
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
                    child: const Text('Done'),
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

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];

  /// "till 14:32" or "till tomorrow 02:10".
  String _till(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final tomorrow = t.day != now.day;
    return ' · till ${tomorrow ? 'tomorrow ' : ''}${_hm(t)}';
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final place = _place;
    return TEScaffold(
      section: TESection.today,
      appBar: AppBar(title: const Text('Today')),
      body: d == null
          ? Center(
              child: _error != null
                  ? Text('Calculation failed: $_error')
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
                          color: TEColors.maroon.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: TEColors.maroon.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 18, color: TEColors.maroon),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Timings are for New Delhi — tap to set'
                                ' your city for accurate sunrise & muhurta.',
                                style: TextStyle(
                                    fontSize: 12.5, color: TEColors.maroon),
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
                          // English UI, English weekday (the Sanskrit
                          // vara stays in kundli panchang contexts).
                          '${_weekdays[d.at.weekday - 1]} · '
                          '${TEDate.date(d.at)}',
                          style: TETheme.serif(size: 18),
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
                                  size: 14, color: TEColors.maroon),
                              const SizedBox(width: 3),
                              Text(
                                place?.name.split(',').first ?? '',
                                style: TETheme.mono(
                                    size: 11.5, color: TEColors.maroon),
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
                    title: 'Panchang',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vikram Samvat month + year. Tap to switch the
                        // naming convention (Purnimanta ⇄ Amanta).
                        InkWell(
                          onTap: _toggleMasaSystem,
                          borderRadius: BorderRadius.circular(8),
                          child: _row(
                            'Maasa',
                            '${d.masa.displayName} · V.S. ${d.masa.samvatYear}'
                            '  (${d.masa.system == MasaSystem.purnimanta ? 'Purnimanta' : 'Amanta'} ⇄)',
                          ),
                        ),
                        _row('Paksha', d.panchang.paksha),
                        // One row per tithi touching today (sunrise →
                        // next sunrise): a transition day shows both,
                        // each with the moment it hands over.
                        for (var i = 0; i < d.tithis.length; i++)
                          _row(i == 0 ? 'Tithi' : '',
                              '${d.tithis[i].name}${_till(d.tithis[i].ends)}'),
                        _row(
                            'Nakshatra',
                            '${d.panchang.nakshatra.displayName}'
                            ' (pada ${d.panchang.pada})'
                            '${_till(d.nakshatraEnds)}'),
                        _row('Yoga',
                            '${d.panchang.yogaName}${_till(d.yogaEnds)}'),
                        _row('Karana',
                            '${d.panchang.karanaName}${_till(d.karanaEnds)}'),
                        _row('Sunrise / Sunset',
                            '${_hm(d.sunrise)} / ${_hm(d.sunset)}'),
                        _row(
                            'Moon',
                            '${d.positions[Planet.moon]!.sign.western} · '
                            '${formatDegreeInSign(d.positions[Planet.moon]!.degreesInSign)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Muhurta / timings card: auspicious in green,
                  // inauspicious in maroon, all local math from the
                  // sunrise-sunset span.
                  ModuleCard(
                    title: 'Timings',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _timeRow('Brahma Muhurta', d.brahmaMuhurta,
                            good: true),
                        _timeRow(
                            'Abhijit Muhurta'
                            '${d.at.weekday == DateTime.wednesday ? ' (avoid — Wednesday)' : ''}',
                            d.abhijitMuhurta,
                            good: d.at.weekday != DateTime.wednesday),
                        _timeRow('Rahu Kaal', d.rahuKalam, good: false),
                        _timeRow('Yamaganda', d.yamaganda, good: false),
                        _timeRow('Gulika Kaal', d.gulikaKalam, good: false),
                        if (d.dishaShool != null)
                          _row('Disha Shool',
                              '${d.dishaShool} — avoid setting out this way'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live transit card.
                  ModuleCard(
                    title: 'Transit now',
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
                          'Rising ${d.lagnaSign.western}'
                          ' ${formatDegreeInSign(d.ascendant)}'
                          ' · as of ${_hm(d.at)}',
                          style: TETheme.mono(
                              size: 11.5, color: TEColors.inkSoft),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: TEColors.hairline),
                        const SizedBox(height: 12),
                        Text('Transit Positions',
                            style: TETheme.serif(size: 16)),
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
                        style: TextStyle(
                            fontSize: 12.5, color: TEColors.inkSoft)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_hm(w.start)} – ${_hm(w.end)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: good ? TEColors.forest : TEColors.maroon,
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
                style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft)),
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
  ConsumerState<_PlacePickerDialog> createState() =>
      _PlacePickerDialogState();
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
      title: const Text('Panchang location'),
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
                  : Icon(Icons.my_location, color: TEColors.maroon),
              title: Text(
                _locating ? 'Locating…' : 'Use current location',
                style: TextStyle(color: TEColors.maroon, fontSize: 14),
              ),
              subtitle: _locateFailed
                  ? const Text(
                      'Could not get location — check permission,'
                      ' or search below',
                      style: TextStyle(fontSize: 11),
                    )
                  : null,
              onTap: _locating ? null : _useCurrentLocation,
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search city…'),
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
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
