import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _moonNakshatraTitle(AppLocalizations l10n) =>
    l10n.moduleMoonNakshatraTitle;

class MoonNakshatraModule extends AstroModule {
  const MoonNakshatraModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'moon_nakshatra',
        title: 'Moon & Nakshatra',
        localizedTitle: _moonNakshatraTitle,
        icon: Icons.nightlight_outlined,
        category: 'Today',
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final moon = ctx.snapshot.positions[Planet.moon]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(moon.nakshatra.label(l10n), style: KJTheme.serif(size: 20)),
        const SizedBox(height: 2),
        Text('${l10n.labelPada} ${moon.pada}',
            style: TextStyle(fontSize: 13, color: KJColors.inkSoft)),
        const SizedBox(height: 10),
        Text(
          l10n.moonInSign(moon.sign.label(l10n)),
          style: const TextStyle(fontSize: 13.5),
        ),
        Text(
          formatDegree(moon.longitude),
          style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
        ),
      ],
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final moon = ctx.snapshot.positions[Planet.moon]!;
    return [
      pdfSectionHeader(l10n.moduleMoonNakshatraTitle),
      pw.Text(
        '${l10n.moonInSign(moon.sign.label(l10n))} '
        '${formatDegree(moon.longitude)} — '
        '${moon.nakshatra.label(l10n)}, ${l10n.labelPada} ${moon.pada}',
        style: pdfBody(),
      ),
    ];
  }
}
