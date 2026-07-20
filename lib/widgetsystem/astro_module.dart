/// The shared widget contract (brief §2.8). The dashboard, the Arrange
/// customizer, and the PDF exporter all loop over the registry of
/// enabled modules — none of them know what's inside a module; they
/// render whatever the module hands back.
///
/// Adding a new module later = implement the pieces below + register
/// it in [moduleRegistry]. It then automatically appears in
/// "+ Add Module", becomes toggleable/reorderable, and participates
/// in PDF export with no changes to the three host surfaces.
library;

import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../charts/chart_style.dart';
import '../core/astro/ashtakavarga.dart';
import '../core/astro/dasha/dasha.dart';
import '../core/astro/dasha/dasha_registry.dart';
import '../core/astro/models.dart';
import '../data/models.dart';
import '../l10n/gen/app_localizations.dart';
export '../data/models.dart' show CardSpan;

/// metadata — id, title, icon, category, default size.
class ModuleMeta {
  const ModuleMeta({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    this.localizedTitle,
    this.defaultSpan = CardSpan.half,
    this.hasDetailView = true,
  });

  final String id; // stable — persisted in view_widgets rows

  /// English title — the stable fallback (and what tests assert on).
  final String title;

  /// Locale-aware title (a static tear-off so the meta stays const);
  /// hosts render [titleFor], never [title] directly.
  final String Function(AppLocalizations l10n)? localizedTitle;

  final IconData icon;
  final String category; // stable grouping key — display via l10n
  final CardSpan defaultSpan;
  final bool hasDetailView;

  String titleFor(AppLocalizations l10n) => localizedTitle?.call(l10n) ?? title;
}

/// A declarative per-instance config option. Modules expose these;
/// host surfaces (dashboard '···' sheet, Arrange) render them
/// generically — hosts never know module internals (brief §2.8).
class ModuleConfigChoice {
  const ModuleConfigChoice({
    required this.key,
    required this.label,
    required this.options, // (storedValue, displayLabel)
    this.defaultValue,
    this.toggleOnValue,
  });

  final String key;
  final String label;
  final List<(String, String)> options;

  /// The value treated as selected when the key is absent from the
  /// instance config. Defaults to the first option, so options can be
  /// listed in a consistent display order (e.g. Hide before Show)
  /// independently of which one is the default.
  final String? defaultValue;

  /// For a plain Hide/Show choice, the stored value meaning "shown"
  /// ('on' or 'show' — both conventions are in use). Non-null marks the
  /// choice as a binary toggle; hosts render those as one selectable
  /// pill grouped with other toggles instead of a full Hide/Show
  /// section. Declared EXPLICITLY (never derived from display labels —
  /// labels are localized, see l10n.hide/l10n.show).
  final String? toggleOnValue;

  String get effectiveDefault => defaultValue ?? options.first.$1;

  bool get isBinaryToggle => toggleOnValue != null;

  /// The stored value meaning "shown"; null when not a toggle.
  String? get onValue => toggleOnValue;

  /// The stored value meaning "hidden"; null when not a toggle.
  String? get offValue {
    final on = toggleOnValue;
    if (on == null) return null;
    return options.firstWhere((o) => o.$1 != on).$1;
  }
}

/// The standard Hide/Show option pair for a binary toggle choice, in
/// the canonical display order. Pass `toggleOnValue: 'on'` alongside.
List<(String, String)> onOffOptions(AppLocalizations l10n) =>
    [('off', l10n.hide), ('on', l10n.show)];

/// dataSource — everything a module may pull from, built once per
/// chart. Dasha trees are computed lazily and memoized here so
/// multiple modules share one calculation.
class ModuleContext {
  ModuleContext({
    required this.kundli,
    required this.snapshot,
    required this.chartStyle,
    this.config = const {},
    this.anonymized = false,
    this.onConfigChanged,
    AppLocalizations? l10n,
  }) : _l10n = l10n;

  final Kundli kundli;
  final AstroSnapshot snapshot;
  final ChartStyle chartStyle;

  /// True for anonymized community (Mahakosh) charts. Modules must not
  /// reveal the exact birth time when set — e.g. the Dasha module drops
  /// to date-only precision, since dasha periods begin at the birth
  /// instant and clock-precision boundaries would expose it.
  final bool anonymized;

