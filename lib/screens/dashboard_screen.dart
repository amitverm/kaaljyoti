/// Screen 04 — Home Dashboard. The core differentiator: named view
/// chips, a responsive span-aware module grid (2 columns on phones,
/// 3 on tablets), long-press drag-to-rearrange, and a generic
/// per-instance widget menu (size / configure / duplicate / remove) —
/// all driven by the widget registry; the host never knows what's
/// inside a module.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/dashboard_repository.dart';
import '../data/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../widgetsystem/astro_module.dart';
import '../widgetsystem/registry.dart';
import '../widgetsystem/view_templates.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundliAsync = ref.watch(kundliByIdProvider(kundliId));
    final viewsAsync = ref.watch(dashboardViewsProvider);
    final ctxAsync = ref.watch(moduleContextProvider(kundliId));

    return Scaffold(
      appBar: AppBar(
        title: kundliAsync.when(
          data: (k) => GestureDetector(
            onTap: () => context.push('/kundli/$kundliId/edit'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k?.name ?? ''),
                if (k != null)
                  Text(
                    TEDate.dateDotTime(k.toBirthData().localDateTime),
                    style:
                        TETheme.mono(size: 10.5, color: TEColors.inkSoft),
                  ),
              ],
            ),
          ),
          loading: () => const Text(''),
          error: (_, __) => const Text('Kundli'),
        ),
        actions: [
          // Arrange is a screen-level setting — pinned in the header so
          // it stays reachable no matter how many view chips exist.
          Consumer(builder: (context, ref, _) {
            final views =
                ref.watch(dashboardViewsProvider).value;
            final activeId = ref.watch(activeViewIdProvider) ??
                (views == null || views.isEmpty ? null : views.first.id);
            return IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Arrange widgets',
              onPressed: activeId == null
                  ? null
                  : () =>
                      context.push('/kundli/$kundliId/arrange/$activeId'),
            );
          }),
          // Life events belong to the native, not the (global) dashboard —
          // so they get their own screen. Hidden for read-only Mahakosh
          // community charts, which have no local event store.
          if (!isMahakoshKundliId(kundliId))
            IconButton(
              icon: const Icon(Icons.event_note_outlined),
              tooltip: 'Life events',
              onPressed: () => context.push('/kundli/$kundliId/events'),
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export / Print',
            onPressed: () => context.push('/kundli/$kundliId/export'),
          ),
        ],
      ),
      // No nav pill inside a kundli — the pill belongs to the five
      // landing screens only; back returns to the kundli list.
      body: viewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Could not load views: $e'),
        data: (views) {
          final activeId = ref.watch(activeViewIdProvider) ??
              (views.isEmpty ? null : views.first.id);
          final activeView = views.where((v) => v.id == activeId).isEmpty
              ? (views.isEmpty ? null : views.first)
              : views.firstWhere((v) => v.id == activeId);
          if (activeView == null) {
            return const EmptyState(message: 'No dashboard views.');
          }
          return Column(
            children: [
              // Instant Prashna: not kept yet — offer Keep / Discard.
              if (kundliAsync.value?.isEphemeral ?? false)
                _ephemeralBanner(context, ref, kundliAsync.value!),
              _viewChips(context, ref, views, activeView),
              Expanded(
                child: ctxAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      EmptyState(message: 'Calculation failed: $e'),
                  data: (moduleCtx) =>
                      _WidgetGrid(view: activeView, moduleCtx: moduleCtx),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _viewChips(BuildContext context, WidgetRef ref,
      List<DashboardView> views, DashboardView active) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final v in views)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                // Long-press a view chip for rename/delete.
                onLongPress: () =>
                    _viewActions(context, ref, views, v),
                child: ChoiceChip(
                  label: Text(v.name),
                  selected: v.id == active.id,
                  labelStyle: TextStyle(
                      color: v.id == active.id
                          ? TEColors.paper
                          : TEColors.ink),
                  onSelected: (_) =>
                      ref.read(activeViewIdProvider.notifier).state = v.id,
                ),
              ),
            ),
          ActionChip(
            label: const Text('+ New view'),
            onPressed: () => _newView(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _ephemeralBanner(
      BuildContext context, WidgetRef ref, Kundli kundli) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: TEColors.maroon.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TEColors.maroon.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Cast for this moment — not saved',
              style: TextStyle(fontSize: 12.5, color: TEColors.maroon),
            ),
          ),
          TextButton(
            onPressed: () async {
              final controller =
                  TextEditingController(text: kundli.name);
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keep this Prashna kundli'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Name (e.g. the question asked)'),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        child: const Text('Keep')),
                  ],
                ),
              );
              if (name == null || name.isEmpty) return;
              await ref.read(kundliRepoProvider).update(kundli.copyWith(
                    name: name,
                    isEphemeral: false,
                  ));
              ref.invalidate(kundlisProvider);
              ref.invalidate(kundliByIdProvider(kundli.id));
            },
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(kundliRepoProvider).delete(kundli.id);
              ref.invalidate(kundlisProvider);
              if (context.mounted) context.go('/');
            },
            child: Text('Discard',
                style: TextStyle(color: TEColors.maroon)),
          ),
        ],
      ),
    );
  }

  /// Long-press menu on a view chip: rename / delete.
  Future<void> _viewActions(BuildContext context, WidgetRef ref,
      List<DashboardView> views, DashboardView view) async {
    final repo = ref.read(dashboardRepoProvider);
    await showModalBottomSheet(
      context: context,
      backgroundColor: TEColors.paper,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(view.name, style: TETheme.serif(size: 18)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, size: 20),
              title: const Text('Rename view'),
              onTap: () async {
                Navigator.pop(ctx);
                final controller = TextEditingController(text: view.name);
                final name = await showDialog<String>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Rename view'),
                    content:
                        TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(dCtx, controller.text.trim()),
                          child: const Text('Rename')),
                    ],
                  ),
                );
                if (name != null && name.isNotEmpty) {
                  await repo.renameView(view.id, name);
                  ref.invalidate(dashboardViewsProvider);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  size: 20,
                  color: views.length > 1
                      ? TEColors.maroon
                      : TEColors.inkSoft),
              title: Text('Delete view',
                  style: TextStyle(
                      color: views.length > 1
                          ? TEColors.maroon
                          : TEColors.inkSoft)),
              subtitle: views.length > 1
                  ? null
                  : const Text('The only view can\'t be deleted',
                      style: TextStyle(fontSize: 11.5)),
              onTap: views.length <= 1
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: Text('Delete "${view.name}"?'),
                          content: const Text(
                              'Its widget arrangement is removed. '
                              'Widgets themselves are not affected.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dCtx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dCtx, true),
                                child: Text('Delete',
                                    style: TextStyle(
                                        color: TEColors.maroon))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await repo.deleteView(view.id);
                        ref.read(activeViewIdProvider.notifier).state =
                            views.firstWhere((v) => v.id != view.id).id;
                        ref.invalidate(dashboardViewsProvider);
                      }
                    },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// New view — template picker (design's Overview/Today presets plus
  /// Divisional Focus and Practitioner).
  Future<void> _newView(BuildContext context, WidgetRef ref) async {
    final template = await showModalBottomSheet<ViewTemplate>(
      context: context,
      backgroundColor: TEColors.paper,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child:
                  Text('New view from template', style: TETheme.serif(size: 18)),
            ),
            // Scrolls when the template list is taller than the sheet's
            // capped height (small screens, large text) instead of
            // overflowing.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 10),
                children: [
                  for (final t in viewTemplates)
                    ListTile(
                      leading:
                          Icon(t.icon, size: 20, color: TEColors.inkSoft),
                      title: Text(t.name),
                      subtitle: Text(t.description,
                          style: const TextStyle(fontSize: 12)),
                      onTap: () => Navigator.pop(ctx, t),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (template == null || !context.mounted) return;

    final controller = TextEditingController(text: template.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this view'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final view = await ref
        .read(dashboardRepoProvider)
        .createView(name, seed: template.widgets);
    ref.invalidate(dashboardViewsProvider);
    ref.read(activeViewIdProvider.notifier).state = view.id;
  }
}

class _WidgetGrid extends ConsumerStatefulWidget {
  const _WidgetGrid({required this.view, required this.moduleCtx});
  final DashboardView view;
  final ModuleContext moduleCtx;

  @override
  ConsumerState<_WidgetGrid> createState() => _WidgetGridState();
}

class _WidgetGridState extends ConsumerState<_WidgetGrid> {
  DashboardView get view => widget.view;
  ModuleContext get moduleCtx => widget.moduleCtx;

  // Restores the board's scroll position when the grid remounts (e.g.
  // returning from a module detail screen recreates this subtree) —
  // the offset is persisted per view in [dashboardScrollOffsetProvider].
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: ref.read(dashboardScrollOffsetProvider(view.id)),
  )..addListener(_saveOffset);

  void _saveOffset() {
    ref.read(dashboardScrollOffsetProvider(view.id).notifier).state =
        _scroll.offset;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placedAsync = ref.watch(viewWidgetsProvider(view.id));
    return placedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: 'Could not load widgets: $e'),
      data: (placed) {
        if (placed.isEmpty) {
          return EmptyState(
            message: 'This view is empty.',
            actionLabel: 'Add starter widgets',
            onAction: () async {
              await ref.read(dashboardRepoProvider).seedWidgets(
                  view.id, DashboardRepository.defaultOverview);
              ref.invalidate(viewWidgetsProvider(view.id));
            },
            secondaryLabel: 'Choose widgets myself',
            onSecondary: () => context.push(
                '/kundli/${moduleCtx.kundli.id}/arrange/${view.id}'),
          );
        }
        return LayoutBuilder(builder: (context, constraints) {
          // Responsive: 3 columns on tablets/wide screens, 2 on phones.
          final isWide = constraints.maxWidth >= 720;
          // Row capacity in sixths: full=6, half=3, third=2 (3 on phone).
          int units(CardSpan s) => switch (s) {
                CardSpan.full => 6,
                CardSpan.half => 3,
                CardSpan.third => isWide ? 2 : 3,
              };

          final rows = <List<PlacedWidget>>[];
          var current = <PlacedWidget>[];
          var used = 0;
          for (final p in placed) {
            final u = units(p.span);
            if (used + u > 6 && current.isNotEmpty) {
              rows.add(current);
              current = [];
              used = 0;
            }
            current.add(p);
            used += u;
            if (used >= 6) {
              rows.add(current);
              current = [];
              used = 0;
            }
          }
          if (current.isNotEmpty) rows.add(current);

          return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < row.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          flex: units(row[i].span),
                          child: _draggableCard(
                              context, ref, row[i], placed),
                        ),
                      ],
                      // Empty remainder of an incomplete row: also a
                      // drop target — dropping here places the dragged
                      // widget right after this row's last card.
                      if (row.fold<int>(
                              0, (sum, p) => sum + units(p.span)) <
                          6) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6 -
                              row.fold<int>(
                                  0, (sum, p) => sum + units(p.span)),
                          child: _emptySlotTarget(
                              ref, placed, row.last.instanceId),
                        ),
                      ],
                    ],
                  ),
                ),
              // Drop zone at the end of the board: move to last.
              _emptySlotTarget(
                  ref,
                  placed,
                  placed.isEmpty ? null : placed.last.instanceId,
                  height: 56,
                  label: 'Move to end'),
              // Always-visible entry point to the widget library — the
              // header tune icon alone isn't discoverable for
              // non-technical users.
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.dashboard_customize_outlined,
                      size: 18),
                  label: const Text('Add / edit widgets'),
                  onPressed: () => context.push(
                      '/kundli/${moduleCtx.kundli.id}/arrange/${view.id}'),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  /// Moves [draggedId] to immediately AFTER [anchorId] (or to the very
  /// front when anchor is null). Shared by empty-slot drop targets.
  Future<void> _moveAfter(
      WidgetRef ref, List<PlacedWidget> all, String draggedId,
      String? anchorId) async {
    final ids = all.map((p) => p.instanceId).toList();
    if (!ids.remove(draggedId)) return;
    final insertAt =
        anchorId == null ? 0 : ids.indexOf(anchorId) + 1;
    ids.insert(insertAt.clamp(0, ids.length), draggedId);
    await ref.read(dashboardRepoProvider).reorder(view.id, ids);
    ref.invalidate(viewWidgetsProvider(view.id));
  }

  /// An invisible-until-hovered drop target for empty space: the
  /// remainder of a partially filled row, or the end of the board.
  Widget _emptySlotTarget(
    WidgetRef ref,
    List<PlacedWidget> all,
    String? anchorId, {
    double height = 120,
    String? label,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != anchorId,
      onAcceptWithDetails: (d) => _moveAfter(ref, all, d.data, anchorId),
      builder: (context, candidates, _) => Container(
        height: height,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: candidates.isNotEmpty
              ? TEColors.maroon.withValues(alpha: 0.06)
              : Colors.transparent,
          border: candidates.isNotEmpty
              ? Border.all(color: TEColors.maroon, width: 1.5)
              : null,
        ),
        child: candidates.isNotEmpty && label != null
            ? Center(
                child: Text(label,
                    style:
                        TextStyle(fontSize: 12.5, color: TEColors.maroon)))
            : null,
      ),
    );
  }

  /// Long-press the card HEADER to drag-rearrange (the body stays free
  /// for chart gestures — double-tap / long-press view-from, etc.);
  /// drop on any other card to move the dragged widget there.
  Widget _draggableCard(BuildContext context, WidgetRef ref,
      PlacedWidget pwd, List<PlacedWidget> all) {
    // Plain copy for the drag feedback image.
    final feedbackCard = _card(context, ref, pwd);
    final card = _card(
      context,
      ref,
      pwd,
      wrapHeader: (header) => LongPressDraggable<String>(
        data: pwd.instanceId,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.9,
            child: SizedBox(width: 200, child: feedbackCard),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: header),
        child: header,
      ),
    );
    return DragTarget<String>(
        onWillAcceptWithDetails: (d) => d.data != pwd.instanceId,
        onAcceptWithDetails: (d) async {
          final ids = all.map((p) => p.instanceId).toList();
          final from = ids.indexOf(d.data);
          var to = ids.indexOf(pwd.instanceId);
          if (from < 0 || to < 0) return;
          ids.removeAt(from);
          to = ids.indexOf(pwd.instanceId);
          ids.insert(from <= to ? to + 1 : to, d.data);
          await ref.read(dashboardRepoProvider).reorder(view.id, ids);
          ref.invalidate(viewWidgetsProvider(view.id));
        },
        builder: (context, candidates, _) => Container(
          decoration: candidates.isNotEmpty
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TEColors.maroon, width: 1.5),
                )
              : null,
          child: card,
        ));
  }

  Widget _card(BuildContext context, WidgetRef ref, PlacedWidget pwd,
      {Widget Function(Widget header)? wrapHeader}) {
    final module = moduleById(pwd.widgetId);
    if (module == null) return const SizedBox();
    final ctx = moduleCtx.withConfig(pwd.config);
    final summary = module.configSummary(pwd.config);
    return ModuleCard(
      title: summary == null
          ? module.meta.title
          : '${module.meta.title} · $summary',
      onDetail: module.meta.hasDetailView
          ? () => context.push(
              '/kundli/${moduleCtx.kundli.id}/module/${module.meta.id}'
              '?instance=${Uri.encodeComponent(pwd.instanceId)}'
              '&view=${Uri.encodeComponent(pwd.viewId)}',
              // Carry this card's own per-instance config (e.g. which
              // varga a Divisional Chart card is set to) so the detail
              // view shows the SAME thing the card does — otherwise it
              // has no way to tell which of possibly several instances
              // of this module was tapped. The instance/view ids let the
              // detail view persist config changes back to this card.
              extra: pwd.config)
          : null,
      onSettings: () => showWidgetMenu(context, ref, module, pwd),
      wrapHeader: wrapHeader,
      child: module.cardView(context, ctx),
    );
  }
}

