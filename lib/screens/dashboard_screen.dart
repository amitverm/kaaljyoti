/// Screen 04 — Home Dashboard. The core differentiator: named view
/// chips, a responsive span-aware module grid (2 columns on phones,
/// 3 on tablets), long-press drag-to-rearrange, and a generic
/// per-instance widget menu (size / configure / duplicate / remove) —
/// all driven by the widget registry; the host never knows what's
/// inside a module.
///
/// The view-chips + widget-grid are extracted into [DashboardBody] so a
/// second host (the Kundli Compare screen) can embed the exact same
/// dashboard for a different chart with externally-owned view + scroll
/// state. DashboardScreen keeps its own state and behaviour — it wires
/// the global [activeViewIdProvider] and an internal per-view scroll
/// controller into the body, matching the pre-refactor behaviour.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/astro/compare.dart' show CompareChart;
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/dashboard_repository.dart';
import '../data/models.dart';
import '../l10n/astro_l10n.dart';
import '../services/long_screenshot.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../ui/dashboard_capture.dart';
import '../ui/dashboard_layout.dart';
import '../ui/module_config_chips.dart';
import '../widgetsystem/astro_module.dart';
import '../widgetsystem/registry.dart';
import '../widgetsystem/view_templates.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Anchors the share sheet on iPad, where UIActivityViewController is
  /// a popover and crashes without a source rect.
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Opening the dashboard IS opening the kundli — recording it here
    // rather than in the list row means recency reflects every entry
    // point (Today, Compare, a deep link), not just the list.
    // Mahakosh community charts are excluded: they have no local row, so
    // they could never be resolved back into the list or the strip.
    if (!isMahakoshKundliId(widget.kundliId)) {
      // After the frame: initState runs during a build pass, and touch()
      // writes to a StateNotifier the list is already watching.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(recentKundlisProvider.notifier).touch(widget.kundliId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kundliId = widget.kundliId;
    final kundliAsync = ref.watch(kundliByIdProvider(kundliId));
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
                    KJDate.dateDotTime(k.toBirthData().localDateTime),
                    style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
                  ),
              ],
            ),
          ),
          loading: () => const Text(''),
          error: (_, __) => Text(context.l10n.dbKundli),
        ),
        // Only three slots: five icons crowded the title out on a phone.
        // Arrange and share stay pinned (both are about the board that is
        // on screen right now); everything that navigates away moves into
        // the overflow menu.
        actions: [
          // Arrange is a screen-level setting — pinned in the header so
          // it stays reachable no matter how many view chips exist.
          Consumer(builder: (context, ref, _) {
            final views = ref.watch(dashboardViewsProvider).value;
            final activeId = ref.watch(activeViewIdProvider) ??
                (views == null || views.isEmpty ? null : views.first.id);
            return IconButton(
              icon: const Icon(Icons.tune),
              tooltip: context.l10n.dbArrangeWidgets,
              onPressed: activeId == null
                  ? null
                  : () => context.push('/kundli/$kundliId/arrange/$activeId'),
            );
          }),
          // The board is taller than any screen and neither OS can
          // screenshot a scrolling Flutter surface — so the app renders
          // the whole thing itself.
          IconButton(
            key: _shareButtonKey,
            icon: const Icon(Icons.ios_share),
            tooltip: context.l10n.dbShareScreenshot,
            onPressed: _shareScreenshot,
          ),
          PopupMenuButton<void>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              // Life events belong to the native, not the (global)
              // dashboard — so they get their own screen. Hidden for
              // read-only Mahakosh community charts, which have no local
              // event store.
              if (!isMahakoshKundliId(kundliId))
                PopupMenuItem(
                  onTap: () => context.push('/kundli/$kundliId/events'),
                  child: _menuRow(
                      Icons.event_note_outlined, ctx.l10n.dbLifeEvents),
                ),
              PopupMenuItem(
                onTap: () => context.push('/kundli/$kundliId/export'),
                child: _menuRow(
                    Icons.picture_as_pdf_outlined, ctx.l10n.dbExportPrint),
              ),
              // Explicit edit affordance. The title has always been
              // tappable, but with no visual cue — and the list row no
              // longer carries a pencil either (it cost header width on
              // every row for an action needed rarely), so this is the
              // discoverable way in.
              if (!isMahakoshKundliId(kundliId))
                PopupMenuItem(
                  onTap: () => context.push('/kundli/$kundliId/edit'),
                  child: _menuRow(Icons.edit_outlined, ctx.l10n.klEditKundli),
                ),
            ],
          ),
        ],
      ),
      // No nav pill inside a kundli — the pill belongs to the five
      // landing screens only; back returns to the kundli list.
      body: Column(
        children: [
          // Instant Prashna: not kept yet — offer Keep / Discard.
          if (kundliAsync.value?.isEphemeral ?? false)
            _ephemeralBanner(context, ref, kundliAsync.value!),
          Expanded(
            child: ctxAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  EmptyState(message: context.l10n.dbCalcFailed('$e')),
              data: (moduleCtx) => Consumer(builder: (context, ref, _) {
                final views = ref.watch(dashboardViewsProvider).value;
                final activeViewId = ref.watch(activeViewIdProvider) ??
                    (views == null || views.isEmpty ? null : views.first.id);
                return DashboardBody(
                  kundliId: kundliId,
                  moduleCtx: moduleCtx,
                  activeViewId: activeViewId,
                  onSelectView: (id) =>
                      ref.read(activeViewIdProvider.notifier).state = id,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// One overflow-menu entry: glyph + label. The icons carry over from
  /// the app-bar buttons these items replaced, so the muscle memory for
  /// "the pencil" and "the PDF sheet" still lands.
  Widget _menuRow(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: KJColors.inkSoft),
          const SizedBox(width: 12),
          Text(label),
        ],
      );

  /// Renders the ACTIVE view at its full scrolling height and hands the
  /// PNG to the system share sheet. Everything it needs is already
  /// loaded behind the board the user just tapped on, so it reads the
  /// providers rather than watching them.
  Future<void> _shareScreenshot() async {
    // Captured before the first await: `use_build_context_synchronously`
    // is an error here, and a snackbar on a popped screen throws.
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    void fail() => messenger
        .showSnackBar(SnackBar(content: Text(l10n.dbScreenshotFailed)));

    final kundli = ref.read(kundliByIdProvider(widget.kundliId)).value;
    final moduleCtx = ref.read(moduleContextProvider(widget.kundliId)).value;
    final views = ref.read(dashboardViewsProvider).value;
    final activeViewId = ref.read(activeViewIdProvider) ??
        (views == null || views.isEmpty ? null : views.first.id);
    final placed = activeViewId == null
        ? null
        : ref.read(viewWidgetsProvider(activeViewId)).value;
    if (kundli == null ||
        moduleCtx == null ||
        placed == null ||
        placed.isEmpty) {
      fail();
      return;
    }

    // Both read while the button is still on screen.
    final origin = _shareOrigin();
    final width = MediaQuery.sizeOf(context).width;

    // A long board takes a visible beat to rasterize. The barrier shows
    // that AND stops a second tap stacking a second capture. Holding the
    // route object (rather than a bare pop) means the finally can never
    // dismiss the dashboard itself if the dialog is already gone.
    //
    // It stays up past the capture, until the share sheet closes: writing
    // the file and — on iOS — thumbnailing a 16k-pixel PNG for the sheet
    // costs another couple of seconds, and dropping the barrier at the
    // end of the capture only turns that into a dead, tappable screen
    // before the sheet appears. The native sheet covers it anyway, so on
    // a phone nobody ever sees the dialog it hides behind.
    final progress = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      // Root navigator, so the app theme has to be carried across —
      // this is what showDialog does under the hood.
      themes: InheritedTheme.capture(from: context, to: rootNavigator.context),
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    rootNavigator.push(progress);

    var shared = false;
    try {
      final bytes = await captureLongWidget(
        context,
        width: width,
        child: DashboardCaptureView(
          kundli: kundli,
          moduleCtx: moduleCtx,
          placed: placed,
          width: width,
        ),
      );
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        // Like the image itself, the filename and subject travel to the
        // recipient with no way to redact them — so neither carries the
        // person's name.
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/kundli_$stamp.png');
        await file.writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: l10n.dbKundli,
          sharePositionOrigin: origin,
        ));
        shared = true;
      }
    } catch (_) {
      // Reported below: a snackbar raised under a full-screen barrier is
      // a snackbar nobody reads.
    } finally {
      if (progress.isActive) rootNavigator.removeRoute(progress);
    }
    if (!shared) fail();
  }

  /// The share button's rect in global coordinates. iPad presents the
  /// share sheet as a popover and throws without a source rect; the
  /// screen centre is the fallback if the button is somehow gone.
  Rect _shareOrigin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }

  Widget _ephemeralBanner(BuildContext context, WidgetRef ref, Kundli kundli) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: KJColors.maroon.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KJColors.maroon.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.dbPrashnaUnsaved,
              style: TextStyle(fontSize: 12.5, color: KJColors.maroon),
            ),
          ),
          TextButton(
            onPressed: () async {
              final controller = TextEditingController(text: kundli.name);
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(context.l10n.dbKeepPrashna),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: context.l10n.dbPrashnaNameHint),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(ctx.l10n.cancel)),
                    TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        child: Text(ctx.l10n.keep)),
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
            child: Text(context.l10n.keep),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(kundliRepoProvider).delete(kundli.id);
              ref.invalidate(kundlisProvider);
              if (context.mounted) context.go('/');
            },
            child: Text(context.l10n.discard,
                style: TextStyle(color: KJColors.maroon)),
          ),
        ],
      ),
    );
  }
}

