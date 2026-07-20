/// Sade Sati tracker — Saturn's ~7.5-year transit over, before, and
/// after the natal Moon sign, tracked across the whole computed
/// lifetime. Reuses [sadeSatiPhasesProvider] (shared with Upcoming
/// Events) so the scan happens once and is memoized per kundli, and
/// [ModuleContext.ashtakavarga] (shared with the Ashtakavarga module)
/// for the per-phase severity tag — no recomputation of either.
///
/// Round 2, Task 8: the raw phase list from the scan engine reports
/// every Saturn OCCUPANCY interval separately, so a retrograde
/// re-entry near a sign boundary shows up as extra Rising/Peak/Setting
/// entries with the same label back-to-back. [mergeCycleByLabel]
/// collapses those into exactly one merged segment per label so the
/// card strip always shows exactly three boxes; the raw intervals are
/// preserved as `subPhases` for the detail view's "retrograde
/// re-entry" sub-rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/ashtakavarga.dart';
import '../core/astro/models.dart';
import '../core/astro/transit_scan.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _sadeSatiTitle(AppLocalizations l10n) => l10n.moduleSadeSatiTitle;

/// Display-only localization of the severity band words; the raw band
/// ('eased'/'moderate'/'harsh') stays in logic (see [_severityColor]).
String _bandLabel(AppLocalizations l10n, String band) => switch (band) {
      'eased' => l10n.ssBandEased,
      'moderate' => l10n.ssBandModerate,
      'harsh' => l10n.ssBandHarsh,
      _ => band,
    };

// Follows the user's app-wide date-format choice.
DateFormat get _fmt => DateFormat(KJDate.pref.datePattern);

int _ageYears(DateTime birth, DateTime t) {
  var y = t.year - birth.year;
  if (t.month < birth.month || (t.month == birth.month && t.day < birth.day)) {
    y -= 1;
  }
  return y;
}

/// Bare age span with no word prefix: '32' or '32–48' (used directly
/// in the PDF's Age column, and wrapped by [_ageSpan] for prose).
String _ageSpanBare(DateTime birth, DateTime start, DateTime end) {
  final a = _ageYears(birth, start);
  final b = _ageYears(birth, end);
  return a == b ? '$a' : '$a–$b';
}

String _ageSpan(
        AppLocalizations l10n, DateTime birth, DateTime start, DateTime end) =>
    l10n.ssAge(_ageSpanBare(birth, start, end));

/// Compact duration: '7y 4m', '1y', '8m', '24d'.
String _lenText(AppLocalizations l10n, Duration d) {
  final days = d.inDays;
  if (days >= 365) {
    final y = days ~/ 365;
    final m = ((days % 365) / 30.44).round();
    return m > 0 ? l10n.ssDurYearsMonths('$y', '$m') : l10n.ssDurYears('$y');
  }
  if (days >= 30) return l10n.ssDurMonths('${(days / 30.44).round()}');
  return l10n.ssDurDays('$days');
}

/// Approximate half-year duration text, e.g. '≈7½ years' or '≈8 years'.
String approxYears(AppLocalizations l10n, Duration d) {
  final years = d.inDays / 365.25;
  final halves = (years * 2).round();
  final half = halves / 2;
  return half == half.roundToDouble()
      ? l10n.ssApproxYears('${half.round()}')
      : l10n.ssApproxYearsHalf('${half.floor()}');
}

List<SadeSatiPhase> _mainPhases(List<SadeSatiPhase> all) =>
    all.where((p) => p.kind != SadeSatiPhaseKind.smallPanoti).toList();

List<SadeSatiPhase> _smallPanoti(List<SadeSatiPhase> all) =>
    all.where((p) => p.kind == SadeSatiPhaseKind.smallPanoti).toList();

/// Groups the (already-sorted) main phases into ~7.5-year Sade Sati
/// cycles: a gap of more than 2 years between one phase's end and the
/// next phase's start starts a NEW cycle (a genuine repeat is ~30
/// years later; anything closer — including the short <9-month gaps a
/// retrograde dip OUT of the Sade Sati zone can briefly create — is
/// part of the same run).
List<List<SadeSatiPhase>> groupIntoCycles(List<SadeSatiPhase> mainPhases) {
  final cycles = <List<SadeSatiPhase>>[];
  for (final p in mainPhases) {
    if (cycles.isEmpty ||
        p.start.difference(cycles.last.last.end) > const Duration(days: 730)) {
      cycles.add([p]);
    } else {
      cycles.last.add(p);
    }
  }
  return cycles;
}

/// One label's (Rising/Peak/Setting) merged span within a cycle — see
/// the library doc comment for why this collapses retrograde re-entry
/// slivers into a single segment.
class MergedSadeSatiPhase {
  const MergedSadeSatiPhase({
    required this.kind,
    required this.sign,
    required this.duration,
    required this.subPhases,
  });

