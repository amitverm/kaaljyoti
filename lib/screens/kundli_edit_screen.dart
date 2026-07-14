/// Screen 03 — Kundli Details (Edit). Same field set as onboarding,
/// plus: recalculation warning, per-kundli ayanamsa override, cloud
/// sync toggle, Mahakosh share/withdraw, and delete.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../charts/chart_style.dart';
import '../core/astro/ayanamsa.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../mahakosh/models.dart';
import '../services/place_lookup_service.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class KundliEditScreen extends ConsumerStatefulWidget {
  const KundliEditScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  ConsumerState<KundliEditScreen> createState() => _KundliEditScreenState();
}

class _KundliEditScreenState extends ConsumerState<KundliEditScreen> {
  Kundli? _kundli;
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  PlaceResult? _newPlace;
  List<PlaceResult> _placeResults = [];
  Timer? _debounce;
  bool _dirtyBirthData = false;

  @override
  void initState() {
    super.initState();
    ref.read(kundliRepoProvider).byId(widget.kundliId).then((k) {
      if (k == null || !mounted) return;
      final local = k.toBirthData().localDateTime;
      setState(() {
        _kundli = k;
        _nameController.text = k.name;
        _placeController.text = k.placeName;
        _noteController.text = k.note ?? '';
        _date = DateTime(local.year, local.month, local.day);
        _time = TimeOfDay(hour: local.hour, minute: local.minute);
      });
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

  Future<void> _save() async {
    final k = _kundli;
    if (k == null) return;
    final noteText = _noteController.text.trim();
    var updated = k.copyWith(
      name: _nameController.text.trim(),
      note: noteText.isEmpty ? null : noteText,
      clearNote: noteText.isEmpty,
    );

    if (_dirtyBirthData && _date != null && _time != null) {
      final place = _newPlace;
      final tzName = place?.timezoneName ?? k.timezoneName;
      final localWall = DateTime(
          _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
      final resolved =
          ref.read(placeLookupProvider).resolveLocalTime(tzName, localWall);
      updated = updated.copyWith(
        birthUtc: resolved.utc,
        utcOffsetMinutes: resolved.offsetMinutes,
        latitude: place?.latitude,
        longitude: place?.longitude,
        timezoneName: place?.timezoneName,
        placeName: place?.displayName,
      );
    }

    await ref.read(kundliRepoProvider).update(updated);
    ref.invalidate(kundlisProvider);
    ref.invalidate(snapshotProvider(k.id));
    ref.invalidate(moduleContextProvider(k.id));
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this kundli?'),
        content: const Text(
            'This removes the kundli and its dashboard layouts from this '
            'device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: TEColors.maroon))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(kundliRepoProvider).delete(widget.kundliId);
    // Tombstone (not hard-delete) so other devices apply the deletion.
    ref.read(syncServiceProvider)?.deleteRemote(widget.kundliId);
    ref.invalidate(kundlisProvider);
    if (mounted) context.go('/');
  }

  /// Push the kundli's CURRENT life events to its already-shared Mahakosh
  /// chart (same MK code). Events recorded after the first share otherwise
  /// wouldn't reach Mahakosh without a withdraw + re-share.
  Future<void> _updateMahakoshEvents() async {
    final k = _kundli;
    if (k?.mahakoshCode == null) return;
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null) return;
    final stored = await ref.read(kundliEventRepoProvider).forKundli(k!.id);
    if (!mounted) return;
    final inputs = lifeEventsFromStored(stored);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Mahakosh events?'),
        content: Text(inputs.isEmpty
            ? 'This removes all life events from the shared chart.'
            : 'This replaces the shared chart\'s life events with the '
                '${inputs.length} event${inputs.length == 1 ? '' : 's'} on '
                'this kundli. The chart keeps the same code.\n\n'
                'Event titles and notes become visible to researchers — '
                'check they contain no names or other identifying details.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.updateEvents(mkCode: k.mahakoshCode!, events: inputs);
      // Drop the cached community-chart fetch so its Life Events card shows
      // the new set next time it's opened.
      ref.invalidate(mahakoshChartProvider(k.mahakoshCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Mahakosh chart updated · ${inputs.length} '
                'event${inputs.length == 1 ? '' : 's'}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update events: $e')));
      }
    }
  }

  Future<void> _withdraw() async {
    final k = _kundli;
    if (k?.mahakoshCode == null) return;
    final repo = ref.read(mahakoshRepoProvider);
    if (repo != null) await repo.withdraw(k!.mahakoshCode!);
    final updated = k!.copyWith(clearMahakoshCode: true);
    await ref.read(kundliRepoProvider).update(updated);
    setState(() => _kundli = updated);
    ref.invalidate(kundlisProvider);
  }

  @override
  Widget build(BuildContext context) {
    final k = _kundli;
    if (k == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = ref.watch(authUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kundli Details'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: formPadding(context),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: TEColors.maroon.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: TEColors.maroon.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Changing birth details recalculates every widget for this '
              'kundli.',
              style: TextStyle(fontSize: 12.5, color: TEColors.maroon),
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
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
                      initialEntryMode: DatePickerEntryMode.input,
                    );
                    if (d != null)

                      setState(() {
                        _date = d;
                        _dirtyBirthData = true;
                      });
                  },
                  child: Text(_date == null
                      ? 'Date'
                      : TEDate.date(_date!)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: context,
                        initialTime:
                            _time ?? const TimeOfDay(hour: 6, minute: 0),
                        initialEntryMode: TimePickerEntryMode.input);
                    if (t != null)

                      setState(() {
                        _time = t;
                        _dirtyBirthData = true;
                      });
                  },
                  child:
                      Text(_time == null ? 'Time' : _time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placeController,
            decoration: const InputDecoration(labelText: 'Place of birth'),
            onChanged: (q) {
              setState(() {
                _newPlace = null;
                _dirtyBirthData = true;
              });
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () async {
                final results =
                    await ref.read(placeLookupProvider).search(q);
                if (mounted) setState(() => _placeResults = results);
              });
            },
          ),
          if (_placeResults.isNotEmpty && _newPlace == null)
            Card(
              margin: const EdgeInsets.only(top: 4),
              child: Column(
                children: [
                  for (final r in _placeResults)
                    ListTile(
                      dense: true,
                      title: Text(r.displayName),
                      onTap: () => setState(() {
                        _newPlace = r;
                        _placeController.text = r.displayName;
                        _placeResults = [];
                      }),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Who is this? e.g. "Ramesh\'s daughter — match"',
            ),
          ),
          const SizedBox(height: 24),
          _settingBlock(
            title: 'Chart style',
            subtitle: ChartStyle.values
                .firstWhere((s) => s.name == k.chartStyle,
                    orElse: () => ChartStyle.north)
                .displayName,
            child: TextButton(
              onPressed: _pickChartStyle,
              child: const Text('Change…'),
            ),
          ),
          _settingBlock(
            title: 'Ayanamsa override',
            subtitle: k.ayanamsaOverrideId == null
                ? 'Using app default (${Ayanamsa.byId(Ayanamsa.lahiri.id).name}) '
                    '— set in Profile'
                : 'This kundli: ${Ayanamsa.byId(k.ayanamsaOverrideId!).name}',
            child: TextButton(
              onPressed: _pickAyanamsa,
              child: Text(
                  k.ayanamsaOverrideId == null ? 'Override…' : 'Change…'),
            ),
          ),
          _settingBlock(
            title: 'Cloud sync',
            subtitle: user == null
                ? 'Sign in to sync this kundli across devices'
                : (k.syncEnabled
                    ? 'Syncing to your account'
                    : 'Device only'),
            child: user == null
                ? TextButton(
                    onPressed: () => context.push('/signin'),
                    child: const Text('Sign in'))
                : Switch(
                    value: k.syncEnabled,
                    activeColor: TEColors.maroon,
                    onChanged: (v) async {
                      final updated = k.copyWith(syncEnabled: v);
                      await ref.read(kundliRepoProvider).update(updated);
                      setState(() => _kundli = updated);
                      final sync = ref.read(syncServiceProvider);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        if (v) {
                          await sync?.pushAll();
                        } else {
                          await sync?.removeRemote(k.id);
                        }
                      } catch (e) {
                        // A silent sync failure here cost a debugging
                        // session once (duplicate-id upsert, 0022) —
                        // never swallow it again.
                        messenger.showSnackBar(SnackBar(
                            content: Text('Sync failed: $e')));
                      }
                    },
                  ),
          ),
          _settingBlock(
            title: 'Mahakosh',
            subtitle: k.isSharedToMahakosh
                ? 'Shared to Mahakosh · ${k.mahakoshCode} (anonymized)'
                : 'Not shared',
            child: k.isSharedToMahakosh
                ? TextButton(
                    onPressed: _withdraw,
                    child: Text('Withdraw',
                        style: TextStyle(color: TEColors.maroon)))
                : TextButton(
                    onPressed: () =>
                        context.push('/kundli/${k.id}/contribute'),
                    child: const Text('Share…')),
          ),
          if (k.isSharedToMahakosh)
            _settingBlock(
              title: 'Mahakosh events',
              subtitle: 'Push this kundli\'s current life events to the '
                  'shared chart',
              child: TextButton(
                onPressed: _updateMahakoshEvents,
                child: const Text('Update'),
              ),
            ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(
                foregroundColor: TEColors.maroon,
                side: BorderSide(color: TEColors.maroon)),
            child: const Text('Delete kundli'),
          ),
        ],
      ),
    );
  }

  Widget _settingBlock({
    required String title,
    required String subtitle,
    required Widget child,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: TEColors.inkSoft)),
                  ],
                ),
              ),
              child,
            ],
          ),
        ),
      );

  void _pickChartStyle() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TEColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final s in ChartStyle.values)
            ListTile(
              dense: true,
              title: Text(s.displayName),
              trailing: _kundli!.chartStyle == s.name
                  ? Icon(Icons.check, color: TEColors.maroon, size: 18)
                  : null,
              onTap: () async {
                final updated = _kundli!.copyWith(chartStyle: s.name);
                await ref.read(kundliRepoProvider).update(updated);
                setState(() => _kundli = updated);
                ref.invalidate(snapshotProvider(widget.kundliId));
                ref.invalidate(moduleContextProvider(widget.kundliId));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _pickAyanamsa() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TEColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          ListTile(
            dense: true,
            title: const Text('Use app default'),
            onTap: () async {
              final updated = _kundli!.copyWith(clearAyanamsaOverride: true);
              await ref.read(kundliRepoProvider).update(updated);
              setState(() => _kundli = updated);
              ref.invalidate(snapshotProvider(widget.kundliId));
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          for (final a in Ayanamsa.all)
            ListTile(
              dense: true,
              title: Text(a.name),
              trailing: _kundli!.ayanamsaOverrideId == a.id
                  ? Icon(Icons.check, color: TEColors.maroon, size: 18)
                  : null,
              onTap: () async {
                final updated =
                    _kundli!.copyWith(ayanamsaOverrideId: a.id);
                await ref.read(kundliRepoProvider).update(updated);
                setState(() => _kundli = updated);
                ref.invalidate(snapshotProvider(widget.kundliId));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }
}
