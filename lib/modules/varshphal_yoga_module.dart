/// Tajika Yogas — the sixteen inter-planetary yogas of the varsha
/// chart (Charak ch. X; engine in core/astro/tajika_yoga.dart).
/// Verdict-free: formations are listed with their orbs and qualifiers.
/// The karyesha house is configurable (default 10th); the widget
/// follows the shared varsha year.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/models.dart';
import '../core/astro/tajika_yoga.dart';
import '../core/astro/varshphal.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';

String _title(AppLocalizations l10n) => l10n.moduleVarshphalYogaTitle;

int _karyeshaHouse(Map<String, dynamic> config) =>
    int.tryParse('${config['karyesha_house'] ?? ''}') ?? 10;

String _yogaName(AppLocalizations l10n, TajikaYogaType t) => switch (t) {
      TajikaYogaType.ikabala => l10n.tyIkabala,
      TajikaYogaType.ikabalaPartial => l10n.tyIkabalaPartial,
      TajikaYogaType.induvara => l10n.tyInduvara,
      TajikaYogaType.induvaraPartial => l10n.tyInduvaraPartial,
      TajikaYogaType.vartamanaIthasala => l10n.tyVartamana,
      TajikaYogaType.poornaIthasala => l10n.tyPoorna,
      TajikaYogaType.bhavishyatIthasala => l10n.tyBhavishyat,
      TajikaYogaType.rashyantaIthasala => l10n.tyRashyanta,
      TajikaYogaType.ishrafa => l10n.tyIshrafa,
      TajikaYogaType.nakta => l10n.tyNakta,
      TajikaYogaType.yamaya => l10n.tyYamaya,
      TajikaYogaType.manau => l10n.tyManau,
      TajikaYogaType.kamboola => l10n.tyKamboola,
      TajikaYogaType.gairiKamboola => l10n.tyGairiKamboola,
      TajikaYogaType.khallasara => l10n.tyKhallasara,
      TajikaYogaType.rudda => l10n.tyRudda,
      TajikaYogaType.duhphaliKuttha => l10n.tyDuhphali,
      TajikaYogaType.dutthotthaDavira => l10n.tyDutthottha,
      TajikaYogaType.tambira => l10n.tyTambira,
      TajikaYogaType.kuttha => l10n.tyKuttha,
      TajikaYogaType.durpaha => l10n.tyDurpaha,
    };

/// Ishrafa and the negating/afflicting yogas read maroon; links and
/// formations read forest.
bool _adverse(TajikaYogaType t) => const {
      TajikaYogaType.ishrafa,
      TajikaYogaType.manau,
      TajikaYogaType.khallasara,
      TajikaYogaType.rudda,
      TajikaYogaType.duhphaliKuttha,
      TajikaYogaType.durpaha,
      TajikaYogaType.induvara,
      TajikaYogaType.induvaraPartial,
    }.contains(t);

String _disp(AppLocalizations l10n, String token) => switch (token) {
      'excellent' => l10n.tyDispExcellent,
      'good' => l10n.tyDispGood,
      'inferior' => l10n.tyDispInferior,
      _ => l10n.tyDispMediocre,
    };

String _fmtOrb(double deg) {
  final d = deg.floor();
  final m = ((deg - d) * 60).round();
  return '$d°${m.toString().padLeft(2, '0')}′';
}

class VarshphalYogaModule extends AstroModule {
  const VarshphalYogaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_yogas',
        title: 'Tajika Yogas',
        localizedTitle: _title,
        icon: Icons.join_inner_outlined,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'karyesha_house',
          label: l10n.tyKaryeshaHouse,
          options: [
            for (var h = 1; h <= 12; h++) ('$h', l10n.tyHouseN('$h')),
          ],
          defaultValue: '10',
        ),
      ];

  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) {
    final h = _karyeshaHouse(config);
    return h == 10 ? null : l10n.tyHouseN('$h');
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _YogaBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _YogaBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    // Varsha-dependent, screen-reading tool — same call as the other
    // varsha widgets: the PDF carries the Varshphal Chart section.
    return const [];
  }
}

