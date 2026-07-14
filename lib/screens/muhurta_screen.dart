/// Muhurta — a standalone section (menu entry, not a nav pill) for
/// checking a chosen date & place: Panchang, the Choghadiya/Hora day
/// timeline, Rahu Kaal/Yamaganda/Gulika Kaal/Abhijit, and an optional
/// personalized Tara bala / Chandra bala check against a saved kundli.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/astro/daily_panchang.dart' show TimeWindow;
import '../core/astro/ephemeris_service.dart';
import '../core/astro/models.dart';
import '../core/astro/muhurta.dart';
import '../core/astro/panchang.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/settings_repository.dart';
import '../services/current_location_service.dart';
import '../services/place_lookup_service.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class _MuhurtaData {
  const _MuhurtaData({
    required this.sunrise,
    required this.sunset,
    required this.nextSunrise,
    required this.panchang,
    required this.moonSign,
    required this.choghadiyaDay,
    required this.choghadiyaNight,
    required this.hora,
    required this.rahuKaal,
    required this.yamaganda,
    required this.gulikaKaal,
    required this.abhijit,
    required this.abhijitApplies,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime nextSunrise;
  final PanchangData panchang;
  final ZodiacSign moonSign;
  final List<MuhurtaSegment> choghadiyaDay;
  final List<MuhurtaSegment> choghadiyaNight;
  final List<MuhurtaSegment> hora;
  final TimeWindow rahuKaal;
  final TimeWindow yamaganda;
  final TimeWindow gulikaKaal;
  final TimeWindow abhijit;
  final bool abhijitApplies;
}

class MuhurtaScreen extends ConsumerStatefulWidget {
  const MuhurtaScreen({super.key});

  @override
  ConsumerState<MuhurtaScreen> createState() => _MuhurtaScreenState();
}

class _MuhurtaScreenState extends ConsumerState<MuhurtaScreen> {
  DateTime _date = DateTime.now();
  TodayPlace? _place;
  int? _ayanamsaId;
  String? _personalizeKundliId;
  _MuhurtaData? _data;
  Object? _error;

  static final _hm = DateFormat('HH:mm');
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settings = ref.read(settingsRepoProvider);
    // Default: device location if already known (same "current place"
    // concept as Today), else the app default — the personalize picker
    // covers "last kundli's place" implicitly once a kundli is chosen.
    final place = await settings.todayPlace();
    final ayanamsa = await settings.defaultAyanamsaId();
    if (!mounted) return;
    setState(() {
      _place = place;
      _ayanamsaId = ayanamsa;
    });
    await _compute();
  }

  Future<void> _compute() async {
    final place = _place;
    final ayanamsa = _ayanamsaId;
    if (place == null || ayanamsa == null) return;
    try {
      await EphemerisService.init();
      final svc = EphemerisService.instance;
      final today = svc.sunRiseSet(_date, place.latitude, place.longitude);
      final tomorrow = svc.sunRiseSet(
          _date.add(const Duration(days: 1)), place.latitude, place.longitude);
      final sunrise = today.rise;
      final sunset = today.set;
      final nextSunrise = tomorrow.rise;

      final jdSunrise = svc.julianDayUt(sunrise.toUtc());
      final positions = svc.planetPositions(jdSunrise, ayanamsa);
      final panchang = computePanchang(
        sunLongitude: positions[Planet.sun]!.longitude,
        moonLongitude: positions[Planet.moon]!.longitude,
        localDateTime: sunrise,
      );
      final chog = choghadiyaSegments(
          sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise);

      final data = _MuhurtaData(
        sunrise: sunrise,
        sunset: sunset,
        nextSunrise: nextSunrise,
        panchang: panchang,
        moonSign: positions[Planet.moon]!.sign,
        choghadiyaDay: chog.day,
        choghadiyaNight: chog.night,
        hora: horaSegments(
            sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise),
        rahuKaal: rahuKaalWindow(sunrise, sunset),
        yamaganda: yamagandaWindow(sunrise, sunset),
        gulikaKaal: gulikaKaalWindow(sunrise, sunset),
        abhijit: abhijitMuhurtaWindow(sunrise, sunset),
        abhijitApplies: abhijitApplies(sunrise),
      );
      if (mounted) setState(() { _data = data; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1800),
      lastDate: DateTime(2400),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _compute();
  }

  Future<void> _pickPlace() async {
    final picked = await showDialog<TodayPlace>(
      context: context,
      builder: (_) => const _MuhurtaPlacePickerDialog(),
    );
    if (picked == null) return;
    setState(() => _place = picked);
    await _compute();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Muhurta')),
      body: d == null
          ? Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Calculation failed: $_error',
                          textAlign: TextAlign.center))
                  : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _compute,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _dateplaceRow(),
                  const SizedBox(height: 12),
                  ModuleCard(
                    title: 'Panchang',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Tithi', '${d.panchang.paksha} ${d.panchang.tithiName}'),
                        _row('Vara', d.panchang.vara),
                        _row('Nakshatra',
                            '${d.panchang.nakshatra.displayName} · pada ${d.panchang.pada}'),
                        _row('Yoga', d.panchang.yogaName),
                        _row('Karana', d.panchang.karanaName),
                        _row('Sunrise / Sunset',
                            '${_hm.format(d.sunrise)} / ${_hm.format(d.sunset)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ModuleCard(
                    title: 'Windows',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _windowRow('Abhijit Muhurta'
                            '${d.abhijitApplies ? '' : ' (avoid — Wednesday)'}',
                            d.abhijit, good: d.abhijitApplies),
                        _windowRow('Rahu Kaal', d.rahuKaal, good: false),
                        _windowRow('Yamaganda', d.yamaganda, good: false),
                        _windowRow('Gulika Kaal', d.gulikaKaal, good: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ModuleCard(
                    title: 'Choghadiya',
                    child: _ChoghadiyaTable(day: d.choghadiyaDay, night: d.choghadiyaNight),
                  ),
                  const SizedBox(height: 12),
                  ModuleCard(
                    title: 'Hora',
                    child: _HoraTable(hora: d.hora),
                  ),
                  const SizedBox(height: 12),
                  ModuleCard(
                    title: 'Personalize',
                    child: _PersonalizeSection(
                      selectedKundliId: _personalizeKundliId,
                      onChanged: (id) => setState(() => _personalizeKundliId = id),
                      dayNakshatra: d.panchang.nakshatra,
                      dayMoonSign: d.moonSign,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _dateplaceRow() => Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: TEColors.maroon),
                    const SizedBox(width: 6),
                    Text(
                      '${_weekdays[_date.weekday - 1]} · '
                      '${TEDate.date(_date)}',
                      style: TETheme.serif(size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: _pickPlace,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place_outlined, size: 14, color: TEColors.maroon),
                  const SizedBox(width: 3),
                  Text(
                    _place?.name.split(',').first ?? '',
                    style: TETheme.mono(size: 11.5, color: TEColors.maroon),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: Text(label,
                  style: TETheme.mono(size: 11.5, color: TEColors.inkSoft)),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      );

  Widget _windowRow(String label, TimeWindow w, {required bool good}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: TETheme.mono(size: 11.5, color: TEColors.inkSoft)),
            ),
            Expanded(
              child: Text(
                '${_hm.format(w.start)} – ${_hm.format(w.end)}',
                style: TextStyle(
                  fontSize: 13.5,
                  color: good ? TEColors.forest : TEColors.maroon,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ChoghadiyaTable extends StatelessWidget {
  const _ChoghadiyaTable({required this.day, required this.night});
  final List<MuhurtaSegment> day;
  final List<MuhurtaSegment> night;

  static final _hm = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('DAY'),
        for (final s in day) _segRow(s),
        const SizedBox(height: 8),
        _label('NIGHT'),
        for (final s in night) _segRow(s),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.8,
                color: TEColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );

  Widget _segRow(MuhurtaSegment s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text('${_hm.format(s.start)} – ${_hm.format(s.end)}',
                  style: TETheme.mono(size: 11, color: TEColors.inkSoft)),
            ),
            Text(s.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: (s.good ?? false) ? TEColors.forest : TEColors.maroon,
                )),
          ],
        ),
      );
}

class _HoraTable extends StatelessWidget {
  const _HoraTable({required this.hora});
  final List<MuhurtaSegment> hora;

  static final _hm = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in hora)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text('${_hm.format(s.start)} – ${_hm.format(s.end)}',
                      style: TETheme.mono(size: 11, color: TEColors.inkSoft)),
                ),
                Text(s.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: s.planet != null ? planetInk(s.planet!) : TEColors.ink,
                    )),
              ],
            ),
          ),
      ],
    );
  }
}

