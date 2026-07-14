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
import 'package:pdf/widgets.dart' as pw;

import '../charts/chart_style.dart';
import '../core/astro/ashtakavarga.dart';
import '../core/astro/dasha/dasha.dart';
import '../core/astro/dasha/dasha_registry.dart';
import '../core/astro/models.dart';
import '../data/models.dart';
export '../data/models.dart' show CardSpan;

/// metadata — id, title, icon, category, default size.
class ModuleMeta {
  const ModuleMeta({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    this.defaultSpan = CardSpan.half,
    this.hasDetailView = true,
  });

  final String id; // stable — persisted in view_widgets rows
  final String title;
  final IconData icon;
  final String category; // 'Chart & Grahas', 'Timing & Dashas', …
  final CardSpan defaultSpan;
  final bool hasDetailView;
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
  });

  final String key;
  final String label;
  final List<(String, String)> options;

  /// The value treated as selected when the key is absent from the
  /// instance config. Defaults to the first option, so options can be
  /// listed in a consistent display order (e.g. Hide before Show)
  /// independently of which one is the default.
  final String? defaultValue;

  String get effectiveDefault => defaultValue ?? options.first.$1;

  /// True when this is a plain Hide/Show choice — exactly two options
  /// labelled 'Hide' and 'Show'. Hosts render these as a single
  /// selectable toggle pill (selected = the "shown" value) grouped with
  /// other toggles, instead of giving each its own Hide/Show section.
  /// Matched by label rather than stored value so both value conventions
  /// in use — 'off'/'on' and 'hide'/'show' — are covered.
  bool get isBinaryToggle => onValue != null;

  /// For a [isBinaryToggle] choice, the stored value meaning "shown"
  /// (the option whose display label is 'Show'); null otherwise.
  String? get onValue {
    if (options.length != 2) return null;
    String? label(int i) => options[i].$2.trim().toLowerCase();
    final labels = {label(0), label(1)};
    if (!labels.containsAll(const {'hide', 'show'})) return null;
    return options.firstWhere((o) => o.$2.trim().toLowerCase() == 'show').$1;
  }

  /// For a [isBinaryToggle] choice, the stored value meaning "hidden"
  /// (the option whose display label is 'Hide'); null otherwise.
  String? get offValue {
    final on = onValue;
    if (on == null) return null;
    return options.firstWhere((o) => o.$1 != on).$1;
  }
}

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
  });

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
  List<ModuleConfigChoice> configChoices() => const [];

  /// Short label describing an instance's config (shown on the card
  /// header and in Arrange), e.g. 'D9' or 'South Indian'. Null = none.
  String? configSummary(Map<String, dynamic> config) => null;
}
