/// Screens 06/07 (and any module drill-in): generic host for a
/// module's detailView. Chart modules render their own style-switcher
/// header inside their scroll view ([ChartDetailHeader] in
/// modules/common.dart), so it scrolls away with the content instead
/// of sticking under the app bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../ui/common.dart';
import '../widgetsystem/registry.dart';

class ModuleDetailScreen extends ConsumerStatefulWidget {
  const ModuleDetailScreen({
    super.key,
    required this.kundliId,
    required this.moduleId,
    this.initialConfig,
    this.instanceId,
    this.viewId,
  });
  final String kundliId;
  final String moduleId;

  /// The specific dashboard card's per-instance config (varga, chart
  /// style override, etc.) — null when opened some other way (e.g. a
  /// module with no per-instance config, or a future non-dashboard
  /// entry point). Falls back to the module's own defaults.
  final Map<String, dynamic>? initialConfig;

  /// The dashboard widget row this view was opened from. When present,
  /// config edits made here (chart style, dasha system, extras…) are
  /// written straight back to that row so the card stays in sync. Null
  /// when opened without a specific card, in which case edits are local
  /// to this screen only.
  final String? instanceId;
  final String? viewId;

  @override
  ConsumerState<ModuleDetailScreen> createState() =>
      _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  // Working copy of the instance config. Edits (from a module's detail
  // body via ctx.onConfigChanged — including the chart-style header)
  // land here and, when we know the originating card, are persisted
  // back to it. Null until the first edit — until then the incoming
  // config is used.
  Map<String, dynamic>? _config;

  /// Persist a config change: update the working copy, write it back to
  /// the dashboard widget row (when known), and refresh the card.
  void _updateConfig(Map<String, dynamic> next) {
    setState(() => _config = next);
    final id = widget.instanceId;
    if (id == null) return; // opened without a card row — local only
    ref.read(dashboardRepoProvider).setConfig(id, next);
    final view = widget.viewId;
    if (view != null) ref.invalidate(viewWidgetsProvider(view));
  }

  @override
  Widget build(BuildContext context) {
    final module = moduleById(widget.moduleId);
    final ctxAsync = ref.watch(moduleContextProvider(widget.kundliId));

    if (module == null) {
      return const Scaffold(body: Center(child: Text('Unknown module')));
    }

    final config = _config ?? widget.initialConfig ?? const {};
    final summary = module.configSummary(config);
    return Scaffold(
      appBar: AppBar(
        title: Text(summary == null
            ? module.meta.title
            : '${module.meta.title} · $summary'),
      ),
      body: ctxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Calculation failed: $e'),
        data: (baseCtx) {
          final effective = _config ?? widget.initialConfig ?? baseCtx.config;
          // onConfigChanged lets the module's own detail body (chart
          // style header, dasha system, extras, yoga basis…) persist
          // config back to the originating dashboard card.
          final ctx =
              baseCtx.withConfig(effective, onConfigChanged: _updateConfig);
          return module.detailView(context, ctx);
        },
      ),
    );
  }
}
