/// "What does an absent config key mean?" must have exactly ONE answer.
///
/// A module parses its own config with a fallback (`config['varga'] ??
/// 'd9'`), while every host — the dashboard's widget menu, the PDF
/// export screen's block sheet — renders the selected chip from
/// [ModuleConfigChoice.effectiveDefault], which is `defaultValue ??
/// options.first`. When a module declares no `defaultValue`, those two
/// silently disagree.
///
/// That shipped: a Divisional block with no stored 'varga' rendered and
/// was LABELLED D9 (the module's own fallback) while its settings sheet
/// showed D2 selected (the first option) — and tapping Done changed
/// nothing, because nothing was ever out of sync in the stored data.
/// Both surfaces share [ModuleConfigChips], so both were wrong.
///
/// The generic guard below can't read a module's private fallback, so
/// it pins the invariant that MADE the mismatch possible: a
/// multi-value choice whose default is not simply its first option must
/// say so explicitly. Anything that opts out is listed with a reason.
library;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/divisional.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/modules/divisional_module.dart';
import 'package:kaaljyoti/modules/varshphal_divisional_module.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';
import 'package:kaaljyoti/widgetsystem/registry.dart';

/// What a host chip shows as selected for [key] given [config] — the
/// exact expression `ModuleConfigChips` uses.
String _chipSelection(
  AstroModule module,
  Map<String, dynamic> config,
  String key,
  AppLocalizations l10n,
) {
  final choice = module.configChoices(l10n).firstWhere((c) => c.key == key);
  return (config[key] as String?) ?? choice.effectiveDefault;
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('an unconfigured divisional block', () {
    test('renders D9 and its settings sheet agrees', () {
      const module = DivisionalChartModule();
      // What the block is labelled with (configSummary drives
      // moduleInstanceTitle).
      expect(module.configSummary(const {}, l10n), Varga.d9.code);
      // What the settings sheet shows selected.
      expect(_chipSelection(module, const {}, 'varga', l10n), Varga.d9.name);
    });

    test('the varshphal divisional block agrees too', () {
      const module = VarshphalDivisionalModule();
      expect(module.configSummary(const {}, l10n), Varga.d9.code);
      expect(_chipSelection(module, const {}, 'varga', l10n), Varga.d9.name);
    });

    test('an explicitly configured block is unaffected', () {
      const module = DivisionalChartModule();
      const config = {'varga': 'd7'};
      expect(module.configSummary(config, l10n), Varga.d7.code);
      expect(_chipSelection(module, config, 'varga', l10n), 'd7');
    });
  });

  test('every multi-value choice declares its default explicitly', () {
    // Choices whose default genuinely IS the first option, verified by
    // reading the module's own parser. Listing them here is the cost of
    // the guard, and a cheap one: a new module either declares its
    // default or shows up in this list on purpose.
    const firstOptionIsTheDefault = {
      // 'default' = inherit the kundli's style, and it is listed first.
      'style',
      // Vimshottari is DashaSystem.values.first and the parser's orElse.
      'system_dasha',
      // null/'sav' both mean SAV, which is the first option.
      'chart',
    };
    final offenders = <String>[];
    for (final module in moduleRegistry.values) {
      for (final choice in module.configChoices(l10n)) {
        if (choice.isBinaryToggle) continue; // on/off pairs are explicit
        final id = '${module.meta.id}.${choice.key}';
        final generic = choice.key == 'style'
            ? 'style'
            : (choice.key == 'system' &&
                    (module.meta.id == 'dasha' ||
                        module.meta.id == 'upcoming_events'))
                ? 'system_dasha'
                : choice.key;
        if (choice.defaultValue == null &&
            !firstOptionIsTheDefault.contains(generic)) {
          offenders.add(id);
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'these choices leave the host to guess "options.first" as '
            'the selected chip. If that is genuinely the module\'s own '
            'fallback, add the key to firstOptionIsTheDefault above; '
            'otherwise set defaultValue so the settings sheet matches '
            'what the block actually renders.');
  });
}
