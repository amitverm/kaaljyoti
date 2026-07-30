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
///
/// TWO METHODS, one widget. The classical sign-based reading above is
/// the default and is untouched. A 'method' config choice switches the
/// card, detail and PDF to the degree-based reading instead — Saturn
/// within 45° either side of the natal Moon's exact longitude
/// ([sadeSatiDegreeWindows]). The two are different definitions, not
/// competing approximations of one: degree mode therefore carries NO
/// rising/peak/setting labels and no small panoti, because those are
/// defined by signs and mean nothing on a 90° arc. Each method shows
/// what it defines and nothing more.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/ashtakavarga.dart';
import '../core/astro/models.dart';
import '../core/astro/transit.dart' as transit;
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

// --- Degree-based method ----------------------------------------------------

/// Instance-config key selecting the calculation method.
const String kSadeSatiMethodKey = 'method';

/// True when this instance renders the degree-based reading. The
/// fallback for an absent key is the CLASSICAL method, and it has to
/// stay in step with the `defaultValue` declared in [configChoices] —
/// test/module_config_defaults_test.dart exists because a module whose
/// private fallback and declared default disagree ships a settings
/// sheet that contradicts what the card draws.
bool isDegreeMethod(Map<String, dynamic> config) =>
    ((config[kSadeSatiMethodKey] as String?) ?? 'signs') == 'degrees';

/// Separation text for the 0–180° arc between two longitudes: `43°12'`.
///
/// Deliberately NOT [formatDegree]/[formatDegreeInSign]: both reduce
/// their argument into a 30° sign, so a 44° separation would print as
/// 14° — correct for a position, nonsense for a distance. Same
/// degree°minute' shape, no sign reduction.
String separationText(double separation) {
  final total = (separation.abs() * 60).round();
  return "${total ~/ 60}°${(total % 60).toString().padLeft(2, '0')}'";
}

/// Groups windows into PASSAGES — one per Saturn lap past the natal
/// Moon — so the degree detail can section itself the way the classical
/// body sections into cycles.
///
/// Same 2-year threshold, and the same reasoning, as [groupIntoCycles]:
/// the only gaps INSIDE one passage come from Saturn retrograding back
/// out of the arc, which lasts months at most, while the next lap is a
/// full sidereal period (~29.5 years) away. Two years sits in the
/// middle of that gulf with room to spare in both directions, so the
/// split never depends on the exact figure.
List<List<SadeSatiDegreeWindow>> groupDegreeWindows(
    List<SadeSatiDegreeWindow> windows) {
  final passages = <List<SadeSatiDegreeWindow>>[];
  for (final w in windows) {
    if (passages.isEmpty ||
        w.start.difference(passages.last.last.end) >
            const Duration(days: 730)) {
      passages.add([w]);
    } else {
      passages.last.add(w);
    }
  }
  return passages;
}

/// The window containing [now], else null.
SadeSatiDegreeWindow? currentDegreeWindow(
        List<SadeSatiDegreeWindow> windows, DateTime now) =>
    windows.where((w) => w.contains(now)).firstOrNull;

/// The first window that has not started yet, else null.
SadeSatiDegreeWindow? nextDegreeWindow(
        List<SadeSatiDegreeWindow> windows, DateTime now) =>
    windows.where((w) => w.start.isAfter(now)).firstOrNull;

/// The one-line status, shaped like the classical method's
/// [AppLocalizations.ssStatusInPhase] so a reader switching methods
/// isn't switching dialects: in/not-in, then the distinguishing detail,
/// then the end date.
///
/// Inside the arc, the SIGN of [separation] carries the detail the
/// sign-based method gets from its phase name: 'before' while Saturn is
/// still approaching the natal Moon, 'past' once it has crossed. Exact
/// conjunction (separation 0) takes the 'past' wording — it lasts an
/// instant, and a third string for it would be a state nobody can read
/// off the screen anyway.
///
/// [severity] is the classical status line's trailing
/// '· Sa BAV 5/8 · SAV 39 · eased' fragment, appended verbatim when
/// given. Saturn's bindu count in the sign it is transiting RIGHT NOW
/// is a fact about Saturn, not about either method's definition of
/// Sade Sati, so both status lines carry it. It is appended in code
/// rather than through a placeholder because that is exactly what the
/// classical strings do with it — a trailing ' · ' fragment — and this
/// way the three degree strings stay free of an argument two of them
/// would only pass through.
///
/// Still no verdict: this says where Saturn is, never what it does.
String degreeStatusLine(
  AppLocalizations l10n,
  List<SadeSatiDegreeWindow> windows,
  double separation,
  DateTime now, {
  String? severity,
}) {
  final base = () {
    final current = currentDegreeWindow(windows, now);
    if (current != null) {
      final sep = separationText(separation);
      final date = _fmt.format(current.end.toLocal());
      return separation < 0
          ? l10n.ssDegStatusInBefore(sep, date)
          : l10n.ssDegStatusInPast(sep, date);
    }
    final next = nextDegreeWindow(windows, now);
    if (next != null) {
      return l10n.ssDegStatusNext(_fmt.format(next.start.toLocal()));
    }
    return l10n.ssDegStatusNone;
  }();
  return severity == null ? base : '$base · $severity';
}

