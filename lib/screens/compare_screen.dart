/// Kundli Compare (spec §3) — a research tool for studying 2–4 charts
/// together. Phones can't show two kundlis side by side, so the design
/// substitutes fast tab switching with LOCKED CONTEXT: the same
/// dashboard view and scroll offset across every chart tab, so flicking
/// between tabs makes differences pop. A pinned "Similarities" tab lists
/// the computed shared factors (spec §4).
///
/// The chart tabs reuse the global dashboard system verbatim via
/// [DashboardBody]; the compare screen owns the shared view + scroll
/// state and hands it in. Legacy (positions-only) bookmarks render the
/// same grid geometry with placeholder cards so scanning still works.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/astro/compare.dart';
import '../core/astro/dasha/dasha.dart';
import '../core/astro/models.dart';
import '../core/astro/transit_scan.dart' show SadeSatiPhaseKind;
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../widgetsystem/astro_module.dart' show moduleInstanceTitle;
import '../widgetsystem/registry.dart';
import 'dashboard_screen.dart';

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(compareSubjectsProvider);
    final refs = ref.watch(compareSetProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.cmpTitle),
        actions: [
          if (refs.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'customize') {
                  final slots = slotsAsync.value ?? const [];
                  final activeView = ref.read(compareViewIdProvider);
                  // Any resolvable chart id works for the Arrange route
                  // (views are global); prefer a full subject's id.
                  final id = slots
                      .where((s) => s.kundliId != null)
                      .map((s) => s.kundliId)
                      .firstOrNull;
                  if (id != null && activeView != null) {
                    context.push('/kundli/$id/arrange/$activeView');
                  }
                } else if (v == 'new') {
                  ref.read(compareSetProvider.notifier).clear();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                    value: 'customize',
                    child: Text(ctx.l10n.cmpCustomizeView)),
                PopupMenuItem(
                    value: 'new', child: Text(ctx.l10n.cmpNewComparison)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _ChipRow(slotsAsync: slotsAsync),
          const Divider(height: 1),
          Expanded(
            child: slotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(message: '$e'),
              data: (slots) {
                if (slots.isEmpty) {
                  return EmptyState(message: context.l10n.cmpPickHint);
                }
                return _CompareTabs(slots: slots);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The removable, drag-reorderable chip row + "Add chart" button
/// (spec §3.2). Order = tab order.
class _ChipRow extends ConsumerWidget {
  const _ChipRow({required this.slotsAsync});
  final AsyncValue<List<CompareSlot>> slotsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refs = ref.watch(compareSetProvider);
    final slots = slotsAsync.value ?? const [];
    CompareSlot? slotFor(String r) =>
        slots.where((s) => s.ref == r).firstOrNull;

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: refs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(context.l10n.cmpChipRowHint,
                          style:
                              TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
                    ),
                  )
                : ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: refs.length,
                    onReorder: (o, n) =>
                        ref.read(compareSetProvider.notifier).reorder(o, n),
                    itemBuilder: (ctx, i) {
                      final r = refs[i];
                      final slot = slotFor(r);
                      return ReorderableDragStartListener(
                        key: ValueKey(r),
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 12),
                          child: _chartChip(context, ref, r, slot),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(context.l10n.cmpAddChart),
              onPressed: () => _showPicker(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartChip(
      BuildContext context, WidgetRef ref, String r, CompareSlot? slot) {
    final label = slot?.label ?? (isCompareMkRef(r) ? r.substring(3) : r);
    final unavailable = slot?.unavailable ?? false;
    final limited = slot?.limited ?? false;
    final isMk = slot?.isMahakosh ?? isCompareMkRef(r);
    return InputChip(
      avatar: isMk
          ? Icon(Icons.public,
              size: 16,
              color: unavailable ? KJColors.inkSoft : KJColors.forest)
          : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12.5,
                decoration:
                    unavailable ? TextDecoration.lineThrough : null,
                color: unavailable ? KJColors.inkSoft : KJColors.ink,
              )),
          if (limited)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Tooltip(
                message: context.l10n.cmpLimitedTooltip,
                child: KJTag(context.l10n.cmpLimitedBadge, maroon: true),
              ),
            ),
        ],
      ),
      onDeleted: () => ref.read(compareSetProvider.notifier).remove(r),
    );
  }

  Future<void> _showPicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: KJColors.paper,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (ctx) => const _PickerSheet(),
    );
  }
}

