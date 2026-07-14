import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/jaimini_aspect.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Jaimini Rashi Drishti (sign-based aspects) between the grahas in the
/// chart — a different scheme from the planet-based Parashari aspects
/// shown elsewhere. See core/astro/jaimini_aspect.dart for the rules.
class JaiminiAspectModule extends AstroModule {
  const JaiminiAspectModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'jaimini_aspect',
        title: 'Jaimini Aspects',
        icon: Icons.compare_arrows,
        category: 'Jaimini',
        defaultSpan: CardSpan.half,
      );

  /// Unique unordered planet pairs — the underlying relation is
  /// symmetric (see core/astro/jaimini_aspect.dart), so a→b and b→a
  /// are the same relationship; keep only one direction for display.
  List<JaiminiAspect> _uniquePairs(AstroSnapshot s) {
    final all = jaiminiAspects(s.positions);
    const order = Planet.values;
    return all
        .where((a) => order.indexOf(a.from) < order.indexOf(a.to))
        .toList();
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final pairs = _uniquePairs(ctx.snapshot);
    if (pairs.isEmpty) {
      return Text(
        'No Rashi Drishti between grahas in this chart.',
        style: TETheme.mono(size: 12, color: TEColors.inkSoft),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in pairs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: TEColors.paperAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TEColors.hairline),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12.5),
                children: [
                  TextSpan(
                      text: p.from.displayName,
                      style: TextStyle(
                          color: planetInk(p.from),
                          fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' ⟷ '),
                  TextSpan(
                      text: p.to.displayName,
                      style: TextStyle(
                          color: planetInk(p.to),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    final pairs = _uniquePairs(s);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jaimini Rashi Drishti', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Sign-based aspects: movable signs aspect fixed signs (except'
            ' the one right after); fixed signs aspect movable signs'
            ' (except the one right before); dual signs aspect each other.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Text('Graha pairs', style: TETheme.serif(size: 15)),
          const SizedBox(height: 8),
          if (pairs.isEmpty)
            Text('None in this chart.',
                style: TETheme.mono(size: 12, color: TEColors.inkSoft))
          else
            for (final p in pairs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13.5),
                    children: [
                      TextSpan(
                          text: p.from.displayName,
                          style: TextStyle(
                              color: planetInk(p.from),
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: ' (${p.fromSign.western}) ⟷ '),
                      TextSpan(
                          text: p.to.displayName,
                          style: TextStyle(
                              color: planetInk(p.to),
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: ' (${p.toSign.western})'),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 20),
          Text('Sign aspects', style: TETheme.serif(size: 15)),
          const SizedBox(height: 8),
          for (final sign in ZodiacSign.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${sign.western} → ${jaiminiRashiDrishti(sign).map((x) => x.western).join(', ')}',
                style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
              ),
            ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final pairs = _uniquePairs(ctx.snapshot);
    return [
      pdfSectionHeader('Jaimini Aspects (Rashi Drishti)'),
      if (pairs.isEmpty)
        pw.Text('None in this chart.', style: pdfBody())
      else
        pw.TableHelper.fromTextArray(
          headers: ['Graha', 'Sign', 'Graha', 'Sign'],
          data: [
            for (final p in pairs)
              [
                p.from.displayName,
                p.fromSign.western,
                p.to.displayName,
                p.toSign.western,
              ],
          ],
          headerStyle: pdfLabel(),
          cellStyle: pdfBody(size: 9),
          border: null,
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
        ),
    ];
  }
}
