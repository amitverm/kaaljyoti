/// Shadbala strength bars — horizontal bar per graha (total rupas,
/// required-minimum tick, ratio), backed by the shared
/// [shadbalaProvider] so the (fairly heavy) computation runs once per
/// kundli, memoized, never in build().
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/shadbala.dart';
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _shadbalaTitle(AppLocalizations l10n) => l10n.moduleShadbalaTitle;

String _fmt1(double v) => v.toStringAsFixed(1);

class ShadbalaModule extends AstroModule {
  const ShadbalaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'shadbala',
        title: 'Shadbala',
        localizedTitle: _shadbalaTitle,
        icon: Icons.equalizer_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _ShadbalaBody(ctx: ctx, detailed: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _ShadbalaBody(ctx: ctx, detailed: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final results = computeShadbalaSync(ctx.snapshot);
    final l10n = ctx.l10n;
    return [
      pdfSectionHeader(l10n.moduleShadbalaTitle),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.labelGraha,
          l10n.sbSthana,
          l10n.sbDig,
          l10n.sbKala,
          l10n.sbCheshta,
          l10n.sbNaisargika,
          l10n.sbDrik,
          l10n.sbRupas,
          l10n.sbReqd,
          l10n.sbRatioHeader,
        ],
        data: [
          for (final r in results)
            [
              r.planet.label(l10n),
              _fmt1(r.sthana),
              _fmt1(r.dig),
              _fmt1(r.kala),
              _fmt1(r.cheshta),
              _fmt1(r.naisargika),
              _fmt1(r.drik),
              _fmt1(r.rupas),
              _fmt1(r.requiredMinimum / 60),
              r.ratio.toStringAsFixed(2),
            ],
        ],
        headerStyle: pw.TextStyle(
            fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: pdfInkSoft),
        cellStyle: pdfBody(size: 8.5),
        border: null,
        headerDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: pdfInk, width: 0.8)),
        ),
        rowDecoration: const pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(color: pdfHairline, width: 0.5)),
        ),
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        l10n.sbPdfNote,
        style: pw.TextStyle(fontSize: 7.5, color: pdfInkSoft),
      ),
    ];
  }
}

class _ShadbalaBody extends ConsumerWidget {
  const _ShadbalaBody({required this.ctx, required this.detailed});
  final ModuleContext ctx;
  final bool detailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(shadbalaProvider(ctx.kundli.id));
    return async.when(
      loading: () => const SizedBox(
          height: 90, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.sbCouldNotCompute('$e')),
      data: (results) {
        final maxScale = [
          700.0,
          for (final r in results) r.total * 1.1,
        ].reduce((a, b) => a > b ? a : b);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in results) ...[
              _BalaBar(result: r, maxScale: maxScale),
              SizedBox(height: detailed ? 4 : 10),
              if (detailed) ...[
                _ComponentBreakdown(result: r),
                const SizedBox(height: 16),
              ],
            ],
            if (!detailed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.sbTickCaption,
                  style: KJTheme.mono(size: 10, color: KJColors.inkSoft),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BalaBar extends StatelessWidget {
  const _BalaBar({required this.result, required this.maxScale});
  final ShadbalaResult result;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = planetInk(result.planet);
    // Round 2, Task 10: pastel fill (lerped halfway to paper) so seven
    // simultaneous bars read as a calm strip rather than a wall of
    // saturated color; a full-ink leading edge keeps each bar
    // identifiable as "belongs to this planet" without the saturation.
    final pastel = Color.lerp(color, KJColors.paper, 0.5)!;
    final strong = result.ratio >= 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Text(result.planet.abbrLabel(l10n),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final fillFrac = (result.total / maxScale).clamp(0.0, 1.0);
              final tickFrac =
                  (result.requiredMinimum / maxScale).clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: KJColors.paperAlt,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: KJColors.hairline),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fillFrac,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: pastel,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Full-ink leading edge — the planet's true
                            // color, undiluted, right at the bar's tip.
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 2, color: color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (w * tickFrac).clamp(0.0, w) - 1,
                    top: -2,
                    bottom: -2,
                    child: Container(width: 2, color: KJColors.ink),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(
              l10n.sbBarValue(
                  _fmt1(result.rupas), result.ratio.toStringAsFixed(2)),
              style: KJTheme.mono(
                  size: 11, color: strong ? KJColors.forest : KJColors.maroon),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentBreakdown extends StatelessWidget {
  const _ComponentBreakdown({required this.result});
  final ShadbalaResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = <(String, double)>[
      (l10n.sbSthana, result.sthana),
      (l10n.sbDig, result.dig),
      (l10n.sbKala, result.kala),
      (l10n.sbCheshta, result.cheshta),
      (l10n.sbNaisargika, result.naisargika),
      (l10n.sbDrik, result.drik),
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 42),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          for (final (label, value) in parts)
            Text(
              '$label ${_fmt1(value)}',
              style: TextStyle(fontSize: 11, color: KJColors.inkSoft),
            ),
        ],
      ),
    );
  }
}