  final SadeSatiPhaseKind kind;
  final ZodiacSign sign;

  /// CALENDAR span of this phase within the cycle (first entry until
  /// the next phase begins) — retro dips out of the sign are counted
  /// IN, so the three segments tile the whole cycle and their sum
  /// equals the cycle's real start→end length. Retro therefore makes
  /// a cycle read longer, never shorter.
  final Duration duration;
  final List<SadeSatiPhase> subPhases; // chronological raw intervals

  DateTime get start => subPhases.first.start;
  DateTime get end => subPhases.last.end;

  /// True when a retrograde dip split this label into >1 raw interval.
  bool get hasReentries => subPhases.length > 1;
}

/// Collapses a cycle's raw phases into exactly one merged segment per
/// phase, in Rising → Peak → Setting order (a phase absent from this
/// particular cycle — shouldn't normally happen — is simply skipped).
List<MergedSadeSatiPhase> mergeCycleByLabel(List<SadeSatiPhase> cycle) {
  const order = [
    SadeSatiPhaseKind.rising,
    SadeSatiPhaseKind.peak,
    SadeSatiPhaseKind.setting,
  ];
  final byKind = <SadeSatiPhaseKind, List<SadeSatiPhase>>{};
  for (final p in cycle) {
    (byKind[p.kind] ??= []).add(p);
  }
  final picked = <(SadeSatiPhaseKind, List<SadeSatiPhase>)>[
    for (final kind in order)
      if (byKind[kind] case final subs? when subs.isNotEmpty) (kind, subs),
  ];
  if (picked.isEmpty) return const [];
  final cycleEnd = cycle.last.end;
  final out = <MergedSadeSatiPhase>[];
  for (var i = 0; i < picked.length; i++) {
    final (kind, subs) = picked[i];
    // Calendar tiling: this phase runs until the NEXT phase's first
    // entry (or cycle end), so retro dips stay inside the span.
    final spanEnd =
        i + 1 < picked.length ? picked[i + 1].$2.first.start : cycleEnd;
    out.add(MergedSadeSatiPhase(
        kind: kind,
        sign: subs.first.sign,
        duration: spanEnd.difference(subs.first.start),
        subPhases: subs));
  }
  return out;
}

Color _phaseColor(SadeSatiPhaseKind kind) => switch (kind) {
      SadeSatiPhaseKind.rising => KJColors.maroon.withValues(alpha: 0.32),
      SadeSatiPhaseKind.peak => KJColors.maroon,
      SadeSatiPhaseKind.setting => KJColors.maroon.withValues(alpha: 0.6),
      SadeSatiPhaseKind.smallPanoti => KJColors.inkSoft.withValues(alpha: 0.35),
    };

/// Saturn's Bhinnashtakavarga bindus in [sign] + that sign's
/// Sarvashtakavarga total — a quick "how rough will this phase feel"
/// signal. Bands per the handoff: >=5 bindus eased, 3-4 moderate,
/// <=2 harsh (out of a possible 8 contributors).
({int bav, int sav, String band}) severityOf(Ashtakavarga av, ZodiacSign sign) {
  final bindus = av.bav(Planet.saturn)[sign.index];
  final savTotal = av.sav()[sign.index];
  final band = bindus >= 5 ? 'eased' : (bindus >= 3 ? 'moderate' : 'harsh');
  return (bav: bindus, sav: savTotal, band: band);
}

String severityTag(
        AppLocalizations l10n, ({int bav, int sav, String band}) sev) =>
    l10n.ssSeverity(Planet.saturn.abbrLabel(l10n), '${sev.bav}', '${sev.sav}',
        _bandLabel(l10n, sev.band));

Color _severityColor(String band) => switch (band) {
      'eased' => KJColors.forest,
      'harsh' => KJColors.maroon,
      _ => KJColors.inkSoft,
    };

