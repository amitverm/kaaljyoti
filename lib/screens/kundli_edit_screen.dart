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
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../mahakosh/models.dart';
import '../services/place_lookup_service.dart';
import '../ui/date_fields.dart';
import '../l10n/astro_l10n.dart';
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
  bool _placeSearchFailed = false;

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
    // Captured before the awaits — the catch below must not touch
    // context (use_build_context_synchronously is an error here).
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
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
    } catch (e) {
      // Same belt as birth entry: a bad place/timezone (or repo error)
      // must surface, not crash — the form stays filled for a retry.
      messenger.showSnackBar(SnackBar(content: Text(l10n.keSaveFailed('$e'))));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.keDeleteTitle),
        content: Text(ctx.l10n.keDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.delete,
                  style: TextStyle(color: KJColors.maroon))),
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
        title: Text(ctx.l10n.keUpdateEventsTitle),
        content: Text(inputs.isEmpty
            ? ctx.l10n.keUpdateEventsEmpty
            : ctx.l10n.keUpdateEventsBody(inputs.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.keUpdate)),
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
            content: Text(context.l10n.keEventsUpdated(inputs.length))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.keUpdateEventsError('$e'))));
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
        title: Text(context.l10n.keTitle),
        actions: [
          TextButton(onPressed: _save, child: Text(context.l10n.save)),
        ],
      ),
      body: ListView(
        padding: formPadding(context),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: KJColors.maroon.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KJColors.maroon.withValues(alpha: 0.3)),
            ),
            child: Text(
              context.l10n.recalcWarning,
              style: TextStyle(fontSize: 12.5, color: KJColors.maroon),
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: context.l10n.nameLabel),
          ),
          const SizedBox(height: 12),
          // Day · named month · year — same unambiguous entry as the
          // create screen (see date_fields.dart).
          DateFieldsRow(
            initial: _date,
            onChanged: (d) => setState(() {
              _date = d;
              _dirtyBirthData = true;
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
                  child: Text(_time == null
                      ? context.l10n.keTime
                      : _time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placeController,
            decoration: InputDecoration(labelText: context.l10n.placeOfBirth),
            onChanged: (q) {
              setState(() {
                _newPlace = null;
                _dirtyBirthData = true;
              });
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () async {
                try {
                  final results =
                      await ref.read(placeLookupProvider).search(q);
                  if (mounted) {
                    setState(() {
                      _placeResults = results;
                      _placeSearchFailed = false;
                    });
                  }
                } catch (_) {
                  // Offline / dead network: surface inline rather than
                  // letting the exception escape the Timer callback and
                  // get reported as a crash.
                  if (mounted) {
                    setState(() {
                      _placeResults = [];
                      _placeSearchFailed = true;
                    });
                  }
                }
              });
            },
          ),
          if (_placeSearchFailed && _newPlace == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(context.l10n.placeSearchOffline,
                  style: TextStyle(fontSize: 12, color: KJColors.inkSoft)),
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
            decoration: InputDecoration(
              labelText: context.l10n.keNoteLabel,
              hintText: context.l10n.beNoteHint,
            ),
          ),
          const SizedBox(height: 24),
          _settingBlock(
            title: context.l10n.labelChartStyle,
            subtitle: ChartStyle.values
                .firstWhere((s) => s.name == k.chartStyle,
                    orElse: () => ChartStyle.north)
                .label(context.l10n),
            child: TextButton(
              onPressed: _pickChartStyle,
              child: Text(context.l10n.keChange),
            ),
          ),
          _settingBlock(
            title: context.l10n.keAyanamsaOverride,
            subtitle: k.ayanamsaOverrideId == null
                ? context.l10n.keAyanamsaUsingDefault(
                    Ayanamsa.byId(Ayanamsa.lahiri.id).name)
                : context.l10n.keAyanamsaThisKundli(
                    Ayanamsa.byId(k.ayanamsaOverrideId!).name),
            child: TextButton(
              onPressed: _pickAyanamsa,
              child: Text(k.ayanamsaOverrideId == null
                  ? context.l10n.keOverride
                  : context.l10n.keChange),
            ),
          ),
          _settingBlock(
            title: context.l10n.cloudSync,
            subtitle: user == null
                ? context.l10n.keSyncSignInPrompt
                : (k.syncEnabled
                    ? context.l10n.keSyncingToAccount
                    : context.l10n.deviceOnly),
            child: user == null
                ? TextButton(
                    onPressed: () => context.push('/signin'),
                    child: Text(context.l10n.signIn))
                : Switch(
                    value: k.syncEnabled,
                    activeColor: KJColors.maroon,
                    onChanged: (v) async {
                      // Captured before the first await — context must not
                      // be used across suspension points, and the error
                      // path below must survive the screen being popped.
                      final l10n = context.l10n;
                      final messenger = ScaffoldMessenger.of(context);
                      final updated = k.copyWith(syncEnabled: v);
                      await ref.read(kundliRepoProvider).update(updated);
                      setState(() => _kundli = updated);
                      final sync = ref.read(syncServiceProvider);
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
                        messenger.showSnackBar(
                            SnackBar(content: Text(l10n.keSyncFailed('$e'))));
                      }
                    },
                  ),
          ),
          _settingBlock(
            title: context.l10n.mahakoshTitle,
            subtitle: k.isSharedToMahakosh
                ? context.l10n.keSharedToMahakosh('${k.mahakoshCode}')
                : context.l10n.notShared,
            child: k.isSharedToMahakosh
                ? TextButton(
                    onPressed: _withdraw,
                    child: Text(context.l10n.withdraw,
                        style: TextStyle(color: KJColors.maroon)))
                : TextButton(
                    onPressed: () => context.push('/kundli/${k.id}/contribute'),
                    child: Text(context.l10n.share)),
          ),
          if (k.isSharedToMahakosh)
            _settingBlock(
              title: context.l10n.keMahakoshEvents,
              subtitle: context.l10n.keMahakoshEventsSubtitle,
              child: TextButton(
                onPressed: _updateMahakoshEvents,
                child: Text(context.l10n.keUpdate),
              ),
            ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(
                foregroundColor: KJColors.maroon,
                side: BorderSide(color: KJColors.maroon)),
            child: Text(context.l10n.deleteKundli),
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
                        style:
                            TextStyle(fontSize: 12, color: KJColors.inkSoft)),
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
      backgroundColor: KJColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final s in ChartStyle.values)
            ListTile(
              dense: true,
              title: Text(s.label(context.l10n)),
              trailing: _kundli!.chartStyle == s.name
                  ? Icon(Icons.check, color: KJColors.maroon, size: 18)
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
      backgroundColor: KJColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          ListTile(
            dense: true,
            title: Text(context.l10n.keUseAppDefault),
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
                  ? Icon(Icons.check, color: KJColors.maroon, size: 18)
                  : null,
              onTap: () async {
                final updated = _kundli!.copyWith(ayanamsaOverrideId: a.id);
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
