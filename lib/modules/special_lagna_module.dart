import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/ephemeris_service.dart';
import '../core/astro/models.dart';
import '../core/astro/special_lagna.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _specialLagnasTitle(AppLocalizations l10n) =>
    l10n.moduleSpecialLagnasTitle;

/// Special Lagnas — Bhava, Hora, Ghati (sunrise-based), Indu and Sree.
/// See core/astro/special_lagna.dart for the formulas.
class SpecialLagnaModule extends AstroModule {
  const SpecialLagnaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'special_lagna',
        title: 'Special Lagnas',
        localizedTitle: _specialLagnasTitle,
        icon: Icons.flag_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.half,
      );

  /// BL/HL/GL need the sunrise preceding birth; IL/SL come straight
  /// from the snapshot. Sunrise can be undefined at polar latitudes —
  /// then only the positional lagnas are shown.
  List<SpecialLagnaPoint> _lagnas(AstroSnapshot s) {
    final svc = EphemerisService.instance;
    final jdBirth = svc.julianDayUt(s.birth.dateTimeUtc);
    final rise =
        svc.sunriseBefore(jdBirth, s.birth.latitude, s.birth.longitude);
    return [
      if (rise != null)
        ...timeBasedSpecialLagnas(
          sunAtSunrise: svc.sunLongitude(rise, s.ayanamsaId),
          daysSinceSunrise: jdBirth - rise,
        ),
      ...positionalSpecialLagnas(s),
    ];
  }

  String _position(SpecialLagnaPoint p, AppLocalizations l10n) =>
      p.longitude != null
          ? '${p.sign.label(l10n)} ${formatDegreeInSign(p.longitude!)}'
          : p.sign.label(l10n);

  Widget _row(SpecialLagnaPoint p, AppLocalizations l10n,
          {bool withMeaning = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Text(p.kind.code,
                  style: KJTheme.mono(
                      size: 12.5,
                      color: KJColors.maroon,
                      weight: FontWeight.w600)),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.kind.label(l10n),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (withMeaning)
                    Text(p.kind.meaningLabel(l10n),
                        style:
                            KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(_position(p, l10n),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final lagnas = _lagnas(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in lagnas) _row(p, l10n),
        const SizedBox(height: 4),
        Text(
          l10n.slFromSunrise,
          style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    final lagnas = _lagnas(s);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.moduleSpecialLagnasTitle, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.slBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 12),
          for (final p in lagnas) _row(p, l10n, withMeaning: true),
          const SizedBox(height: 12),
          Text(
            l10n.slReferenceNote(
                s.lagnaSign.label(l10n), formatDegreeInSign(s.ascendant)),
            style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
          ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final lagnas = _lagnas(ctx.snapshot);
    return [
      pdfSectionHeader(l10n.moduleSpecialLagnasTitle),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.labelCode,
          l10n.labelLagna,
          l10n.labelPosition,
          l10n.labelSignifies,
        ],
        data: [
          for (final p in lagnas)
            [
              p.kind.code,
              p.kind.label(l10n),
              _position(p, l10n),
              p.kind.meaningLabel(l10n),
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
