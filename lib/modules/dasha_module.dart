import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/dasha/dasha.dart';
import '../core/astro/models.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

// Full-date formatters follow the user's app-wide date-format choice
// (read lazily via getters so a settings change is picked up on rebuild).
// The compact _fmtShort/_fmtUntil stay fixed — they are deliberately terse
// labels inside dense dasha timelines, not full dates.
DateFormat get _fmt => DateFormat(TEDate.pref.datePattern);
final _fmtShort = DateFormat('d MMM yy');
DateFormat get _fmtTime => DateFormat('${TEDate.pref.datePattern}, HH:mm');
final _fmtUntil = DateFormat('d MMM, HH:mm');

/// Short level names used in chips ('Antar Saturn', 'Pran Sun', …).
const _levelShort = ['Maha', 'Antar', 'Pratyantar', 'Sookshma', 'Pran'];

/// Professional level tags for breadcrumbs and lineage (MD/AD/PD/SD/PrD).
const _levelAbbr = ['MD', 'AD', 'PD', 'SD', 'PrD'];

// ---------------------------------------------------------------------------
// Shared formatting helpers
// ---------------------------------------------------------------------------

/// Periods shorter than this show clock time in their ranges — at
/// sookshma/pran depth a bare date is ambiguous.
const _clockThreshold = Duration(days: 3);

String _rangeText(DashaPeriod p, {bool anonymized = false}) {
  // Anonymized (Mahakosh) charts never show clock time: dasha periods
  // begin at the birth instant, so a HH:mm boundary would expose it.
  final f = (!anonymized && p.length < _clockThreshold) ? _fmtTime : _fmt;
  return '${f.format(p.start.toLocal())} — ${f.format(p.end.toLocal())}';
}

/// Compact duration: '16y', '2y 2m', '3m 12d', '14d', '38h', '55m'.
String _lenText(Duration d) {
  final days = d.inDays;
  if (days >= 365) {
    final y = days ~/ 365;
    final m = ((days % 365) / 30.44).round();
    return m > 0 ? '${y}y ${m}m' : '${y}y';
  }
  if (days >= 45) {
    final m = (days / 30.44).floor();
    final rem = (days - m * 30.44).round();
    return rem > 0 ? '${m}m ${rem}d' : '${m}m';
  }
  if (days >= 3) return '${days}d';
  if (d.inHours >= 1) return '${d.inHours}h';
  return '${d.inMinutes}m';
}

int _ageYears(DateTime birth, DateTime t) {
  var y = t.year - birth.year;
  if (t.month < birth.month ||
      (t.month == birth.month && t.day < birth.day)) {
    y--;
  }
  return y < 0 ? 0 : y;
}

/// Age span label for a period: 'age 32–48' (or 'age 34' when equal).
String _ageSpan(DateTime birth, DashaPeriod p) {
  final a = _ageYears(birth, p.start);
  final b = _ageYears(birth, p.end);
  return a == b ? 'age $a' : 'age $a–$b';
}

const _signAbbrs = [
  'Ar', 'Ta', 'Ge', 'Cn', 'Le', 'Vi', 'Li', 'Sc', 'Sg', 'Cp', 'Aq', 'Pi',
];

String _abbrOf(DashaPeriod p) {
  if (p.planet != null) return p.planet!.abbr;
  if (p.sign != null) return _signAbbrs[p.sign!.index];
  return p.lordLabel.substring(0, 2);
}

String _firstWord(String s) => s.split(' ').first;

/// Lord ink: planets use the traditional palette; rashis (Jaimini)
/// take their lord planet's colour via [signInk].
Color _lordInk(DashaPeriod p) => p.planet != null
    ? planetInk(p.planet!)
    : (p.sign != null ? signInk(p.sign!) : TEColors.ink);

// ---------------------------------------------------------------------------
// Professional context helpers (all four are toggleable extras)
// ---------------------------------------------------------------------------

/// Sandhi (junction) alert when [t] falls in the fragile opening or
/// closing stretch of [p] — 1/7th of the period, capped at 30 days.
String? _sandhiText(DashaPeriod p, DateTime t) {
  if (!p.contains(t)) return null;
  var thresh = p.length ~/ 7;
  const cap = Duration(days: 30);
  if (thresh > cap) thresh = cap;
  final toEnd = p.end.difference(t);
  if (toEnd <= thresh) return 'sandhi · ends in ${_lenText(toEnd)}';
  final sinceStart = t.difference(p.start);
  if (sinceStart <= thresh) return 'sandhi · began ${_lenText(sinceStart)} ago';
  return null;
}

