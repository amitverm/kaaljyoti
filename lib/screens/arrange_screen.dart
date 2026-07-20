/// Screen 05 — Arrange (customization edit mode). "ON THIS VIEW":
/// widget instances (reorderable, removable, duplicatable, tap for
/// size/config); "WIDGET LIBRARY": the registry grouped by category
/// with search — modules can be added multiple times.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../core/theme/tokens.dart';
import '../data/models.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../widgetsystem/registry.dart';
import 'dashboard_screen.dart' show showWidgetMenu;

class ArrangeScreen extends ConsumerStatefulWidget {
  const ArrangeScreen(
      {super.key, required this.kundliId, required this.viewId});
  final String kundliId;
  final String viewId;

  @override
  ConsumerState<ArrangeScreen> createState() => _ArrangeScreenState();
}

class _ArrangeScreenState extends ConsumerState<ArrangeScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final placedAsync = ref.watch(viewWidgetsProvider(widget.viewId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.arTitle),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.l10n.done),
          ),
        ],
      ),
      body: placedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (placed) {
          final query = _search.trim().toLowerCase();
          final l10n = context.l10n;
          final library = moduleRegistry.values
              .where((m) =>
                  query.isEmpty ||
                  m.meta.titleFor(l10n).toLowerCase().contains(query) ||
                  m.meta.title.toLowerCase().contains(query) ||
                  m.meta.category.toLowerCase().contains(query))
              .toList();
          final categories =
              library.map((m) => m.meta.category).toSet().toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _label(context.l10n.arOnThisView),
              if (placed.isEmpty)
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(context.l10n.arEmpty,
                      style: TextStyle(fontSize: 13, color: KJColors.inkSoft)),
                ),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: true,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  final ids = placed.map((p) => p.instanceId).toList();
                  final item = ids.removeAt(oldIndex);
                  ids.insert(newIndex, item);
                  await ref
                      .read(dashboardRepoProvider)
                      .reorder(widget.viewId, ids);
                  ref.invalidate(viewWidgetsProvider(widget.viewId));
                },
                children: [
                  for (final p in placed) _instanceTile(p),
                ],
              ),
              const SizedBox(height: 20),
              _label(context.l10n.arLibrary),
              TextField(
                decoration: InputDecoration(
                  hintText: context.l10n.arSearchWidgets,
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KJSpace.sm - 2),
                  child: KJSectionLabel(
                      moduleCategoryLabel(context.l10n, category)),
                ),
                for (final m
                    in library.where((m) => m.meta.category == category))
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading:
                          Icon(m.meta.icon, size: 20, color: KJColors.inkSoft),
                      title: Text(m.meta.titleFor(context.l10n)),
                      subtitle: Text(
                        placed.any((p) => p.widgetId == m.meta.id)
                            ? context.l10n.arAlreadyOnView(moduleCategoryLabel(
                                context.l10n, m.meta.category))
                            : moduleCategoryLabel(
                                context.l10n, m.meta.category),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.add_circle_outline,
                            color: KJColors.forest, size: 20),
                        onPressed: () async {
                          await ref.read(dashboardRepoProvider).addWidget(
                                widget.viewId,
                                m.meta.id,
                                span: m.meta.defaultSpan,
                              );
                          ref.invalidate(viewWidgetsProvider(widget.viewId));
                        },
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _instanceTile(PlacedWidget p) {
    final module = moduleById(p.widgetId);
    return Card(
      key: ValueKey(p.instanceId),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(module?.meta.icon, size: 20, color: KJColors.inkSoft),
        title: Text(module == null
            ? p.widgetId
            : moduleInstanceTitle(module, p.config, context.l10n)),
        subtitle: Text(p.span.label, style: const TextStyle(fontSize: 11.5)),
        onTap: module == null
            ? null
            : () => showWidgetMenu(context, ref, module, p),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.copy, size: 18, color: KJColors.inkSoft),
              tooltip: context.l10n.duplicate,
              onPressed: () async {
                await ref.read(dashboardRepoProvider).duplicate(p);
                ref.invalidate(viewWidgetsProvider(widget.viewId));
              },
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  color: KJColors.maroon, size: 20),
              onPressed: () async {
                await ref
                    .read(dashboardRepoProvider)
                    .removeInstance(p.instanceId);
                ref.invalidate(viewWidgetsProvider(widget.viewId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.1,
                color: KJColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );
}
