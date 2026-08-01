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
import '../data/models.dart';
import '../core/astro/ayanamsa.dart';
import '../core/theme/theme.dart';
import '../services/location_service.dart';
import '../services/place_lookup_service.dart';
import '../ui/birth_form.dart';
import '../ui/date_fields.dart';
import '../ui/manual_place_dialog.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../ui/common.dart';

/// Whether a freshly created kundli joins the alert follow-set.
///
/// Named and pure so the invariant is testable and stated once. The
/// exclusions are not cosmetic: [KundliAlertService] skips ephemeral
/// charts inside the scheduling pass, so following one would put an id
/// in the set that can never produce an alert — a quiet inconsistency
/// between what the UI claims and what the scheduler does. [prashna] is
/// the screen's own distinction (an unkept instant Prashna arrives via
/// the list screen and is ephemeral too); both are checked because a
/// Prashna cast from THIS form is saved and non-ephemeral, so neither
/// condition implies the other.
bool shouldFollowNewKundli({
  required bool toggleOn,
  required bool prashna,
  required bool isEphemeral,
}) =>
    toggleOn && !prashna && !isEphemeral;

/// The distinct places this practitioner most recently cast a chart for,
/// newest first, at most [limit].
///
/// Derived from the saved kundlis rather than kept in its own prefs
/// store: the charts ARE the history, so a separate list would be a
/// second copy to keep in sync, to migrate, and to clean up when a
/// kundli is deleted. Deduped by the stored place string, because
/// "Pune, Maharashtra, India" entered twice is one place to a user.
List<PlaceResult> recentBirthPlaces(
  List<Kundli> kundlis, {
  int limit = 3,
}) {
  final byRecency = [...kundlis]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final seen = <String>{};
  final out = <PlaceResult>[];
  for (final k in byRecency) {
    final label = k.placeName.trim();
    if (label.isEmpty || !seen.add(label)) continue;
    out.add(placeFromStoredName(
      placeName: k.placeName,
      latitude: k.latitude,
      longitude: k.longitude,
      timezoneName: k.timezoneName,
    ));
    if (out.length >= limit) break;
  }
  return out;
}

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
  // True when the last geocoder search threw (offline / dead network) —
  // drives the inline nudge toward manual entry so the failure isn't silent.
  bool _placeSearchFailed = false;
  Timer? _debounce;
  int _ayanamsaId = Ayanamsa.lahiri.id;
  // Chart style is no longer chosen here — new kundlis adopt the app-wide
  // default (set in Profile / on the widgets); it can still be overridden
  // per kundli on the Kundli Details screen.
  ChartStyle _style = ChartStyle.north;
  String _relationTag = 'Client';
  bool _syncEnabled = true; // default ON for signed-in users
  // Default ON, and per-creation only — exactly like _syncEnabled above,
  // which is a plain field and not a stored preference either. A chart
  // you just cast is the one you are about to work with, so alerts for
  // it are the useful default; a "follow new kundlis by default"
  // setting would be a preference nobody asked for.
  bool _followAlerts = true;
  bool _saving = false;

  /// Required fields flagged by the last failed Cast. Empty until the
  /// user actually presses the button: marking a form red before anyone
  /// has claimed to be finished is nagging, not validation.
  Set<BirthField> _missing = {};

  final _scroll = ScrollController();

  static final _fieldKeys = {
    for (final f in BirthField.values) f: birthFieldKey(f),
  };

  /// Drops [field] from the flagged set the moment it is filled, so the
  /// error disappears as the user fixes it rather than at the next
  /// press of Cast.
  void _clearMissing(BirthField field) {
    if (_missing.contains(field)) {
      setState(() => _missing = {..._missing}..remove(field));
    }
  }

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
    _scroll.dispose();
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
      _choosePlace(place);
    } on LocationDenied catch (denied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(denied.permanently
            ? context.l10n.beLocationDisabled
            : context.l10n.beLocationUnavailable),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.beLocationFailed)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onPlaceQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await ref.read(placeLookupProvider).search(q);
        if (mounted) {
          setState(() {
            _placeResults = results;
            _placeSearchFailed = false;
          });
        }
      } catch (_) {
        // Offline / dead network: surface it inline (manual entry works
        // offline) instead of failing silently.
        if (mounted) {
          setState(() {
            _placeResults = [];
            _placeSearchFailed = true;
          });
        }
      }
    });
  }

  Future<void> _enterPlaceManually() async {
    final result = await showDialog<PlaceResult>(
      context: context,
      builder: (_) => ManualPlaceDialog(
        lookup: ref.read(placeLookupProvider),
        // Whatever they typed into the search is almost certainly the
        // place name they wanted — carry it in.
        initialName: _place == null ? _placeController.text.trim() : '',
      ),
    );
    if (result == null || !mounted) return;
    _choosePlace(result);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    // Inline, not a snackbar. The old snackbar named the four required
    // fields and then vanished, leaving the user to work out which of
    // them they had actually missed — on a form long enough that the
    // offender is usually off screen.
    final missing = missingBirthFields(
      name: name,
      date: _date,
      time: _time,
      place: _place,
    );
    if (missing.isNotEmpty) {
      setState(() => _missing = missing);
      _scrollToFirstMissing(missing);
      return;
    }
    setState(() => _saving = true);
    final signedIn = ref.read(authUserProvider).value != null;
    // Captured before the awaits — the catch below must not touch
    // context (use_build_context_synchronously is an error here).
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
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
      if (shouldFollowNewKundli(
        toggleOn: _followAlerts,
        prashna: widget.prashna,
        isEphemeral: kundli.isEphemeral,
      )) {
        ref.read(followedKundlisProvider.notifier).addAll([kundli.id]);
        // Creation with the toggle defaulted ON is now the earliest
        // point a user can have asked for a notification, so it is where
        // the permission prompt belongs. No-op after the first time.
        unawaited(ref.read(kundliAlertServiceProvider).ensurePermission());
        // No reschedule call here on purpose: the app root listens to
        // followedKundlisProvider and runs one debounced pass. Adding a
        // second trigger would just mean two ephemeris passes for one
        // chart.
      }
      ref.invalidate(kundlisProvider);
      // Replace the form with the dashboard: Home stays underneath, so
      // the dashboard gets a back button and back doesn't re-open the
      // filled-in form.
      if (mounted) context.pushReplacement('/kundli/${kundli.id}');
    } catch (e) {
      // Chart creation must never hard-crash on a bad place/timezone
      // (the geocoder once returned zones missing from the trimmed tz
      // dataset — P0; the dataset is fixed, this is the belt): surface
      // the error and leave the filled-in form intact for a retry.
      messenger.showSnackBar(SnackBar(content: Text(l10n.beSaveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.prashna ? l10n.prashnaTitle : l10n.birthDetailsTitle),
        actions: [
          // Was a TextButton under the Cast button, which the pinned bar
          // has now taken over. It is a "cast a different KIND of chart"
          // switch, not a step in this form, so the header is where it
          // belongs — and it stops competing with the primary action.
          if (!widget.prashna)
            TextButton(
              onPressed: () => context.push('/new?prashna=1'),
              child: Text(l10n.bePrashnaAction),
            ),
        ],
      ),
      body: ListView(
        controller: _scroll,
        padding: formPadding(context),
        children: [
          if (widget.prashna)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.beQuestionChartNote,
                style: TextStyle(fontSize: 13, color: KJColors.inkSoft),
              ),
            ),
          TextField(
            key: _fieldKeys[BirthField.name],
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              errorText: _missing.contains(BirthField.name)
                  ? l10n.beFieldRequired
                  : null,
            ),
            textCapitalization: TextCapitalization.words,
            // Straight into the first field on open. This form is used
            // several times a day and always starts the same way; a tap
            // to begin typing is a tap paid every single time.
            autofocus: true,
            // Enter moves on to the day box rather than dismissing the
            // keyboard. Default traversal already reaches it, so nothing
            // inside DateFieldsRow had to change.
            textInputAction: TextInputAction.next,
            // The summary line is gated on all four fields, so the bar
            // has to rebuild as the name is typed.
            onChanged: (v) {
              if (v.trim().isNotEmpty) _clearMissing(BirthField.name);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          // Day · named month · year — never a bare d/m vs m/d text
          // field (see date_fields.dart for the wrong-birth-date risk).
          DateFieldsRow(
            key: _fieldKeys[BirthField.date],
            initial: _date,
            errorText: _missing.contains(BirthField.date)
                ? l10n.beFieldRequired
                : null,
            onChanged: (d) {
              setState(() => _date = d);
              if (d != null) _clearMissing(BirthField.date);
            },
          ),
          const SizedBox(height: 8),
          TimeFieldTile(
            key: _fieldKeys[BirthField.time],
            time: _time,
            label: l10n.timeLabel,
            errorText: _missing.contains(BirthField.time)
                ? l10n.beFieldRequired
                : null,
            onPick: (t) {
              setState(() => _time = t);
              _clearMissing(BirthField.time);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            key: _fieldKeys[BirthField.place],
            controller: _placeController,
            decoration: InputDecoration(
              labelText: l10n.placeOfBirth,
              helperText: _place == null
                  ? l10n.bePlaceHelper
                  : '${_place!.latitude.toStringAsFixed(4)}, '
                      '${_place!.longitude.toStringAsFixed(4)} · '
                      '${_place!.timezoneName}',
              // Typed-but-not-chosen gets its own message: the field
              // LOOKS filled in, so "Required" would read as a bug.
              errorText: !_missing.contains(BirthField.place)
                  ? null
                  : _placeController.text.trim().isEmpty
                      ? l10n.beFieldRequired
                      : l10n.bePlaceNotChosen,
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
                      onTap: () => _choosePlace(r),
                    ),
                ],
              ),
            ),
          if (_placeSearchFailed && _place == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.bePlaceSearchOffline,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _recentPlaceChips(),
          // Wrap, not Row: on narrow screens the two labels together
          // exceed the width and a Row overflows (~26px) — the second
          // button drops to the next line instead.
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                icon: Icon(
                    _locating ? Icons.hourglass_empty : Icons.my_location,
                    size: 18),
                label: Text(
                    _locating ? l10n.tdLocating : l10n.beUseCurrentLocation),
                onPressed: _locating ? null : _useCurrentLocation,
              ),
              // The geocoder is the only path to a chart otherwise — an
              // unfound village (Indian ones as much as foreign) or a dead
              // network must not block kundli creation.
              TextButton.icon(
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: Text(l10n.beManualEntry),
                onPressed: _enterPlaceManually,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel(l10n.beSectionRelation),
          Wrap(
            spacing: 8,
            children: [
              // The STORED tag stays English (it's persisted on the row
              // and read back by relationTagLabel); only the chip's text
              // is localized.
              for (final tag in _relationTags)
                ChoiceChip(
                  label: Text(relationTagLabel(l10n, tag)),
                  selected: _relationTag == tag,
                  labelStyle: TextStyle(
                      color:
                          _relationTag == tag ? KJColors.paper : KJColors.ink),
                  onSelected: (_) => setState(() => _relationTag = tag),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel(l10n.beSectionNoteOptional),
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.beNoteHint),
          ),
          const SizedBox(height: 8),
          // Chart style follows the app-wide default set in Profile / on the
          // widgets, so it isn't asked here; it can be overridden per kundli
          // in Kundli Details. Ayanamsa is tucked away — a professional sets
          // it once and rarely changes it per chart.
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: KJSectionLabel(l10n.beAdvanced),
              subtitle: Text(
                l10n.beAyanamsaSubtitle(Ayanamsa.byId(_ayanamsaId).name),
                style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
              ),
              children: [
                _sectionLabel(l10n.beSectionAyanamsa),
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
                                ? KJColors.paper
                                : KJColors.ink),
                        onSelected: (_) => setState(() => _ayanamsaId = a.id),
                      ),
                    ActionChip(
                      label: Text(Ayanamsa.quickPicks
                              .any((a) => a.id == _ayanamsaId)
                          ? l10n.beMore
                          : l10n.beMoreWith(Ayanamsa.byId(_ayanamsaId).name)),
                      onPressed: _showAllAyanamsas,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.prashna) ...[
            const SizedBox(height: 20),
            // One section, because to the user these are one question:
            // what happens to this chart once it exists. They were two
            // headings only because they were built at different times.
            _sectionLabel(l10n.beSectionAfterCasting),
            if (ref.watch(authUserProvider).value != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _syncEnabled,
                activeThumbColor: KJColors.maroon,
                title: Text(l10n.beSyncTitle,
                    style: const TextStyle(fontSize: 13.5)),
                subtitle: Text(
                  l10n.beSyncSubtitle,
                  style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
                ),
                onChanged: (v) => setState(() => _syncEnabled = v),
              ),
            // NO SIGN-IN GATE, deliberately, and unlike the sync row
            // directly above it. Alerts are computed and scheduled on
            // this device, so an account has nothing to do with them —
            // and the whole point of naming them "Kundli alerts" was to
            // stop the two reading as one feature. Sharing a section
            // heading must not quietly re-merge them.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _followAlerts,
              activeThumbColor: KJColors.maroon,
              title: Text(l10n.beFollowAlertsTitle,
                  style: const TextStyle(fontSize: 13.5)),
              subtitle: Text(
                l10n.beFollowAlertsSubtitle,
                style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
              ),
              onChanged: (v) => setState(() => _followAlerts = v),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.trustStatement,
            textAlign: TextAlign.center,
            style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
          ),
        ],
      ),
      bottomNavigationBar: PinnedActionBar(
        summary: _summaryLine(),
        summaryKey: const Key('birthSummary'),
        actionLabel: _saving ? l10n.beCasting : l10n.castKundli,
        onAction: _saving ? null : _save,
      ),
    );
  }

  /// Bring the topmost offender into view. Best-effort: a field whose
  /// element is not mounted (the Advanced section is collapsed, the
  /// layout is mid-frame) simply doesn't scroll, which is no worse than
  /// the old behaviour.
  void _scrollToFirstMissing(Set<BirthField> missing) {
    final first = firstMissingBirthField(missing);
    if (first == null) return;
    final ctx = _fieldKeys[first]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      alignment: 0.1,
    );
  }

  /// The resolution summary, or null while the form is incomplete.
  String? _summaryLine() {
    final place = _place;
    return birthResolutionSummary(
      lookup: ref.read(placeLookupProvider),
      l10n: context.l10n,
      name: _nameController.text,
      date: _date,
      time: _time,
      timezoneName: place?.timezoneName,
      placeShortName: place == null ? null : shortPlaceName(place.displayName),
    );
  }

  Widget _sectionLabel(String t) => KJSectionLabel(t, padded: true);

  /// Up to three previously-used birth places, offered while the place
  /// box is empty.
  ///
  /// A practitioner's charts cluster hard around a handful of cities —
  /// their own, and wherever their clients are — so the typeahead is
  /// usually being asked the same question it was asked an hour ago.
  /// Hidden the moment anything is typed: they are a shortcut past the
  /// search, not a filter on it.
  Widget _recentPlaceChips() {
    if (_place != null || _placeController.text.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }
    final kundlis = ref.watch(kundlisProvider).valueOrNull ?? const <Kundli>[];
    final recents = recentBirthPlaces(kundlis);
    if (recents.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final r in recents)
            ActionChip(
              avatar: Icon(Icons.history, size: 16, color: KJColors.inkSoft),
              label: Text(r.displayName, style: const TextStyle(fontSize: 12)),
              onPressed: () => _choosePlace(r),
            ),
        ],
      ),
    );
  }

  /// Every path that settles on a place goes through here, so a chip and
  /// a search hit cannot drift apart in what they set.
  void _choosePlace(PlaceResult place) {
    setState(() {
      _place = place;
      _placeController.text = place.displayName;
      _placeResults = [];
      _placeSearchFailed = false;
    });
    _clearMissing(BirthField.place);
  }

  void _showAllAyanamsas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KJColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final a in Ayanamsa.all)
            ListTile(
              dense: true,
              title: Text(a.name),
              trailing: _ayanamsaId == a.id
                  ? Icon(Icons.check, color: KJColors.maroon, size: 18)
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