/// Natal placement of the period's lord: sign · house · nakshatra-pada
/// for grahas; house-from-lagna + lord placement for rashis (Jaimini).
String? _placementText(ModuleContext ctx, DashaPeriod p) {
  final snap = ctx.snapshot;
  if (p.planet != null) {
    final pos = snap.positions[p.planet!];
    if (pos == null) return null;
    // HOUSE ownership (from lagna) — sign lordship is fixed knowledge,
    // but which houses those signs occupy is chart-specific and tells
    // the astrologer benefic/malefic ownership at a glance. Naturally
    // empty for Rahu/Ketu.
    final owned = [
      for (final s in ZodiacSign.values)
        if (s.lord == p.planet)
          ((s.index - snap.lagnaSign.index + 12) % 12) + 1,
    ]..sort();
    return '${pos.sign.western} · H${snap.houseOf(pos.longitude)} · '
        '${pos.nakshatra.displayName} ${pos.pada}'
        '${owned.isEmpty ? '' : ' · lord of ${owned.map((h) => 'H$h').join(', ')}'}';
  }
  if (p.sign != null) {
    final house = ((p.sign!.index - snap.lagnaSign.index + 12) % 12) + 1;
    final lord = p.sign!.lord;
    final pos = snap.positions[lord];
    if (pos == null) return 'H$house';
    return 'H$house · lord ${lord.displayName} in ${pos.sign.western}';
  }
  return null;
}

/// Names of natal yogas whose participants include this period's lord
/// (rashi periods use the sign's Vedic lord).
List<String> _activeYogas(ModuleContext ctx, DashaPeriod p) {
  final planet = p.planet ?? p.sign?.lord;
  if (planet == null) return const [];
  return [
    for (final y in ctx.snapshot.yogas)
      if (y.participants.contains(planet)) y.name,
  ];
}

/// 'Me › Ju › Sa › Ve › Mo' compact chain.
String _chainAbbr(List<DashaPeriod> chain) =>
    chain.map(_abbrOf).join(' › ');

// ---------------------------------------------------------------------------
// Module
// ---------------------------------------------------------------------------

