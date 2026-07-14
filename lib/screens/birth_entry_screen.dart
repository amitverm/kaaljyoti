/// Screen 01 — Birth Details Entry. Name, DOB, time, place typeahead
/// (auto lat/long/timezone), relation, an optional free-text note, and an
/// "Advanced" section for the ayanamsa override. Chart style follows the
/// app default (overridable in Kundli Details). Prashna variant and the
/// on-device trust statement included.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../charts/chart_style.dart';
import '../core/astro/ayanamsa.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../services/location_service.dart';
import '../services/place_lookup_service.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class BirthEntryScreen extends ConsumerStatefulWidget {
  const BirthEntryScreen({super.key, this.prashna = false});
  final bool prashna;

  @override
  ConsumerState<BirthEntryScreen> createState() => _BirthEntryScreenState();
}

class _BirthEntryScreenState extends ConsumerState<BirthEntryScreen> {
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  PlaceResult? _place;
  List<PlaceResult> _placeResults = [];
  Timer? _debounce;
  int _ayanamsaId = Ayanamsa.lahiri.id;
  // Chart style is no longer chosen here — new kundlis adopt the app-wide
  // default (set in Profile / on the widgets); it can still be overridden
  // per kundli on the Kundli Details screen.
  ChartStyle _style = ChartStyle.north;
  String _relationTag = 'Client';
  bool _syncEnabled = true; // default ON for signed-in users
  bool _saving = false;