class _PersonalizeSection extends ConsumerWidget {
  const _PersonalizeSection({
    required this.selectedKundliId,
    required this.onChanged,
    required this.dayNakshatra,
    required this.dayMoonSign,
  });

  final String? selectedKundliId;
  final ValueChanged<String?> onChanged;
  final Nakshatra dayNakshatra;
  final ZodiacSign dayMoonSign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundlis = ref.watch(kundlisProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kundlis.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Could not load kundlis: $e'),
          data: (list) => DropdownButton<String?>(
            isExpanded: true,
            value: selectedKundliId,
            hint: const Text('Choose a kundli…'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('None')),
              for (final k in list)
                DropdownMenuItem<String?>(value: k.id, child: Text(k.name)),
            ],
            onChanged: onChanged,
          ),
        ),
        if (selectedKundliId != null) ...[
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final snapshot = ref.watch(snapshotProvider(selectedKundliId!));
            return snapshot.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not compute: $e'),
              data: (s) {
                final tara = taraBala(
                    janmaNakshatra: s.moonNakshatra, dayNakshatra: dayNakshatra);
                final chandra = chandraBala(
                    janmaRashi: s.moonSign, dayMoonSign: dayMoonSign);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text('Tara bala',
                              style: TETheme.mono(
                                  size: 11.5, color: TEColors.inkSoft)),
                        ),
                        Expanded(
                          child: TETag(
                            '${tara.label}'
                            '${tara.favorable ? ' · favorable' : ' · unfavorable'}',
                            maroon: !tara.favorable,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text('Chandra bala',
                              style: TETheme.mono(
                                  size: 11.5, color: TEColors.inkSoft)),
                        ),
                        Expanded(
                          child: TETag(
                            switch (chandra) {
                              ChandraBalaResult.favorable => 'Favorable',
                              ChandraBalaResult.neutral => 'Neutral',
                              ChandraBalaResult.unfavorable => 'Unfavorable',
                            },
                            maroon: chandra == ChandraBalaResult.unfavorable,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          }),
        ],
      ],
    );
  }
}

/// Place picker for the Muhurta date+place header — mirrors the Today
/// screen's dialog (current location or search), kept as a separate
/// small copy so this screen has no dependency on Today's private
/// widget.
class _MuhurtaPlacePickerDialog extends ConsumerStatefulWidget {
  const _MuhurtaPlacePickerDialog();

  @override
  ConsumerState<_MuhurtaPlacePickerDialog> createState() =>
      _MuhurtaPlacePickerDialogState();
}

class _MuhurtaPlacePickerDialogState
    extends ConsumerState<_MuhurtaPlacePickerDialog> {
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
      title: const Text('Muhurta location'),
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
