/// Bhava Bala strength bars — one bar per house (not per planet),
/// pastel-filled like Shadbala (Task 10's treatment), backed by the
/// shared [bhavaBalaProvider] so the computation (which hard-depends
/// on Shadbala) runs once per kundli, memoized.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/bhava_bala.dart';
import '../core/astro/shadbala.dart' show computeShadbalaSync;
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _bhavaBalaTitle(AppLocalizations l10n) => l10n.moduleBhavaBalaTitle;

String _fmt1(double v) => v.toStringAsFixed(1);

class BhavaBalaModule extends AstroModule {
  const BhavaBalaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'bhava_bala',
        title: 'Bhava Bala',
        localizedTitle: _bhavaBalaTitle,
        icon: Icons.home_work_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _BhavaBalaBody(ctx: ctx, detailed: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _BhavaBalaBody(ctx: ctx, detailed: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final shadbala = computeShadbalaSync(ctx.snapshot);
    final results = computeBhavaBala(ctx.snapshot, shadbala);
    final l10n = ctx.l10n;
    return [
      pdfSectionHeader(l10n.moduleBhavaBalaTitle),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.labelHouse,
          l10n.labelSign,
          l10n.bbFromLord,
          l10n.sbDig,
          l10n.bbDrishti,
          l10n.bbPlanetsIn,
          l10n.bbDayNight,
          l10n.sbRupas,
        ],
        data: [
          for (final r in results)
            [
              '${r.house}',
              r.sign.label(l10n),
              _fmt1(r.fromLord),
              _fmt1(r.dig),
              _fmt1(r.drishti),
              _fmt1(r.planetsIn),
              _fmt1(r.dayNight),
              _fmt1(r.rupas),
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
        l10n.bbPdfNote,
        style: pw.TextStyle(fontSize: 7.5, color: pdfInkSoft),
      ),
    ];
  }
}

class _BhavaBalaBody extends ConsumerWidget {
  const _BhavaBalaBody({required this.ctx, required this.detailed});
  final ModuleContext ctx;
  final bool detailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(bhavaBalaProvider(ctx.kundli.id));
    return async.when(
      loading: () => const SizedBox(
          height: 90, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.sbCouldNotCompute('$e')),
      data: (results) {
        final maxScale = [
          480.0,
          for (final r in results) r.total.abs() * 1.15,
        ].reduce((a, b) => a > b ? a : b);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in results) ...[
              _BhavaBar(result: r, maxScale: maxScale),
              SizedBox(height: detailed ? 4 : 6),
              if (detailed) ...[
                _ComponentBreakdown(result: r),
                const SizedBox(height: 14),
              ],
            ],
            if (!detailed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.bbCardCaption,
                  style: KJTheme.mono(size: 10, color: KJColors.inkSoft),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BhavaBar extends StatelessWidget {
  const _BhavaBar({required this.result, required this.maxScale});
  final BhavaBalaResult result;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    // Houses don't have a single "identity" color the way planets do
    // (via planetInk) — cycle through the same maroon family, tinted
    // pastel exactly like Shadbala's bars (Task 10 treatment), so the
    // two strength widgets read as a matched pair.
    final l10n = context.l10n;
    final color = KJColors.maroon;
    final pastel = Color.lerp(color, KJColors.paper, 0.5)!;
    final negative = result.total < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: Text(l10n.bbHouseShort('${result.house}'),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final fillFrac = (result.total.abs() / maxScale).clamp(0.0, 1.0);
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
                                color: negative
                                    ? KJColors.maroon.withValues(alpha: 0.18)
                                    : pastel,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                  width: 2,
                                  color: negative ? KJColors.maroon : color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              l10n.bbBarValue(result.sign.abbrLabel(l10n), _fmt1(result.rupas)),
              style: KJTheme.mono(
                  size: 11,
                  color: negative ? KJColors.maroon : KJColors.forest),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentBreakdown extends StatelessWidget {
  const _ComponentBreakdown({required this.result});
  final BhavaBalaResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = <(String, double)>[
      (l10n.bbFromLord, result.fromLord),
      (l10n.sbDig, result.dig),
      (l10n.bbDrishti, result.drishti),
      (l10n.bbPlanetsIn, result.planetsIn),
      (l10n.bbDayNight, result.dayNight),
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          for (final (label, value) in parts)
            Text(
              '$label ${_fmt1(value)}',
              style: TextStyle(
                fontSize: 11,
                color: value < 0 ? KJColors.maroon : KJColors.inkSoft,
              ),
            ),
        ],
      ),
    );
  }
}
