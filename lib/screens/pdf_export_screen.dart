/// PDF Export screen (§2.9): the block list mirrors the dashboard's
/// widget INSTANCES (config-aware — three divisional charts export as
/// three different vargas), reorderable and editable, plus paper size,
/// cover page, and optional practitioner branding.
///
/// The composition is ONE GLOBAL TEMPLATE, not a per-kundli setting, and
/// each block keeps tracking the dashboard instance it came from until
/// it's customized here — so changing a card's settings on the dashboard
/// shows up in the next report instead of being frozen at first export.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../data/export_repository.dart';
import '../data/models.dart';
import '../pdf/pdf_exporter.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import '../state/providers.dart';
import '../widgetsystem/registry.dart';
import '../ui/common.dart';
import '../ui/module_config_chips.dart';

class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  ConsumerState<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _Entry {
  _Entry(
    this.widgetId,
    this.config,
    this.selected, {
    this.instanceId,
    this.overridden = false,
  });
  final String widgetId;

  /// The dashboard instance this block mirrors, or null for a block that
  /// has none (a registry remainder, or a duplicate made here).
  final String? instanceId;

  /// Once true the block stops following [instanceId] and renders
  /// [config] as frozen here.
  bool overridden;

  Map<String, dynamic> config;
  bool selected;

  PdfBlock get block => (widgetId: widgetId, config: config);

  ExportBlock get saved => (
        widgetId: widgetId,
        instanceId: instanceId,
        overridden: overridden,
        config: config,
      );

  String label(AppLocalizations l10n) {
    final module = moduleById(widgetId);
    if (module == null) return widgetId;
    return moduleInstanceTitle(module, config, l10n);
  }

  /// A duplicate is a block in its own right: it has no dashboard
  /// instance to follow, so its config is frozen from the moment it's
  /// made (otherwise both copies would track the same card and could
  /// never differ — the whole point of duplicating).
  _Entry copy() => _Entry(widgetId, Map.of(config), true, overridden: true);
}

class _PdfExportScreenState extends ConsumerState<PdfExportScreen> {
  List<_Entry>? _entries;
  PdfPaper _paper = PdfPaper.a4;
  bool _coverPage = true;
  final _brandingController = TextEditingController();
  bool _working = false;

  bool _hasSavedConfig = false;

  Future<void> _initSelection() async {
    if (_entries != null) return;

    // One template for every kundli. Saved blocks that still track a
    // live dashboard instance take that instance's CURRENT config, so a
    // setting changed on the dashboard reaches the next report; blocks
    // customized here, and blocks whose card has since been removed,
    // keep the config frozen with them.
    final saved = await ref.read(exportRepoProvider).load();
    if (saved != null) {
      _hasSavedConfig = true;
      _paper = saved.paper == 'letter' ? PdfPaper.letter : PdfPaper.a4;
      _coverPage = saved.coverPage;
      _brandingController.text = saved.branding;
      final resolved =
          resolveTemplateBlocks(saved.blocks, await _liveInstances(saved));
      final entries = <_Entry>[
        for (final b in resolved)
          _Entry(b.widgetId, Map.of(b.config), true,
              instanceId: b.instanceId, overridden: b.overridden),
      ];
      _entries = entries..addAll(_registryRemainder(entries));
      if (mounted) setState(() {});
      return;
    }

    _entries = await _dashboardSeed();
    if (mounted) setState(() {});
  }

  /// The dashboard instances the saved blocks point at, keyed by id —
  /// missing entries are cards the user has since removed.
  Future<Map<String, PlacedWidget>> _liveInstances(
      SavedExportConfig saved) async {
    final repo = ref.read(dashboardRepoProvider);
    final live = <String, PlacedWidget>{};
    for (final id
        in {for (final b in saved.blocks) b.instanceId}.whereType<String>()) {
      final placed = await repo.instanceById(id);
      if (placed != null) live[id] = placed;
    }
    return live;
  }

