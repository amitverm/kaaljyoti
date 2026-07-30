import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Panchang at birth (the shared snapshot's panchang). A live "Panchang
/// Today" variant can be added later as its own module registration.
class PanchangModule extends AstroModule {
  const PanchangModule();

  static String _title(AppLocalizations l10n) => l10n.modulePanchangTitle;

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'panchang',
        title: 'Panchang',
        localizedTitle: _title,
        icon: Icons.wb_sunny_outlined,
        category: 'Today',
      );

  /// (limb label, value) rows — one source for the card and the PDF.
  List<(String, String)> _rows(ModuleContext ctx, AppLocalizations l10n) {
    final p = ctx.snapshot.panchang;
    return [
      (
        l10n.labelTithi,
        '${pakshaLabelForIndex(l10n, p.tithiIndex)} '
            '${tithiLabelForIndex(l10n, p.tithiIndex)}'
      ),
      (l10n.labelVara, varaLabelForIndex(l10n, p.varaIndex)),
      (l10n.labelNakshatra, '${p.nakshatra.label(l10n)} · ${p.pada}'),
      (l10n.labelYoga, yogaLabelForIndex(l10n, p.yogaIndex)),
      (l10n.labelKarana, karanaLabelForIndex(l10n, p.karanaIndex)),
    ];
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in _rows(ctx, l10n))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // At half span on a phone the row is ~163pt wide, which the
            // longest limb values ("Shatabhisha · 3") do not fit on one
            // line beside their label. The label stays rigid and the
            // value column wraps — never ellipsised, the reading has to
            // stay legible.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        // Disambiguates from the Today screen's live panchang, which
        // uses the user's current city.
        Text(
          l10n.panchangAtBirthNote,
          style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
        ),
      ],
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final p = ctx.snapshot.panchang;
    return pdfSection(
      header: pdfSectionHeader(l10n.panchangPdfHeader),
      rest: [
        // Deliberately headerless: this is a label/value list, not a
        // grid — the left column IS the heading for each row.
        pdfDataTable(
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(2.2),
          },
          rows: [
            for (final (label, value) in _rows(ctx, l10n))
              if (label == l10n.labelNakshatra)
                // The PDF spells the pada out where the card keeps it terse.
                [
                  label,
                  '${p.nakshatra.label(l10n)} · ${l10n.labelPada} ${p.pada}'
                ]
              else
                [label, value],
          ],
        ),
        pdfSectionGap(),
      ],
    );
  }
}
