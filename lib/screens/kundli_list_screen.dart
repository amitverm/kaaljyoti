/// Screen 02 — Kundli List. Landing screen: the saved kundlis, built to
/// stay findable at library sizes in the hundreds — search, sort, pins, a
/// recents strip, and label/relation filter chips, with the row itself
/// pared back to what actually identifies a chart.
///
/// Two things here are load-bearing for large libraries and easy to undo
/// by accident:
///   * the list is LAZY (slivers + builder). The old eager `ListView`
///     built every row on open, and every row watched [snapshotProvider],
///     so opening this screen with 200 kundlis meant 200 ephemeris
///     computations.
///   * the lagna/moon quick reads — the only thing here that needs a
///     snapshot — exist in the DETAILED density only, so the default
///     costs no astronomy at all.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../core/theme/tokens.dart';
import '../core/theme/type_scale.dart';
import '../data/models.dart';
import '../data/settings_repository.dart';
import '../l10n/astro_l10n.dart';
import '../services/location_service.dart';
import '../state/providers.dart';
import '../ui/common.dart';

/// Multi-select state for the "Compare (n)" entry (spec §3.1) and the
/// bulk pin/label/delete actions. Null = not in select mode.
final kundliMultiSelectProvider = StateProvider<Set<String>?>((ref) => null);

/// Library sizes at which the finding aids start earning their space. A
/// user with eight charts wants none of this chrome; a user with two
/// hundred needs all of it.
const _searchThreshold = 8;
const _recentsThreshold = 12;
const _sectionHeaderThreshold = 30;

/// How many charts the recents strip shows.
const _recentsShown = 8;

class KundliListScreen extends ConsumerWidget {
  const KundliListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(kundliListDataProvider);
    final user = ref.watch(authUserProvider).value;
    final selection = ref.watch(kundliMultiSelectProvider);

