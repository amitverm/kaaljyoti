/// Bhava Bala strength bars — one bar per house (not per planet),
/// pastel-filled like Shadbala (Task 10's treatment), backed by the
/// shared [bhavaBalaProvider] so the computation (which hard-depends
/// on Shadbala) runs once per kundli, memoized.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/bhava_bala.dart';
import '../core/astro/shadbala.dart' show computeShadbalaSync;
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _fmt1(double v) => v.toStringAsFixed(1);

class BhavaBalaModule extends AstroModule {
  const BhavaBalaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'bhava_bala',
        title: 'Bhava Bala',
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
    return [
      pdfSectionHeader('Bhava Bala'),
      pw.TableHelper.fromTextArray(
        headers: const [
          'House', 'Rashi', 'From Lord', 'Dig', 'Drishti', 'Planets-in',
          'Day-Night', 'Rupas',
        ],
        data: [
          for (final r in results)
            [
              '${r.house}',
              r.sign.western,
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
        'Shashtiamsas (Virupas); Rupas = total/60, can be negative. '
        'Bhavadhipati/Drishti components carry the same validation '
        'caveats as shadbala.dart and bhava_bala.dart doc comments — '
        'not yet numerically validated against a printed reference.',
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
    final async = ref.watch(bhavaBalaProvider(ctx.kundli.id));
    return async.when(
      loading: () => const SizedBox(
          height: 90, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Could not compute: $e'),
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
                  'Bhava (house) strength — not to be confused with the '
                  'planets\' own Shadbala above',
                  style: TETheme.mono(size: 10, color: TEColors.inkSoft),
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
    final color = TEColors.maroon;
    final pastel = Color.lerp(color, TEColors.paper, 0.5)!;
    final negative = result.total < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: Text('H${result.house}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final fillFrac =
                  (result.total.abs() / maxScale).clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: TEColors.paperAlt,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: TEColors.hairline),
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
                                    ? TEColors.maroon.withValues(alpha: 0.18)
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
                                  color: negative ? TEColors.maroon : color),
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
              '${result.sign.western.substring(0, 3)} · ${_fmt1(result.rupas)}R',
              style: TETheme.mono(
                  size: 11, color: negative ? TEColors.maroon : TEColors.forest),
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
    final parts = <(String, double)>[
      ('From Lord', result.fromLord),
      ('Dig', result.dig),
      ('Drishti', result.drishti),
      ('Planets-in', result.planetsIn),
      ('Day-Night', result.dayNight),
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
                color: value < 0 ? TEColors.maroon : TEColors.inkSoft,
              ),
            ),
        ],
      ),
    );
  }
}