/// Saturn's sidereal longitude right now — the one live reading the
/// degree status line needs on top of the memoized lifetime scan.
///
/// A provider rather than a bare [transit.currentTransitPositions] call
/// inside `build` (the shape kota_chakra/sarvatobhadra use) purely for
/// the seam: it keeps the ephemeris behind something a widget test can
/// override, so the detail view can be pumped without FFI like every
/// other test in this suite.
final currentSaturnLongitudeProvider = Provider.family<double, int>(
  (ref, ayanamsaId) => transit
      .currentTransitPositions(ayanamsaId: ayanamsaId)[Planet.saturn]!
      .longitude,
);

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
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: kSadeSatiMethodKey,
          label: l10n.ssMethodLabel,
          options: [
            ('signs', l10n.ssMethodSigns),
            ('degrees', l10n.ssMethodDegrees),
          ],
          defaultValue: 'signs',
        ),
      ];

  /// Only the non-default method earns a title suffix: an unconfigured
  /// card keeps reading plain 'Sade Sati', exactly as it always has.
  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) =>
      isDegreeMethod(config) ? l10n.ssMethodDegrees : null;

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      isDegreeMethod(ctx.config)
          ? _SadeSatiDegreeBody(ctx: ctx, detailed: false)
          : _SadeSatiBody(ctx: ctx, detailed: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      _SadeSatiDetail(ctx: ctx);

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) =>
      isDegreeMethod(ctx.config) ? _degreePdfView(ctx) : _signPdfView(ctx);

  /// Degree-based export: the window table plus the caption that
  /// carries the definition. No phase column and no panoti section —
  /// those belong to the sign method (see the library doc comment).
  List<pw.Widget> _degreePdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final s = ctx.snapshot;
    final birth = s.birth.dateTimeUtc;
    final windows = sadeSatiDegreeWindows(
      natalMoonLon: s.positions[Planet.moon]!.longitude,
      from: birth,
      to: birth.add(const Duration(days: 36525)),
      ayanamsaId: s.ayanamsaId,
    );

    return pdfSection(
      header: pdfSectionHeader(
          '${l10n.moduleSadeSatiTitle} · ${l10n.ssMethodDegrees}'),
      lead: pdfNote(l10n.ssDegCaption),
      rest: [
        if (windows.isEmpty)
          pdfNote(l10n.ssDegNoWindows)
        else
          pdfDataTable(
            // Leading Cycle column mirroring the classical export's, so
            // a reader can see which rows belong to one lap past the
            // Moon — the paper equivalent of the screen's sections.
            headers: [
              l10n.ssColCycle,
              l10n.ssDegColEntry,
              l10n.ssDegColExit,
              l10n.ssColDuration,
              l10n.ssColAge,
              l10n.ssDegColConjunction,
            ],
            fontSize: 9,
            rows: [
              for (final (i, passage) in groupDegreeWindows(windows).indexed)
                for (final w in passage)
                  [
                    '${i + 1}',
                    _fmt.format(w.start.toLocal()),
                    _fmt.format(w.end.toLocal()),
                    _lenText(l10n, w.length),
                    _ageSpanBare(birth, w.start, w.end),
                    [for (final c in w.conjunctions) _fmt.format(c.toLocal())]
                        .join(', '),
                  ],
            ],
          ),
        pdfSectionGap(),
      ],
    );
  }

  List<pw.Widget> _signPdfView(ModuleContext ctx) {
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
      ...pdfSection(
        header: pdfSectionHeader(l10n.moduleSadeSatiTitle),
        rest: [
          pdfDataTable(
            headers: [
              l10n.ssColCycle,
              l10n.ssColPhase,
              l10n.ssColStart,
              l10n.ssColEnd,
              l10n.ssColDuration,
              l10n.ssColAge,
              l10n.ssColSeverity,
            ],
            fontSize: 9,
            rows: [
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
          ),
          pdfNote(l10n.ssPdfRetroFootnote),
          pdfSectionGap(),
        ],
      ),
      if (panoti.isNotEmpty)
        ...pdfSection(
          header: pdfSectionHeader(l10n.ssSmallPanotiHeading),
          rest: [
            pdfDataTable(
              headers: [
                l10n.ssColStart,
                l10n.ssColEnd,
                l10n.ssColDuration,
                l10n.ssColAge,
                l10n.ssColSeverity,
              ],
              fontSize: 9,
              rows: [
                for (final p in panoti)
                  [
                    _fmt.format(p.start.toLocal()),
                    _fmt.format(p.end.toLocal()),
                    _lenText(l10n, p.length),
                    _ageSpanBare(birth, p.start, p.end),
                    severityTag(l10n, severityOf(av, p.sign)),
                  ],
              ],
            ),
            pdfSectionGap(),
          ],
        ),
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
                  start: nearestCycle!.first.start,
                  end: nearestCycle.last.end,
                  segments: _phaseSegments(l10n, merged),
                  now: now,
                  legend: _phaseLegend(l10n),
                ),
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
                start: cycles[i].first.start,
                end: cycles[i].last.end,
                segments: _phaseSegments(l10n, mergeCycleByLabel(cycles[i])),
                now: now,
                legend: _phaseLegend(l10n),
              ),
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

