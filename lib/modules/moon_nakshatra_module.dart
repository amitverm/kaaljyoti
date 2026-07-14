import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

class MoonNakshatraModule extends AstroModule {
  const MoonNakshatraModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'moon_nakshatra',
        title: 'Moon & Nakshatra',
        icon: Icons.nightlight_outlined,
        category: 'Today',
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final moon = ctx.snapshot.positions[Planet.moon]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(moon.nakshatra.displayName, style: TETheme.serif(size: 20)),
        const SizedBox(height: 2),
        Text('Pada ${moon.pada}',
            style: TextStyle(fontSize: 13, color: TEColors.inkSoft)),
        const SizedBox(height: 10),
        Text(
          'Moon in ${moon.sign.western}',
          style: const TextStyle(fontSize: 13.5),
        ),
        Text(
          formatDegree(moon.longitude),
          style: TETheme.mono(size: 12, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final moon = ctx.snapshot.positions[Planet.moon]!;
    return [
      pdfSectionHeader('Moon & Nakshatra'),
      pw.Text(
        'Moon in ${moon.sign.western} ${formatDegree(moon.longitude)} — '
        '${moon.nakshatra.displayName}, Pada ${moon.pada}',
        style: pdfBody(),
      ),
    ];
  }
}