    return KJScaffold(
      section: KJSection.kundlis,
      appBar: selection != null
          ? _selectAppBar(context, ref, selection)
          : AppBar(
              title: Text(l10n.kundlisTitle),
              actions: [
                const _ListOptionsButton(),
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => context.push('/notifications'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: KJSpace.md),
                  child: GestureDetector(
                    onLongPress: () => _castPrashna(context, ref),
                    child: FilledButton(
                      onPressed: () => context.push('/new'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: KJSpace.lg + 2,
                              vertical: KJSpace.sm)),
                      child: Text(l10n.plusNew),
                    ),
                  ),
                ),
              ],
            ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: l10n.klLoadError('$e')),
        data: (list) => list.totalCount == 0
            ? _firstRun(context, user)
            : _Library(data: list, showSignIn: user == null),
      ),
    );
  }

  /// First-run: no kundlis at all. Distinct from "no search matches",
  /// which [_Library] handles.
  Widget _firstRun(BuildContext context, Object? user) {
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: EmptyState(
            leading: Image.asset('assets/emblem.png', width: 64, height: 64),
            message: l10n.klEmpty,
            actionLabel: l10n.newKundli,
            onAction: () => context.push('/new'),
          ),
        ),
        // Secondary, value-framed sign-in nudge — an account is never
        // required to cast charts (brief: value-driven, not a login wall).
        if (user == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                KJSpace.xxxl, 0, KJSpace.xxxl, KJSpace.xxl),
            child: Column(
              children: [
                Text(
                  l10n.klRestoreNudge,
                  textAlign: TextAlign.center,
                  style: KJType.caption(size: 12.5, color: KJColors.inkSoft),
                ),
                TextButton(
                  onPressed: () => context.push('/signin'),
                  child: Text(l10n.signIn),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The multi-select app bar (spec §3.1): "n selected", Compare at 2–4,
  /// bulk pin / alerts / label / archive / delete, and a close button.
  PreferredSizeWidget _selectAppBar(
      BuildContext context, WidgetRef ref, Set<String> selection) {
    final l10n = context.l10n;
    final canCompare = selection.length >= 2;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () =>
            ref.read(kundliMultiSelectProvider.notifier).state = null,
      ),
      title: Text(l10n.klSelected('${selection.length}')),
      actions: [
        _selectAction(
          icon: Icons.push_pin_outlined,
          tooltip: l10n.klPin,
          onPressed: selection.isEmpty
              ? null
              : () => _bulkPin(context, ref, selection),
        ),
        _selectAction(
          icon: Icons.notifications_active_outlined,
          tooltip: l10n.klFollowAlerts,
          onPressed: selection.isEmpty
              ? null
              : () => _bulkFollow(context, ref, selection),
        ),
        _selectAction(
          icon: Icons.sell_outlined,
          tooltip: l10n.klLabels,
          onPressed: selection.isEmpty
              ? null
              : () => _bulkLabel(context, ref, selection),
        ),
        // Archive sits next to delete because that is the choice being
        // made — get this out of my list, permanently or not. Direction
        // is read from the selection, so the one button toggles.
        Consumer(builder: (context, ref, _) {
          final archived = _selectionArchived(ref, selection);
          return _selectAction(
            icon:
                archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            tooltip: archived ? l10n.klUnarchive : l10n.klArchive,
            onPressed: selection.isEmpty
                ? null
                : () =>
                    _bulkArchive(context, ref, selection, archived: !archived),
          );
        }),
        _selectAction(
          icon: Icons.delete_outline,
          tooltip: l10n.delete,
          onPressed: selection.isEmpty
              ? null
              : () => _bulkDelete(context, ref, selection),
        ),
        Padding(
          padding: const EdgeInsets.only(right: KJSpace.sm),
          child: FilledButton(
            onPressed: canCompare
                ? () {
                    ref.read(compareSetProvider.notifier).clear();
                    ref
                        .read(compareSetProvider.notifier)
                        .addAll(selection.toList());
                    ref.read(kundliMultiSelectProvider.notifier).state = null;
                    context.push('/compare');
                  }
                : null,
            // Tighter than the app's usual button padding, for the same
            // reason [_selectAction] is: this bar is the widest thing in
            // the app and an AppBar's trailing row clips rather than
            // wraps. Everything here is paying for the space.
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: KJSpace.md, vertical: KJSpace.sm)),
            child: Text(l10n.klCompareN('${selection.length}')),
          ),
        ),
      ],
    );
  }

  /// One bulk action in the select bar.
  ///
  /// Compact by construction: five icon buttons plus "Compare (n)" is
  /// more than a narrow phone's app bar can hold at the stock 48pt slot,
  /// and the trailing row of an AppBar clips rather than wraps. 40pt
  /// keeps a usable target while buying back the width the fifth action
  /// costs.
  Widget _selectAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) =>
      IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      );

  /// Pins the selection — or unpins it, when every selected chart is
  /// already pinned, so the one button toggles the way a user expects.
  void _bulkPin(BuildContext context, WidgetRef ref, Set<String> selection) {
    final pins = ref.read(pinnedKundlisProvider.notifier);
    final allPinned = selection.every(pins.isPinned);
    if (allPinned) {
      pins.removeAll(selection);
    } else {
      pins.addAll(selection);
    }
    ref.read(kundliMultiSelectProvider.notifier).state = null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(allPinned
          ? context.l10n.klUnpinnedN('${selection.length}')
          : context.l10n.klPinnedN('${selection.length}')),
    ));
  }

  /// Follows the selection for event alerts — or unfollows it when every
  /// selected chart is already followed, exactly like [_bulkPin].
  ///
  /// Mahakosh community charts are never eligible: they are read-only,
  /// server-owned and anonymized (no birth time), so there is nothing
  /// this device could compute alerts from. The list itself only ever
  /// contains saved, non-ephemeral kundlis, but the guard is cheap and
  /// keeps a stray id out of the follow-set.
  void _bulkFollow(BuildContext context, WidgetRef ref, Set<String> selection) {
    final eligible = selection.where((id) => !isMahakoshKundliId(id)).toSet();
    if (eligible.isEmpty) return;
    final follows = ref.read(followedKundlisProvider.notifier);
    final allFollowed = eligible.every(follows.isFollowed);
    if (allFollowed) {
      follows.removeAll(eligible);
    } else {
      follows.addAll(eligible);
      // First follow is the moment the permission prompt makes sense —
      // the user has just asked to be notified about something.
      unawaited(ref.read(kundliAlertServiceProvider).ensurePermission());
    }
    ref.read(kundliMultiSelectProvider.notifier).state = null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(allFollowed
          ? context.l10n.klAlertsOffN('${eligible.length}')
          : context.l10n.klAlertsOnN('${eligible.length}')),
    ));
  }

  Future<void> _bulkLabel(
      BuildContext context, WidgetRef ref, Set<String> selection) async {
    final all = ref.read(kundliListDataProvider).value;
    if (all == null) return;
    final label = await showLabelPicker(context, existing: all.labels);
    if (label == null || label.isEmpty) return;

    final repo = ref.read(kundliRepoProvider);
    for (final id in selection) {
      final k = await repo.byId(id);
      if (k == null || k.labels.contains(label)) continue;
      await repo.update(k.copyWith(labels: [...k.labels, label]));
    }
    ref.invalidate(kundlisProvider);
    ref.read(kundliMultiSelectProvider.notifier).state = null;
  }

  /// True when EVERY selected chart is already archived, which is what
  /// turns the one button into Unarchive — the same rule [_bulkPin] and
  /// [_bulkFollow] already use. A MIXED selection archives: that is the
  /// safe direction, since it never drags a chart back into a list the
  /// user is in the middle of tidying.
  bool _selectionArchived(WidgetRef ref, Set<String> selection) {
    if (selection.isEmpty) return false;
    final all = ref.watch(kundlisProvider).value ?? const <Kundli>[];
    final byId = {for (final k in all) k.id: k};
    return selection.every((id) => byId[id]?.isArchived ?? false);
  }

  Future<void> _bulkArchive(
    BuildContext context,
    WidgetRef ref,
    Set<String> selection, {
    required bool archived,
  }) async {
    // Captured before the awaits inside the helper: the select bar is
    // gone by the time the snackbar goes up.
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ids = {...selection};
    ref.read(kundliMultiSelectProvider.notifier).state = null;
    await setKundlisArchived(ref, ids, archived: archived);
    messenger.showSnackBar(SnackBar(
      content: Text(archived
          ? l10n.klArchivedN('${ids.length}')
          : l10n.klUnarchivedN('${ids.length}')),
      action: SnackBarAction(
        label: l10n.klUndo,
        onPressed: () => setKundlisArchived(ref, ids, archived: !archived),
      ),
    ));
  }

  Future<void> _bulkDelete(
      BuildContext context, WidgetRef ref, Set<String> selection) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.klDeleteNTitle('${selection.length}')),
        content: Text(l10n.klDeleteNBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text(ctx.l10n.delete, style: TextStyle(color: KJColors.maroon)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(kundliRepoProvider);
    final sync = ref.read(syncServiceProvider);
    for (final id in selection) {
      await repo.delete(id);
      // Tombstone, not a bare local delete — without this a synced chart
      // is resurrected by the next pull from another device, and the
      // dialog above promised the opposite.
      sync?.deleteRemote(id);
    }
    // Once, after the loop — pingSoon is debounced, so calling it per id
    // would be harmless, but there is no reason to make the timer do the
    // coalescing a for-loop boundary already does.
    ref.read(devicePingServiceProvider)?.pingSoon();
    // A deleted chart must not keep a slot in the recents strip, the
    // pins, or the alert follow-set (a stale follow would keep costing
    // an ephemeris pass and schedule alerts for a chart that is gone).
    ref.read(pinnedKundlisProvider.notifier).removeAll(selection);
    ref.read(followedKundlisProvider.notifier).removeAll(selection);
    ref.read(recentKundlisProvider.notifier).forget(selection);
    ref.invalidate(kundlisProvider);
    ref.read(kundliMultiSelectProvider.notifier).state = null;
  }

  /// Instant Prashna: current place + current instant, chart shown
  /// immediately as an EPHEMERAL kundli — the dashboard offers
  /// Keep / Discard. Falls back to the manual form if location is
  /// unavailable. Ephemeral rows are filtered out of the list until kept
  /// (see [KundliRepository.saved]), so a discarded question never looks
  /// like a saved chart.
  Future<void> _castPrashna(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.klCastingPrashna),
      duration: const Duration(seconds: 10),
    ));
    try {
      final place = await LocationService().currentPlace();
      final now = DateTime.now();
      final kundli = await ref.read(kundliRepoProvider).create(
            name: l10n.klPrashnaName(
                DateFormat('d MMM, HH:mm', l10n.localeName).format(now)),
            relationTag: 'Prashna',
            birthUtc: now.toUtc(),
            latitude: place.latitude,
            longitude: place.longitude,
            timezoneName: place.timezoneName,
            utcOffsetMinutes: now.timeZoneOffset.inMinutes,
            placeName: place.displayName,
            isPrashna: true,
            isEphemeral: true,
          );
      messenger.hideCurrentSnackBar();
      ref.invalidate(kundlisProvider);
      if (context.mounted) context.push('/kundli/${kundli.id}');
    } on LocationDenied catch (denied) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(denied.permanently
            ? l10n.klLocationDisabled
            : l10n.klLocationUnavailable),
      ));
      if (context.mounted) context.push('/new?prashna=1');
    } catch (_) {
      messenger.hideCurrentSnackBar();
      if (context.mounted) context.push('/new?prashna=1');
    }
  }
}