/// One shaded block of [_SadeSatiTimeline].
///
/// Method-NEUTRAL by construction: the classical body fills these from
/// its merged phases, the degree body from its windows and the
/// retrograde gaps between them. Keeping the bar ignorant of both
/// vocabularies is what lets one widget serve two definitions — it
/// knows only "this much time, this colour, this tooltip".
class _BarSegment {
  const _BarSegment({
    required this.duration,
    required this.color,
    required this.tooltip,
  });

  final Duration duration;
  final Color color;
  final String tooltip;
}

/// Classical segments: one per merged phase, coloured by phase.
List<_BarSegment> _phaseSegments(
        AppLocalizations l10n, List<MergedSadeSatiPhase> merged) =>
    [
      for (final m in merged)
        _BarSegment(
          duration: m.duration,
          color: _phaseColor(m.kind),
          tooltip: '${m.kind.label(l10n)}\n'
              '${_fmt.format(m.start.toLocal())} – '
              '${_fmt.format(m.end.toLocal())}'
              '${m.hasReentries ? '\n${l10n.ssTooltipRetroNote}' : ''}',
        ),
    ];

/// Degree-method shades, chosen to RHYME with the classical bar rather
/// than to invent a second vocabulary: approaching takes the Rising
/// shade, separating the Setting shade, and the retrograde gap the
/// palest wash. The conjunction — the degree method's answer to Peak —
/// is not a band at all but an instant, so it is a tick, in the solid
/// Peak colour ([_degreeTickColor]).
Color _degreeSpanColor(DegreeSpanKind kind) => switch (kind) {
      DegreeSpanKind.approaching => _phaseColor(SadeSatiPhaseKind.rising),
      DegreeSpanKind.separating => _phaseColor(SadeSatiPhaseKind.setting),
      DegreeSpanKind.outOfArc => KJColors.maroon.withValues(alpha: 0.18),
    };

Color get _degreeTickColor => _phaseColor(SadeSatiPhaseKind.peak);

String _degreeSpanLabel(AppLocalizations l10n, DegreeSpanKind kind) =>
    switch (kind) {
      DegreeSpanKind.approaching => l10n.ssDegLegendApproaching,
      DegreeSpanKind.separating => l10n.ssDegLegendSeparating,
      DegreeSpanKind.outOfArc => l10n.ssDegLegendOutOfArc,
    };