/// The two-tab add-chart picker: My Kundlis (search + list) and
/// Bookmarks (spec §3.2). Adding is capped at four; rows beyond the cap
/// are disabled with a toast.
class _PickerSheet extends ConsumerStatefulWidget {
  const _PickerSheet();

  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  String _search = '';

  void _tryAdd(String subjectRef) {
    final ok = ref.read(compareSetProvider.notifier).add(subjectRef);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cmpMaxCharts)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(compareSetProvider);
    final atCap = selected.length >= CompareSetNotifier.maxCharts;
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              tabs: [
                Tab(text: context.l10n.cmpMyKundlis),
                Tab(text: context.l10n.cmpBookmarks),
              ],
            ),
            Flexible(
              child: TabBarView(
                children: [
                  _myKundlisTab(selected, atCap),
                  _bookmarksTab(selected, atCap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myKundlisTab(List<String> selected, bool atCap) {
    final kundlis = ref.watch(kundlisProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.l10n.cmpSearchKundlis,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: kundlis.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (list) {
              final q = _search.trim().toLowerCase();
              final filtered = [
                for (final k in list)
                  if (q.isEmpty || k.name.toLowerCase().contains(q)) k,
              ];
              if (filtered.isEmpty) {
                return EmptyState(message: context.l10n.cmpNoKundlis);
              }
              return ListView(
                children: [
                  for (final k in filtered)
                    _pickerTile(
                      subjectRef: k.id,
                      title: k.name,
                      leading: Icons.person_outline,
                      selected: selected.contains(k.id),
                      atCap: atCap,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bookmarksTab(List<String> selected, bool atCap) {
    final bookmarks = ref.watch(mahakoshBookmarksProvider);
    return bookmarks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: context.l10n.cmpBookmarksOffline),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(message: context.l10n.cmpNoBookmarks);
        }
        return ListView(
          children: [
            for (final b in list)
              _pickerTile(
                subjectRef: compareMkRef(b.mkCode),
                title: b.mkCode,
                subtitle: b.chart == null
                    ? context.l10n.cmpBookmarkGone
                    : b.chart!.locationGeneral,
                leading: Icons.public,
                selected: selected.contains(compareMkRef(b.mkCode)),
                atCap: atCap,
                disabled: b.chart == null,
              ),
          ],
        );
      },
    );
  }

  Widget _pickerTile({
    required String subjectRef,
    required String title,
    String? subtitle,
    required IconData leading,
    required bool selected,
    required bool atCap,
    bool disabled = false,
  }) {
    // Already-selected rows stay tappable to REMOVE; unselected rows are
    // disabled once the cap is hit (spec §3.2 cap enforcement).
    final blocked = disabled || (!selected && atCap);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        enabled: !blocked,
        leading: Icon(leading,
            size: 20,
            color: blocked ? KJColors.inkSoft : KJColors.maroon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle, color: KJColors.forest, size: 20)
            : const Icon(Icons.add, size: 20),
        onTap: blocked
            ? null
            : () {
                if (selected) {
                  ref.read(compareSetProvider.notifier).remove(subjectRef);
                } else {
                  _tryAdd(subjectRef);
                }
                setState(() {});
              },
      ),
    );
  }
}

/// The tabbed compare view: one tab per chart + a pinned Similarities
/// tab (spec §3.3/§3.4). Owns the shared scroll offset across tabs and
/// the per-tab scroll controllers, recreated when the subject set
/// changes.
class _CompareTabs extends ConsumerStatefulWidget {
  const _CompareTabs({required this.slots});
  final List<CompareSlot> slots;

  @override
  ConsumerState<_CompareTabs> createState() => _CompareTabsState();
}

class _CompareTabsState extends ConsumerState<_CompareTabs>
    with TickerProviderStateMixin {
  late TabController _tab;
  late List<ScrollController> _scrolls;
  double _offset = 0;

  bool get _showSim => widget.slots.length >= 2;
  int get _tabCount => widget.slots.length + (_showSim ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _build(initialIndex: 0);
  }

  @override
  void didUpdateWidget(_CompareTabs old) {
    super.didUpdateWidget(old);
    final oldRefs = old.slots.map((s) => s.ref).join('|');
    final newRefs = widget.slots.map((s) => s.ref).join('|');
    if (oldRefs != newRefs) {
      final keepIndex = math.min(_tab.index, _tabCount - 1);
      _disposeControllers();
      _build(initialIndex: math.max(0, keepIndex));
      setState(() {});
    }
  }

  void _build({required int initialIndex}) {
    _tab = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: initialIndex.clamp(0, math.max(0, _tabCount - 1)),
    );
    _scrolls = [
      for (var i = 0; i < widget.slots.length; i++)
        ScrollController(initialScrollOffset: _offset),
    ];
    for (var i = 0; i < _scrolls.length; i++) {
      final idx = i;
      final c = _scrolls[i];
      c.addListener(() {
        if (_tab.index == idx && c.hasClients) _offset = c.offset;
      });
    }
    _tab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tab.index < _scrolls.length) _syncScroll(_tab.index);
  }

  void _syncScroll(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index < 0 || index >= _scrolls.length) return;
      final c = _scrolls[index];
      if (c.hasClients) {
        c.jumpTo(_offset.clamp(0, c.position.maxScrollExtent));
      }
    });
  }

  void _disposeControllers() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    for (final c in _scrolls) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeView = ref.watch(compareViewIdProvider);
    // Pre-warm every full subject's snapshot/context on entry so tab
    // switching feels instant (spec §3.3) — the providers cache, so
    // watching them here builds all charts up front instead of on first
    // visit to each tab.
    for (final s in widget.slots) {
      if (s.kundliId != null) ref.watch(moduleContextProvider(s.kundliId!));
    }
    return Column(
      children: [
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final s in widget.slots)
              Tab(
                child: Text(
                  s.label,
                  style: TextStyle(
                    decoration:
                        s.unavailable ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            if (_showSim) Tab(text: context.l10n.cmpSimilarities),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              for (var i = 0; i < widget.slots.length; i++)
                _chartTab(i, widget.slots[i], activeView),
              if (_showSim) _SimilaritiesTab(slots: widget.slots),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartTab(int index, CompareSlot slot, String? activeView) {
    if (slot.unavailable) {
      return EmptyState(message: context.l10n.cmpChartUnavailable);
    }
    void onSelect(String id) =>
        ref.read(compareViewIdProvider.notifier).select(id);

    if (slot.limited) {
      // Legacy Mahakosh: same grid, placeholder / positions cards so the
      // geometry matches the full tabs (spec §3.3).
      return DashboardBody(
        kundliId: slot.ref,
        activeViewId: activeView,
        onSelectView: onSelect,
        scrollController: _scrolls[index],
        limitedCardBuilder: (ctx, pwd) => _limitedCard(ctx, slot, pwd),
      );
    }

    // Full subject: build a real ModuleContext for the chart tab.
    final ctxAsync = ref.watch(moduleContextProvider(slot.kundliId!));
    return ctxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: context.l10n.dbCalcFailed('$e')),
      data: (moduleCtx) => DashboardBody(
        kundliId: slot.kundliId!,
        moduleCtx: moduleCtx,
        activeViewId: activeView,
        onSelectView: onSelect,
        scrollController: _scrolls[index],
      ),
    );
  }

  Widget _limitedCard(BuildContext context, CompareSlot slot, PlacedWidget pwd) {
    final module = moduleById(pwd.widgetId);
    final title = module == null
        ? pwd.widgetId
        : moduleInstanceTitle(module, pwd.config, context.l10n);
    if (module != null &&
        !moduleNeedsFullChart(module.meta.id) &&
        slot.chart != null) {
      return ComparePositionsCard(title: title, chart: slot.chart!);
    }
    return CompareUnavailableCard(title: title);
  }
}

/// The Similarities tab (spec §3.4): dasha-system selector + grouped
/// findings list, each finding showing which charts share it, with
/// event rows expanding to a per-chart detail sheet.
class _SimilaritiesTab extends ConsumerWidget {
  const _SimilaritiesTab({required this.slots});
  final List<CompareSlot> slots;

  static const _groupOrder = ['lagnaMoon', 'placements', 'dignity', 'events'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final findingsAsync = ref.watch(compareFindingsProvider);
    final system = ref.watch(compareDashaSystemProvider);
    final viewerAyanamsa = ref.watch(defaultAyanamsaProvider).value;

    String labelFor(String subjectId) =>
        slots.where((s) => s.ref == subjectId).firstOrNull?.label ?? subjectId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // Header: subject names.
        Text(
          slots.map((s) => s.label).join('  ·  '),
          style: KJTheme.serif(size: 16),
        ),
        const SizedBox(height: 12),
        // Dasha-system segmented selector.
        KJSectionLabel(l10n.cmpDashaSystem),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final s in DashaSystem.values)
              ChoiceChip(
                label: Text(s.label(l10n),
                    style: const TextStyle(fontSize: 12.5)),
                selected: system == s,
                labelStyle: TextStyle(
                    fontSize: 12.5,
                    color: system == s ? KJColors.paper : KJColors.ink),
                onSelected: (_) =>
                    ref.read(compareDashaSystemProvider.notifier).select(s),
              ),
          ],
        ),
        // Ayanamsa-mismatch notice (spec §4.4).
        for (final s in slots)
          if (s.isMahakosh &&
              viewerAyanamsa != null &&
              s.ayanamsaId != null &&
              s.ayanamsaId != viewerAyanamsa)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.cmpAyanamsaNotice(s.label),
                style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
              ),
            ),
        const SizedBox(height: 16),
        findingsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(message: '$e'),
          data: (findings) => _body(context, ref, findings, labelFor),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<CompareFinding> findings,
      String Function(String) labelFor) {
    final l10n = context.l10n;
    // Static (non-event) overlaps drive the "no overlaps" empty state.
    final staticFindings =
        findings.where((f) => f.group != 'events').toList();
    final eventFindings = findings.where((f) => f.group == 'events').toList();
    // A real event finding is anything that isn't a neutral row.
    final hasRealEvents =
        eventFindings.any((f) => !f.key.startsWith('event-neutral:'));

    final children = <Widget>[];
    for (final group in _groupOrder) {
      final inGroup = findings.where((f) => f.group == group).toList();
      children.add(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: KJSectionLabel(_groupLabel(l10n, group)),
      ));
      if (inGroup.isEmpty) {
        if (group == 'events' && !hasRealEvents) {
          children.add(_emptyRow(context, l10n.cmpNoEvents, onTap: () {
            // Link to each kundli's events screen (spec §3.4).
            _openEventsScreens(context, ref);
          }));
        } else if (group != 'events' && staticFindings.isEmpty) {
          children.add(_emptyRow(context, l10n.cmpNoOverlaps));
        } else {
          children.add(_emptyRow(context, l10n.cmpNoneInGroup));
        }
        continue;
      }
      for (final f in inGroup) {
        children.add(_findingRow(context, f, labelFor));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  void _openEventsScreens(BuildContext context, WidgetRef ref) {
    // Open the events screen for the first local subject (the only kind
    // with an editable event store).
    final local = slots
        .where((s) => !s.isMahakosh && s.kundliId != null)
        .map((s) => s.kundliId)
        .firstOrNull;
    if (local != null) context.push('/kundli/$local/events');
  }

  Widget _emptyRow(BuildContext context, String message, {VoidCallback? onTap}) {
    final w = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(message,
          style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
    );
    return onTap == null ? w : InkWell(onTap: onTap, child: w);
  }

  Widget _findingRow(BuildContext context, CompareFinding f,
      String Function(String) labelFor) {
    final l10n = context.l10n;
    final neutral = f.key.startsWith('event-neutral:');
    final isEvent = f.group == 'events';
    final dots = [
      for (final id in f.subjectIds) labelFor(id),
    ].join(', ');

    Widget row = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KJColors.paperAlt.withValues(alpha: neutral ? 0.5 : 1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KJColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(f),
              size: 16,
              color: neutral ? KJColors.inkSoft : KJColors.maroon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(compareFindingLabel(l10n, f),
                    style: TextStyle(
                        fontSize: 13.5,
                        color: neutral ? KJColors.inkSoft : KJColors.ink)),
                const SizedBox(height: 2),
                Text(dots,
                    style:
                        TextStyle(fontSize: 11.5, color: KJColors.inkSoft)),
              ],
            ),
          ),
          if (isEvent && (f.eventDetails?.isNotEmpty ?? false))
            Icon(Icons.chevron_right, size: 18, color: KJColors.inkSoft),
        ],
      ),
    );

    if (isEvent && (f.eventDetails?.isNotEmpty ?? false)) {
      return InkWell(
        onTap: () => _showEventDetail(context, f, labelFor),
        child: row,
      );
    }
    return row;
  }

  IconData _iconFor(CompareFinding f) {
    if (f.key.startsWith('lagna') || f.key.startsWith('moon')) {
      return Icons.brightness_2_outlined;
    }
    if (f.group == 'events') return Icons.event_note_outlined;
    if (f.group == 'dignity') return Icons.trending_up;
    return Icons.public;
  }

  void _showEventDetail(BuildContext context, CompareFinding f,
      String Function(String) labelFor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KJColors.paper,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => _EventDetailSheet(finding: f, labelFor: labelFor),
    );
  }

  String _groupLabel(AppLocalizations l10n, String group) => switch (group) {
        'lagnaMoon' => l10n.cmpGroupLagnaMoon,
        'placements' => l10n.cmpGroupPlacements,
        'dignity' => l10n.cmpGroupDignity,
        'events' => l10n.cmpGroupEvents,
        _ => group,
      };
}