  // Client-first ordering — this app is used by professional astrologers,
  // so the chart is usually someone other than the user.
  static const _relationTags = [
    'Client',
    'Self',
    'Spouse',
    'Family',
    'Friend',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prashna) {
      final now = DateTime.now();
      _date = now;
      _time = TimeOfDay.fromDateTime(now);
    }
    ref.read(settingsRepoProvider).defaultAyanamsaId().then((id) {
      if (mounted) setState(() => _ayanamsaId = id);
    });
    ref.read(settingsRepoProvider).defaultChartStyle().then((s) {
      if (mounted) {
        setState(() => _style = ChartStyle.values
            .firstWhere((e) => e.name == s, orElse: () => ChartStyle.north));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _placeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _locating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final place = await LocationService().currentPlace();
      if (!mounted) return;
      setState(() {
        _place = place;
        _placeController.text = place.displayName;
        _placeResults = [];
      });
    } on LocationDenied catch (denied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(denied.permanently
            ? 'Location is disabled for this app — enable it in Settings.'
            : 'Location unavailable — type the place instead.'),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not get your location — type the place.')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onPlaceQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await ref.read(placeLookupProvider).search(q);
      if (mounted) setState(() => _placeResults = results);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _date == null || _time == null || _place == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name, date, time and place are all required.')));
      return;
    }
    setState(() => _saving = true);
    final signedIn = ref.read(authUserProvider).value != null;
    try {
      final localWall = DateTime(
          _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
      final resolved = ref
          .read(placeLookupProvider)
          .resolveLocalTime(_place!.timezoneName, localWall);

      final kundli = await ref.read(kundliRepoProvider).create(
            name: name,
            relationTag: _relationTag,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            birthUtc: resolved.utc,
            latitude: _place!.latitude,
            longitude: _place!.longitude,
            timezoneName: _place!.timezoneName,
            utcOffsetMinutes: resolved.offsetMinutes,
            placeName: _place!.displayName,
            ayanamsaOverrideId:
                _ayanamsaId == Ayanamsa.lahiri.id ? null : _ayanamsaId,
            chartStyle: _style.name,
            isPrashna: widget.prashna,
            syncEnabled: !widget.prashna && signedIn && _syncEnabled,
          );
      if (kundli.syncEnabled) {
        // Fire-and-forget initial backup; sync is best-effort.
        ref.read(syncServiceProvider)?.pushAll();
      }
      ref.invalidate(kundlisProvider);
      // Replace the form with the dashboard: Home stays underneath, so
      // the dashboard gets a back button and back doesn't re-open the
      // filled-in form.
      if (mounted) context.pushReplacement('/kundli/${kundli.id}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prashna ? 'Prashna Kundli' : 'Birth Details'),
      ),
      body: ListView(
        padding: formPadding(context),
        children: [
          if (widget.prashna)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'A question chart cast for this exact moment.',
                style:
                    TextStyle(fontSize: 13, color: TEColors.inkSoft),
              ),
            ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date ?? DateTime(1990),
                      firstDate: DateTime(1800),
                      lastDate: DateTime(2100),
                      // Type the date directly — far faster than paging a
                      // calendar across decades for a birth year.
                      initialEntryMode: DatePickerEntryMode.input,
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: Text(_date == null
                      ? 'Date of birth'
                      : TEDate.date(_date!)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _time ?? const TimeOfDay(hour: 6, minute: 0),
                      // Birth times are exact — open the keypad, not the
                      // 5-minute-snap dial.
                      initialEntryMode: TimePickerEntryMode.input,
                    );
                    if (t != null) setState(() => _time = t);
                  },
                  child: Text(
                      _time == null ? 'Time' : _time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placeController,
            decoration: InputDecoration(
              labelText: 'Place of birth',
              helperText: _place == null
                  ? 'Start typing — lat/long & timezone resolve automatically'
                  : '${_place!.latitude.toStringAsFixed(4)}, '
                      '${_place!.longitude.toStringAsFixed(4)} · '
                      '${_place!.timezoneName}',
            ),
            onChanged: (q) {
              setState(() => _place = null);
              _onPlaceQuery(q);
            },
          ),
          if (_placeResults.isNotEmpty && _place == null)
            Card(
              margin: const EdgeInsets.only(top: 4),
              child: Column(
                children: [
                  for (final r in _placeResults)
                    ListTile(
                      dense: true,
                      title: Text(r.displayName),
                      onTap: () => setState(() {
                        _place = r;
                        _placeController.text = r.displayName;
                        _placeResults = [];
                      }),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: Icon(
                  _locating ? Icons.hourglass_empty : Icons.my_location,
                  size: 18),
              label: Text(
                  _locating ? 'Locating…' : 'Use current location'),
              onPressed: _locating ? null : _useCurrentLocation,
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('RELATION'),
          Wrap(
            spacing: 8,
            children: [
              for (final tag in _relationTags)
                ChoiceChip(
                  label: Text(tag),
                  selected: _relationTag == tag,
                  labelStyle: TextStyle(
                      color: _relationTag == tag
                          ? TEColors.paper
                          : TEColors.ink),
                  onSelected: (_) => setState(() => _relationTag = tag),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('NOTE (OPTIONAL)'),
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Who is this? e.g. "Ramesh\'s daughter — match"',
            ),
          ),
          const SizedBox(height: 8),
          // Chart style follows the app-wide default set in Profile / on the
          // widgets, so it isn't asked here; it can be overridden per kundli
          // in Kundli Details. Ayanamsa is tucked away — a professional sets
          // it once and rarely changes it per chart.
          Theme(
            data:
                Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Text('Advanced',
                  style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      color: TEColors.inkSoft,
                      fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Ayanamsa · ${Ayanamsa.byId(_ayanamsaId).name}',
                style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
              ),
              children: [
                _sectionLabel('AYANAMSA'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in Ayanamsa.quickPicks)
                      ChoiceChip(
                        label: Text(a.name),
                        selected: _ayanamsaId == a.id,
                        labelStyle: TextStyle(
                            color: _ayanamsaId == a.id
                                ? TEColors.paper
                                : TEColors.ink),
                        onSelected: (_) =>
                            setState(() => _ayanamsaId = a.id),
                      ),
                    ActionChip(
                      label: Text(
                          Ayanamsa.quickPicks.any((a) => a.id == _ayanamsaId)
                              ? 'More…'
                              : 'More… (${Ayanamsa.byId(_ayanamsaId).name})'),
                      onPressed: _showAllAyanamsas,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.prashna &&
              ref.watch(authUserProvider).value != null) ...[
            const SizedBox(height: 20),
            _sectionLabel('CLOUD SYNC'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _syncEnabled,
              activeColor: TEColors.maroon,
              title: const Text('Back up & sync this kundli',
                  style: TextStyle(fontSize: 13.5)),
              subtitle: Text(
                'Available on all your devices. Change anytime in '
                'Kundli Details.',
                style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
              ),
              onChanged: (v) => setState(() => _syncEnabled = v),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Casting…' : 'Cast Kundli'),
          ),
          if (!widget.prashna)
            TextButton(
              onPressed: () => context.push('/new?prashna=1'),
              child: const Text(
                  'Or cast a Prashna kundli for this exact moment'),
            ),
          const SizedBox(height: 16),
          Text(
            'Computed on-device. Your kundali never '
            'leaves this phone unless you turn on sync.',
            textAlign: TextAlign.center,
            style: TETheme.mono(size: 11, color: TEColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => TESectionLabel(t, padded: true);

  void _showAllAyanamsas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TEColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final a in Ayanamsa.all)
            ListTile(
              dense: true,
              title: Text(a.name),
              trailing: _ayanamsaId == a.id
                  ? Icon(Icons.check, color: TEColors.maroon, size: 18)
                  : null,
              onTap: () {
                setState(() => _ayanamsaId = a.id);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }
}
