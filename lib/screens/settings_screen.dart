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
import '../l10n/astro_l10n.dart';
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
    final language = ref.watch(languageProvider);
    final l10n = context.l10n;

    // (stored value, display label). Built from the locales gen-l10n
    // found — a new app_<code>.arb appears here on its own, no edit
    // needed. Each language's name comes from its OWN file's
    // languageEndonym, so it reads in its own script and is never
    // translated into the current UI language.
    final languageChoices = [
      ('system', l10n.languageSystemDefault),
      for (final locale in AppLocalizations.supportedLocales)
        (
          locale.languageCode,
          lookupAppLocalizations(locale).languageEndonym,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _label(l10n.languageTitle.toUpperCase()),
          Card(
            child: Column(
              children: [
                for (final (code, label) in languageChoices) ...[
                  if (code != 'system') const Divider(height: 1),
                  RadioListTile<String>(
                    value: code,
                    groupValue: language,
                    activeColor: KJColors.maroon,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(languageProvider.notifier).update(v);
                      }
                    },
                    title: Text(label, style: const TextStyle(fontSize: 14.5)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.languageSectionNote,
            style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 20),
          _label(l10n.stSectionDateFormat),
          Card(
            child: Column(
              children: [
                for (final pref in DateFormatPref.values) ...[
                  if (pref != DateFormatPref.values.first)
                    const Divider(height: 1),
                  RadioListTile<DateFormatPref>(
                    value: pref,
                    groupValue: dateFormat,
                    activeColor: KJColors.maroon,
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
            l10n.stDateFormatNote,
            style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 20),
          _label('DEFAULTS'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.stDefaultAyanamsa),
                  subtitle: Text(
                    l10n.stAyanamsaSubtitle(
                        Ayanamsa.byId(ayanamsa.value ?? Ayanamsa.lahiri.id)
                            .name),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _pickAyanamsa,
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(l10n.stDefaultChartStyle),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _pickChartStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label(l10n.stSectionChartText),
          _chartTextCard(),
          const SizedBox(height: 6),
          Text(
            l10n.stChartTextNote,
            style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
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
    final l10n = context.l10n;
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
                        style: KJTheme.mono(size: 12, color: KJColors.inkSoft)),
                  ],
                ),
                Slider(
                  value: value.clamp(min, max).toDouble(),
                  min: min,
                  max: max,
                  divisions: divisions,
                  activeColor: KJColors.maroon,
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
                  label: l10n.stPlanetSize,
                  value: t.baseScale,
                  min: 0.7,
                  max: 1.6,
                  divisions: 18,
                  onChanged: (v) => set(t.copyWith(baseScale: v)),
                ),
                sliderRow(
                  label: l10n.stDegreesMarksSize,
                  value: t.annotationScale,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (v) => set(t.copyWith(annotationScale: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.stBoldPlanetNames,
                      style: const TextStyle(fontSize: 13.5)),
                  activeThumbColor: KJColors.maroon,
                  value: t.weight != FontWeight.w400,
                  onChanged: (v) => set(t.copyWith(
                      weight: v ? FontWeight.w600 : FontWeight.w400)),
                ),
                const SizedBox(height: 4),
                Text(l10n.stDegreeDetail,
                    style: const TextStyle(fontSize: 13.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (minutes, label) in [
                      (true, l10n.stDegreeMinutes),
                      (false, l10n.stDegreeWhole),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: t.degreeMinutes == minutes,
                        labelStyle: TextStyle(
                            color: t.degreeMinutes == minutes
                                ? KJColors.paper
                                : KJColors.ink),
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
                      label: l10n.stSmallestSize,
                      value: t.minFontScale,
                      min: 0.3,
                      max: 1.0,
                      divisions: 14,
                      onChanged: (v) => set(t.copyWith(minFontScale: v)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.stSmallestSizeNote,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                    sliderRow(
                      label: l10n.stSignLabelSize,
                      value: t.signScale,
                      min: 0.7,
                      max: 1.5,
                      divisions: 16,
                      onChanged: (v) => set(t.copyWith(signScale: v)),
                    ),
                    sliderRow(
                      label: l10n.stTextAreaInHouse,
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
                    child: Text(l10n.stResetDefaults),
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
    final l10n = context.l10n;
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
                Text(l10n.stTextSize, style: const TextStyle(fontSize: 13.5)),
                Text('${(appearance.textScale * 100).round()}%',
                    style: KJTheme.mono(size: 12, color: KJColors.inkSoft)),
              ],
            ),
            Slider(
              value: appearance.textScale,
              min: 1.0,
              max: 1.6,
              divisions: 6,
              activeColor: KJColors.maroon,
              onChanged: (v) =>
                  notifier.update(appearance.copyWith(textScale: v)),
            ),
            const SizedBox(height: 4),
            Text(l10n.stTheme, style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (name, label) in [
                  ('classic', l10n.stThemeClassic),
                  ('contrast', l10n.stThemeHighContrast),
                  ('dark', l10n.stThemeDark),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: appearance.paletteName == name,
                    labelStyle: TextStyle(
                        color: appearance.paletteName == name
                            ? KJColors.paper
                            : KJColors.ink),
                    onSelected: (_) =>
                        notifier.update(appearance.copyWith(paletteName: name)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.stTypography, style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (editorial, label) in [
                  (true, l10n.stTypeEditorial),
                  (false, l10n.stTypePlain),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: appearance.serifHeadings == editorial,
                    labelStyle: TextStyle(
                        color: appearance.serifHeadings == editorial
                            ? KJColors.paper
                            : KJColors.ink),
                    onSelected: (_) => notifier
                        .update(appearance.copyWith(serifHeadings: editorial)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              appearance.serifHeadings
                  ? l10n.stTypographyNoteEditorial
                  : l10n.stTypographyNotePlain,
              style: KJType.caption(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => KJSectionLabel(t, padded: true);

  void _pickAyanamsa() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KJColors.paper,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final a in Ayanamsa.all)
            ListTile(
              dense: true,
              title: Text(a.name),
              onTap: () async {
                await ref.read(settingsRepoProvider).setDefaultAyanamsaId(a.id);
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
      backgroundColor: KJColors.paper,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          for (final s in ChartStyle.values)
            ListTile(
              dense: true,
              title: Text(s.label(context.l10n)),
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