/// The expandable per-event detail sheet (spec §3.4/§4.3): per chart —
/// date/age, precision badge, MD/AD lords, Sade Sati, and the full
/// nine-graha transit grid (house from Moon / from lagna).
class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({required this.finding, required this.labelFor});
  final CompareFinding finding;
  final String Function(String) labelFor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final details = finding.eventDetails ?? const [];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(compareFindingLabel(l10n, finding),
                style: KJTheme.serif(size: 18)),
            const SizedBox(height: 12),
            for (final d in details) ...[
              _detailCard(context, d),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailCard(BuildContext context, CompareEventDetail d) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KJColors.paperAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KJColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(labelFor(d.subjectId),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              if (d.approximate)
                KJTag(l10n.cmpApprox, maroon: true)
              else
                KJTag(d.precision),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _dateLine(l10n, d),
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 6),
          _kv(l10n.cmpMahadasha, d.mdLordLabel ?? '—'),
          _kv(l10n.cmpAntardasha, d.adLordLabel ?? '—'),
          _kv(
              l10n.cmpSadeSati,
              d.sadeSatiPhase == null
                  ? '—'
                  : d.sadeSatiPhase!.label(l10n)),
          const SizedBox(height: 8),
          KJSectionLabel(l10n.cmpTransitGrid),
          const SizedBox(height: 4),
          _transitGrid(context, d),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text(k, style: const TextStyle(fontSize: 12))),
            Text(v, style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
          ],
        ),
      );

  String _dateLine(AppLocalizations l10n, CompareEventDetail d) {
    if (d.date != null) {
      return '${d.date!.year}-${d.date!.month.toString().padLeft(2, '0')}-'
          '${d.date!.day.toString().padLeft(2, '0')}';
    }
    if (d.ageYears != null) return l10n.cmpAge('${d.ageYears}');
    return '—';
  }

  Widget _transitGrid(BuildContext context, CompareEventDetail d) {
    final l10n = context.l10n;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
      },
      children: [
        TableRow(children: [
          _th(''),
          _th(l10n.cmpFromMoon),
          _th(l10n.cmpFromLagna),
        ]),
        for (final p in Planet.values)
          if (d.transitHousesFromMoon[p] != null)
            TableRow(children: [
              _td(p.label(l10n)),
              _td('${d.transitHousesFromMoon[p]}'),
              _td('${d.transitHousesFromLagna[p]}'),
            ]),
      ],
    );
  }

  Widget _th(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(t,
            style: KJTheme.mono(size: 10, color: KJColors.inkSoft)),
      );

  Widget _td(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(t, style: const TextStyle(fontSize: 12)),
      );
}