class _YogaBody extends ConsumerWidget {
  const _YogaBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  String _tagText(AppLocalizations l10n, TajikaYoga y, String tag) {
    if (tag == 'slow-retrograde') return l10n.tyTagSlowRetro;
    if (tag == 'contiguous') return l10n.tyTagContiguous;
    final sep = tag.indexOf(':');
    if (sep <= 0) return tag;
    final head = tag.substring(0, sep);
    final rest = tag.substring(sep + 1);
    if (head == 'moon') return l10n.tyTagMoonState(_disp(l10n, rest));
    if (head == 'pair') return l10n.tyTagPartnerState(_disp(l10n, rest));
    if (head == 'slow' || head == 'fast') {
      final p = head == 'slow' ? y.planets.last : y.planets.first;
      return '${p.abbrLabel(l10n)} ${_disp(l10n, rest)}';
    }
    // '<planet>:<disqualification>' from Rudda.
    final planet = Planet.values.asNameMap()[head];
    final abbr = planet?.abbrLabel(l10n) ?? head;
    final what = switch (rest) {
      'combust' => l10n.tyTagCombust,
      'debilitated' => l10n.tyTagDebilitated,
      'trik' => l10n.tyTagTrik,
      'enemy-sign' => l10n.tyTagEnemySign,
      _ => rest,
    };
    return '$abbr $what';
  }

  Widget _row(AppLocalizations l10n, TajikaYoga y) {
    final color = _adverse(y.type) ? KJColors.maroon : KJColors.forest;
    final pair = y.planets.length <= 2
        ? y.planets.map((p) => p.abbrLabel(l10n)).join('–')
        : y.planets.map((p) => p.abbrLabel(l10n)).join(' ');
    final extras = <String>[
      if (y.linker != null) l10n.tyVia(y.linker!.abbrLabel(l10n)),
      for (final t in y.tags) _tagText(l10n, y, t),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 74,
                child: Text(pair,
                    style: KJTheme.mono(size: 11.5, weight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(_yogaName(l10n, y.type),
                    style: KJTheme.mono(
                        size: 11.5, color: color, weight: FontWeight.w600)),
              ),
              if (y.orb != null)
                Text(_fmtOrb(y.orb!),
                    style: KJTheme.mono(size: 11, color: KJColors.inkSoft)),
            ],
          ),
          if (extras.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 74),
              child: Text(extras.join(' · '),
                  style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final natal = ctx.snapshot;
    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final async = ref.watch(varshphalProvider((ctx.kundli.id, year)));

    return async.when(
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.vpError('$e')),
      data: (d) {
        final scan = scanTajikaYogas(d.snapshot,
            karyeshaHouse: _karyeshaHouse(ctx.config));
        final involved = scan.pairYogas
            .where((y) =>
                y.planets.contains(scan.lagnesha) ||
                y.planets.contains(scan.karyesha))
            .toList();
        final shown = detail ? scan.pairYogas : involved;
        final others = detail ? 0 : scan.pairYogas.length - involved.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail) ...[
              Text(l10n.moduleVarshphalYogaTitle,
                  style: KJTheme.serif(size: 18)),
              const SizedBox(height: 4),
              Text(l10n.tyBlurb,
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
              const SizedBox(height: 8),
            ],
            Text(
              l10n.vpYearLine('$year', '${d.returnUtc.toUtc().year}'),
              style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
            ),
            const SizedBox(height: 2),
            Text(
              '${l10n.tyLagnesha}: ${scan.lagnesha.abbrLabel(l10n)}'
              ' · ${l10n.tyKaryesha}: ${scan.karyesha.abbrLabel(l10n)}'
              ' (${l10n.tyHouseN('${_karyeshaHouse(ctx.config)}')})',
              style: KJTheme.mono(
                  size: 11.5, color: KJColors.maroon, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final y in scan.chartYogas) _row(l10n, y),
            if (scan.chartYogas.isNotEmpty)
              Divider(height: 10, color: KJColors.hairline),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.tyNone,
                    style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
              )
            else
              for (final y in shown) _row(l10n, y),
            if (others > 0) ...[
              const SizedBox(height: 4),
              Text(l10n.tyMoreInDetail('$others'),
                  style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
            ],
          ],
        );
      },
    );
  }
}