/// The reusable dashboard body: the named view chips + the span-aware
/// widget grid for one chart. Extracted from [DashboardScreen] so the
/// Kundli Compare screen can embed it per subject with SHARED view +
/// scroll state (spec §3.3 "locked context").
///
/// State ownership is external: [activeViewId] and [onSelectView] hold
/// the selected view at the host level (the home dashboard uses the
/// global [activeViewIdProvider]; compare uses its own screen-level
/// state so all tabs move together). [scrollController], when supplied,
/// is host-owned and shared across tabs; when null the body keeps its
/// own per-view controller (the home dashboard's behaviour).
///
/// When [moduleCtx] is null the body renders in LIMITED mode (a legacy
/// Mahakosh subject with no full snapshot): the same view's grid, same
/// spans, but each card comes from [limitedCardBuilder] — placeholders
/// or a positions-only card — so the grid geometry is identical across
/// tabs and visual scanning still works (spec §3.3).
class DashboardBody extends ConsumerWidget {
  const DashboardBody({
    super.key,
    required this.kundliId,
    required this.activeViewId,
    required this.onSelectView,
    this.moduleCtx,
    this.limitedCardBuilder,
    this.scrollController,
    this.onOpenModule,
    this.readOnly = false,
  });

  final String kundliId;
  final String? activeViewId;
  final ValueChanged<String> onSelectView;

