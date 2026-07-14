/// Settings — app preferences that used to live on the Profile screen:
/// date format, default ayanamsa, default chart style, and appearance.
/// All are stored locally (SharedPreferences) and do not sync across
/// devices.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../charts/chart_style.dart';
import '../charts/chart_tuning.dart';
import '../core/astro/ayanamsa.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final ayanamsa = ref.watch(defaultAyanamsaProvider);
    final dateFormat = ref.watch(dateFormatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _label('DATE FORMAT'),
          Card(
            child: Column(
              children: [
                for (final pref in DateFormatPref.values) ...[
                  if (pref != DateFormatPref.values.first)
                    const Divider(height: 1),
                  RadioListTile<DateFormatPref>(
                    value: pref,
                    groupValue: dateFormat,
                    activeColor: TEColors.maroon,
                    onChanged: (p) {
                      if (p != null) {
                        ref.read(dateFormatProvider.notifier).update(p);
                      }
                    },
                    title: Text(pref.sample,
                        style: const TextStyle(fontSize: 14.5)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Applies everywhere dates appear. Spelled-out formats avoid any '
            'day/month confusion; numeric formats are more compact.',
            style: TextStyle(fontSize: 12, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 20),
          _label('DEFAULTS'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Default ayanamsa'),
                  subtitle: Text(
                    '${Ayanamsa.byId(ayanamsa.value ?? Ayanamsa.lahiri.id).name}'
                    ' — overridable per kundli',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _pickAyanamsa,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default chart style'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _pickChartStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label('CHART TEXT FORMAT'),
          _chartTextCard(),
          const SizedBox(height: 6),
          Text(
            'How planets, degrees and signs render inside the charts. '
            'Changes apply to every chart immediately.',
            style: TextStyle(fontSize: 12, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 20),
          _label('APPEARANCE'),
          _appearanceCard(),
        ],
      ),
    );
  }

  /// Chart text rendering settings. Writes go to the global
  /// [chartTuning] notifier (charts repaint live) and are persisted
  /// via [SettingsRepository].
  Widget _chartTextCard() {
    return ValueListenableBuilder<ChartTuning>(
      valueListenable: chartTuning,
      builder: (context, t, _) {
        void set(ChartTuning next) {
          chartTuning.value = next;
          ref.read(settingsRepoProvider).setChartText(next);
        }

        Widget sliderRow({
          required String label,
          required double value,
          required double min,
          required double max,
          required int divisions,
          required ValueChanged<double> onChanged,
        }) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13.5)),
                    Text('${(value * 100).round()}%',
                        style:
                            TETheme.mono(size: 12, color: TEColors.inkSoft)),
                  ],
                ),
                Slider(
                  value: value.clamp(min, max).toDouble(),
                  min: min,
                  max: max,
                  divisions: divisions,
                  activeColor: TEColors.maroon,
                  onChanged: onChanged,
                ),
              ],
            );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sliderRow(
                  label: 'Planet size',
                  value: t.baseScale,
                  min: 0.7,
                  max: 1.6,
                  divisions: 18,
                  onChanged: (v) => set(t.copyWith(baseScale: v)),
                ),
                sliderRow(
                  label: 'Degrees & marks size',
                  value: t.annotationScale,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (v) => set(t.copyWith(annotationScale: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Bold planet names',
                      style: TextStyle(fontSize: 13.5)),
                  activeThumbColor: TEColors.maroon,
                  value: t.weight != FontWeight.w400,
                  onChanged: (v) => set(t.copyWith(
                      weight: v ? FontWeight.w600 : FontWeight.w400)),
                ),
                const SizedBox(height: 4),
                const Text('Degree detail', style: TextStyle(fontSize: 13.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (minutes, label) in const [
                      (true, "Minutes — 23°41'"),
                      (false, 'Whole — 23°'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: t.degreeMinutes == minutes,
                        labelStyle: TextStyle(
                            color: t.degreeMinutes == minutes
                                ? TEColors.paper
                                : TEColors.ink),
                        onSelected: (_) =>
                            set(t.copyWith(degreeMinutes: minutes)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: const Text('Fine-tuning',
                      style: TextStyle(fontSize: 13.5)),
                  children: [
                    sliderRow(
                      label: 'Smallest allowed size',
                      value: t.minFontScale,
                      min: 0.3,
                      max: 1.0,
                      divisions: 14,
                      onChanged: (v) => set(t.copyWith(minFontScale: v)),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'In a crowded house the text shrinks to fit, but '
                        'never below this fraction of its normal size.',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                    sliderRow(
                      label: 'Sign label size',
                      value: t.signScale,
                      min: 0.7,
                      max: 1.5,
                      divisions: 16,
                      onChanged: (v) => set(t.copyWith(signScale: v)),
                    ),
                    sliderRow(
                      label: 'Text area within house',
                      value: t.contentInflate,
                      min: 1.0,
                      max: 1.35,
                      divisions: 7,
                      onChanged: (v) => set(t.copyWith(contentInflate: v)),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => set(ChartTuning.defaults),
                    child: const Text('Reset to defaults'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _appearanceCard() {
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Text size', style: TextStyle(fontSize: 13.5)),
                Text('${(appearance.textScale * 100).round()}%',
                    style: TETheme.mono(size: 12, color: TEColors.inkSoft)),
              ],
            ),
            Slider(
              value: appearance.textScale,
              min: 1.0,
              max: 1.6,
              divisions: 6,
              activeColor: TEColors.maroon,
              onChanged: (v) =>
                  notifier.update(appearance.copyWith(textScale: v)),
            ),
            const SizedBox(height: 4),
            const Text('Theme', style: TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (name, label) in const [
                  ('classic', 'Classic'),
                  ('contrast', 'High contrast'),
                  ('dark', 'Dark'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: appearance.paletteName == name,
                    labelStyle: TextStyle(
                        color: appearance.paletteName == name
                            ? TEColors.paper
                            : TEColors.ink),
                    onSelected: (_) => notifier
                        .update(appearance.copyWith(paletteName: name)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Typography', style: TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (editorial, label) in const [
                  (true, 'Editorial'),
                  (false, 'Plain'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: appearance.serifHeadings == editorial,
                    labelStyle: TextStyle(
                        color: appearance.serifHeadings == editorial
                            ? TEColors.paper
                            : TEColors.ink),
                    onSelected: (_) => notifier.update(
                        appearance.copyWith(serifHeadings: editorial)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              appearance.serifHeadings
                  ? 'Editorial — Marcellus display headings with IBM Plex '
                      'for body and data. The classic look.'
                  : 'Plain — IBM Plex throughout, no serif. Cleaner and '
                      'more legible at large text sizes.',
              style: TEType.caption(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => TESectionLabel(t, padded: true);

  void _pickAyanamsa() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TEColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final a in Ayanamsa.all)
            ListTile(
              dense: true,
              title: Text(a.name),
              onTap: () async {
                await ref
                    .read(settingsRepoProvider)
                    .setDefaultAyanamsaId(a.id);
                ref.invalidate(defaultAyanamsaProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _pickChartStyle() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TEColors.paper,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          for (final s in ChartStyle.values)
            ListTile(
              dense: true,
              title: Text(s.displayName),
              onTap: () async {
                await ref
                    .read(settingsRepoProvider)
                    .setDefaultChartStyle(s.name);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