/// Dasha Periods module. Per-instance config: {'system': 'vimshottari'}
/// pins which of the 3 systems shows on the compact card (brief §2.8).
class DashaModule extends AstroModule {
  const DashaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'dasha',
        title: 'Dasha Periods',
        icon: Icons.timeline,
        category: 'Timing & Dashas',
        defaultSpan: CardSpan.full,
      );

  /// Show/hide options for the professional extras on the compact
  /// card — all default to Hide so the card stays uncrowded.
  static const _extraToggles = [
    ('placements', 'Lord positions'),
    ('sandhi', 'Sandhi alerts'),
    ('yogas', 'Yoga activation'),
    ('compare', 'System comparison'),
  ];

  @override
  List<ModuleConfigChoice> configChoices() => [
        ModuleConfigChoice(
          key: 'system',
          label: 'Dasha system',
          options: [
            for (final s in DashaSystem.values) (s.name, s.displayName),
          ],
        ),
        for (final (key, label) in _extraToggles)
          ModuleConfigChoice(
            key: key,
            label: label,
            options: const [('hide', 'Hide'), ('show', 'Show')],
            defaultValue: 'hide',
          ),
      ];

  bool _cfgShow(ModuleContext ctx, String key) =>
      (ctx.config[key] as String? ?? 'hide') == 'show';

  @override
  String? configSummary(Map<String, dynamic> config) {
    final name = config['system'] as String?;
    if (name == null || name == DashaSystem.vimshottari.name) return null;
    return DashaSystem.values
        .firstWhere((s) => s.name == name,
            orElse: () => DashaSystem.vimshottari)
        .displayName;
  }

  DashaSystem _configuredSystem(ModuleContext ctx) {
    final name = ctx.config['system'] as String?;
    return DashaSystem.values.firstWhere(
      (s) => s.name == name,
      orElse: () => DashaSystem.vimshottari,
    );
  }

  // -------------------------------------------------------------------------
  // Card view (dashboard)
  // -------------------------------------------------------------------------

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final system = _configuredSystem(ctx);
    final result = ctx.dasha(system);
    final now = DateTime.now().toUtc();
    final chain = result.chainAt(now);

    if (chain.isEmpty) {
      return const Text('Outside computed dasha range.');
    }

    final maha = chain[0];
    final antar = chain.elementAtOrNull(1);
    final birth = ctx.snapshot.birth.dateTimeUtc;
    final mahaPlace =
        _cfgShow(ctx, 'placements') ? _placementText(ctx, maha) : null;
    final antarPlace = _cfgShow(ctx, 'placements') && antar != null
        ? _placementText(ctx, antar)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(system.displayName.toUpperCase(), style: TEType.kicker()),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: TETheme.serif(size: 18),
            children: [
              TextSpan(
                text: maha.lordLabel,
                style: TextStyle(color: _lordInk(maha)),
              ),
              const TextSpan(text: ' Mahadasha'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_rangeText(maha, anonymized: ctx.anonymized)} · '
          '${_lenText(maha.length)} · ${_ageSpan(birth, maha)}',
          style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
        ),
        if (mahaPlace != null) ...[
          const SizedBox(height: 3),
          Text('${_abbrOf(maha)}: $mahaPlace',
              style: TETheme.mono(size: 10.5, color: TEColors.inkSoft)),
        ],
        const SizedBox(height: 12),
        _AntardashaTimeline(
            maha: maha, now: now, anonymized: ctx.anonymized),
        if (antar != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: TEColors.maroon,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      TextSpan(
                          text: antar.lordLabel,
                          style: TextStyle(
                              color: _lordInk(antar),
                              fontWeight: FontWeight.w600)),
                      TextSpan(
                        text: ' Antardasha · '
                            '${_rangeText(antar, anonymized: ctx.anonymized)}'
                            ' · ${_lenText(antar.length)}',
                        style: TextStyle(color: TEColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (antarPlace != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text('${_abbrOf(antar)}: $antarPlace',
                  style: TETheme.mono(size: 10.5, color: TEColors.inkSoft)),
            ),
          ],
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in chain.skip(2))
              _chainChip(p, anonymized: ctx.anonymized),
            if (_cfgShow(ctx, 'sandhi'))
              for (final p in chain.take(2))
                if (_sandhiText(p, now) case final s?) _sandhiChip(p, s),
            if (_cfgShow(ctx, 'yogas'))
              for (final p in chain.take(2))
                if (_activeYogas(ctx, p) case final ys when ys.isNotEmpty)
                  _yogaChip(p, ys),
          ],
        ),
        if (_cfgShow(ctx, 'compare')) ...[
          const SizedBox(height: 10),
          _SystemComparison(ctx: ctx, asOf: now),
        ],
      ],
    );
  }

  /// Warning pill: 'MD sandhi · ends in 22d'.
  Widget _sandhiChip(DashaPeriod p, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: TEColors.maroon.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: TEColors.maroon.withValues(alpha: 0.55)),
        ),
        child: Text(
          '${_levelAbbr[p.level - 1]} $text',
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: TEColors.maroon),
        ),
      );

  /// 'MD Jupiter activates Gaja Kesari +1' pill (tooltip lists all).
  Widget _yogaChip(DashaPeriod p, List<String> yogas) => Tooltip(
        message: yogas.join('\n'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: TEColors.forest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: TEColors.forest.withValues(alpha: 0.45)),
          ),
          child: Text(
            '${_levelAbbr[p.level - 1]} ${_firstWord(p.lordLabel)} '
            'activates ${yogas.first}'
            '${yogas.length > 1 ? ' +${yogas.length - 1}' : ''}',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: TEColors.forest),
          ),
        ),
      );

  /// 'Pratyantar · Saturn → 14 Aug 26' pill for the running chain.
  Widget _chainChip(DashaPeriod p, {bool anonymized = false}) {
    final until = (!anonymized && p.length < _clockThreshold)
        ? _fmtUntil.format(p.end.toLocal())
        : _fmtShort.format(p.end.toLocal());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: TEColors.paperAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TEColors.hairline),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
                text: '${_levelShort[p.level - 1]} · ',
                style: TextStyle(color: TEColors.inkSoft)),
            TextSpan(
                text: _firstWord(p.lordLabel),
                style: TextStyle(
                    color: _lordInk(p), fontWeight: FontWeight.w600)),
            TextSpan(
                text: ' → $until',
                style: TETheme.mono(size: 10.5, color: TEColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  /// Screen 07 — multi-system dasha drill-down.
  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      _DashaDetailBody(ctx: ctx, initial: _configuredSystem(ctx));

  // -------------------------------------------------------------------------
  // PDF
  // -------------------------------------------------------------------------

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final now = DateTime.now().toUtc();
    final birth = ctx.snapshot.birth.dateTimeUtc;
    // Respect the instance config: an unconfigured instance prints all
    // three systems; a configured one prints only its system.
    final systems = ctx.config['system'] == null
        ? DashaSystem.values
        : [_configuredSystem(ctx)];
    // Every header/table is a top-level widget so MultiPage can break
    // pages between and inside the tables.
    final blocks = <pw.Widget>[
      pdfSectionHeader(systems.length == 1
          ? 'Dasha Periods — ${systems.first.displayName}'
          : 'Dasha Periods'),
    ];
    for (final system in systems) {
      final result = ctx.dasha(system);
      final chain = result.chainAt(now);
      final maha = chain.elementAtOrNull(0);
      blocks.addAll([
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 2),
          child: pw.Text(system.displayName,
              style: pdfBody(size: 10.5)
                  .copyWith(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text(system.subtitle, style: pdfLabel()),
        // Active chain down to pran, as of print time.
        if (chain.isNotEmpty) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
            child: pw.Text(
              'Active chain · ${_fmtTime.format(now.toLocal())}',
              style: pdfLabel(),
            ),
          ),
          pw.TableHelper.fromTextArray(
            headers: ['Level', 'Lord', 'From', 'To', 'Length'],
            data: [
              for (final p in chain)
                [
                  kDashaLevelNames[p.level - 1],
                  p.lordLabel,
                  (p.length < _clockThreshold ? _fmtTime : _fmt)
                      .format(p.start.toLocal()),
                  (p.length < _clockThreshold ? _fmtTime : _fmt)
                      .format(p.end.toLocal()),
                  _lenText(p.length),
                ],
            ],
            headerStyle: pdfLabel(),
            cellStyle: pdfBody(size: 9),
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 4),
        ],
        // All mahadashas.
        pw.TableHelper.fromTextArray(
          headers: ['Mahadasha', 'From', 'To', 'Length', 'Age'],
          data: [
            for (final p in result.periods.take(12))
              [
                '${p.contains(now) ? '» ' : ''}${p.lordLabel}',
                _fmt.format(p.start.toLocal()),
                _fmt.format(p.end.toLocal()),
                _lenText(p.length),
                _ageSpan(birth, p).replaceFirst('age ', ''),
              ],
          ],
          headerStyle: pdfLabel(),
          cellStyle: pdfBody(size: 9),
          border: null,
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
        ),
        // Antardashas of the running mahadasha.
        if (maha != null) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
            child: pw.Text(
              'Antardashas of ${maha.lordLabel} Mahadasha',
              style: pdfLabel(),
            ),
          ),
          pw.TableHelper.fromTextArray(
            headers: ['Antardasha', 'From', 'To', 'Length'],
            data: [
              for (final a in maha.children)
                [
                  '${a.contains(now) ? '» ' : ''}${a.lordLabel}',
                  _fmt.format(a.start.toLocal()),
                  _fmt.format(a.end.toLocal()),
                  _lenText(a.length),
                ],
            ],
            headerStyle: pdfLabel(),
            cellStyle: pdfBody(size: 9),
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
        ],
        pw.SizedBox(height: 6),
      ]);
    }
    return blocks;
  }
}

