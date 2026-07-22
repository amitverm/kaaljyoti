import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../charts/chart_style.dart';
import '../charts/chart_view.dart';
import '../core/astro/divisional.dart';
import '../core/astro/jaimini_pada.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../pdf/pdf_chart.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _divisionalChartTitle(AppLocalizations l10n) =>
    l10n.moduleDivisionalChartTitle;

/// Configurable divisional chart. Per-instance config picks the varga
/// ({'varga': 'd9'}), so duplicating this widget three times can show
/// D3 / D7 / D9 side by side. Chart style follows the kundli default
/// unless overridden per instance ({'style': 'south'}).
class DivisionalChartModule extends AstroModule {
  const DivisionalChartModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'divisional',
        title: 'Divisional Chart',
        localizedTitle: _divisionalChartTitle,
        icon: Icons.grid_view,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  Varga _varga(Map<String, dynamic> config) =>
      Varga.byName((config['varga'] as String?) ?? 'd9');

  /// Padas are on unless explicitly hidden. Computed from the varga's
  /// OWN lagna and lord placements (per K.N. Rao) — not the D1 padas
  /// overlaid.
  bool _showPadas(Map<String, dynamic> config) =>
      (config['padas'] as String?) != 'off';

  Map<ZodiacSign, List<String>> _padaLabels(
          AstroSnapshot s, Varga varga, Map<String, dynamic> config) =>
      _showPadas(config)
          ? padaLabelsBySign(vargaArudhaPadas(s, varga))
          : const {};

  ChartStyleOverride _style(ModuleContext ctx) =>
      chartStyleFromConfig(ctx.config, ctx.chartStyle);

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'varga',
          label: l10n.cfgDivisionalChart,
          options: [
            for (final v in Varga.values.where((v) => v != Varga.d1))
              (v.name, v.displayLabel(l10n)),
          ],
        ),
        chartStyleChoice(l10n),
        ModuleConfigChoice(
          key: 'padas',
          label: l10n.cfgJaiminiPadas,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
          defaultValue: 'on', // shown by default, Parashar Light style
        ),
      ];

  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) =>
      _varga(config).code;

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartDetailHeader(ctx: ctx),
            cardView(context, ctx),
          ],
        ),
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final varga = _varga(ctx.config);
    final s = ctx.snapshot;
    return _DivisionalChartBody(
      viewKey: '${ctx.kundli.id}#${varga.code}',
      varga: varga,
      snapshot: s,
      style: _style(ctx).style,
      padaLabels: _padaLabels(s, varga, ctx.config),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final varga = _varga(ctx.config);
    final s = ctx.snapshot;
    final l10n = ctx.l10n;
    return [
      pdfSectionHeader(varga.displayLabel(l10n)),
      pw.Text(
        l10n.vargaLagnaLine(varga.code, vargaLagna(s, varga).label(l10n)),
        style: pdfBody(),
      ),
      pw.SizedBox(height: 10),
      pw.Center(
        child: pdfChart(
          l10n: l10n,
          placements: vargaPlacements(s, varga),
          lagna: vargaLagna(s, varga),
          style: _style(ctx).style,
          size: 200,
          padaLabels: _padaLabels(s, varga, ctx.config),
        ),
      ),
      pw.SizedBox(height: 6),
    ];
  }
}

/// Chart body with the Birth-Chart-style double-tap rotation, keyed
/// per (kundli, varga) so each divisional chart rotates independently.
class _DivisionalChartBody extends ConsumerWidget {
  const _DivisionalChartBody({
    required this.viewKey,
    required this.varga,
    required this.snapshot,
    required this.style,
    required this.padaLabels,
  });

  final String viewKey;
  final Varga varga;
  final AstroSnapshot snapshot;
  final ChartStyle style;
  final Map<ZodiacSign, List<String>> padaLabels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = snapshot;
    final lagna = vargaLagna(s, varga);
    final viewFrom = ref.watch(widgetViewFromProvider(viewKey)) ?? lagna;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartView(
          placements: vargaPlacements(s, varga),
          lagna: viewFrom,
          trueAscendantSign: lagna,
          style: style,
          // Only D1 boxes carry a real degree progression to mirror
          // spatially; higher vargas list planets in traditional order.
          directionalStack: varga == Varga.d1,
          ascendantRank: varga == Varga.d1
              ? ascendantRankIn(s.positions, s.ascendant)
              : null,
          padaLabels: padaLabels,
          onSignSelect: (sign) => ref
              .read(widgetViewFromProvider(viewKey).notifier)
              .state = sign == lagna ? null : sign,
        ),
        const SizedBox(height: 10),
        Text(
          '${varga.displayLabel(context.l10n)}\n'
          '${context.l10n.vargaLagnaLine(varga.code, lagna.label(context.l10n))}',
          style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
        ),
      ],
    );
  }
}