/// The populated list. Everything above the rows is conditional on
/// library size — see the thresholds at the top of the file.
class _Library extends ConsumerWidget {
  const _Library({required this.data, required this.showSignIn});

  final KundliListData data;
  final bool showSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final density = ref.watch(kundliDensityProvider);
    final sort = ref.watch(kundliSortProvider);
    final query = ref.watch(kundliSearchProvider);
    final filter = ref.watch(kundliFilterProvider);
    final searching = query.trim().isNotEmpty || filter != null;

    final showSearch = data.totalCount >= _searchThreshold;
    final showRecents = data.totalCount >= _recentsThreshold &&
        !searching &&
        data.recents.isNotEmpty;
    // A–Z grouping only makes sense in name order, and only once the list
    // is long enough that the letters actually break it up.
    final grouped = sort == KundliSort.name &&
        data.others.length >= _sectionHeaderThreshold;

    return CustomScrollView(
      slivers: [
        if (showSearch) const SliverToBoxAdapter(child: _SearchField()),
        // The row earns its space as soon as there is anything to sort
        // by — including an archive on its own, which is the only way
        // back to those charts.
        if (data.labels.isNotEmpty ||
            data.relationTags.length > 1 ||
            data.archivedCount > 0)
          SliverToBoxAdapter(child: _FilterChips(data: data)),
        if (showRecents)
          SliverToBoxAdapter(child: _RecentsStrip(recents: data.recents)),
        if (showSignIn) SliverToBoxAdapter(child: _signInBanner(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                KJSpace.lg, KJSpace.xs, KJSpace.lg, KJSpace.md),
            child: Text(
              searching
                  ? l10n.klShowingCount(
                      '${data.visibleCount}', '${data.totalCount}')
                  : l10n.savedEncrypted(data.totalCount),
              style: KJType.meta(size: 11.5, color: KJColors.inkSoft),
            ),
          ),
        ),
        if (data.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              message: l10n.klNoMatches,
              actionLabel: l10n.klClearFilters,
              onAction: () {
                ref.read(kundliSearchProvider.notifier).state = '';
                ref.read(kundliFilterProvider.notifier).state = null;
              },
            ),
          ),
        if (data.pinned.isNotEmpty) ...[
          SliverToBoxAdapter(child: _SectionLabel(label: l10n.klPinned)),
          SliverList.builder(
            itemCount: data.pinned.length,
            itemBuilder: (_, i) =>
                _KundliRow(kundli: data.pinned[i], density: density),
          ),
          if (data.others.isNotEmpty)
            SliverToBoxAdapter(child: _SectionLabel(label: l10n.klAllKundlis)),
        ],
        if (grouped)
          ..._groupedSlivers(data.others, density)
        else
          SliverList.builder(
            itemCount: data.others.length,
            itemBuilder: (_, i) =>
                _KundliRow(kundli: data.others[i], density: density),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, KJSpace.md, 0, 96),
            child: Center(
              child: Text(l10n.klLongPressPrashna,
                  style: KJType.meta(size: 10.5, color: KJColors.inkSoft)),
            ),
          ),
        ),
      ],
    );
  }

  /// One sticky letter header per initial, each followed by its rows.
  /// [SliverMainAxisGroup] is what makes the header stick only for the
  /// span of its own group rather than over the whole list.
  List<Widget> _groupedSlivers(List<Kundli> kundlis, KundliDensity density) {
    final groups = <String, List<Kundli>>{};
    for (final k in kundlis) {
      groups.putIfAbsent(initialFor(k.name), () => []).add(k);
    }
    return [
      for (final entry in groups.entries)
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _LetterHeaderDelegate(entry.key),
            ),
            SliverList.builder(
              itemCount: entry.value.length,
              itemBuilder: (_, i) =>
                  _KundliRow(kundli: entry.value[i], density: density),
            ),
          ],
        ),
    ];
  }

  Widget _signInBanner(BuildContext context) => Card(
        margin:
            const EdgeInsets.fromLTRB(KJSpace.lg, 0, KJSpace.lg, KJSpace.md),
        child: Padding(
          padding: const EdgeInsets.all(KJSpace.md + 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.signInBanner,
                  style: KJType.body(size: 13),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/signin'),
                child: Text(context.l10n.signIn),
              ),
            ],
          ),
        ),
      );
}