// ---------------------------------------------------------------------------
// Card: segmented antardasha timeline
// ---------------------------------------------------------------------------

/// The current mahadasha as a proportional band of its antardashas:
/// past sub-periods muted, the running one maroon, future ones paper.
/// Each segment is labelled (when wide enough), carries a tooltip with
/// full name + dates, and a needle marks 'now'.
class _AntardashaTimeline extends StatelessWidget {
  const _AntardashaTimeline(
      {required this.maha, required this.now, this.anonymized = false});

  final DashaPeriod maha;
  final DateTime now;
  final bool anonymized;

  static const double _height = 26;

  @override
  Widget build(BuildContext context) {
    final antars = maha.children;
    final totalSec = maha.length.inSeconds;
    if (antars.isEmpty || totalSec <= 0) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      // Inner width: the wrapping Container draws a 1px border on each
      // side, so segments must fit in maxWidth - 2 to avoid overflow.
      final w = constraints.maxWidth - 2;
      final widths = <double>[];
      var used = 0.0;
      for (var i = 0; i < antars.length; i++) {
        if (i == antars.length - 1) {
          widths.add(w - used);
        } else {
          final seg = w * antars[i].length.inSeconds / totalSec;
          widths.add(seg);
          used += seg;
        }
      }
      final needleX = maha.contains(now)
          ? (1 + w * maha.progressAt(now)).clamp(1.0, w + 1.0).toDouble()
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: TEColors.hairline),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Row(
                    children: [
                      for (var i = 0; i < antars.length; i++)
                        _segment(antars[i], widths[i],
                            last: i == antars.length - 1),
                    ],
                  ),
                ),
              ),
              if (needleX != null)
                // Paper halo behind the ink needle so it stays visible
                // over both the maroon current segment and muted past.
                Positioned(
                  left: needleX - 2,
                  top: -4,
                  bottom: -4,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: TEColors.paper,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                    child: Container(width: 2, color: TEColors.ink),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(_fmtShort.format(maha.start.toLocal()),
                  style: TETheme.mono(size: 9.5, color: TEColors.inkSoft)),
              const Spacer(),
              Text(_fmtShort.format(maha.end.toLocal()),
                  style: TETheme.mono(size: 9.5, color: TEColors.inkSoft)),
            ],
          ),
        ],
      );
    });
  }

  Widget _segment(DashaPeriod antar, double width, {required bool last}) {
    final isCurrent = antar.contains(now);
    final isPast = !antar.end.isAfter(now);
    final color = isCurrent
        ? TEColors.maroon
        : isPast
            ? TEColors.inkSoft.withValues(alpha: 0.22)
            : TEColors.paperAlt;
    return Tooltip(
      message: '${antar.lordLabel}\n'
          '${_rangeText(antar, anonymized: anonymized)}'
          ' · ${_lenText(antar.length)}',
      textAlign: TextAlign.center,
      child: Container(
        width: width,
        height: _height,
        decoration: BoxDecoration(
          color: color,
          border: last
              ? null
              : Border(
                  right: BorderSide(
                      color: TEColors.inkSoft.withValues(alpha: 0.45),
                      width: 0.7)),
        ),
        alignment: Alignment.center,
        // Horizontal label when the segment is wide enough; rotated
        // 90° for narrow slivers (e.g. Sun 6/120 in Vimshottari,
        // Mangala 1/36 in Yogini) so every antardasha stays named.
        child: width >= 16
            ? Text(
                _abbrOf(antar),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? TEColors.paper : TEColors.inkSoft,
                ),
              )
            : width >= 8
                ? RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      _abbrOf(antar),
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color:
                            isCurrent ? TEColors.paper : TEColors.inkSoft,
                      ),
                    ),
                  )
                : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cross-system comparison (shared by card and detail view)