/// Degree segments: one per [degreeArcSpans] stretch, so an in-arc
/// window that contains a conjunction is drawn as two differently
/// shaded halves rather than one flat block.
List<_BarSegment> _degreeSegments(
        AppLocalizations l10n, List<SadeSatiDegreeWindow> passage) =>
    [
      for (final s in degreeArcSpans(passage))
        _BarSegment(
          duration: s.length,
          color: _degreeSpanColor(s.kind),
          tooltip: s.kind == DegreeSpanKind.outOfArc
              ? _outOfArcText(l10n, s.start, s.end)
              : '${_degreeSpanLabel(l10n, s.kind)}\n'
                  '${_fmt.format(s.start.toLocal())} – '
                  '${_fmt.format(s.end.toLocal())}',
        ),
    ];

/// The legend rows under a bar. Both methods get one: a user reading
/// three unexplained shades had to ASK what they meant, which is the
/// whole reason this exists.
List<(Color, String)> _phaseLegend(AppLocalizations l10n) => [
      for (final k in const [
        SadeSatiPhaseKind.rising,
        SadeSatiPhaseKind.peak,
        SadeSatiPhaseKind.setting,
      ])
        (_phaseColor(k), k.label(l10n)),
    ];

List<(Color, String)> _degreeLegend(AppLocalizations l10n) => [
      (
        _degreeSpanColor(DegreeSpanKind.approaching),
        l10n.ssDegLegendApproaching
      ),
      (_degreeTickColor, l10n.ssDegLegendConjunction),
      (_degreeSpanColor(DegreeSpanKind.separating), l10n.ssDegLegendSeparating),
      (_degreeSpanColor(DegreeSpanKind.outOfArc), l10n.ssDegLegendOutOfArc),
    ];

/// The gap between two windows of one passage: Saturn retrograded back
/// OUT of the arc and will re-enter. Worded for what the degree method
/// actually sees — no "re-entry into the sign", which is not a thing
/// here.
String _outOfArcText(AppLocalizations l10n, DateTime start, DateTime end) =>
    l10n.ssDegOutOfArc(
      _fmt.format(start.toLocal()),
      _fmt.format(end.toLocal()),
      _lenText(l10n, end.difference(start)),
    );

class _SadeSatiTimeline extends StatelessWidget {
  const _SadeSatiTimeline({
    required this.start,
    required this.end,
    required this.segments,
    required this.now,
    this.ticks = const [],
    this.tickColor,
    this.legend = const [],
  });

  /// Span the bar covers end to end (the footer line's dates).
  final DateTime start;
  final DateTime end;
  final List<_BarSegment> segments;
  final DateTime now;

  /// Instants marked with a hairline inside the bar. The degree method
  /// passes its exact conjunctions — a moment, not a band, so it gets a
  /// tick rather than a segment. Classical callers pass none and the
  /// bar renders exactly as it did before ticks existed.
  final List<DateTime> ticks;
  final Color? tickColor;

  /// (swatch colour, label) pairs shown under the bar.
  final List<(Color, String)> legend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalSec = end.difference(start).inSeconds;
    if (totalSec <= 0 || segments.isEmpty) return const SizedBox.shrink();

    final segTotalSec =
        segments.fold(0, (a, m) => a + m.duration.inSeconds).clamp(1, 1 << 62);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth - 2;
      final widths = <double>[];
      var used = 0.0;
      for (var i = 0; i < segments.length; i++) {
        if (i == segments.length - 1) {
          widths.add(w - used);
        } else {
          final seg = w * segments[i].duration.inSeconds / segTotalSec;
          widths.add(seg);
          used += seg;
        }
      }
      // Needle position: simple fraction of the full span
      // (start..end) — a documented simplification, since the classical
      // body's merged segment widths compress out small internal
      // non-SS gaps (see [MergedSadeSatiPhase]) and precisely
      // re-deriving "now"'s position within that compressed space isn't
      // worth the complexity for a position marker. (The degree body's
      // segments tile their passage exactly, so there the needle is
      // exact.)
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
                      for (var i = 0; i < segments.length; i++)
                        Tooltip(
                          message: segments[i].tooltip,
                          textAlign: TextAlign.center,
                          child: Container(
                            width: widths[i],
                            height: 22,
                            color: segments[i].color,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Ticks sit INSIDE the bar and are thin and coloured; the
              // needle overhangs it, is wider, and is ink-black on a
              // paper halo. Nobody should have to work out which is
              // which.
              for (final t in ticks)
                if (!t.isBefore(start) && !t.isAfter(end))
                  Positioned(
                    left: (1 + w * (t.difference(start).inSeconds / totalSec))
                        .clamp(1.0, w + 1.0)
                        .toDouble(),
                    top: 0,
                    bottom: 0,
                    child:
                        Container(width: 1.5, color: tickColor ?? KJColors.ink),
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
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 4),
            _BarLegend(items: legend),
          ],
        ],
      );
    });
  }
}