  /// Every registry module not already in [entries], unselected — the
  /// menu of blocks the user can still add to the report.
  List<_Entry> _registryRemainder(List<_Entry> entries) {
    final used = entries.map((e) => e.widgetId).toSet();
    return [
      for (final m in moduleRegistry.values)
        if (!used.contains(m.meta.id)) _Entry(m.meta.id, {}, false),
    ];
  }

  Future<List<_Entry>> _dashboardSeed() async {
    final entries = <_Entry>[];
    final views = await ref.read(dashboardRepoProvider).views();
    if (views.isNotEmpty) {
      final placed =
          await ref.read(dashboardRepoProvider).widgetsFor(views.first.id);
      for (final p in placed) {
        if (moduleById(p.widgetId) == null) continue;
        // Seeded blocks keep the instance link so they FOLLOW the card
        // they came from until the user customizes them here.
        entries.add(_Entry(p.widgetId, Map.of(p.config), true,
            instanceId: p.instanceId));
      }
    }
    return entries..addAll(_registryRemainder(entries));
  }

  /// Back to the dashboard's layout: drops the global template so the
  /// blocks track their cards again.
  Future<void> _resetFromDashboard() async {
    await ref.read(exportRepoProvider).clear();
    final entries = await _dashboardSeed();
    if (mounted) {
      setState(() {
        _hasSavedConfig = false;
        _entries = entries;
      });
    }
  }

  /// Writes the template. Called on EVERY mutation, not just after a
  /// successful export — the old "first export defines the template"
  /// rule meant edits made before printing were silently lost. The row
  /// is a few hundred bytes, so no debouncing.
  Future<void> _saveConfig() async {
    final entries = _entries;
    if (entries == null) return;
    await ref.read(exportRepoProvider).save(
          SavedExportConfig(
            blocks: [
              for (final e in entries)
                if (e.selected) e.saved,
            ],
            paper: _paper == PdfPaper.letter ? 'letter' : 'a4',
            coverPage: _coverPage,
            branding: _brandingController.text.trim(),
          ),
        );
    if (!_hasSavedConfig && mounted) setState(() => _hasSavedConfig = true);
  }

  /// setState + persist, the shape every control on this screen uses.
  void _mutate(VoidCallback change) {
    setState(change);
    _saveConfig();
  }