// ---------------------------------------------------------------------------

/// All three systems' chains for one instant, one compact line each:
/// 'Vimshottari   Me › Ju › Sa › Ve › Mo'.
class _SystemComparison extends StatelessWidget {
  const _SystemComparison({required this.ctx, required this.asOf});

  final ModuleContext ctx;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: TEColors.paperAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TEColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALL SYSTEMS · MD › AD › PD › SD › PrD',
              style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                  color: TEColors.inkSoft,
                  fontWeight: FontWeight.w600)),
          for (final s in DashaSystem.values)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(s.displayName,
                        style: TextStyle(
                            fontSize: 10.5, color: TEColors.inkSoft)),
                  ),
                  Expanded(
                    child: Builder(builder: (_) {
                      final chain = ctx.dasha(s).chainAt(asOf);
                      return Text(
                        chain.isEmpty ? '—' : _chainAbbr(chain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TETheme.mono(size: 11, color: TEColors.ink),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail view: chain summary + breadcrumb drill-down to pran
// ---------------------------------------------------------------------------

class _DashaDetailBody extends StatefulWidget {
  const _DashaDetailBody({required this.ctx, required this.initial});
  final ModuleContext ctx;
  final DashaSystem initial;

  @override
  State<_DashaDetailBody> createState() => _DashaDetailBodyState();
}

class _DashaDetailBodyState extends State<_DashaDetailBody> {
  late DashaSystem _system = widget.initial;

  /// Drill path: selected ancestors, outermost first. Empty = the
  /// mahadasha list. Level shown = _path.length + 1.
  final List<DashaPeriod> _path = [];

  /// Reference instant for 'current' highlighting and the chain card;
  /// null = live now (dasha-on-a-date lookup otherwise).
  DateTime? _asOf;

  // Professional extras — all off by default so the screen stays
  // uncrowded until opted in (matching the dashboard card's defaults).
  //
  // These are the module's declared config choices, so a change is
  // persisted back to the dashboard widget row (via ctx.onConfigChanged)
  // and the card reflects it. Seeded from that config; local fields keep
  // the toggle responsive without waiting on the round-trip.
  late bool _showPlacements = widget.ctx.config['placements'] == 'show';
  late bool _showSandhi = widget.ctx.config['sandhi'] == 'show';
  late bool _showYogas = widget.ctx.config['yogas'] == 'show';
  late bool _showCompare = widget.ctx.config['compare'] == 'show';

  /// Write a config key back to the originating card. No-op when opened
  /// without a card (onConfigChanged null) — then toggles stay local.
  void _persist(String key, String value) =>
      widget.ctx.onConfigChanged?.call({...widget.ctx.config, key: value});

  DateTime get _refUtc => (_asOf ?? DateTime.now()).toUtc();

  Future<void> _pickAsOf() async {
    final local = (_asOf ?? DateTime.now()).toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    setState(() => _asOf = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 0,
          time?.minute ?? 0,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.ctx.dasha(_system);
    final asOf = _refUtc;
    final chain = result.chainAt(asOf);
    final birth = widget.ctx.snapshot.birth.dateTimeUtc;

    final level = _path.length + 1;
    final periods = _path.isEmpty ? result.periods : _path.last.children;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // System selector
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final s in DashaSystem.values)
              ChoiceChip(
                label: Text(s.displayName),
                selected: _system == s,
                labelStyle: TextStyle(
                    color: _system == s ? TEColors.paper : TEColors.ink),
                onSelected: (_) => setState(() {
                  _system = s;
                  _path.clear();
                  _persist('system', s.name);
                }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(_system.subtitle,
            style: TETheme.mono(size: 11, color: TEColors.inkSoft)),
        const SizedBox(height: 14),

        // As-of control (dasha on a date)
        _asOfBar(),
        const SizedBox(height: 8),

        // Extras toggles
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _toggleChip('Lord positions', _showPlacements, (v) => setState(() {
                  _showPlacements = v;
                  _persist('placements', v ? 'show' : 'hide');
                })),
            _toggleChip('Sandhi', _showSandhi, (v) => setState(() {
                  _showSandhi = v;
                  _persist('sandhi', v ? 'show' : 'hide');
                })),
            _toggleChip('Yogas', _showYogas, (v) => setState(() {
                  _showYogas = v;
                  _persist('yogas', v ? 'show' : 'hide');
                })),
            _toggleChip('All systems', _showCompare, (v) => setState(() {
                  _showCompare = v;
                  _persist('compare', v ? 'show' : 'hide');
                })),
          ],
        ),
        const SizedBox(height: 12),

        // Active chain summary
        if (chain.isEmpty)
          Text('Outside computed dasha range for this date.',
              style: TextStyle(color: TEColors.inkSoft))
        else
          _chainCard(chain),
        if (_showCompare) ...[
          const SizedBox(height: 10),
          _SystemComparison(ctx: widget.ctx, asOf: asOf),
        ],
        const SizedBox(height: 18),

        // Breadcrumbs
        _breadcrumbs(),
        const SizedBox(height: 2),
        if (_path.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'within ${_path.last.lordLabel} ${_path.last.levelName}'
              ' · ${_rangeText(_path.last, anonymized: widget.ctx.anonymized)}',
              style: TETheme.mono(size: 10.5, color: TEColors.inkSoft),
            ),
          )
        else
          const SizedBox(height: 6),

        // Period list at the current drill level
        for (final p in periods)
          _periodRow(
            p,
            isCurrent: p.contains(asOf) && _onActivePath(chain, p),
            birth: birth,
            asOf: asOf,
            canDrill: level < kDashaMaxLevel,
            // 'Sa / Sa / ' ancestry prefix so same-lord sub-periods
            // (Saturn AD inside Saturn MD) are never ambiguous.
            lineage: _path.isEmpty
                ? null
                : '${_path.map(_abbrOf).join(' / ')} / ',
            placement:
                _showPlacements ? _placementText(widget.ctx, p) : null,
            yogas: _showYogas ? _activeYogas(widget.ctx, p) : const [],
            sandhi: _showSandhi ? _sandhiText(p, asOf) : null,
          ),
      ],
    );
  }

  Widget _toggleChip(String label, bool value, ValueChanged<bool> onChanged) =>
      FilterChip(
        label: Text(label),
        selected: value,
        onSelected: onChanged,
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(
            fontSize: 11.5,
            color: value ? TEColors.paper : TEColors.ink),
      );

  /// A period at the shown level is 'current' when it is the chain
  /// entry for its level AND its listed siblings are on the active
  /// branch (drilling into a non-active branch must not highlight
  /// date-coincident periods of other parents).
  bool _onActivePath(List<DashaPeriod> chain, DashaPeriod p) {
    if (p.level - 2 >= 0) {
      // Parent shown in the drill path must equal the chain's parent.
      if (_path.length < p.level - 1) return false;
      if (!identical(chain.elementAtOrNull(p.level - 2),
          _path[p.level - 2])) {
        return false;
      }
    }
    return identical(chain.elementAtOrNull(p.level - 1), p);
  }

  Widget _asOfBar() {
    final live = _asOf == null;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: live
                ? TEColors.transit.withValues(alpha: 0.12)
                : TEColors.paperAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TEColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (live) ...[
                Icon(Icons.circle, size: 8, color: TEColors.transit),
                const SizedBox(width: 6),
              ],
              Text(
                live
                    ? 'Now · ${_fmtTime.format(DateTime.now())}'
                    : _fmtTime.format(_asOf!),
                style: TETheme.mono(size: 11, color: TEColors.inkSoft),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _pickAsOf,
          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
          label: const Text('Chain on a date'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (!live)
          TextButton.icon(
            onPressed: () => setState(() => _asOf = null),
            icon: const Icon(Icons.bolt, size: 16),
            label: const Text('Now'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }

  /// Maha → pran chain for the reference instant. Rows are tappable:
  /// they jump the drill-down to that level's sibling list.
  Widget _chainCard(List<DashaPeriod> chain) {
    return Container(
      decoration: BoxDecoration(
        color: TEColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TEColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text('ACTIVE CHAIN',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: TEColors.inkSoft,
                    fontWeight: FontWeight.w600)),
          ),
          for (final p in chain) ...[
            Container(height: 0.7, color: TEColors.hairline),
            Builder(builder: (_) {
              // Lord positions apply to the active chain too (matching the
              // dashboard card and the period rows below), not just the
              // drill-down list.
              final place =
                  _showPlacements ? _placementText(widget.ctx, p) : null;
              return InkWell(
                onTap: () => setState(() {
                  _path
                    ..clear()
                    ..addAll(chain.sublist(0, p.level - 1));
                }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(kDashaLevelNames[p.level - 1],
                            style: TextStyle(
                                fontSize: 10.5, color: TEColors.inkSoft)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.lordLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _lordInk(p))),
                            if (place != null) ...[
                              const SizedBox(height: 2),
                              Text('${_abbrOf(p)}: $place',
                                  style: TETheme.mono(
                                      size: 10, color: TEColors.inkSoft)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${_rangeText(p, anonymized: widget.ctx.anonymized)}'
                          ' · ${_lenText(p.length)}',
                          maxLines: 2,
                          textAlign: TextAlign.right,
                          style:
                              TETheme.mono(size: 9.5, color: TEColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Chip-style breadcrumb: [Mahadashas] › [MD Saturn] › [AD Saturn] ›
  /// Pratyantardashas. The last chip (where you are) is filled maroon;
  /// ancestors are outlined and tappable. Level tags (MD/AD/…) keep
  /// same-lord chains unambiguous (Saturn MD vs Saturn AD).
  Widget _breadcrumbs() {
    final crumbs = <Widget>[
      _crumbChip(
        label: kDashaLevelNamesPlural[0],
        active: _path.isEmpty,
        onTap: _path.isEmpty ? null : () => setState(_path.clear),
      ),
    ];
    for (var i = 0; i < _path.length; i++) {
      final p = _path[i];
      final isLast = i == _path.length - 1;
      crumbs.addAll([
        _crumbSep(),
        _crumbChip(
          abbr: _levelAbbr[p.level - 1],
          label: _firstWord(p.lordLabel),
          ink: _lordInk(p),
          active: isLast,
          onTap: isLast
              ? null
              : () => setState(() => _path.removeRange(i + 1, _path.length)),
        ),
      ]);
    }
    if (_path.isNotEmpty) {
      crumbs.addAll([
        _crumbSep(),
        Text(
          kDashaLevelNamesPlural[_path.length],
          style: TextStyle(
              fontSize: 13,
              color: TEColors.ink,
              fontWeight: FontWeight.w700),
        ),
      ]);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: crumbs,
    );
  }

  Widget _crumbSep() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Text('›',
            style: TextStyle(fontSize: 14, color: TEColors.inkSoft)),
      );

  Widget _crumbChip({
    required String label,
    String? abbr,
    Color? ink,
    required bool active,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: active ? TEColors.maroon : TEColors.paperAlt,
          borderRadius: BorderRadius.circular(16),
          border: active ? null : Border.all(color: TEColors.hairline),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              if (abbr != null)
                TextSpan(
                  text: '$abbr ',
                  style: TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? TEColors.paper.withValues(alpha: 0.8)
                        : TEColors.inkSoft,
                  ),
                ),
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? TEColors.paper : (ink ?? TEColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodRow(
    DashaPeriod p, {
    required bool isCurrent,
    required DateTime birth,
    required DateTime asOf,
    required bool canDrill,
    String? lineage,
    String? placement,
    List<String> yogas = const [],
    String? sandhi,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isCurrent
            ? TEColors.maroon.withValues(alpha: 0.06)
            : TEColors.paper,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: canDrill ? () => setState(() => _path.add(p)) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent ? TEColors.maroon : TEColors.hairline,
                width: isCurrent ? 1.2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (lineage != null)
                            Text(lineage,
                                style: TETheme.mono(
                                    size: 11, color: TEColors.inkSoft)),
                          Flexible(
                            child: Text(p.lordLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _lordInk(p))),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: TEColors.maroon,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('CURRENT',
                                  style: TextStyle(
                                      fontSize: 8.5,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                      color: TEColors.paper)),
                            ),
                          ],
                          if (sandhi != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: TEColors.maroon
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: TEColors.maroon
                                          .withValues(alpha: 0.55)),
                                ),
                                child: Text(sandhi,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: TEColors.maroon)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_rangeText(p, anonymized: widget.ctx.anonymized)}'
                        ' · ${_lenText(p.length)} · ${_ageSpan(birth, p)}',
                        style: TETheme.mono(
                            size: 10.5, color: TEColors.inkSoft),
                      ),
                      if (placement != null) ...[
                        const SizedBox(height: 2),
                        Text('${_abbrOf(p)}: $placement',
                            style: TETheme.mono(
                                size: 10, color: TEColors.inkSoft)),
                      ],
                      if (yogas.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('activates: ${yogas.join(' · ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: TEColors.forest)),
                      ],
                      if (isCurrent) ...[
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: p.progressAt(asOf),
                            minHeight: 4,
                            backgroundColor: TEColors.paperAlt,
                            valueColor:
                                AlwaysStoppedAnimation(TEColors.maroon),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${(p.progressAt(asOf) * 100).round()}% elapsed',
                          style: TETheme.mono(
                              size: 9.5, color: TEColors.inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canDrill)
                  Icon(Icons.chevron_right,
                      size: 20, color: TEColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
