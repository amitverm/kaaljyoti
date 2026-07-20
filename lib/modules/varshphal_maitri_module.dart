/// Tajika Maitri — per-planet aspect & friendship lists for the varsha
/// chart (Charak's positional rules; see core/astro/tajika.dart).
/// Follows the shared varsha year like every Varshphal widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/models.dart';
import '../core/astro/tajika.dart';
import '../core/astro/varshphal.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';

String _title(AppLocalizations l10n) => l10n.moduleVarshphalMaitriTitle;

/// One planet's categorized relations in a varsha chart.
({
  List<Planet> directFriends,
  List<Planet> hiddenFriends,
  List<Planet> directEnemies,
  List<Planet> hiddenEnemies,
  List<Planet> mutualEnemies,
}) _relationsOf(AstroSnapshot varsha, Planet p) {
  final df = <Planet>[], hf = <Planet>[], de = <Planet>[], he = <Planet>[];
  final me = <Planet>[];
  for (final other in kTajikaPlanets) {
    if (other == p) continue;
    switch (tajikaRelationBetween(varsha, p, other)) {
      case TajikaRelation.directFriend:
        df.add(other);
      case TajikaRelation.hiddenFriend:
        hf.add(other);
      case TajikaRelation.directEnemy:
        de.add(other);
      case TajikaRelation.hiddenEnemy:
        he.add(other);
      case TajikaRelation.none:
        break;
    }
    if (areMutualEnemies(varsha, p, other)) me.add(other);
  }
  return (
    directFriends: df,
    hiddenFriends: hf,
    directEnemies: de,
    hiddenEnemies: he,
    mutualEnemies: me,
  );
}

class VarshphalMaitriModule extends AstroModule {
  const VarshphalMaitriModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_maitri',
        title: 'Tajika Maitri',
        localizedTitle: _title,
        icon: Icons.handshake_outlined,
        category: 'Varshphal',
        // Compact legend rows (DF/HF/DE/HE/ME) fit a half tile; the
        // detail view spells the categories out.
        defaultSpan: CardSpan.half,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _MaitriBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _MaitriBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    // Varsha-dependent and synchronous-PDF: skipped for now — the
    // Varshphal Chart PDF carries the year context; maitri lists are a
    // screen-reading tool. Revisit when the varsha PDF section grows.
    return const [];
  }
}

class _MaitriBody extends ConsumerWidget {
  const _MaitriBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  String _names(AppLocalizations l10n, List<Planet> ps) =>
      ps.isEmpty ? '—' : ps.map((p) => p.abbrLabel(l10n)).join(' ');

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
        final varsha = d.snapshot;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail) ...[
              Text(l10n.moduleVarshphalMaitriTitle,
                  style: KJTheme.serif(size: 18)),
              const SizedBox(height: 4),
              Text(l10n.tmBlurb,
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
              const SizedBox(height: 8),
            ],
            Text(
              l10n.vpYearLine('$year', '${d.returnUtc.toUtc().year}'),
              style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
            ),
            const SizedBox(height: 6),
            if (!detail)
              // Half-tile card: one legend row per planet
              // (DF/HF/DE/HE/ME); the detail view spells them out.
              for (final p in kTajikaPlanets) _compactRow(l10n, varsha, p)
            else
              for (final p in kTajikaPlanets) ...[
                () {
                  final r = _relationsOf(varsha, p);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.label(l10n),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: planetInk(p))),
                        const SizedBox(height: 2),
                        _line(l10n.tmDirectFriends,
                            _names(l10n, r.directFriends), KJColors.forest),
                        _line(l10n.tmHiddenFriends,
                            _names(l10n, r.hiddenFriends), KJColors.forest),
                        _line(l10n.tmDirectEnemies,
                            _names(l10n, r.directEnemies), KJColors.maroon),
                        _line(l10n.tmHiddenEnemies,
                            _names(l10n, r.hiddenEnemies), KJColors.maroon),
                        if (r.mutualEnemies.isNotEmpty || detail)
                          _line(l10n.tmMutualEnemies,
                              _names(l10n, r.mutualEnemies), KJColors.maroon),
                      ],
                    ),
                  );
                }(),
                Divider(height: 8, color: KJColors.hairline),
              ],
          ],
        );
      },
    );
  }

  Widget _compactRow(AppLocalizations l10n, AstroSnapshot varsha, Planet p) {
    final r = _relationsOf(varsha, p);
    final groups = <(String, List<Planet>, Color)>[
      (l10n.tmAbbrDF, r.directFriends, KJColors.forest),
      (l10n.tmAbbrHF, r.hiddenFriends, KJColors.forest),
      (l10n.tmAbbrDE, r.directEnemies, KJColors.maroon),
      (l10n.tmAbbrHE, r.hiddenEnemies, KJColors.maroon),
      (l10n.tmAbbrME, r.mutualEnemies, KJColors.maroon),
    ].where((g) => g.$2.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(p.abbrLabel(l10n),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: planetInk(p))),
          ),
          Expanded(
            child: groups.isEmpty
                ? Text('—',
                    style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft))
                : Text.rich(
                    TextSpan(children: [
                      for (var i = 0; i < groups.length; i++) ...[
                        if (i > 0)
                          TextSpan(
                              text: ' · ',
                              style: KJTheme.mono(
                                  size: 10.5, color: KJColors.hairline)),
                        TextSpan(
                            text: '${groups[i].$1} ',
                            style: KJTheme.mono(
                                size: 10.5, color: KJColors.inkSoft)),
                        TextSpan(
                            text: _names(l10n, groups[i].$2),
                            style: KJTheme.mono(
                                size: 10.5,
                                color: groups[i].$3,
                                weight: FontWeight.w600)),
                      ],
                    ]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, Color valueColor) => Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
            ),
            Expanded(
              child: Text(value,
                  style: KJTheme.mono(
                      size: 11.5,
                      color: value == '—' ? KJColors.inkSoft : valueColor)),
            ),
          ],
        ),
      );
}