class SadeSatiModule extends AstroModule {
  const SadeSatiModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'sade_sati',
        title: 'Sade Sati',
        localizedTitle: _sadeSatiTitle,
        icon: Icons.hourglass_bottom_outlined,
        category: 'Timing & Dashas',
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _SadeSatiBody(ctx: ctx, detailed: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _SadeSatiBody(ctx: ctx, detailed: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final s = ctx.snapshot;
    final birth = s.birth.dateTimeUtc;
    final av = ctx.ashtakavarga;
    final all = sadeSatiPhases(
      moonSign: s.moonSign,
      from: birth,
      to: birth.add(const Duration(days: 36525)),
      ayanamsaId: s.ayanamsaId,
    );
    final main = _mainPhases(all);
    final panoti = _smallPanoti(all);
    final cycles = groupIntoCycles(main);

    return [
      pdfSectionHeader(l10n.moduleSadeSatiTitle),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.ssColCycle,
          l10n.ssColPhase,
          l10n.ssColStart,
          l10n.ssColEnd,
          l10n.ssColDuration,
          l10n.ssColAge,
          l10n.ssColSeverity,
        ],
        data: [
          for (var i = 0; i < cycles.length; i++)
            for (final seg in mergeCycleByLabel(cycles[i]))
              [
                '${i + 1}',
                seg.kind.label(l10n) + (seg.hasReentries ? ' *' : ''),
                _fmt.format(seg.start.toLocal()),
                _fmt.format(seg.end.toLocal()),
                _lenText(l10n, seg.duration),
                _ageSpanBare(birth, seg.start, seg.end),
                severityTag(l10n, severityOf(av, seg.sign)),
              ],
        ],
        headerStyle: pw.TextStyle(
            fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: pdfInkSoft),
        cellStyle: pdfBody(size: 9),
        border: null,
        headerDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: pdfInk, width: 0.8)),
        ),
        rowDecoration: const pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(color: pdfHairline, width: 0.5)),
        ),
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        l10n.ssPdfRetroFootnote,
        style: pw.TextStyle(fontSize: 7.5, color: pdfInkSoft),
      ),
      if (panoti.isNotEmpty) ...[
        pdfSectionHeader(l10n.ssSmallPanotiHeading),
        pw.TableHelper.fromTextArray(
          headers: [
            l10n.ssColStart,
            l10n.ssColEnd,
            l10n.ssColDuration,
            l10n.ssColAge,
            l10n.ssColSeverity,
          ],
          data: [
            for (final p in panoti)
              [
                _fmt.format(p.start.toLocal()),
                _fmt.format(p.end.toLocal()),
                _lenText(l10n, p.length),
                _ageSpanBare(birth, p.start, p.end),
                severityTag(l10n, severityOf(av, p.sign)),
              ],
          ],
          headerStyle: pw.TextStyle(
              fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: pdfInkSoft),
          cellStyle: pdfBody(size: 9),
          border: null,
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ];
  }
}