/// The letter a name files under. Anything that isn't a letter — a chart
/// named for a number, or a script whose first rune isn't A–Z — files
/// under '#' rather than creating a one-item group per glyph.
String initialFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final first = trimmed[0].toUpperCase();
  return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
}

class _LetterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LetterHeaderDelegate(this.letter);
  final String letter;

  static const _height = 30.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      Container(
        height: _height,
        color: KJColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: KJSpace.lg),
        alignment: Alignment.centerLeft,
        child: KJSectionLabel(letter),
      );

  @override
  bool shouldRebuild(_LetterHeaderDelegate old) => old.letter != letter;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            KJSpace.lg, KJSpace.xs, KJSpace.lg, KJSpace.sm),
        child: KJSectionLabel(label),
      );
}

/// Always-visible search. Behind an icon it would be a fallback; at
/// several hundred charts it's the primary way in.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: ref.read(kundliSearchProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the field in step when the query is cleared from elsewhere
    // (the no-matches empty state).
    ref.listen(kundliSearchProvider, (_, next) {
      if (next != _controller.text) _controller.text = next;
    });
    final query = ref.watch(kundliSearchProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KJSpace.lg, KJSpace.sm, KJSpace.lg, KJSpace.xs),
      child: TextField(
        controller: _controller,
        onChanged: (v) => ref.read(kundliSearchProvider.notifier).state = v,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: context.l10n.klSearchHint,
          isDense: true,
          prefixIcon:
              Icon(Icons.search, size: KJIcon.lg, color: KJColors.inkSoft),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: KJIcon.md),
                  tooltip: context.l10n.klClearSearch,
                  onPressed: () {
                    _controller.clear();
                    ref.read(kundliSearchProvider.notifier).state = '';
                  },
                ),
        ),
      ),
    );
  }
}