  /// Read-only mode: the view chips become pure switchers (no "new view"
  /// chip, no rename/delete sheet, no drag-to-reorder) and cards lose
  /// their editing affordances (per-widget menu, drag-rearrange, drop targets, the
  /// add/edit-widgets button). Set by the Kundli Compare hosts — in
  /// compare, editing happens only from the main kundli area (spec §3.3).
  final bool readOnly;

  /// The chart's data. Null → limited mode (see class doc).
  final ModuleContext? moduleCtx;

  /// Builds one card for a placed widget in LIMITED mode. Ignored when
  /// [moduleCtx] is non-null.
  final Widget Function(BuildContext context, PlacedWidget pwd)?
      limitedCardBuilder;

  /// Host-owned scroll controller shared across tabs. Null → the body
  /// keeps its own per-view controller (home dashboard behaviour).
  final ScrollController? scrollController;

  /// Overrides what a card's "open detail" tap does. Null → the default
  /// home-dashboard behaviour (push the single-kundli [ModuleDetailScreen]
  /// route). The compare screen supplies this to open the compare-aware
  /// module detail host with the tapped subject instead.
  final void Function(PlacedWidget pwd)? onOpenModule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewsAsync = ref.watch(dashboardViewsProvider);
    return viewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: context.l10n.dbViewsError('$e')),
      data: (views) {
        final activeId =
            activeViewId ?? (views.isEmpty ? null : views.first.id);
        final activeView = views.where((v) => v.id == activeId).isEmpty
            ? (views.isEmpty ? null : views.first)
            : views.firstWhere((v) => v.id == activeId);
        if (activeView == null) {
          return EmptyState(message: context.l10n.dbNoViews);
        }
        return Column(
          children: [
            _viewChips(context, ref, views, activeView),
            Expanded(
              child: _WidgetGrid(
                // Keyed by kundli AND view: the grid's internal scroll
                // controller is built once per State, so without the
                // view in the key a view switch reused the previous
                // view's controller — the new board opened at the old
                // one's offset, and the listener then overwrote the new
                // view's saved offset with it. Remounting per view makes
                // each board restore its own position.
                key: ValueKey('grid:$kundliId:${activeView.id}'),
                view: activeView,
                kundliId: kundliId,
                moduleCtx: moduleCtx,
                limitedCardBuilder: limitedCardBuilder,
                externalScroll: scrollController,
                onOpenModule: onOpenModule,
                readOnly: readOnly,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _viewChips(BuildContext context, WidgetRef ref,
      List<DashboardView> views, DashboardView active) {
    // Read-only (compare) hosts get a plain strip: chips are pure
    // switchers there, and chip ORDER is shared global state that is
    // edited only from the main kundli area.
    if (readOnly) {
      return SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final v in views)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _viewChip(context, ref, views, v, active),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          // Shrink-wrapped so the "+ New" chip still sits immediately
          // after the last view chip; once the chips outgrow the width
          // the strip scrolls inside this slot and "+ New" stays pinned
          // (it used to scroll off the end).
          Flexible(
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              // The chips ARE the drag handles (a handle glyph on a chip
              // is unreadable at this size) — see the listener below.
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(left: 16),
              onReorderItem: (from, to) => _reorderViews(ref, views, from, to),
              children: [
                for (var i = 0; i < views.length; i++)
                  ReorderableDelayedDragStartListener(
                    key: ValueKey(views[i].id),
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _viewChip(context, ref, views, views[i], active),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              label: Text(context.l10n.dbNewView),
              onPressed: () => _newView(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  /// One view chip. Tapping a chip that is ALREADY active opens its
  /// rename/delete sheet — long-press now starts a reorder drag, so the
  /// actions needed a gesture of their own, and "tap the thing you are
  /// already looking at" is the one that can't be triggered by accident
  /// while switching views.
  Widget _viewChip(BuildContext context, WidgetRef ref,
      List<DashboardView> views, DashboardView v, DashboardView active) {
    final isActive = v.id == active.id;
    return ChoiceChip(
      label: Text(v.name),
      selected: isActive,
      labelStyle: TextStyle(color: isActive ? KJColors.paper : KJColors.ink),
      onSelected: (_) => isActive && !readOnly
          ? _viewActions(context, ref, views, v)
          : onSelectView(v.id),
    );
  }

  /// Commit a chip drag. Positions are global (views are shared by every
  /// kundli), so this writes through immediately rather than holding an
  /// optimistic local order. [to] is already post-removal (onReorderItem
  /// guarantees that, unlike the deprecated onReorder), so the moved id
  /// drops straight in.
  Future<void> _reorderViews(
      WidgetRef ref, List<DashboardView> views, int from, int to) async {
    final ids = views.map((v) => v.id).toList();
    final moved = ids.removeAt(from);
    ids.insert(to, moved);
    await ref.read(dashboardRepoProvider).reorderViews(ids);
    ref.invalidate(dashboardViewsProvider);
  }

  /// Rename / delete sheet for a view — opened by tapping the active chip.
  Future<void> _viewActions(BuildContext context, WidgetRef ref,
      List<DashboardView> views, DashboardView view) async {
    final repo = ref.read(dashboardRepoProvider);
    await showModalBottomSheet(
      context: context,
      backgroundColor: KJColors.paper,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(view.name, style: KJTheme.serif(size: 18)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, size: 20),
              title: Text(context.l10n.dbRenameView),
              onTap: () async {
                Navigator.pop(ctx);
                final controller = TextEditingController(text: view.name);
                final name = await showDialog<String>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: Text(context.l10n.dbRenameView),
                    content: TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: Text(dCtx.l10n.cancel)),
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(dCtx, controller.text.trim()),
                          child: Text(ctx.l10n.rename)),
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
                  color: views.length > 1 ? KJColors.maroon : KJColors.inkSoft),
              title: Text(context.l10n.dbDeleteView,
                  style: TextStyle(
                      color: views.length > 1
                          ? KJColors.maroon
                          : KJColors.inkSoft)),
              subtitle: views.length > 1
                  ? null
                  : Text(context.l10n.dbOnlyViewCannotDelete,
                      style: const TextStyle(fontSize: 11.5)),
              onTap: views.length <= 1
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: Text(dCtx.l10n.dbDeleteViewTitle(view.name)),
                          content: Text(dCtx.l10n.dbDeleteViewBody),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: Text(dCtx.l10n.cancel)),
                            TextButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: Text(dCtx.l10n.delete,
                                    style: TextStyle(color: KJColors.maroon))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await repo.deleteView(view.id);
                        // Fall off the deleted view via the host's own
                        // selection wiring (home → activeViewIdProvider);
                        // no direct provider write here.
                        onSelectView(
                            views.firstWhere((v) => v.id != view.id).id);
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
      backgroundColor: KJColors.paper,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(context.l10n.dbNewViewFromTemplate,
                  style: KJTheme.serif(size: 18)),
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
                      leading: Icon(t.icon, size: 20, color: KJColors.inkSoft),
                      title: Text(templateName(context.l10n, t.key)),
                      subtitle: Text(templateDescription(context.l10n, t.key),
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

    final controller =
        TextEditingController(text: templateName(context.l10n, template.key));
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.dbNameThisView),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(ctx.l10n.create)),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final view = await ref
        .read(dashboardRepoProvider)
        .createView(name, seed: template.widgets);
    ref.invalidate(dashboardViewsProvider);
    // Select the new view through the host's own wiring (home →
    // activeViewIdProvider); no direct provider write here.
    onSelectView(view.id);
  }
}

class _WidgetGrid extends ConsumerStatefulWidget {
  const _WidgetGrid({
    super.key,
    required this.view,
    required this.kundliId,
    required this.moduleCtx,
    required this.limitedCardBuilder,
    required this.externalScroll,
    required this.onOpenModule,
    required this.readOnly,
  });
  final DashboardView view;
  final String kundliId;
  final ModuleContext? moduleCtx;
  final Widget Function(BuildContext, PlacedWidget)? limitedCardBuilder;
  final ScrollController? externalScroll;
  final void Function(PlacedWidget pwd)? onOpenModule;
  final bool readOnly;

  @override
  ConsumerState<_WidgetGrid> createState() => _WidgetGridState();
}

class _WidgetGridState extends ConsumerState<_WidgetGrid> {
  DashboardView get view => widget.view;
  ModuleContext? get moduleCtx => widget.moduleCtx;
  bool get limited => widget.moduleCtx == null;

  /// Layout editing is available only for a full chart that isn't hosted
  /// read-only (compare). Limited subjects and compare tabs are view-only.
  bool get editable => !limited && !widget.readOnly;

  // The board's scroll controller. When the host owns one (compare's
  // shared per-tab controller) we use it directly; otherwise we keep an
  // internal controller that restores the board's scroll position when
  // the grid remounts (e.g. returning from a module detail screen, or
  // switching back to this view) — the offset is persisted per view PER
  // KUNDLI in [dashboardScrollOffsetProvider]. Views are global, so the
  // kundli has to be part of the key or opening a second chart would
  // land on the first one's position.
  ScrollController? _internalScroll;

  DashboardScrollKey get _offsetKey =>
      (kundliId: widget.kundliId, viewId: view.id);

  ScrollController get _scroll =>
      widget.externalScroll ?? (_internalScroll ??= _makeInternal());

  ScrollController _makeInternal() => ScrollController(
        initialScrollOffset:
            ref.read(dashboardScrollOffsetProvider(_offsetKey)),
      )..addListener(_saveOffset);

  void _saveOffset() {
    ref.read(dashboardScrollOffsetProvider(_offsetKey).notifier).state =
        _internalScroll!.offset;
  }

  @override
  void dispose() {
    _internalScroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placedAsync = ref.watch(viewWidgetsProvider(view.id));
    return placedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: context.l10n.dbWidgetsError('$e')),
      data: (placed) {
        if (placed.isEmpty) {
          // Limited subjects and read-only (compare) hosts get a plain
          // empty state (no seeding/arrange affordances — layout is edited
          // on a full chart from the main kundli area).
          if (!editable) {
            return EmptyState(message: context.l10n.dbViewEmpty);
          }
          return EmptyState(
            message: context.l10n.dbViewEmpty,
            actionLabel: context.l10n.dbAddStarterWidgets,
            onAction: () async {
              await ref
                  .read(dashboardRepoProvider)
                  .seedWidgets(view.id, DashboardRepository.defaultOverview);
              ref.invalidate(viewWidgetsProvider(view.id));
            },
            secondaryLabel: context.l10n.dbChooseWidgets,
            onSecondary: () =>
                context.push('/kundli/${widget.kundliId}/arrange/${view.id}'),
          );
        }
        return LayoutBuilder(builder: (context, constraints) {
          // Responsive: 3 columns on tablets/wide screens, 2 on phones.
          // Packing lives in dashboard_layout.dart so the shared-image
          // render (DashboardCaptureView) lays out identically.
          final isWide = constraints.maxWidth >= 720;
          final rows = packDashboardRows(placed, isWide: isWide);

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
                          flex: spanUnits(row[i].span, isWide: isWide),
                          child: limited
                              ? widget.limitedCardBuilder!(context, row[i])
                              : editable
                                  ? _draggableCard(context, ref, row[i], placed)
                                  // Read-only (compare) full tab: no drag
                                  // handle and no structural edits, but the
                                  // per-instance CONFIGURE path stays — the
                                  // card's menu shows configure options only.
                                  : _card(context, ref, row[i],
                                      configOnly: true),
                        ),
                      ],
                      // Empty remainder of an incomplete row: also a
                      // drop target — dropping here places the dragged
                      // widget right after this row's last card.
                      if (rowUnits(row, isWide: isWide) < 6) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6 - rowUnits(row, isWide: isWide),
                          child: editable
                              ? _emptySlotTarget(
                                  ref, placed, row.last.instanceId)
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                ),
              // Layout-editing affordances only on a full chart that isn't
              // hosted read-only — compare is view-only (edits happen on
              // the main kundli dashboard).
              if (editable) ...[
                // Drop zone at the end of the board: move to last.
                _emptySlotTarget(
                    ref, placed, placed.isEmpty ? null : placed.last.instanceId,
                    height: 56, label: context.l10n.dbMoveToEnd),
                // Always-visible entry point to the widget library — the
                // header tune icon alone isn't discoverable for
                // non-technical users.
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.dashboard_customize_outlined,
                        size: 18),
                    label: Text(context.l10n.dbAddEditWidgets),
                    onPressed: () => context
                        .push('/kundli/${widget.kundliId}/arrange/${view.id}'),
                  ),
                ),
              ],
            ],
          );
        });
      },
    );
  }

  /// Moves [draggedId] to immediately AFTER [anchorId] (or to the very
  /// front when anchor is null). Shared by empty-slot drop targets.
  Future<void> _moveAfter(WidgetRef ref, List<PlacedWidget> all,
      String draggedId, String? anchorId) async {
    final ids = all.map((p) => p.instanceId).toList();
    if (!ids.remove(draggedId)) return;
    final insertAt = anchorId == null ? 0 : ids.indexOf(anchorId) + 1;
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
              ? KJColors.maroon.withValues(alpha: 0.06)
              : Colors.transparent,
          border: candidates.isNotEmpty
              ? Border.all(color: KJColors.maroon, width: 1.5)
              : null,
        ),
        child: candidates.isNotEmpty && label != null
            ? Center(
                child: Text(label,
                    style: TextStyle(fontSize: 12.5, color: KJColors.maroon)))
            : null,
      ),
    );
  }

  /// Long-press the card HEADER to drag-rearrange (the body stays free
  /// for chart gestures — double-tap / long-press view-from, etc.);
  /// drop on any other card to move the dragged widget there.
  Widget _draggableCard(BuildContext context, WidgetRef ref, PlacedWidget pwd,
      List<PlacedWidget> all) {
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
                      border: Border.all(color: KJColors.maroon, width: 1.5),
                    )
                  : null,
              child: card,
            ));
  }

  Widget _card(BuildContext context, WidgetRef ref, PlacedWidget pwd,
      {Widget Function(Widget header)? wrapHeader, bool configOnly = false}) {
    final module = moduleById(pwd.widgetId);
    if (module == null) return const SizedBox();
    final ctx = moduleCtx!.withConfig(pwd.config);
    // Read-only (compare) cards keep ONLY the per-instance CONFIGURE path —
    // structural edits (size / duplicate / remove) are gone. The settings
    // affordance therefore appears only when the module actually has config
    // choices to offer; a card with nothing to configure shows no menu.
    // Editable (home) cards always show the full menu.
    final showMenu =
        configOnly ? module.configChoices(context.l10n).isNotEmpty : true;
    return ModuleCard(
      title: moduleInstanceTitle(module, pwd.config, context.l10n),
      onDetail: module.meta.hasDetailView
          ? () => widget.onOpenModule != null
              ? widget.onOpenModule!(pwd)
              : context.push(
                  '/kundli/${moduleCtx!.kundli.id}/module/${module.meta.id}'
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
      // In read-only (compare) mode the menu is configure-only (size /
      // duplicate / remove suppressed); config still writes back per
      // instance via the same dashboard repo path as the home dashboard.
      onSettings: showMenu
          ? () =>
              showWidgetMenu(context, ref, module, pwd, configOnly: configOnly)
          : null,
      wrapHeader: wrapHeader,
      child: module.cardView(context, ctx),
    );
  }
}

