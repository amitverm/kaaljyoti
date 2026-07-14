import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Panchang at birth (the shared snapshot's panchang). A live "Panchang
/// Today" variant can be added later as its own module registration.
class PanchangModule extends AstroModule {
  const PanchangModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'panchang',
        title: 'Panchang',
        icon: Icons.wb_sunny_outlined,
        category: 'Today',
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final p = ctx.snapshot.panchang;
    final rows = <(String, String)>[
      ('Tithi', '${p.paksha} ${p.tithiName}'),
      ('Vara', p.vara),
      ('Nakshatra', '${p.nakshatra.displayName} · ${p.pada}'),
      ('Yoga', p.yogaName),
      ('Karana', p.karanaName),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12.5, color: TEColors.inkSoft)),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        const SizedBox(height: 4),
        // Disambiguates from the Today screen's live panchang, which
        // uses the user's current city.
        Text(
          'At the birth moment & place',
          style: TETheme.mono(size: 10.5, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final p = ctx.snapshot.panchang;
    return [
      pdfSectionHeader('Panchang at Birth'),
      pw.TableHelper.fromTextArray(
        data: [
          ['Tithi', '${p.paksha} ${p.tithiName}'],
          ['Vara', p.vara],
          ['Nakshatra', '${p.nakshatra.displayName} · Pada ${p.pada}'],
          ['Yoga', p.yogaName],
          ['Karana', p.karanaName],
        ],
        cellStyle: pdfBody(size: 9.5),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
      ),
    ];
  }
}