/// Swatch + label pairs under a bar. Wraps, so four degree entries
/// still fit a narrow card.
class _BarLegend extends StatelessWidget {
  const _BarLegend({required this.items});
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 2,
        children: [
          for (final (color, label) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(label,
                    style: KJTheme.mono(size: 10, color: KJColors.inkSoft)),
              ],
            ),
        ],
      );
}

/// Detail view: the method selector over whichever body it selects.
///
/// The chip row is the same convention the Dasha detail uses for its
/// system selector and [ChartDetailHeader] for chart style — a Wrap of
/// ChoiceChips at the very top of the scroll view, so it scrolls away
/// with the content instead of becoming host chrome.
class _SadeSatiDetail extends StatefulWidget {
  const _SadeSatiDetail({required this.ctx});
  final ModuleContext ctx;

  @override
  State<_SadeSatiDetail> createState() => _SadeSatiDetailState();
}

class _SadeSatiDetailState extends State<_SadeSatiDetail> {
  /// Seeded from the instance config, then owned locally: the chip
  /// responds immediately instead of waiting on the write-back, and the
  /// selector still works when the screen was opened WITHOUT a card
  /// behind it (onConfigChanged null — Mahakosh, compare) where there
  /// is nothing to persist to.
  late bool _degrees = isDegreeMethod(widget.ctx.config);

  void _select(String method) => setState(() {
        _degrees = method == 'degrees';
        widget.ctx.onConfigChanged
            ?.call({...widget.ctx.config, kSadeSatiMethodKey: method});
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Labels and stored values come from the module's own declared
    // choice, so this selector and the card's '···' sheet cannot drift.
    final options = const SadeSatiModule()
        .configChoices(l10n)
        .firstWhere((c) => c.key == kSadeSatiMethodKey)
        .options;
    final selected = _degrees ? 'degrees' : 'signs';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final (value, label) in options)
                ChoiceChip(
                  label: Text(label),
                  selected: selected == value,
                  labelStyle: TextStyle(
                      color: selected == value ? KJColors.paper : KJColors.ink),
                  onSelected: (_) => _select(value),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_degrees)
            _SadeSatiDegreeBody(ctx: widget.ctx, detailed: true)
          else
            _SadeSatiBody(ctx: widget.ctx, detailed: true),
        ],
      ),
    );
  }
}

/// Degree-mode card/detail. Owns the two live inputs the pure
/// [SadeSatiDegreeView] cannot compute for itself: the memoized
/// lifetime scan ([sadeSatiDegreeWindowsProvider]) and Saturn's
/// longitude right now. Splitting them apart is what lets the view be
/// pumped in a widget test with no ephemeris behind it.
class _SadeSatiDegreeBody extends ConsumerWidget {
  const _SadeSatiDegreeBody({required this.ctx, required this.detailed});
  final ModuleContext ctx;
  final bool detailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(sadeSatiDegreeWindowsProvider(ctx.kundli.id));
    return async.when(
      loading: () => const SizedBox(
          height: 60, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.ssComputeError('$e')),
      data: (windows) {
        final now = DateTime.now().toUtc();
        return SadeSatiDegreeView(
          windows: windows,
          moonLon: ctx.snapshot.positions[Planet.moon]!.longitude,
          saturnLon: ref
              .watch(currentSaturnLongitudeProvider(ctx.snapshot.ayanamsaId)),
          ashtakavarga: ctx.ashtakavarga,
          birth: ctx.snapshot.birth.dateTimeUtc,
          now: now,
          detailed: detailed,
        );
      },
    );
  }
}

/// The degree method's presentation, pure in its inputs and organised
/// the way the classical body is: a status line, the definition
/// caption, then one section per PASSAGE — section label, timeline
/// bar, span line, and the passage's window rows with its retrograde
/// gaps as indented sub-rows.
///
/// What it deliberately does NOT borrow: rising/peak/setting labels,
/// small panoti, and per-window BAV/SAV. The first two are sign
/// definitions and mean nothing on a 90° arc; the third is sign-domain
/// data that, listed against degree windows, would read as though the
/// arc were divided into signs. The classical tab is one tap away for
/// all three. (Saturn's CURRENT bindus do appear, once, in the status
/// line — that is a fact about where Saturn is, not about the method.)
class SadeSatiDegreeView extends StatelessWidget {
  const SadeSatiDegreeView({
    super.key,
    required this.windows,
    required this.moonLon,
    required this.saturnLon,
    required this.ashtakavarga,
    required this.birth,
    required this.now,
    required this.detailed,
  });

