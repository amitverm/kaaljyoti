/// The chip rendering of a module's [ModuleConfigChoice]s, shared by the
/// dashboard's widget menu and the PDF export screen's per-block sheet so
/// the two never drift apart. Hosts stay ignorant of module internals
/// (brief §2.8): this walks whatever choices the module declares.
library;

import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Renders [module]'s config choices against [config] and reports the
/// NEW map through [onChanged] — the caller owns persistence (the
/// dashboard writes per instance, the export screen writes the block).
///
/// Two shapes, deliberately different: a multi-value choice keeps its own
/// labelled section of single-select chips, while every binary on/off
/// choice collapses into one grouped DISPLAY section of pills, where
/// selected simply means shown. A screen full of Hide/Show rows is noise;
/// a row of pills reads at a glance.
class ModuleConfigChips extends StatelessWidget {
  const ModuleConfigChips({
    super.key,
    required this.module,
    required this.config,
    required this.onChanged,
  });

  final AstroModule module;
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final choices = module.configChoices(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final choice in choices)
          if (!choice.isBinaryToggle) ...[
            const SizedBox(height: 16),
            KJSectionLabel(choice.label.toUpperCase()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in choice.options)
                  ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 12.5)),
                    selected: (config[choice.key] ?? choice.effectiveDefault) ==
                        value,
                    labelStyle: TextStyle(
                        fontSize: 12.5,
                        color:
                            (config[choice.key] ?? choice.effectiveDefault) ==
                                    value
                                ? KJColors.paper
                                : KJColors.ink),
                    onSelected: (_) =>
                        onChanged({...config, choice.key: value}),
                  ),
              ],
            ),
          ],
        if (choices.any((c) => c.isBinaryToggle)) ...[
          const SizedBox(height: 16),
          const KJSectionLabel('DISPLAY'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in choices)
                if (choice.isBinaryToggle)
                  FilterChip(
                    label: Text(choice.label,
                        style: const TextStyle(fontSize: 12.5)),
                    selected: (config[choice.key] ?? choice.effectiveDefault) ==
                        choice.onValue,
                    checkmarkColor: KJColors.paper,
                    labelStyle: TextStyle(
                        fontSize: 12.5,
                        color:
                            (config[choice.key] ?? choice.effectiveDefault) ==
                                    choice.onValue
                                ? KJColors.paper
                                : KJColors.ink),
                    onSelected: (sel) => onChanged({
                      ...config,
                      choice.key: sel ? choice.onValue! : choice.offValue!,
                    }),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}