  Future<void> _run(bool print) async {
    setState(() => _working = true);
    // Capture before the first await — context must not be touched
    // across suspension points.
    final l10n = context.l10n;
    try {
      final ctx = await ref.read(moduleContextProvider(widget.kundliId).future);
      final options = PdfExportOptions(
        blocks: [
          for (final e in _entries!)
            if (e.selected) e.block,
        ],
        paper: _paper,
        coverPage: _coverPage,
        brandingFooter: _brandingController.text.trim().isEmpty
            ? null
            : _brandingController.text.trim(),
      );
      final exporter = PdfExporter();
      // Thread the current locale's strings into the context — pdfView
      // renders outside the widget tree and can't reach an inherited
      // AppLocalizations (see ModuleContext.l10n).
      final localizedCtx = ctx.withL10n(l10n);
      if (print) {
        await exporter.printDialog(localizedCtx, options);
      } else {
        await exporter.exportAndShare(localizedCtx, options);
      }
      // Belt and braces — every edit already wrote the template.
      await _saveConfig();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.peExportFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Per-block config, rendered with the SAME widget as the dashboard's
  /// card menu. Editing here detaches the block from its dashboard card:
  /// an explicit choice made for the report must not be overwritten the
  /// next time the card's own settings change.
  Future<void> _configureEntry(_Entry e) async {
    final module = moduleById(e.widgetId);
    if (module == null) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: KJColors.paper,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(module.meta.titleFor(ctx.l10n),
                          style: KJTheme.serif(size: 18)),
                      const SizedBox(height: 14),
                      ModuleConfigChips(
                        module: module,
                        config: e.config,
                        onChanged: (next) {
                          e.config = next;
                          e.overridden = true;
                          setSheetState(() {});
                          _mutate(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Pinned Done — changes apply instantly.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.l10n.done),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Community (Mahakosh) charts must never be exported: the cover page
    // and several modules print the exact birth time, which is withheld
    // for anonymized charts. The chart screen offers no export entry, but
    // guard here too so no direct route can leak it.
    if (isMahakoshKundliId(widget.kundliId)) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.peTitle)),
        body: EmptyState(message: context.l10n.peOwnKundlisOnly),
      );
    }

    _initSelection();
    final entries = _entries;
    final selectedCount = entries?.where((e) => e.selected).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.peTitle)),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: formPadding(context),
              children: [
                Text(context.l10n.peModulesSection,
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        color: KJColors.inkSoft,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _hasSavedConfig
                            ? context.l10n.peSavedReportNote
                            : context.l10n.peFirstExportNote,
                        style:
                            TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
                      ),
                    ),
                    if (_hasSavedConfig)
                      TextButton(
                        onPressed: _resetFromDashboard,
                        child: Text(context.l10n.peReset,
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Blocks print in list order, so the list IS the report's
                // running order — drag to rearrange. Nested inside the
                // page's own ListView, hence shrinkWrap + no physics of
                // its own.
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: entries.length,
                  // onReorderItem, not onReorder: it hands back a
                  // newIndex already adjusted for the removed item.
                  onReorderItem: (oldIndex, newIndex) => _mutate(() =>
                      entries.insert(newIndex, entries.removeAt(oldIndex))),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return Card(
                      // Entries are not unique by widgetId — a duplicated
                      // block shares one — so identity is the key.
                      key: ObjectKey(e),
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.drag_indicator,
                                  size: 16,
                                  color:
                                      KJColors.inkSoft.withValues(alpha: 0.55)),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: KJColors.maroon,
                              value: e.selected,
                              title: Text(e.label(context.l10n)),
                              onChanged: (v) =>
                                  _mutate(() => e.selected = v ?? false),
                            ),
                          ),
                          if (moduleById(e.widgetId)
                                  ?.configChoices(context.l10n)
                                  .isNotEmpty ??
                              false)
                            IconButton(
                              icon: const Icon(Icons.tune, size: 18),
                              tooltip: context.l10n.peConfigureBlock,
                              onPressed: () => _configureEntry(e),
                            ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: context.l10n.peDuplicateBlock,
                            onPressed: () =>
                                _mutate(() => entries.insert(i + 1, e.copy())),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(context.l10n.peOptionsSection,
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        color: KJColors.inkSoft,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(context.l10n.pePaper,
                        style: const TextStyle(fontSize: 13.5)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('A4'),
                      selected: _paper == PdfPaper.a4,
                      labelStyle: TextStyle(
                          color: _paper == PdfPaper.a4
                              ? KJColors.paper
                              : KJColors.ink),
                      onSelected: (_) => _mutate(() => _paper = PdfPaper.a4),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Letter'),
                      selected: _paper == PdfPaper.letter,
                      labelStyle: TextStyle(
                          color: _paper == PdfPaper.letter
                              ? KJColors.paper
                              : KJColors.ink),
                      onSelected: (_) =>
                          _mutate(() => _paper = PdfPaper.letter),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: KJColors.maroon,
                  value: _coverPage,
                  onChanged: (v) => _mutate(() => _coverPage = v),
                  title: Text(context.l10n.peCoverPage,
                      style: const TextStyle(fontSize: 13.5)),
                ),
                TextField(
                  controller: _brandingController,
                  onChanged: (_) => _saveConfig(),
                  decoration: InputDecoration(
                    labelText: context.l10n.peBranding,
                    helperText: context.l10n.peBrandingHelper,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed:
                      selectedCount == 0 || _working ? null : () => _run(false),
                  child: Text(_working
                      ? context.l10n.peGenerating
                      : context.l10n.peGenerateShare),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed:
                      selectedCount == 0 || _working ? null : () => _run(true),
                  child: Text(context.l10n.pePrint),
                ),
              ],
            ),
    );
  }
}
