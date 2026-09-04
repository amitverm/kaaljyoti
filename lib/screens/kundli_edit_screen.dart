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
import '../ui/birth_form.dart';
import '../ui/date_fields.dart';
import '../ui/manual_place_dialog.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import 'kundli_list_screen.dart' show showLabelPicker;

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
  bool _saving = false;

  /// Required fields flagged by the last failed Save. Empty until the
  /// user actually presses it: reddening a form before anyone has
  /// claimed to be finished is nagging, not validation.
  Set<BirthField> _missing = {};

  final _scroll = ScrollController();
  static final _fieldKeys = {
    for (final f in BirthField.values) f: birthFieldKey(f),
  };

  void _clearMissing(BirthField field) {
    if (_missing.contains(field)) {
      setState(() => _missing = {..._missing}..remove(field));
    }
  }

  /// The place a Save would actually use, or null when there isn't one.
  ///
  /// Three states, and only the middle one is obvious:
  ///   * a freshly picked place — use it;
  ///   * the box still holding the STORED name, untouched — the stored
  ///     place stands, and nothing is missing;
  ///   * text that is neither — typed and never picked. Saving that
  ///     silently kept the old coordinates while the field claimed
  ///     otherwise, which is the quiet version of a wrong chart.
  Object? _effectivePlace(Kundli k) {
    if (_newPlace != null) return _newPlace;
    final typed = _placeController.text.trim();
    if (typed.isEmpty) return null;
    return typed == k.placeName.trim() ? k : null;
  }

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
    _scroll.dispose();
    _nameController.dispose();
    _placeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Same escape hatch as birth entry — the geocoder must never be the
  /// only path to a corrected birthplace (unfound villages, offline, or
  /// book-sourced coordinates the search would never match).
  Future<void> _enterPlaceManually() async {
    final result = await showDialog<PlaceResult>(
      context: context,
      builder: (_) => ManualPlaceDialog(
        lookup: ref.read(placeLookupProvider),
        // Carry in the field text (stored place name or fresh search
        // query) — it's almost certainly the name they want.
        initialName: _newPlace == null ? _placeController.text.trim() : '',
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _newPlace = result;
      _placeController.text = result.displayName;
      _placeResults = [];
      _placeSearchFailed = false;
      _dirtyBirthData = true;
    });
    _clearMissing(BirthField.place);
  }

  Future<void> _save() async {
    final k = _kundli;
    if (k == null) return;
    // Inline, exactly as on the entry screen. Clearing the date or
    // retyping the place without picking used to save silently — the
    // birth block was skipped and nothing said so.
    final missing = missingBirthFields(
      name: _nameController.text,
      date: _date,
      time: _time,
      place: _effectivePlace(k),
    );
    if (missing.isNotEmpty) {
      setState(() => _missing = missing);
      final first = firstMissingBirthField(missing);
      final ctx = first == null ? null : _fieldKeys[first]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250), alignment: 0.1);
      }
      return;
    }
    setState(() => _saving = true);
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The relation chips, exactly as the create screen offers them (same
  /// shared [kRelationTags], same order). Relation used to be a create-
  /// only decision, which made a mis-tapped chip permanent — the one
  /// field on the form with no way back.
  ///
  /// Save-bound like name, note and labels: the pick lands on the
  /// in-memory kundli and is written by [_save], so backing out of the
  /// screen discards it.
  Widget _relationEditor(Kundli k) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KJSectionLabel(l10n.beSectionRelation, padded: true),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // The STORED tag stays English (it's persisted on the row and
            // read back by relationTagLabel); only the chip text is
            // localized.
            for (final tag in kRelationTags)
              ChoiceChip(
                label: Text(relationTagLabel(l10n, tag)),
                selected: k.relationTag == tag,
                labelStyle: TextStyle(
                    color:
                        k.relationTag == tag ? KJColors.paper : KJColors.ink),
                onSelected: (_) =>
                    setState(() => _kundli = k.copyWith(relationTag: tag)),
              ),
          ],
        ),
      ],
    );
  }

  /// Labels as removable chips plus an "add" affordance. Edits apply to
  /// the in-memory kundli and persist on Save alongside name and note —
  /// a label added here must not survive the user backing out.
  Widget _labelEditor(Kundli k) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KJSectionLabel(l10n.klLabels, padded: true),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in k.labels)
              InputChip(
                label: Text(label),
                onDeleted: () => setState(() {
                  _kundli = k.copyWith(labels: [...k.labels]..remove(label));
                }),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(l10n.klAddLabel),
              onPressed: () async {
                // Offer every label already in use so the user picks the
                // existing "2026 clients" instead of coining a near-miss.
                final all = ref.read(kundliListDataProvider).value?.labels ??
                    const <String>[];
                final picked = await showLabelPicker(context, existing: all);
                if (picked == null || !mounted) return;
                final current = _kundli ?? k;
                if (current.labels.contains(picked)) return;
                setState(() {
                  _kundli =
                      current.copyWith(labels: [...current.labels, picked]);
                });
              },
            ),
          ],
        ),
      ],
    );
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
    ref.read(devicePingServiceProvider)?.pingSoon();
    // Drop the device-local list state too, so the chart can't linger in
    // the pinned section or the recents strip.
    ref.read(pinnedKundlisProvider.notifier).removeAll([widget.kundliId]);
    ref.read(followedKundlisProvider.notifier).removeAll([widget.kundliId]);
    ref.read(recentKundlisProvider.notifier).forget([widget.kundliId]);
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
          // Delete lives here, not at the foot of the scroll where it
          // used to sit — with Save now pinned to the bottom edge, the
          // old position put a destructive button directly above the
          // primary one, under the same thumb. Behind a menu and behind
          // a confirm dialog is the right distance for it.
          PopupMenuButton<void>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                onTap: _delete,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline,
                        size: 20, color: KJColors.maroon),
                    const SizedBox(width: 12),
                    Text(ctx.l10n.deleteKundli,
                        style: TextStyle(color: KJColors.maroon)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: PinnedActionBody(
        form: ListView(
          controller: _scroll,
          padding: formPadding(context),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: KJColors.maroon.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: KJColors.maroon.withValues(alpha: 0.3)),
              ),
              child: Text(
                context.l10n.recalcWarning,
                style: TextStyle(fontSize: 12.5, color: KJColors.maroon),
              ),
            ),
            TextField(
              key: _fieldKeys[BirthField.name],
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.nameLabel,
                errorText: _missing.contains(BirthField.name)
                    ? context.l10n.beFieldRequired
                    : null,
              ),
              onChanged: (v) {
                if (v.trim().isNotEmpty) _clearMissing(BirthField.name);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            // Day · named month · year — same unambiguous entry as the
            // create screen (see date_fields.dart).
            DateFieldsRow(
              key: _fieldKeys[BirthField.date],
              initial: _date,
              errorText: _missing.contains(BirthField.date)
                  ? context.l10n.beFieldRequired
                  : null,
              onChanged: (d) {
                setState(() {
                  _date = d;
                  _dirtyBirthData = true;
                });
                if (d != null) _clearMissing(BirthField.date);
              },
            ),
            const SizedBox(height: 8),
            TimeFieldTile(
              key: _fieldKeys[BirthField.time],
              time: _time,
              label: context.l10n.keTime,
              errorText: _missing.contains(BirthField.time)
                  ? context.l10n.beFieldRequired
                  : null,
              onPick: (t) {
                setState(() {
                  _time = t;
                  _dirtyBirthData = true;
                });
                _clearMissing(BirthField.time);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: _fieldKeys[BirthField.place],
              controller: _placeController,
              decoration: InputDecoration(
                labelText: context.l10n.placeOfBirth,
                // Typed-but-not-chosen gets its own message: the box LOOKS
                // filled in, so "Required" would read as a bug.
                errorText: !_missing.contains(BirthField.place)
                    ? null
                    : _placeController.text.trim().isEmpty
                        ? context.l10n.beFieldRequired
                        : context.l10n.bePlaceNotChosen,
                // Coordinates in play: the pending pick, else what's stored —
                // so a manual/typeahead change is verifiable before Save.
                helperText: _newPlace != null
                    ? '${_newPlace!.latitude.toStringAsFixed(4)}, '
                        '${_newPlace!.longitude.toStringAsFixed(4)} · '
                        '${_newPlace!.timezoneName}'
                    : '${k.latitude.toStringAsFixed(4)}, '
                        '${k.longitude.toStringAsFixed(4)} · '
                        '${k.timezoneName}',
              ),
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
                        onTap: () {
                          setState(() {
                            _newPlace = r;
                            _placeController.text = r.displayName;
                            _placeResults = [];
                          });
                          _clearMissing(BirthField.place);
                        },
                      ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: Text(context.l10n.beManualEntry),
                onPressed: _enterPlaceManually,
              ),
            ),
            const SizedBox(height: 12),
            // Same slot as on the create screen — after the birth block,
            // before the note — so the two forms read the same way.
            _relationEditor(k),
            const SizedBox(height: 20),
            _labelEditor(k),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            _sectionLabel(context.l10n.keSectionChart),
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
            const SizedBox(height: 20),
            _sectionLabel(context.l10n.keSectionSharing),
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
                      activeThumbColor: KJColors.maroon,
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
                      onPressed: () =>
                          context.push('/kundli/${k.id}/contribute'),
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
            // Its own section, deliberately NOT folded into "Sharing &
            // sync" above. Sync is a server feature behind an account;
            // alerts are computed and scheduled on this device and need
            // neither. Housing them together is precisely the conflation
            // the "Kundli alerts" rename was made to undo.
            //
            // Ephemeral charts are excluded because the scheduling pass
            // skips them, so a follow would be an id that can never
            // produce an alert. A Mahakosh id cannot reach this screen at
            // all (byId finds nothing in the local store and the form
            // never loads), but the guard costs nothing and states the
            // rule where a reader will look for it.
            if (!k.isEphemeral && !isMahakoshKundliId(k.id)) ...[
              const SizedBox(height: 20),
              _sectionLabel(context.l10n.stSectionKundliAlerts),
              _settingBlock(
                title: context.l10n.beFollowAlertsTitle,
                subtitle: context.l10n.keAlertsSubtitle,
                child: Switch(
                  value: ref.watch(followedKundlisProvider).contains(k.id),
                  activeThumbColor: KJColors.maroon,
                  // Live-bound and immediate, like the dashboard's own
                  // follow toggle — NOT save-bound. Flipping it is the
                  // whole action; the app root listens to the follow-set
                  // and runs one debounced rescheduling pass. Routing it
                  // through Save would mean a switch that lies until you
                  // press a button somewhere else.
                  onChanged: (v) {
                    final follows = ref.read(followedKundlisProvider.notifier);
                    if (v) {
                      follows.addAll([k.id]);
                      // May be this user's first-ever follow.
                      unawaited(ref
                          .read(kundliAlertServiceProvider)
                          .ensurePermission());
                    } else {
                      follows.removeAll([k.id]);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        bar: PinnedActionBar(
          summary: _summaryLine(k),
          summaryKey: const Key('birthSummary'),
          actionLabel: context.l10n.save,
          onAction: _saving ? null : _save,
        ),
      ),
    );
  }

  /// The resolution summary for the values as currently edited.
  ///
  /// Falls back to the STORED zone and place exactly as [_save] does, so
  /// the line always describes what a Save would write — including
  /// before anything has been touched, which is the point: opening this
  /// screen is how you check a chart cast years ago, and a birth whose
  /// offset was historic (1943 Kolkata is +06:30) never said so
  /// anywhere until now.
  String? _summaryLine(Kundli k) {
    final place = _newPlace;
    return birthResolutionSummary(
      lookup: ref.read(placeLookupProvider),
      l10n: context.l10n,
      name: _nameController.text,
      date: _date,
      time: _time,
      timezoneName: place?.timezoneName ?? k.timezoneName,
      placeShortName: shortPlaceName(place?.displayName ?? k.placeName),
    );
  }

  Widget _sectionLabel(String t) => KJSectionLabel(t, padded: true);

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
