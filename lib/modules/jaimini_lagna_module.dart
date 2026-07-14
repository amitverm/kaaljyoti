import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/jaimini_lagna.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Karakamsha Lagna — the Jaimini special ascendant (Atmakaraka's
/// Navamsha sign). See core/astro/jaimini_lagna.dart.
class JaiminiLagnaModule extends AstroModule {
  const JaiminiLagnaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'jaimini_lagna',
        title: 'Jaimini Lagna',
        icon: Icons.explore_outlined,
        category: 'Jaimini',
        defaultSpan: CardSpan.half,
      );

  List<Planet> _occupants(AstroSnapshot s, ZodiacSign sign) => s.positions.values
      .where((p) => p.sign == sign)
      .map((p) => p.planet)
      .toList();

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final k = karakamshaLagna(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Karakamsha Lagna', style: TETheme.serif(size: 16)),
        const SizedBox(height: 2),
        Text(k.sign.western, style: TETheme.serif(size: 22)),
        const SizedBox(height: 6),
        Text(
          'Atmakaraka ${k.atmakaraka.displayName}\'s Navamsha sign',
          style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    final k = karakamshaLagna(s);
    final occupants = _occupants(s, k.sign);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Karakamsha Lagna', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'The Jaimini system\'s special ascendant, alongside the Rashi'
            ' and Navamsha lagnas: the Navamsha sign of the Atmakaraka'
            ' (soul significator), used for dharma / life-purpose'
            ' readings distinct from the birth chart.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Text(k.sign.western, style: TETheme.serif(size: 26)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13.5),
              children: [
                const TextSpan(text: 'Atmakaraka: '),
                TextSpan(
                    text: k.atmakaraka.displayName,
                    style: TextStyle(
                        color: planetInk(k.atmakaraka),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            occupants.isEmpty
                ? 'No other rashi-chart grahas share this sign.'
                : 'Rashi-chart grahas also in ${k.sign.western}: '
                    '${occupants.map((p) => p.displayName).join(', ')}',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final k = karakamshaLagna(ctx.snapshot);
    return [
      pdfSectionHeader('Jaimini Lagna (Karakamsha)'),
      pw.Text(
        'Karakamsha: ${k.sign.western} (Atmakaraka: ${k.atmakaraka.displayName})',
        style: pdfBody(),
      ),
    ];
  }
}