class _SadeSatiBody extends ConsumerWidget {
  const _SadeSatiBody({required this.ctx, required this.detailed});
  final ModuleContext ctx;
  final bool detailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(sadeSatiPhasesProvider(ctx.kundli.id));
    return async.when(
      loading: () => const SizedBox(
          height: 60, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.ssComputeError('$e')),
      data: (all) {
        final av = ctx.ashtakavarga;
        final birth = ctx.snapshot.birth.dateTimeUtc;
        final now = DateTime.now().toUtc();
        final main = _mainPhases(all);
        final panoti = _smallPanoti(all);
        final cycles = groupIntoCycles(main);

        final currentCycle =
            cycles.where((c) => c.any((p) => p.contains(now))).firstOrNull;
        final nearestCycle = currentCycle ??
            cycles.where((c) => c.first.start.isAfter(now)).firstOrNull;

        SadeSatiPhase? activePhase() =>
            currentCycle?.firstWhere((p) => p.contains(now));

        final statusLine = () {
          if (currentCycle != null) {
            final active = activePhase()!;
            final sev = severityTag(l10n, severityOf(av, active.sign));
            return l10n.ssStatusInPhase(active.kind.label(l10n),
                _fmt.format(active.end.toLocal()), sev);
          }
          if (nearestCycle != null) {
            final start = nearestCycle.first.start;
            final sev =
                severityTag(l10n, severityOf(av, nearestCycle.first.sign));
            return l10n.ssStatusNext(_fmt.format(start.toLocal()),
                '${_ageYears(birth, start)}', sev);
          }
          return l10n.ssStatusNone;
        }();

        if (!detailed) {
          final merged =
              nearestCycle == null ? null : mergeCycleByLabel(nearestCycle);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusLine,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: currentCycle != null
                          ? KJColors.maroon
                          : KJColors.ink)),
              if (merged != null) ...[
                const SizedBox(height: 10),
                _SadeSatiTimeline(
                    cycle: nearestCycle!, merged: merged, now: now),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusLine,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        currentCycle != null ? KJColors.maroon : KJColors.ink)),
            const SizedBox(height: 14),
            for (var i = 0; i < cycles.length; i++) ...[
              Text(l10n.ssCycleHeading('${i + 1}'),
                  style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.8,
                      color: KJColors.inkSoft,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _SadeSatiTimeline(
                  cycle: cycles[i],
                  merged: mergeCycleByLabel(cycles[i]),
                  now: now),
              const SizedBox(height: 8),
              for (final seg in mergeCycleByLabel(cycles[i]))
                _segmentRows(l10n, seg, av, birth, now),
              const SizedBox(height: 12),
            ],
            if (panoti.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 6),
              Text(l10n.ssSmallPanotiHeadingUpper,
                  style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.8,
                      color: KJColors.inkSoft,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              for (final p in panoti)
                _phaseRow(l10n, p, av, birth, now, secondary: true),
            ],
          ],
        );
      },
    );
  }

  Widget _segmentRows(AppLocalizations l10n, MergedSadeSatiPhase seg,
      Ashtakavarga av, DateTime birth, DateTime now) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _phaseRow(
            l10n,
            seg.subPhases.first,
            av,
            birth,
            now,
            overrideEnd: seg.end,
            overrideDuration: seg.duration,
          ),
          for (var i = 1; i < seg.subPhases.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                l10n.ssRetroReentry(
                  _fmt.format(seg.subPhases[i].start.toLocal()),
                  _fmt.format(seg.subPhases[i].end.toLocal()),
                  _lenText(l10n, seg.subPhases[i].length),
                ),
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: KJColors.inkSoft),
              ),
            ),
        ],
      ),
    );
  }

  Widget _phaseRow(
    AppLocalizations l10n,
    SadeSatiPhase p,
    Ashtakavarga av,
    DateTime birth,
    DateTime now, {
    bool secondary = false,
    DateTime? overrideEnd,
    Duration? overrideDuration,
  }) {
    final end = overrideEnd ?? p.end;
    final duration = overrideDuration ?? p.length;
    final active = !now.isBefore(p.start) && now.isBefore(end);
    final sev = severityOf(av, p.sign);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(p.kind.label(l10n),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: secondary
                      ? KJColors.inkSoft
                      : (active ? KJColors.maroon : KJColors.ink),
                )),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmt.format(p.start.toLocal())} – ${_fmt.format(end.toLocal())}'
                  ' · ${_lenText(l10n, duration)}'
                  ' · ${_ageSpan(l10n, birth, p.start, end)}',
                  style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
                ),
                Text(
                  severityTag(l10n, sev),
                  style:
                      KJTheme.mono(size: 10.5, color: _severityColor(sev.band)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SadeSatiTimeline extends StatelessWidget {
  const _SadeSatiTimeline({
    required this.cycle,
    required this.merged,
    required this.now,
  });
  final List<SadeSatiPhase> cycle;
  final List<MergedSadeSatiPhase> merged;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final start = cycle.first.start;
    final end = cycle.last.end;
    final totalSec = end.difference(start).inSeconds;
    if (totalSec <= 0 || merged.isEmpty) return const SizedBox.shrink();

    final segTotalSec =
        merged.fold(0, (a, m) => a + m.duration.inSeconds).clamp(1, 1 << 62);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth - 2;
      final widths = <double>[];
      var used = 0.0;
      for (var i = 0; i < merged.length; i++) {
        if (i == merged.length - 1) {
          widths.add(w - used);
        } else {
          final seg = w * merged[i].duration.inSeconds / segTotalSec;
          widths.add(seg);
          used += seg;
        }
      }
      // Needle position: simple fraction of the full cycle span
      // (firstStart..lastEnd) — a documented simplification, since the
      // merged segment widths compress out small internal non-SS gaps
      // (see the class doc comment) and precisely re-deriving "now"'s
      // position within that compressed space isn't worth the
      // complexity for a position marker.
      final withinCycle = !now.isBefore(start) && now.isBefore(end);
      final needleX = withinCycle
          ? (1 + w * (now.difference(start).inSeconds / totalSec))
              .clamp(1.0, w + 1.0)
              .toDouble()
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: KJColors.hairline),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Row(
                    children: [
                      for (var i = 0; i < merged.length; i++)
                        Tooltip(
                          message: '${merged[i].kind.label(l10n)}\n'
                              '${_fmt.format(merged[i].start.toLocal())} – '
                              '${_fmt.format(merged[i].end.toLocal())}'
                              '${merged[i].hasReentries ? '\n${l10n.ssTooltipRetroNote}' : ''}',
                          textAlign: TextAlign.center,
                          child: Container(
                            width: widths[i],
                            height: 22,
                            color: _phaseColor(merged[i].kind),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (needleX != null)
                Positioned(
                  left: needleX - 2,
                  top: -4,
                  bottom: -4,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: KJColors.paper,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                    child: Container(width: 2, color: KJColors.ink),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmt.format(start.toLocal())} — ${_fmt.format(end.toLocal())}'
            ' · ${approxYears(l10n, end.difference(start))}',
            style: KJTheme.mono(size: 10, color: KJColors.inkSoft),
          ),
        ],
      );
    });
  }
}