  final List<SadeSatiDegreeWindow> windows;
  final double moonLon;
  final double saturnLon;
  final Ashtakavarga ashtakavarga;
  final DateTime birth;
  final DateTime now;
  final bool detailed;

  /// The passage in progress, else the next one — the card's subject,
  /// mirroring the classical card's `currentCycle ?? nearestCycle`.
  List<SadeSatiDegreeWindow>? _nearest(
      List<List<SadeSatiDegreeWindow>> passages) {
    for (final p in passages) {
      if (p.any((w) => w.contains(now))) return p;
    }
    for (final p in passages) {
      if (p.first.start.isAfter(now)) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final separation = sadeSatiSeparation(saturnLon, moonLon);
    final current = currentDegreeWindow(windows, now);
    final passages = groupDegreeWindows(windows);
    // Saturn's bindus in the sign it is transiting RIGHT NOW — see
    // [degreeStatusLine]'s severity parameter.
    final severity = severityTag(
        l10n, severityOf(ashtakavarga, ZodiacSign.fromLongitude(saturnLon)));

    final status = Text(
      degreeStatusLine(l10n, windows, separation, now, severity: severity),
      style: TextStyle(
        fontSize: detailed ? 15 : 14,
        fontWeight: FontWeight.w600,
        color: current != null ? KJColors.maroon : KJColors.ink,
      ),
    );
    final caption = Text(l10n.ssDegCaption,
        style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft));

    if (windows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          status,
          const SizedBox(height: 4),
          caption,
          const SizedBox(height: 8),
          Text(l10n.ssDegNoWindows,
              style: KJTheme.mono(size: 11, color: KJColors.inkSoft)),
        ],
      );
    }

    // The card carries one bar for the passage in progress (or the next
    // one) and nothing else — the same shape as the classical card.
    if (!detailed) {
      final nearest = _nearest(passages);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          status,
          const SizedBox(height: 4),
          caption,
          if (nearest != null) ...[
            const SizedBox(height: 10),
            _bar(l10n, nearest),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        status,
        const SizedBox(height: 4),
        caption,
        const SizedBox(height: 14),
        for (var i = 0; i < passages.length; i++) ...[
          // Same label, style and l10n string as the classical body's
          // cycle sections — 'CYCLE n' says nothing method-specific.
          Text(l10n.ssCycleHeading('${i + 1}'),
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  color: KJColors.inkSoft,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _bar(l10n, passages[i]),
          const SizedBox(height: 8),
          _passageRows(l10n, passages[i]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _bar(AppLocalizations l10n, List<SadeSatiDegreeWindow> passage) =>
      _SadeSatiTimeline(
        start: passage.first.start,
        end: passage.last.end,
        segments: _degreeSegments(l10n, passage),
        now: now,
        ticks: [for (final w in passage) ...w.conjunctions],
        tickColor: _degreeTickColor,
        legend: _degreeLegend(l10n),
      );

  /// A passage's rows: each window, with the retrograde gap to the next
  /// one as an indented sub-row in the classical body's sub-row style.
  Widget _passageRows(
          AppLocalizations l10n, List<SadeSatiDegreeWindow> passage) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < passage.length; i++) ...[
            _windowRow(l10n, passage[i]),
            if (i + 1 < passage.length)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  _outOfArcText(l10n, passage[i].end, passage[i + 1].start),
                  style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: KJColors.inkSoft),
                ),
              ),
          ],
        ],
      );

  Widget _windowRow(AppLocalizations l10n, SadeSatiDegreeWindow w) {
    final active = w.contains(now);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fmt.format(w.start.toLocal())} – ${_fmt.format(w.end.toLocal())}'
            ' · ${_lenText(l10n, w.length)}'
            ' · ${_ageSpan(l10n, birth, w.start, w.end)}',
            style: KJTheme.mono(
              size: 11.5,
              color: active ? KJColors.maroon : KJColors.ink,
            ),
          ),
          for (final c in w.conjunctions)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                l10n.ssDegConjunctionRow(_fmt.format(c.toLocal())),
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
}