/// Relation tags, user labels and the archive in one scrolling row.
/// Chips rather than tabs because chips compose with search (Client +
/// "sharma") and cost no permanent vertical space when there's nothing
/// to filter by.
///
/// The archived chip is the odd one out and deliberately so: the other
/// chips narrow the active library, while this one steps out of it. It
/// lives here rather than in a section of its own because "which slice
/// of my charts am I looking at" is one question, and answering it in
/// two different places (a chip row AND a fold-out at the bottom of a
/// 200-row list) is how an archive becomes a place things get lost.
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.data});
  final KundliListData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final active = ref.watch(kundliFilterProvider);

    void select(KundliFilter? filter) =>
        ref.read(kundliFilterProvider.notifier).state = filter;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: KJSpace.lg),
        children: [
          _chip(
            label: l10n.klFilterAll,
            selected: active == null,
            onTap: () => select(null),
          ),
          for (final tag in data.relationTags)
            _chip(
              label: relationTagLabel(l10n, tag),
              selected: active?.kind == KundliFilterKind.relation &&
                  active?.value == tag,
              onTap: () =>
                  select((kind: KundliFilterKind.relation, value: tag)),
            ),
          for (final label in data.labels)
            _chip(
              label: label,
              selected: active?.kind == KundliFilterKind.label &&
                  active?.value == label,
              onTap: () => select((kind: KundliFilterKind.label, value: label)),
              icon: Icons.sell_outlined,
            ),
          // Last, and only once something has been archived. It carries
          // its own glyph so it can't be mistaken for a user label that
          // happens to be called "Archived" — and unlike every other
          // chip, selecting it REPLACES the list body rather than
          // narrowing it. Tapping it again (or "All") comes back.
          if (data.archivedCount > 0)
            _chip(
              label: l10n.klArchived('${data.archivedCount}'),
              selected: active?.kind == KundliFilterKind.archived,
              onTap: () => select(active?.kind == KundliFilterKind.archived
                  ? null
                  : kArchivedFilter),
              icon: Icons.archive_outlined,
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) =>
      Padding(
        padding: const EdgeInsets.only(right: KJSpace.sm),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: KJSpace.md, vertical: KJSpace.sm),
            decoration: BoxDecoration(
              color: selected
                  ? KJColors.maroon.withValues(alpha: KJTint.soft)
                  : KJColors.paperAlt,
              borderRadius: KJRadius.all(KJRadius.pill),
              border: Border.all(
                  color: selected
                      ? KJColors.maroon.withValues(alpha: KJTint.muted)
                      : KJColors.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: KJIcon.inline,
                      color: selected ? KJColors.maroon : KJColors.inkSoft),
                  KJSpace.gapW(KJSpace.xs),
                ],
                Text(
                  label,
                  style: KJType.chip(
                      size: 12,
                      color: selected ? KJColors.maroon : KJColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
      );
}

/// The charts opened most recently. The "Recently opened" SORT already
/// floats the working set to the top of the list; this strip is the
/// jump-back-to-what-I-just-had affordance, which is a different job —
/// it survives the user switching to name or birth-date order.
class _RecentsStrip extends ConsumerWidget {
  const _RecentsStrip({required this.recents});
  final List<Kundli> recents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = recents.take(_recentsShown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              KJSpace.lg, KJSpace.sm, KJSpace.lg, KJSpace.sm),
          child: KJSectionLabel(context.l10n.klRecent),
        ),
        SizedBox(
          height: 78,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KJSpace.lg),
            itemCount: shown.length,
            itemBuilder: (_, i) {
              final k = shown[i];
              return GestureDetector(
                onTap: () => openKundli(context, ref, k.id),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      KundliAvatar(name: k.name, size: 44),
                      KJSpace.gap(KJSpace.xs + 2),
                      Text(
                        k.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style:
                            KJType.caption(size: 11, color: KJColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Sort and density, together in one menu — both answer "how do I want
/// to see this list", and neither deserves its own app-bar slot.
class _ListOptionsButton extends ConsumerWidget {
  const _ListOptionsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sort = ref.watch(kundliSortProvider);
    final density = ref.watch(kundliDensityProvider);

    return PopupMenuButton<void Function()>(
      // Deliberately NOT Icons.tune: the dashboard uses that glyph in the
      // same app-bar slot for "arrange widgets", and these two screens
      // are one tap apart. Also not Icons.filter_list — that would read
      // as the filter chip row directly below.
      icon: const Icon(Icons.sort),
      tooltip: l10n.klListOptions,
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(enabled: false, child: KJSectionLabel(l10n.klSortLabel)),
        for (final option in KundliSort.values)
          CheckedPopupMenuItem(
            value: () => ref.read(kundliSortProvider.notifier).select(option),
            checked: sort == option,
            child: Text(sortLabel(l10n, option)),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
            enabled: false, child: KJSectionLabel(l10n.klDensityLabel)),
        for (final option in KundliDensity.values)
          CheckedPopupMenuItem(
            value: () =>
                ref.read(kundliDensityProvider.notifier).select(option),
            checked: density == option,
            child: Text(densityLabel(l10n, option)),
          ),
      ],
    );
  }
}

String sortLabel(AppLocalizations l10n, KundliSort sort) => switch (sort) {
      KundliSort.recent => l10n.klSortRecent,
      KundliSort.added => l10n.klSortAdded,
      KundliSort.name => l10n.klSortName,
      KundliSort.birth => l10n.klSortBirth,
    };

String densityLabel(AppLocalizations l10n, KundliDensity density) =>
    switch (density) {
      KundliDensity.compact => l10n.klDensityCompact,
      KundliDensity.comfortable => l10n.klDensityComfortable,
      KundliDensity.detailed => l10n.klDensityDetailed,
    };

/// Archives (or unarchives) [ids] and puts the list back in step.
///
/// Shared by the list's bulk action bar and the dashboard's overflow
/// menu so the two can't drift — archiving is one of those operations
/// with a tail (pins, recents, sync) that is easy to half-do.
///
/// Rows are re-read rather than passed in: the caller may be holding a
/// Kundli from before an edit, and `update` writes the whole row.
/// Charts already on the requested side are skipped, so an Undo that
/// races a second archive doesn't churn `updated_at` for nothing.
///
/// No pingSoon: archiving changes neither number the device ping
/// reports — an archived chart is still a saved chart.
Future<void> setKundlisArchived(
  WidgetRef ref,
  Iterable<String> ids, {
  required bool archived,
}) async {
  final repo = ref.read(kundliRepoProvider);
  final changed = <String>[];
  for (final id in ids) {
    final k = await repo.byId(id);
    if (k == null || k.isArchived == archived) continue;
    await repo.update(k.copyWith(isArchived: archived));
    changed.add(id);
  }
  if (changed.isEmpty) return;
  if (archived) {
    // The point of archiving is to stop seeing the chart, and both of
    // these would keep showing it above the fold. Unarchiving does NOT
    // undo them: a pin the user set months ago is not recoverable from
    // here, and silently re-pinning would be a guess.
    ref.read(pinnedKundlisProvider.notifier).removeAll(changed);
    ref.read(recentKundlisProvider.notifier).forget(changed);
    // Followed alerts are deliberately NOT dropped. Following is its own
    // explicit opt-in ("tell me when this native's dasha turns"), and
    // that request survives the chart leaving the roll call — unlike a
    // delete, where the subject is gone.
  }
  ref.invalidate(kundlisProvider);
  for (final id in changed) {
    ref.invalidate(kundliByIdProvider(id));
  }
  // The flag rides inside the row payload, so a plain push carries it —
  // and `update` bumped updated_at, so LWW settles it on every device.
  ref.read(syncServiceProvider)?.pushAll();
}

/// Opens a kundli and records the visit, so recency ordering reflects
/// every entry point rather than just the list.
void openKundli(BuildContext context, WidgetRef ref, String id) {
  ref.read(activeKundliIdProvider.notifier).state = id;
  ref.read(recentKundlisProvider.notifier).touch(id);
  context.push('/kundli/$id');
}

/// Initial-letter avatar. A shape is faster to re-find than a word, which
/// is the whole point at 200 rows. Colour is derived from the name so it
/// stays put across sorts and sessions; when photos land later they slot
/// in here and the letter stays as the fallback.
class KundliAvatar extends StatelessWidget {
  const KundliAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  /// Drawn from the app palette rather than a generic rainbow, so a
  /// screen full of avatars still reads as this app.
  static List<Color> _palette() => [
        KJColors.maroon,
        KJColors.forest,
        KJColors.transit,
        KJColors.ink,
      ];

  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    // Sum of code units, not hashCode — Dart's String.hashCode is not
    // guaranteed stable across runs, and a colour that changes on
    // restart defeats the purpose.
    final seed = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final color = palette[seed % palette.length];
    final letter = initialFor(name);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: KJTint.soft),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: KJTint.medium)),
      ),
      child: Text(
        letter,
        style: KJTheme.serif(size: size * 0.4, color: color),
      ),
    );
  }
}

