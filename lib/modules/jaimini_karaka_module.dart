import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/jaimini_karaka.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _jaiminiKarakasTitle(AppLocalizations l10n) =>
    l10n.moduleJaiminiKarakasTitle;

/// Dedicated Sapta Karaka card — previously only available buried
/// inside the Birth Chart module's "Jaimini karakas" toggle (which
/// still exists, for on-chart labels). This surfaces the same ranking
/// as its own scannable table: code, graha, sign/degree, and the
/// classical significator role.
class JaiminiKarakaModule extends AstroModule {
  const JaiminiKarakaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'jaimini_karaka',
        title: 'Jaimini Karakas',
        localizedTitle: _jaiminiKarakasTitle,
        icon: Icons.auto_awesome_outlined,
        category: 'Jaimini',
        defaultSpan: CardSpan.half,
      );

  Map<Karaka, PlanetPosition> _ranked(AstroSnapshot s) {
    final karakas = saptaKarakas(s.positions);
    final byKaraka = <Karaka, PlanetPosition>{
      for (final e in karakas.entries) e.value: s.positions[e.key]!,
    };
    return {for (final k in Karaka.values) k: byKaraka[k]!};
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final ranked = _ranked(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in ranked.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(entry.key.code,
                      style: KJTheme.mono(
                          size: 12.5,
                          color: KJColors.maroon,
                          weight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(entry.value.planet.label(l10n),
                      style: TextStyle(
                          fontSize: 13.5,
                          color: planetInk(entry.value.planet),
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${entry.value.sign.label(l10n)} ${formatDegreeInSign(entry.value.degreesInSign)}',
                    style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final ranked = _ranked(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.saptaKarakasHeading, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.saptaKarakasBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 16),
          for (final entry in ranked.entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: KJColors.paperAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: KJColors.hairline),
                      ),
                      child: Text(entry.key.code,
                          style: KJTheme.mono(
                              size: 12.5,
                              color: KJColors.maroon,
                              weight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(text: '${entry.key.label(l10n)} · '),
                                TextSpan(
                                  text: entry.value.planet.label(l10n),
                                  style: TextStyle(
                                      color: planetInk(entry.value.planet)),
                                ),
                              ],
                            ),
                          ),
                          Text(entry.key.signifiesLabel(l10n),
                              style: KJTheme.mono(
                                  size: 11, color: KJColors.inkSoft)),
                        ],
                      ),
                    ),
                    Text(
                      '${entry.value.sign.label(l10n)} ${formatDegreeInSign(entry.value.degreesInSign)}',
                      style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final ranked = _ranked(ctx.snapshot);
    return [
      pdfSectionHeader(l10n.karakaPdfHeader),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.labelKaraka,
          l10n.labelGraha,
          l10n.labelSign,
          l10n.labelDegree,
          l10n.labelSignifies,
        ],
        data: [
          for (final entry in ranked.entries)
            [
              '${entry.key.code} · ${entry.key.label(l10n)}',
              entry.value.planet.label(l10n),
              entry.value.sign.label(l10n),
              formatDegreeInSign(entry.value.degreesInSign),
              entry.key.signifiesLabel(l10n),
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
