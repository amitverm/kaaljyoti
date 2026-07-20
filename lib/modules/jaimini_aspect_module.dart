import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/jaimini_aspect.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _jaiminiAspectsTitle(AppLocalizations l10n) =>
    l10n.moduleJaiminiAspectsTitle;

/// Jaimini Rashi Drishti (sign-based aspects) between the grahas in the
/// chart — a different scheme from the planet-based Parashari aspects
/// shown elsewhere. See core/astro/jaimini_aspect.dart for the rules.
class JaiminiAspectModule extends AstroModule {
  const JaiminiAspectModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'jaimini_aspect',
        title: 'Jaimini Aspects',
        localizedTitle: _jaiminiAspectsTitle,
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
    final l10n = context.l10n;
    final pairs = _uniquePairs(ctx.snapshot);
    if (pairs.isEmpty) {
      return Text(
        l10n.jaNoDrishti,
        style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
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
              color: KJColors.paperAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KJColors.hairline),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12.5),
                children: [
                  TextSpan(
                      text: p.from.label(l10n),
                      style: TextStyle(
                          color: planetInk(p.from),
                          fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' ⟷ '),
                  TextSpan(
                      text: p.to.label(l10n),
                      style: TextStyle(
                          color: planetInk(p.to), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    final pairs = _uniquePairs(s);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.jaHeading, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.jaBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Text(l10n.jaGrahaPairs, style: KJTheme.serif(size: 15)),
          const SizedBox(height: 8),
          if (pairs.isEmpty)
            Text(l10n.jaNone,
                style: KJTheme.mono(size: 12, color: KJColors.inkSoft))
          else
            for (final p in pairs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13.5),
                    children: [
                      TextSpan(
                          text: p.from.label(l10n),
                          style: TextStyle(
                              color: planetInk(p.from),
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: ' (${p.fromSign.label(l10n)}) ⟷ '),
                      TextSpan(
                          text: p.to.label(l10n),
                          style: TextStyle(
                              color: planetInk(p.to),
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: ' (${p.toSign.label(l10n)})'),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 20),
          Text(l10n.jaSignAspects, style: KJTheme.serif(size: 15)),
          const SizedBox(height: 8),
          for (final sign in ZodiacSign.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${sign.label(l10n)} → ${jaiminiRashiDrishti(sign).map((x) => x.label(l10n)).join(', ')}',
                style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
              ),
            ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final pairs = _uniquePairs(ctx.snapshot);
    return [
      pdfSectionHeader(l10n.jaPdfHeader),
      if (pairs.isEmpty)
        pw.Text(l10n.jaNone, style: pdfBody())
      else
        pw.TableHelper.fromTextArray(
          headers: [
            l10n.labelGraha,
            l10n.labelSign,
            l10n.labelGraha,
            l10n.labelSign,
          ],
          data: [
            for (final p in pairs)
              [
                p.from.label(l10n),
                p.fromSign.label(l10n),
                p.to.label(l10n),
                p.toSign.label(l10n),
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
