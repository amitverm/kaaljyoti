/// Screens 06/07 (and any module drill-in): generic host for a
/// module's detailView. Chart modules render their own style-switcher
/// header inside their scroll view ([ChartDetailHeader] in
/// modules/common.dart), so it scrolls away with the content instead
/// of sticking under the app bar.
///
/// The scroll-view + config-writeback body is extracted into
/// [ModuleDetailBody] so a second host (the Kundli Compare module
/// detail screen) can embed the exact same detail content for a
/// different chart under one app bar / tab bar. [ModuleDetailScreen]
/// keeps its own state and behaviour — it owns the working config copy,
/// writes edits back to the originating dashboard card, and renders the
/// title-bearing Scaffold, exactly as before the refactor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
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
  ConsumerState<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  // Working copy of the instance config. Edits (from a module's detail
  // body via ctx.onConfigChanged — including the chart-style header)
  // land here and, when we know the originating card, are persisted
  // back to it. Null until the first edit — until then the incoming
  // config is used.
  Map<String, dynamic>? _config;

  @override
  Widget build(BuildContext context) {
    final module = moduleById(widget.moduleId);

    if (module == null) {
      return Scaffold(body: Center(child: Text(context.l10n.mdUnknownModule)));
    }

    final config = _config ?? widget.initialConfig ?? const {};
    return Scaffold(
      appBar: AppBar(
        title: Text(moduleInstanceTitle(module, config, context.l10n)),
      ),
      body: ModuleDetailBody(
        kundliId: widget.kundliId,
        moduleId: widget.moduleId,
        // Overriding config: the working copy once edited, otherwise the
        // card's own config; null lets the body fall back to the chart's
        // base config (preserving pre-refactor behaviour exactly).
        configOverride: _config ?? widget.initialConfig,
        onConfigChanged: _updateConfig,
      ),
    );
  }

  /// Persist a config change: update the working copy, write it back to
  /// the dashboard widget row (when known), and refresh the card.
  void _updateConfig(Map<String, dynamic> next) {
    setState(() => _config = next);
    persistModuleConfig(ref, next,
        instanceId: widget.instanceId, viewId: widget.viewId);
  }
}

/// Writes a per-instance config change back to the originating dashboard
/// card (global views — the card stays in sync everywhere the row is
/// shown). No-ops when the view wasn't opened from a specific card row.
/// Shared by [ModuleDetailScreen] and the compare module detail host so
/// both keep identical write-back semantics.
void persistModuleConfig(
  WidgetRef ref,
  Map<String, dynamic> config, {
  required String? instanceId,
  required String? viewId,
}) {
  if (instanceId == null) return; // opened without a card row — local only
  ref.read(dashboardRepoProvider).setConfig(instanceId, config);
  if (viewId != null) ref.invalidate(viewWidgetsProvider(viewId));
}

/// The reusable module-detail body: builds the chart's [ModuleContext]
/// and renders the module's own scroll-view detail (chart-style header
/// inside the scroll, so it scrolls with the content). State ownership
/// is external — the host owns the working [configOverride] and the
/// [onConfigChanged] write-back — so this same body serves both the
/// single-kundli [ModuleDetailScreen] and the compare host, where one
/// config is shared across every subject tab.
class ModuleDetailBody extends ConsumerWidget {
  const ModuleDetailBody({
    super.key,
    required this.kundliId,
    required this.moduleId,
    required this.configOverride,
    required this.onConfigChanged,
  });

  final String kundliId;
  final String moduleId;

  /// The host's working config, or null to fall back to the chart's base
  /// config. Kept as a public field so hosts (and tests) can assert the
  /// shared config that drives every tab.
  final Map<String, dynamic>? configOverride;

  /// Persists a config edit made from within the module's detail body
  /// (chart-style header, dasha system, extras, yoga basis…).
  final void Function(Map<String, dynamic> config) onConfigChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = moduleById(moduleId);
    if (module == null) {
      return Center(child: Text(context.l10n.mdUnknownModule));
    }
    final ctxAsync = ref.watch(moduleContextProvider(kundliId));
    return ctxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: context.l10n.mdCalcFailed('$e')),
      data: (baseCtx) {
        final effective = configOverride ?? baseCtx.config;
        // onConfigChanged lets the module's own detail body (chart style
        // header, dasha system, extras, yoga basis…) persist config back
        // to the originating dashboard card.
        final ctx =
            baseCtx.withConfig(effective, onConfigChanged: onConfigChanged);
        return module.detailView(context, ctx);
      },
    );
  }
}