  /// Per-instance settings (brief §2.8 config hook), e.g. the Dasha
  /// module pinning which system shows on its compact card.
  final Map<String, dynamic> config;

  /// Persist a change to this instance's [config]. Non-null only on the
  /// detail screen, which owns the write-back to the dashboard widget
  /// row (and thus keeps the card and detail in sync). Null on the
  /// dashboard card and PDF, where a module must not mutate its config —
  /// there such controls behave as ephemeral, local-only state.
  final void Function(Map<String, dynamic> config)? onConfigChanged;

  final AppLocalizations? _l10n;

  /// Localized strings for the context-free render path (pdfView has no
  /// BuildContext). Widget paths should prefer `context.l10n`. Falls
  /// back to English when the host didn't inject one (e.g. tests).
  AppLocalizations get l10n =>
      _l10n ?? lookupAppLocalizations(const Locale('en'));

  /// Copy with localized strings injected (see [l10n]); the PDF export
  /// screen calls this before handing the context to the exporter.
  ModuleContext withL10n(AppLocalizations l10n) {
    final ctx = ModuleContext(
      kundli: kundli,
      snapshot: snapshot,
      chartStyle: chartStyle,
      config: config,
      anonymized: anonymized,
      onConfigChanged: onConfigChanged,
      l10n: l10n,
    );
    ctx._dashaCache.addAll(_dashaCache);
    ctx._ashtakavarga = _ashtakavarga;
    return ctx;
  }

  final Map<DashaSystem, DashaResult> _dashaCache = {};

  DashaResult dasha(DashaSystem system) => _dashaCache.putIfAbsent(
        system,
        () => dashaCalculators[system]!.calculate(snapshot),
      );

  /// Shared Ashtakavarga (BAV/SAV) calculator — one instance per chart,
  /// reused by any module that needs bindu counts (e.g. Sade Sati's
  /// severity tags) instead of recomputing them.
  Ashtakavarga? _ashtakavarga;
  Ashtakavarga get ashtakavarga => _ashtakavarga ??= Ashtakavarga(snapshot);

  ModuleContext withConfig(
    Map<String, dynamic> config, {
    void Function(Map<String, dynamic> config)? onConfigChanged,
  }) {
    final ctx = ModuleContext(
      kundli: kundli,
      snapshot: snapshot,
      chartStyle: chartStyle,
      config: config,
      anonymized: anonymized,
      onConfigChanged: onConfigChanged ?? this.onConfigChanged,
      l10n: _l10n,
    );
    ctx._dashaCache.addAll(_dashaCache);
    ctx._ashtakavarga = _ashtakavarga;
    return ctx;
  }
}

/// The module contract.
abstract class AstroModule {
  const AstroModule();

  ModuleMeta get meta;

  /// Compact dashboard card body (host provides the card chrome).
  Widget cardView(BuildContext context, ModuleContext ctx);

  /// Optional full-screen tap-in view body (host provides Scaffold).
  /// Default: the card content with safe padding and scroll — modules
  /// overriding this must provide their own padding.
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: cardView(context, ctx),
      );

  /// PDF export layout blocks for this module. Returns a LIST of
  /// top-level widgets (header, tables, …) rather than one wrapped
  /// Column: MultiPage can only paginate between top-level children,
  /// so long tables must not be buried inside a single unsplittable
  /// widget (PdfTooBigPageException otherwise).
  List<pw.Widget> pdfView(ModuleContext ctx);

  /// Per-instance config options, rendered generically by hosts.
  /// Labels and option display strings come from [l10n]; stored values
  /// stay locale-independent (they're persisted in view_widgets rows).
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => const [];

  /// Short label describing an instance's config (shown on the card
  /// header and in Arrange), e.g. 'D9' or 'South Indian'. Null = none.
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) =>
      null;
}

/// Card/app-bar/checklist title for a module instance — the localized
/// module title plus its config summary when one exists
/// ('Divisional Chart · D9'). Shared by every host surface.
String moduleInstanceTitle(
  AstroModule module,
  Map<String, dynamic> config,
  AppLocalizations l10n,
) {
  final summary = module.configSummary(config, l10n);
  return summary == null
      ? module.meta.titleFor(l10n)
      : '${module.meta.titleFor(l10n)} · $summary';
}
