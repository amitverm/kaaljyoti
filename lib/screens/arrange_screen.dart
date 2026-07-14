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
        title: const Text('Arrange'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: placedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (placed) {
          final query = _search.trim().toLowerCase();
          final library = moduleRegistry.values
              .where((m) =>
                  query.isEmpty ||
                  m.meta.title.toLowerCase().contains(query) ||
                  m.meta.category.toLowerCase().contains(query))
              .toList();
          final categories =
              library.map((m) => m.meta.category).toSet().toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _label('ON THIS VIEW'),
              if (placed.isEmpty)
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Empty — add widgets from the library below.',
                      style:
                          TextStyle(fontSize: 13, color: TEColors.inkSoft)),
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
              _label('WIDGET LIBRARY'),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search widgets…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: TESpace.sm - 2),
                  child: TESectionLabel(category),
                ),
                for (final m
                    in library.where((m) => m.meta.category == category))
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(m.meta.icon,
                          size: 20, color: TEColors.inkSoft),
                      title: Text(m.meta.title),
                      subtitle: Text(
                        placed.any((p) => p.widgetId == m.meta.id)
                            ? '${m.meta.category} · already on view — adds another copy'
                            : m.meta.category,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.add_circle_outline,
                            color: TEColors.forest, size: 20),
                        onPressed: () async {
                          await ref.read(dashboardRepoProvider).addWidget(
                                widget.viewId,
                                m.meta.id,
                                span: m.meta.defaultSpan,
                              );
                          ref.invalidate(
                              viewWidgetsProvider(widget.viewId));
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
    final summary = module?.configSummary(p.config);
    return Card(
      key: ValueKey(p.instanceId),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:
            Icon(module?.meta.icon, size: 20, color: TEColors.inkSoft),
        title: Text(module == null
            ? p.widgetId
            : summary == null
                ? module.meta.title
                : '${module.meta.title} · $summary'),
        subtitle: Text(p.span.label,
            style: const TextStyle(fontSize: 11.5)),
        onTap: module == null
            ? null
            : () => showWidgetMenu(context, ref, module, p),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.copy,
                  size: 18, color: TEColors.inkSoft),
              tooltip: 'Duplicate',
              onPressed: () async {
                await ref.read(dashboardRepoProvider).duplicate(p);
                ref.invalidate(viewWidgetsProvider(widget.viewId));
              },
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  color: TEColors.maroon, size: 20),
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
                color: TEColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );
}