/// Generic per-instance widget menu: size, module config choices,
/// duplicate, remove. Shared with the Arrange screen. Changes apply
/// instantly; the pinned Done button (and swipe-down on the drag
/// handle) closes the panel. Height is capped so the dashboard stays
/// visible behind the sheet.
Future<void> showWidgetMenu(
  BuildContext context,
  WidgetRef ref,
  AstroModule module,
  PlacedWidget pwd,
) async {
  final repo = ref.read(dashboardRepoProvider);
  // Mutable copy OUTSIDE the sheet builder — StatefulBuilder re-runs
  // the builder on every selection, which would otherwise reset it.
  var config = Map<String, dynamic>.of(pwd.config);
  await showModalBottomSheet(
    context: context,
    backgroundColor: TEColors.paper,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        Widget sectionLabel(String t) => TESectionLabel(t);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(module.meta.title,
                          style: TETheme.serif(size: 18)),
                      const SizedBox(height: 14),
                      sectionLabel('SIZE'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final s in CardSpan.values)
                            ChoiceChip(
                              label: Text(s.label),
                              selected: pwd.span == s,
                              labelStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: pwd.span == s
                                      ? TEColors.paper
                                      : TEColors.ink),
                              onSelected: (_) async {
                                await repo.setSpan(pwd.instanceId, s);
                                ref.invalidate(
                                    viewWidgetsProvider(pwd.viewId));
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            ),
                        ],
                      ),
                      // Multi-value choices (e.g. Chart Style) keep their
                      // own labelled section of single-select chips.
                      for (final choice in module.configChoices())
                        if (!choice.isBinaryToggle) ...[
                          const SizedBox(height: 16),
                          sectionLabel(choice.label.toUpperCase()),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (value, label) in choice.options)
                                ChoiceChip(
                                  label: Text(label,
                                      style:
                                          const TextStyle(fontSize: 12.5)),
                                  selected: (config[choice.key] ??
                                          choice.effectiveDefault) ==
                                      value,
                                  labelStyle: TextStyle(
                                      fontSize: 12.5,
                                      color: (config[choice.key] ??
                                                  choice.effectiveDefault) ==
                                              value
                                          ? TEColors.paper
                                          : TEColors.ink),
                                  onSelected: (_) async {
                                    config = {
                                      ...config,
                                      choice.key: value
                                    };
                                    await repo.setConfig(
                                        pwd.instanceId, config);
                                    ref.invalidate(
                                        viewWidgetsProvider(pwd.viewId));
                                    setSheetState(() {});
                                  },
                                ),
                            ],
                          ),
                        ],
                      // Binary on/off choices collapse into one grouped
                      // section of selectable pills — selected = shown.
                      if (module.configChoices().any((c) => c.isBinaryToggle))
                        ...[
                        const SizedBox(height: 16),
                        sectionLabel('DISPLAY'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final choice in module.configChoices())
                              if (choice.isBinaryToggle)
                                FilterChip(
                                  label: Text(choice.label,
                                      style:
                                          const TextStyle(fontSize: 12.5)),
                                  selected: (config[choice.key] ??
                                          choice.effectiveDefault) ==
                                      choice.onValue,
                                  checkmarkColor: TEColors.paper,
                                  labelStyle: TextStyle(
                                      fontSize: 12.5,
                                      color: (config[choice.key] ??
                                                  choice.effectiveDefault) ==
                                              choice.onValue
                                          ? TEColors.paper
                                          : TEColors.ink),
                                  onSelected: (sel) async {
                                    config = {
                                      ...config,
                                      choice.key:
                                          sel ? choice.onValue! : choice.offValue!
                                    };
                                    await repo.setConfig(
                                        pwd.instanceId, config);
                                    ref.invalidate(
                                        viewWidgetsProvider(pwd.viewId));
                                    setSheetState(() {});
                                  },
                                ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Duplicate'),
                            onPressed: () async {
                              await repo.duplicate(pwd);
                              ref.invalidate(
                                  viewWidgetsProvider(pwd.viewId));
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline,
                                size: 16),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: TEColors.maroon,
                                side:
                                    BorderSide(color: TEColors.maroon)),
                            label: const Text('Remove'),
                            onPressed: () async {
                              await repo.removeInstance(pwd.instanceId);
                              ref.invalidate(
                                  viewWidgetsProvider(pwd.viewId));
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Pinned Done — always visible even when options scroll.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
