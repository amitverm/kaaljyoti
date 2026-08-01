import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../charts/moon_phase_painter.dart';
import '../core/astro/dasha/dasha.dart';
import '../core/astro/dignity.dart';
import '../core/astro/divisional.dart';
import '../core/astro/guna_milan.dart';
import '../core/astro/models.dart';
import '../core/astro/nakshatra_attrs.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _moonNakshatraTitle(AppLocalizations l10n) =>
    l10n.moduleMoonNakshatraTitle;

/// Balance of the first Vimshottari mahadasha at birth, in the printed
/// panchang's years/months/days form.
///
/// A 365.25-day year and a 30-day month: the classical balance is a
/// FRACTION of the lord's period reduced to y/m/d, not a walk over
/// calendar months, so the split has to be arithmetic. The reading is
/// never finer than a day — dasha periods begin at the birth instant,
/// so an hours-and-minutes balance would restate the birth time, which
/// an anonymized (Mahakosh) chart must not do.
String balanceText(AppLocalizations l10n, Duration balance) {
  final years = balance.inSeconds / (365.25 * 86400);
  var y = years.floor();
  final monthsF = (years - y) * 12;
  var m = monthsF.floor();
  var d = ((monthsF - m) * 30).round();
  // The rounding can push the day count onto the next month/year.
  if (d >= 30) {
    d = 0;
    m++;
  }
  if (m >= 12) {
    m = 0;
    y++;
  }
  return [
    if (y > 0) l10n.dmUnitYears('$y'),
    if (m > 0) l10n.dmUnitMonths('$m'),
    // A balance under a month still needs a number to show, so the day
    // part prints when everything else is zero.
    if (d > 0 || (y == 0 && m == 0)) l10n.dmUnitDays('$d'),
  ].join(' ');
}

class MoonNakshatraModule extends AstroModule {
  const MoonNakshatraModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'moon_nakshatra',
        title: 'Moon & Nakshatra',
        localizedTitle: _moonNakshatraTitle,
        icon: Icons.nightlight_outlined,
        category: 'Today',
        defaultSpan: CardSpan.full,
      );

  /// The janma-nakshatra attribute pairs — one source for the card's
  /// chips and the PDF's table.
  List<(String, String)> _attributes(ModuleContext ctx, AppLocalizations l10n) {
    final moon = ctx.snapshot.positions[Planet.moon]!;
    final nak = moon.nakshatra;
    return [
      (l10n.akKootaGana, ganaOf(nak).label(l10n)),
      (l10n.akKootaYoni, yoniOf(nak).yoniLabel(l10n)),
      (l10n.akKootaNadi, nadiOf(nak).label(l10n)),
      // Varna is read from the Moon's RASHI, not its nakshatra.
      (l10n.akKootaVarna, varnaLabel(l10n, moon.sign)),
      (l10n.labelDeity, deityOf(nak).label(l10n)),
      (l10n.labelSymbol, symbolOf(nak).label(l10n)),
    ];
  }

  /// Vimshottari balance at birth: the first mahadasha is the one the
  /// birth falls inside, so what is left of it is the balance. Read
  /// through [ModuleContext.dasha] so the tree is shared with the Dasha
  /// widget rather than calculated twice.
  (Planet?, String)? _balance(ModuleContext ctx, AppLocalizations l10n) {
    final periods = ctx.dasha(DashaSystem.vimshottari).periods;
    if (periods.isEmpty) return null;
    final first = periods.first;
    final left = first.end.difference(ctx.snapshot.birth.dateTimeUtc);
    if (left.isNegative) return null;
    return (first.planet, balanceText(l10n, left));
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final moon = ctx.snapshot.positions[Planet.moon]!;
    final sun = ctx.snapshot.positions[Planet.sun]!;
    final dignity = dignityOf(moon).label(l10n);
    final balance = _balance(ctx, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(moon.nakshatra.label(l10n),
                      style: KJTheme.serif(size: 20)),
                  const SizedBox(height: 2),
                  Text('${l10n.labelPada} ${moon.pada}',
                      style: TextStyle(fontSize: 13, color: KJColors.inkSoft)),
                  const SizedBox(height: 10),
                  _Reading(
                    label: l10n.labelNakshatraLord,
                    value: moon.nakshatra.lord.label(l10n),
                    ink: planetInk(moon.nakshatra.lord),
                  ),
                  if (balance != null)
                    _Reading(
                      label: l10n.labelDashaBalance,
                      value: balance.$1 == null
                          ? balance.$2
                          : '${balance.$1!.label(l10n)} · ${balance.$2}',
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // The phase disc and the Moon's own placement read as one
            // unit — the disc is a picture of the elongation the sign
            // and degree beside it are measured from.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoonPhaseDisc(elongation: moon.longitude - sun.longitude),
                const SizedBox(height: 8),
                Text(
                  l10n.moonInSign(moon.sign.label(l10n)),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 13.5),
                ),
                Text(
                  formatDegree(moon.longitude),
                  style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
                ),
                // "No dignity" is the ordinary case and has no reading
                // to print, so the line is absent rather than blank.
                if (dignity != null)
                  Text(dignity,
                      style: TextStyle(fontSize: 12.5, color: KJColors.maroon)),
                Text(
                  '${Varga.d9.nameLabel(l10n)} · '
                  '${navamsaSign(moon.longitude).label(l10n)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: KJColors.hairline),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final (label, value) in _attributes(ctx, l10n))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                          color: KJColors.inkSoft)),
                  Text(value, style: const TextStyle(fontSize: 13)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final moon = ctx.snapshot.positions[Planet.moon]!;
    final dignity = dignityOf(moon).label(l10n);
    final balance = _balance(ctx, l10n);
    return pdfSection(
      header: pdfSectionHeader(l10n.moduleMoonNakshatraTitle),
      lead: pdfStack([
        pw.Text(
          '${l10n.moonInSign(moon.sign.label(l10n))} '
          '${formatDegree(moon.longitude)} — '
          '${moon.nakshatra.label(l10n)}, ${l10n.labelPada} ${moon.pada}',
          style: pdfBody(),
        ),
        pw.SizedBox(height: 6),
      ]),
      rest: [
        pdfDataTable(
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(2.2),
          },
          rows: [
            [l10n.labelNakshatraLord, moon.nakshatra.lord.label(l10n)],
            if (balance != null)
              [
                l10n.labelDashaBalance,
                balance.$1 == null
                    ? balance.$2
                    : '${balance.$1!.label(l10n)} · ${balance.$2}'
              ],
            if (dignity != null) [l10n.labelDignity, dignity],
            [
              Varga.d9.nameLabel(l10n),
              navamsaSign(moon.longitude).label(l10n),
            ],
            for (final (label, value) in _attributes(ctx, l10n)) [label, value],
          ],
        ),
        pdfSectionGap(),
      ],
    );
  }
}

/// A label-over-value reading in the card's left column.
class _Reading extends StatelessWidget {
  const _Reading({required this.label, required this.value, this.ink});

  final String label;
  final String value;
  final Color? ink;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                    color: KJColors.inkSoft)),
            Text(value, style: TextStyle(fontSize: 13.5, color: ink)),
          ],
        ),
      );
}
