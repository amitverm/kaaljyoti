/// Compare-aware module detail host (spec §3.3). Reached by drilling
/// into a widget on one of the Kundli Compare screen's chart tabs: it
/// opens the SAME module's full detail view, but with a subject tab bar
/// on top so the researcher can flip the one module between every chart
/// in the comparison — same locked context (one shared per-instance
/// config, one shared scroll offset) so differences pop visually.
///
/// Like the compare screen itself, tab switching is an INSTANT
/// [IndexedStack] swap (no [TabBarView] slide) — the blink-comparison is
/// the whole point. The subject the user drilled in from is pre-selected.
/// There is no Similarities tab here.
///
/// Config edits made inside a tab's detail body write straight back to
/// the originating dashboard card (global views — consistent
/// everywhere), exactly as [ModuleDetailScreen] does.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../widgetsystem/astro_module.dart';
import '../widgetsystem/registry.dart';
import 'dashboard_screen.dart'
    show ComparePositionsCard, CompareUnavailableCard, moduleNeedsFullChart;
import 'module_detail_screen.dart';

class CompareModuleDetailScreen extends ConsumerStatefulWidget {
  const CompareModuleDetailScreen({
    super.key,
    required this.moduleId,
    required this.subjectRef,
    this.initialConfig,
    this.instanceId,
    this.viewId,
  });

  final String moduleId;

  /// The compare-set ref (local kundli id or `mk:<code>`) whose chart tab
  /// the user drilled in from — pre-selected on entry.
  final String subjectRef;

  /// The tapped card's per-instance config, and the dashboard row it came
  /// from — same trio [ModuleDetailScreen] receives, so config edits here
  /// persist back to the (global) card identically.
  final Map<String, dynamic>? initialConfig;
  final String? instanceId;
  final String? viewId;

  @override
  ConsumerState<CompareModuleDetailScreen> createState() =>
      _CompareModuleDetailScreenState();
}

class _CompareModuleDetailScreenState
    extends ConsumerState<CompareModuleDetailScreen> {
  // The one working config copy shared across every subject tab (locked
  // context). Null until the first edit — then it drives all tabs and is
  // persisted back to the dashboard card. Mirrors ModuleDetailScreen.
  Map<String, dynamic>? _config;

  void _updateConfig(Map<String, dynamic> next) {
    setState(() => _config = next);
    persistModuleConfig(ref, next,
        instanceId: widget.instanceId, viewId: widget.viewId);
  }

  @override
  Widget build(BuildContext context) {
    final module = moduleById(widget.moduleId);
    if (module == null) {
      return Scaffold(body: Center(child: Text(context.l10n.mdUnknownModule)));
    }

    final config = _config ?? widget.initialConfig ?? const {};
    final slotsAsync = ref.watch(compareSubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleInstanceTitle(module, config, context.l10n)),
      ),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: '$e'),
        data: (slots) {
          if (slots.isEmpty) {
            return EmptyState(message: context.l10n.cmpPickHint);
          }
          return _CompareModuleTabs(
            slots: slots,
            moduleId: widget.moduleId,
            preselectRef: widget.subjectRef,
            configOverride: _config ?? widget.initialConfig,
            onConfigChanged: _updateConfig,
          );
        },
      ),
    );
  }
}

/// The subject tab bar + per-tab module detail body. Owns the shared
/// scroll offset across tabs and the per-tab scroll controllers,
/// recreated when the subject set changes — the same mechanism the
/// compare screen uses for its dashboard tabs.
class _CompareModuleTabs extends ConsumerStatefulWidget {
  const _CompareModuleTabs({
    required this.slots,
    required this.moduleId,
    required this.preselectRef,
    required this.configOverride,
    required this.onConfigChanged,
  });

  final List<CompareSlot> slots;
  final String moduleId;
  final String preselectRef;
  final Map<String, dynamic>? configOverride;
  final void Function(Map<String, dynamic> config) onConfigChanged;

  @override
  ConsumerState<_CompareModuleTabs> createState() => _CompareModuleTabsState();
}

