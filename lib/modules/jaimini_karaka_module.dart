import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/jaimini_karaka.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

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
                      style: TETheme.mono(
                          size: 12.5,
                          color: TEColors.maroon,
                          weight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(entry.value.planet.displayName,
                      style: TextStyle(
                          fontSize: 13.5,
                          color: planetInk(entry.value.planet),
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${entry.value.sign.western} ${formatDegreeInSign(entry.value.degreesInSign)}',
                    style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
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
    final ranked = _ranked(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sapta Karakas', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Ranked by degree within sign, highest first — the classical'
            ' 7-karaka scheme (Sun–Saturn; no Rahu/Ketu).',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
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
                        color: TEColors.paperAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TEColors.hairline),
                      ),
                      child: Text(entry.key.code,
                          style: TETheme.mono(
                              size: 12.5,
                              color: TEColors.maroon,
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
                                TextSpan(
                                    text: '${entry.key.displayName} · '),
                                TextSpan(
                                  text: entry.value.planet.displayName,
                                  style: TextStyle(
                                      color:
                                          planetInk(entry.value.planet)),
                                ),
                              ],
                            ),
                          ),
                          Text(entry.key.signifies,
                              style: TETheme.mono(
                                  size: 11, color: TEColors.inkSoft)),
                        ],
                      ),
                    ),
                    Text(
                      '${entry.value.sign.western} ${formatDegreeInSign(entry.value.degreesInSign)}',
                      style: TETheme.mono(size: 12, color: TEColors.inkSoft),
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
    final ranked = _ranked(ctx.snapshot);
    return [
      pdfSectionHeader('Jaimini Karakas (Sapta)'),
      pw.TableHelper.fromTextArray(
        headers: ['Karaka', 'Graha', 'Sign', 'Degree', 'Signifies'],
        data: [
          for (final entry in ranked.entries)
            [
              '${entry.key.code} · ${entry.key.displayName}',
              entry.value.planet.displayName,
              entry.value.sign.western,
              formatDegreeInSign(entry.value.degreesInSign),
              entry.key.signifies,
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