// ---------------------------------------------------------------------------
// Finding → human-readable English label (spec §3.4; similarities ship
// English-only per resolution §8.4). The engine's params already carry
// English display values; this only picks the right template.
// ---------------------------------------------------------------------------

String compareFindingLabel(AppLocalizations l10n, CompareFinding f) {
  final p = f.params;
  String cat() {
    final tag = p['tag'];
    if (tag != null && tag.isNotEmpty) return tag;
    return eventCategoryLabel(l10n, EventCategory.byCode(p['category']));
  }

  String frame() => p['frame'] == 'lagna' ? l10n.cmpFromLagna : l10n.cmpFromMoon;

  final key = f.key;
  if (key.startsWith('lagna-sign:')) return l10n.cmpFndLagnaSign(p['sign'] ?? '');
  if (key.startsWith('lagna-nak:')) {
    return l10n.cmpFndLagnaNak(p['nakshatra'] ?? '');
  }
  if (key.startsWith('moon-sign:')) return l10n.cmpFndMoonSign(p['sign'] ?? '');
  if (key.startsWith('moon-nak:')) {
    return l10n.cmpFndMoonNak(p['nakshatra'] ?? '');
  }
  if (key.startsWith('moon-pada:')) {
    return l10n.cmpFndMoonPada(p['nakshatra'] ?? '', p['pada'] ?? '');
  }
  if (key.startsWith('graha-sign:')) {
    return l10n.cmpFndGrahaSign(p['planet'] ?? '', p['sign'] ?? '');
  }
  if (key.startsWith('graha-house:')) {
    return l10n.cmpFndGrahaHouse(p['planet'] ?? '', p['house'] ?? '');
  }
  if (key.startsWith('graha-dignity:')) {
    return l10n.cmpFndDignity(p['planet'] ?? '', _dignity(l10n, p['dignity']));
  }
  if (key.startsWith('graha-retro:')) {
    return l10n.cmpFndRetro(p['planet'] ?? '');
  }
  if (key.startsWith('dasha-today:')) {
    return l10n.cmpFndDashaToday(p['lord'] ?? '');
  }
  if (key.startsWith('event-md:')) return l10n.cmpFndEventMd(cat(), p['lord'] ?? '');
  if (key.startsWith('event-ad:')) return l10n.cmpFndEventAd(cat(), p['lord'] ?? '');
  if (key.startsWith('event-sadesati:')) {
    return l10n.cmpFndEventSade(cat(), _phase(l10n, p['phase']));
  }
  if (key.contains(':rahuketu:')) {
    return l10n.cmpFndEventAxis(
        cat(), p['rahuHouse'] ?? '', p['ketuHouse'] ?? '', frame());
  }
  if (key.startsWith('event-transit:')) {
    return l10n.cmpFndEventTransit(
        p['planet'] ?? '', p['house'] ?? '', frame(), cat());
  }
  if (key.startsWith('event-neutral:')) return l10n.cmpFndNeutral(cat());
  return f.key;
}

String _dignity(AppLocalizations l10n, String? d) => switch (d) {
      'exalted' => l10n.cmpDignExalted,
      'debilitated' => l10n.cmpDignDebilitated,
      'ownSign' => l10n.cmpDignOwn,
      _ => d ?? '',
    };

String _phase(AppLocalizations l10n, String? name) {
  final kind = SadeSatiPhaseKind.values
      .where((k) => k.name == name)
      .firstOrNull;
  return kind?.label(l10n) ?? (name ?? '');
}
