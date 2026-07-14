import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/ephemeris_service.dart';
import '../core/astro/models.dart';
import '../core/astro/special_lagna.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Special Lagnas — Bhava, Hora, Ghati (sunrise-based), Indu and Sree.
/// See core/astro/special_lagna.dart for the formulas.
class SpecialLagnaModule extends AstroModule {
  const SpecialLagnaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'special_lagna',
        title: 'Special Lagnas',
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

  String _position(SpecialLagnaPoint p) => p.longitude != null
      ? '${p.sign.western} ${formatDegreeInSign(p.longitude!)}'
      : p.sign.western;

  Widget _row(SpecialLagnaPoint p, {bool withMeaning = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Text(p.kind.code,
                  style: TETheme.mono(
                      size: 12.5,
                      color: TEColors.maroon,
                      weight: FontWeight.w600)),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.kind.displayName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (withMeaning)
                    Text(p.kind.meaning,
                        style: TETheme.mono(
                            size: 10.5, color: TEColors.inkSoft)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(_position(p),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final lagnas = _lagnas(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in lagnas) _row(p),
        const SizedBox(height: 4),
        Text(
          'From the birth sunrise at the birth place',
          style: TETheme.mono(size: 10.5, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    final lagnas = _lagnas(s);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Special Lagnas', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Auxiliary ascendants. BL/HL/GL run from the Sun\'s position'
            ' at the sunrise preceding birth; Indu counts kalas of the'
            ' 9th lords from Lagna and Moon; Sree projects the Moon\'s'
            ' nakshatra fraction from the Lagna.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 12),
          for (final p in lagnas) _row(p, withMeaning: true),
          const SizedBox(height: 12),
          Text(
            'Rashi Lagna ${s.lagnaSign.western} '
            '${formatDegreeInSign(s.ascendant)} for reference. All values'
            ' use the birth sunrise at the BIRTH place — the Today screen'
            ' is where your current city applies.',
            style: TETheme.mono(size: 11, color: TEColors.inkSoft),
          ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final lagnas = _lagnas(ctx.snapshot);
    return [
      pdfSectionHeader('Special Lagnas'),
      pw.TableHelper.fromTextArray(
        headers: ['Code', 'Lagna', 'Position', 'Signifies'],
        data: [
          for (final p in lagnas)
            [p.kind.code, p.kind.displayName, _position(p), p.kind.meaning],
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