class _CompareModuleTabsState extends ConsumerState<_CompareModuleTabs>
    with TickerProviderStateMixin {
  late TabController _tab;
  late List<ScrollController> _scrolls;
  double _offset = 0;
  // Which tab the IndexedStack currently shows — tracked separately so a
  // real index change triggers exactly one instant swap (no interpolated
  // slide) rather than rebuilding on every indicator animation tick.
  int _shownIndex = 0;

  int get _tabCount => widget.slots.length;

  int _indexOfPreselect() {
    final i = widget.slots.indexWhere((s) => s.ref == widget.preselectRef);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _build(initialIndex: _indexOfPreselect());
  }

  @override
  void didUpdateWidget(_CompareModuleTabs old) {
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
    final start = initialIndex.clamp(0, math.max(0, _tabCount - 1)).toInt();
    _tab = TabController(length: _tabCount, vsync: this, initialIndex: start);
    _shownIndex = start;
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
    final i = _tab.index;
    if (i == _shownIndex) return;
    setState(() => _shownIndex = i);
    _syncScroll(i);
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
    // Pre-warm every full subject's context on entry so tab switching
    // feels instant (the providers cache) — same as the compare screen.
    for (final s in widget.slots) {
      if (s.kundliId != null) ref.watch(moduleContextProvider(s.kundliId!));
    }
    return Column(
      children: [
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final s in widget.slots) _subjectTab(context, s)],
        ),
        Expanded(
          // IndexedStack, not TabBarView: the point of Compare is visual
          // diffing — flipping between charts must be a one-frame content
          // swap with no slide/fade. IndexedStack keeps every tab alive
          // and laid out, so revealing a tab is instant and its scroll
          // offset can be synced to the shared offset (via _onTabChanged).
          child: IndexedStack(
            index: _shownIndex,
            children: [
              for (var i = 0; i < widget.slots.length; i++)
                _detailTab(i, widget.slots[i]),
            ],
          ),
        ),
      ],
    );
  }

  /// A subject tab styled like the compare screen's chips: MK glyph for
  /// Mahakosh subjects, a strike-through label when unavailable, and a
  /// "limited" badge for positions-only bookmarks.
  Widget _subjectTab(BuildContext context, CompareSlot slot) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (slot.isMahakosh)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.public,
                  size: 15,
                  color: slot.unavailable ? KJColors.inkSoft : KJColors.forest),
            ),
          Text(
            slot.label,
            style: TextStyle(
              decoration: slot.unavailable ? TextDecoration.lineThrough : null,
            ),
          ),
          if (slot.limited)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: KJTag(context.l10n.cmpLimitedBadge, maroon: true),
            ),
        ],
      ),
    );
  }

  Widget _detailTab(int index, CompareSlot slot) {
    if (slot.unavailable) {
      return EmptyState(message: context.l10n.cmpChartUnavailable);
    }

    // Legacy (positions-only) bookmark: no full snapshot, so the module's
    // real detail can't render. Reuse the compare screen's placeholder
    // treatment inside the detail tab (spec §3.3 / §4.4).
    if (slot.limited) {
      final module = moduleById(widget.moduleId);
      final title = module == null
          ? widget.moduleId
          : moduleInstanceTitle(
              module, widget.configOverride ?? const {}, context.l10n);
      final Widget card =
          module != null && !moduleNeedsFullChart(widget.moduleId) &&
                  slot.chart != null
              ? ComparePositionsCard(title: title, chart: slot.chart!)
              : CompareUnavailableCard(title: title);
      return SingleChildScrollView(
        controller: _scrolls[index],
        padding: const EdgeInsets.all(16),
        child: card,
      );
    }

    // Full subject: the module's own detail body, its internal scroll
    // view bound to this tab's controller (via PrimaryScrollController) so
    // the shared offset syncs across tabs. Config is the host-owned copy,
    // identical on every tab; edits persist back to the dashboard card.
    return PrimaryScrollController(
      controller: _scrolls[index],
      child: ModuleDetailBody(
        kundliId: slot.kundliId!,
        moduleId: widget.moduleId,
        configOverride: widget.configOverride,
        onConfigChanged: widget.onConfigChanged,
      ),
    );
  }
}