class _KundliRow extends ConsumerWidget {
  const _KundliRow({required this.kundli, required this.density});

  final Kundli kundli;
  final KundliDensity density;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selection = ref.watch(kundliMultiSelectProvider);
    final selecting = selection != null;
    final isSelected = selection?.contains(kundli.id) ?? false;
    final isPinned = ref.watch(pinnedKundlisProvider).contains(kundli.id);
    final isFollowed = ref.watch(followedKundlisProvider).contains(kundli.id);
    final compact = density == KundliDensity.compact;

    void toggleSelection() {
      final current = {...?ref.read(kundliMultiSelectProvider)};
      if (!current.remove(kundli.id)) current.add(kundli.id);
      ref.read(kundliMultiSelectProvider.notifier).state = current;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(KJSpace.lg, 0, KJSpace.lg, KJSpace.sm),
      color:
          isSelected ? KJColors.maroon.withValues(alpha: KJTint.faint) : null,
      child: InkWell(
        borderRadius: KJRadius.all(KJRadius.lg),
        onLongPress: () =>
            ref.read(kundliMultiSelectProvider.notifier).state = {kundli.id},
        onTap: selecting
            ? toggleSelection
            : () => openKundli(context, ref, kundli.id),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: KJSpace.md,
              vertical: compact ? KJSpace.sm : KJSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selecting)
                    Padding(
                      padding: const EdgeInsets.only(right: KJSpace.sm),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: KJIcon.lg,
                        color: isSelected ? KJColors.maroon : KJColors.inkSoft,
                      ),
                    ),
                  KundliAvatar(name: kundli.name, size: compact ? 32 : 40),
                  KJSpace.gapW(KJSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          kundli.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KJTheme.serif(size: compact ? 15 : 17),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 2),
                          Text(
                            _secondaryLine(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                KJType.data(size: 12, color: KJColors.inkSoft),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isFollowed)
                    Padding(
                      padding: const EdgeInsets.only(left: KJSpace.xs),
                      child: Tooltip(
                        message: l10n.klFollowingAlerts,
                        child: Icon(Icons.notifications_active,
                            size: KJIcon.sm - 2, color: KJColors.maroon),
                      ),
                    ),
                  if (isPinned)
                    Padding(
                      padding: const EdgeInsets.only(left: KJSpace.xs),
                      child: Icon(Icons.push_pin,
                          size: KJIcon.sm - 2, color: KJColors.maroon),
                    ),
                  KJSpace.gapW(KJSpace.sm),
                  KJTag(relationTagLabel(l10n, kundli.relationTag)),
                  KJSpace.gapW(KJSpace.sm),
                  // Sync state as a glyph, not a chip: it's on every row,
                  // so it has to be cheap in width even though it carries
                  // real information (is this chart only on this device?).
                  Tooltip(
                    message: kundli.syncEnabled ? l10n.synced : l10n.deviceOnly,
                    child: Icon(
                      kundli.syncEnabled
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      size: KJIcon.sm,
                      color: kundli.syncEnabled
                          ? KJColors.inkSoft
                          : KJColors.inkSoft.withValues(alpha: KJTint.dim),
                    ),
                  ),
                ],
              ),
              if (density == KundliDensity.detailed) ..._detail(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  /// The note identifies a person far better than their birth stamp
  /// ("Ramesh's daughter — marriage match" vs "12.03.1987 · 14:22"), so
  /// it wins line two when there is one. Detailed density shows both.
  String _secondaryLine() {
    final note = kundli.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return KJDate.dateDotTime(kundli.toBirthData().localDateTime);
  }

  List<Widget> _detail(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final note = kundli.note?.trim();
    // Only DETAILED pays for a snapshot, and only for rows actually
    // built — the lazy list means offscreen kundlis compute nothing.
    final snapshot = ref.watch(snapshotProvider(kundli.id));

    return [
      if (note != null && note.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: KJSpace.xs),
          child: Text(
            KJDate.dateDotTime(kundli.toBirthData().localDateTime),
            style: KJType.data(size: 12, color: KJColors.inkSoft),
          ),
        ),
      KJSpace.gap(KJSpace.sm),
      Wrap(
        spacing: KJSpace.sm,
        runSpacing: KJSpace.xs + 2,
        children: [
          snapshot.when(
            data: (s) => KJTag('${l10n.labelLagna} ${s.lagnaSign.label(l10n)}',
                maroon: true),
            loading: () => KJTag('${l10n.labelLagna} …'),
            error: (_, __) => KJTag('${l10n.labelLagna} ?'),
          ),
          snapshot.when(
            data: (s) => KJTag('${l10n.planetMoon} ${s.moonSign.label(l10n)}'),
            loading: () => KJTag('${l10n.planetMoon} …'),
            error: (_, __) => KJTag('${l10n.planetMoon} ?'),
          ),
          for (final label in kundli.labels) KJTag(label),
          if (kundli.isPrashna) KJTag(l10n.tagPrashna),
          if (kundli.isSharedToMahakosh)
            KJTag(l10n.klMahakoshTag(kundli.mahakoshCode!)),
        ],
      ),
    ];
  }
}

/// Pick an existing label or type a new one. Shared by the bulk action
/// and the per-kundli editor so the two can't drift.
Future<String?> showLabelPicker(BuildContext context,
    {required List<String> existing}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final l10n = ctx.l10n;
      return AlertDialog(
        title: Text(l10n.klAddLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: l10n.klLabelHint),
              onSubmitted: (v) =>
                  Navigator.pop(ctx, v.trim().isEmpty ? null : v.trim()),
            ),
            if (existing.isNotEmpty) ...[
              KJSpace.gap(KJSpace.lg),
              KJSectionLabel(l10n.klExistingLabels, padded: true),
              Wrap(
                spacing: KJSpace.sm,
                runSpacing: KJSpace.sm,
                children: [
                  for (final label in existing)
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, label),
                      child: KJTag(label),
                    ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              Navigator.pop(ctx, v.isEmpty ? null : v);
            },
            child: Text(l10n.add),
          ),
        ],
      );
    },
  );
}
