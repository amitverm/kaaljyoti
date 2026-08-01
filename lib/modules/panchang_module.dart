import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/muhurta.dart';
import '../core/astro/vikram_samvat.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Config key for the maasa naming convention, shared with the tests.
const kPanchangMasaSystemKey = 'masa_system';

/// The instance's maasa naming convention. Kept in step with the
/// `defaultValue` declared in [PanchangModule.configChoices] — see
/// test/module_config_defaults_test.dart for why the two must agree.
MasaSystem masaSystemOf(Map<String, dynamic> config) =>
    MasaSystem.byName(config[kPanchangMasaSystemKey] as String?);

/// 24-hour clock; the panchang's timings are read, not spoken, and a
/// meridiem marker is one more token to fit in a table row.
final _clock = DateFormat('HH:mm');

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
        defaultSpan: CardSpan.full,
      );

  /// A rise/set time in the birth place's wall clock. The Vedic day
  /// starts at sunrise, so a birth in the small hours belongs to the
  /// PREVIOUS civil date's sunrise — the bare "05:58" would then read
  /// as if it were hours after the birth rather than hours before it.
  /// The date is appended only in exactly that case, where it is
  /// load-bearing.
  String _timeAt(AppLocalizations l10n, DateTime t, DateTime birthLocal) {
    final time = _clock.format(t);
    final sameDay = t.year == birthLocal.year &&
        t.month == birthLocal.month &&
        t.day == birthLocal.day;
    return sameDay ? time : l10n.pcTimeWithDate(time, KJDate.date(t));
  }

  /// (limb label, value) rows — one source for the card and the PDF.
  /// [spellPada] writes "Pada 3" where the card keeps the terser "· 3".
  List<(String, String)> _rows(
    ModuleContext ctx,
    AppLocalizations l10n, {
    bool spellPada = false,
  }) {
    final p = ctx.snapshot.panchang;
    final birthLocal = ctx.snapshot.birth.localDateTime;
    final sunrise = p.sunrise;
    final sunset = p.sunset;
    final nextSunrise = p.nextSunrise;

    // The vara IS its lord's day — naming the graha beside it is what
    // makes the weekday readable as a planetary period rather than a
    // calendar label. varaIndex 0 = Somavara, so +1 lands on
    // DateTime.weekday's Mon=1 … Sun=7.
    final varaLord = kWeekdayLord[p.varaIndex + 1]!;

    final rows = <(String, String)>[
      (
        l10n.labelTithi,
        '${pakshaLabelForIndex(l10n, p.tithiIndex)} '
            '${tithiLabelForIndex(l10n, p.tithiIndex)}'
      ),
      (
        l10n.labelVara,
        '${varaLabelForIndex(l10n, p.varaIndex)} · ${varaLord.label(l10n)}'
      ),
      (
        l10n.labelNakshatra,
        '${p.nakshatra.label(l10n)} · '
            '${spellPada ? '${l10n.labelPada} ' : ''}${p.pada} · '
            '${p.nakshatra.lord.label(l10n)}'
      ),
      (l10n.labelYoga, yogaLabelForIndex(l10n, p.yogaIndex)),
      (l10n.labelKarana, karanaLabelForIndex(l10n, p.karanaIndex)),
      (
        l10n.labelSunrise,
        sunrise == null ? '—' : _timeAt(l10n, sunrise, birthLocal)
      ),
      (
        l10n.labelSunset,
        sunset == null ? '—' : _timeAt(l10n, sunset, birthLocal)
      ),
    ];

    // Day/night and the hora both measure the birth against the Vedic
    // day's boundaries, so both are simply absent where the sun neither
    // rose nor set (polar births).
    if (sunset != null) {
      rows.add((
        l10n.labelDayNight,
        birthLocal.isBefore(sunset) ? l10n.pcDayBirth : l10n.pcNightBirth,
      ));
    }
    if (sunrise != null && sunset != null && nextSunrise != null) {
      final hora = horaSegments(
        sunrise: sunrise,
        sunset: sunset,
        nextSunrise: nextSunrise,
      ).where((s) => s.contains(birthLocal)).firstOrNull;
      if (hora?.planet != null) {
        rows.add((l10n.labelHoraLord, hora!.planet!.label(l10n)));
      }
    }

    final amanta = p.amantaMonthIndex;
    final samvat = p.samvatYear;
    if (amanta != null && samvat != null) {
      final isAdhik = p.isAdhikMaasa ?? false;
      final month = masaLabelForIndex(
        l10n,
        resolveMonthIndex(
          amanta,
          krishnaPaksha: p.tithiIndex >= 15,
          isAdhik: isAdhik,
          system: masaSystemOf(ctx.config),
        ),
      );
      rows.add((
        l10n.labelMaasa,
        l10n.pcMaasaValue(isAdhik ? l10n.masaAdhik(month) : month, '$samvat'),
      ));
    }
    return rows;
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
            // The card is full span now, but it still has to survive a
            // half-span box: a user can resize any widget, and at ~163pt
            // the longest limb values ("Shatabhisha · 3 · Rahu") do not
            // fit on one line beside their label. The label stays rigid
            // and the value column wraps — never ellipsised, the reading
            // has to stay legible.
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
            for (final (label, value) in _rows(ctx, l10n, spellPada: true))
              [label, value],
          ],
        ),
        pdfSectionGap(),
      ],
    );
  }

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: kPanchangMasaSystemKey,
          label: l10n.labelMasaSystem,
          options: [
            ('purnimanta', l10n.masaPurnimanta),
            ('amanta', l10n.masaAmanta),
          ],
          defaultValue: 'purnimanta',
        ),
      ];

  /// Only the non-default convention earns a title suffix — an
  /// unconfigured card would otherwise carry a qualifier that says
  /// nothing about it.
  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) {
    final system = masaSystemOf(config);
    return system == MasaSystem.purnimanta ? null : system.label(l10n);
  }
}