/// Whether a module needs data a positions-only (legacy Mahakosh)
/// subject lacks — a full snapshot, dasha trees, events, or the birth
/// instant. Such modules render the "Not available for this chart"
/// placeholder in a compare limited tab (spec §3.3 / §4.4). Only the
/// pure-position modules (birth chart D1 and the planetary positions
/// table) can render from stored longitudes; conservatively, everything
/// else is a placeholder. Used by the Compare screen.
bool moduleNeedsFullChart(String moduleId) => moduleId != 'planetary_positions';

/// A compact "Not available for this chart" card, sized to fill its
/// grid slot so the compare grid geometry stays identical across tabs
/// (spec §3.3). [CompareChart] is unused here but the signature mirrors
/// the positions card so hosts can swap freely.
class CompareUnavailableCard extends StatelessWidget {
  const CompareUnavailableCard({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      title: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline,
              size: 16, color: KJColors.inkSoft.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.cmpNotAvailable,
              style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// A minimal planetary-positions card rendered straight from a
/// [CompareChart]'s longitudes — the one module a positions-only
/// (legacy) subject can still show (spec §4.4).
class ComparePositionsCard extends StatelessWidget {
  const ComparePositionsCard(
      {super.key, required this.title, required this.chart});
  final String title;
  final CompareChart chart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ModuleCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in chart.longitudes.keys) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(p.label(l10n),
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                  Text(
                    '${chart.signOf(p).label(l10n)} '
                    '${(chart.lonOf(p) % 30).toStringAsFixed(1)}°',
                    style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Generic per-instance widget menu: size, module config choices,
/// duplicate, remove. Shared with the Arrange screen. Changes apply
/// instantly; the pinned Done button (and swipe-down on the drag
/// handle) closes the panel. Height is capped so the dashboard stays
/// visible behind the sheet.
///
/// When [configOnly] is true (read-only compare hosts) the STRUCTURAL
/// controls — the SIZE selector and the duplicate / remove actions — are
/// suppressed, leaving only the module's own config choices. Config still
/// persists per instance via the shared dashboard repo, exactly as on the
/// home dashboard and the compare module detail screen.
Future<void> showWidgetMenu(
  BuildContext context,
  WidgetRef ref,
  AstroModule module,
  PlacedWidget pwd, {
  bool configOnly = false,
}) async {
  final repo = ref.read(dashboardRepoProvider);
  // Mutable copy OUTSIDE the sheet builder — StatefulBuilder re-runs
  // the builder on every selection, which would otherwise reset it.
  var config = Map<String, dynamic>.of(pwd.config);
  await showModalBottomSheet(
    context: context,
    backgroundColor: KJColors.paper,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        Widget sectionLabel(String t) => KJSectionLabel(t);

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
                      Text(module.meta.titleFor(ctx.l10n),
                          style: KJTheme.serif(size: 18)),
                      const SizedBox(height: 14),
                      // SIZE changes the global grid layout — a structural
                      // edit, so it's hidden in read-only (compare) hosts.
                      if (!configOnly) ...[
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
                                        ? KJColors.paper
                                        : KJColors.ink),
                                onSelected: (_) async {
                                  await repo.setSpan(pwd.instanceId, s);
                                  ref.invalidate(
                                      viewWidgetsProvider(pwd.viewId));
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                              ),
                          ],
                        ),
                      ],
                      // Shared with the PDF export screen's per-block sheet
                      // so the two config UIs can't drift.
                      ModuleConfigChips(
                        module: module,
                        config: config,
                        onChanged: (next) async {
                          config = next;
                          await repo.setConfig(pwd.instanceId, config);
                          ref.invalidate(viewWidgetsProvider(pwd.viewId));
                          setSheetState(() {});
                        },
                      ),
                      // Duplicate / remove add and delete widget instances —
                      // structural edits, hidden in read-only (compare) hosts.
                      if (!configOnly) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: Text(context.l10n.duplicate),
                              onPressed: () async {
                                await repo.duplicate(pwd);
                                ref.invalidate(viewWidgetsProvider(pwd.viewId));
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: KJColors.maroon,
                                  side: BorderSide(color: KJColors.maroon)),
                              label: Text(context.l10n.remove),
                              onPressed: () async {
                                await repo.removeInstance(pwd.instanceId);
                                ref.invalidate(viewWidgetsProvider(pwd.viewId));
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      ],
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
                    child: Text(context.l10n.done),
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
