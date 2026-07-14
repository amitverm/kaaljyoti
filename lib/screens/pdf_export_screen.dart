/// PDF Export screen (§2.9): the toggle list mirrors the dashboard's
/// widget INSTANCES (config-aware — three divisional charts export as
/// three different vargas), pre-checked and editable per export, plus
/// paper size, cover page, and optional practitioner branding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../data/export_repository.dart';
import '../pdf/pdf_exporter.dart';
import '../state/providers.dart';
import '../widgetsystem/registry.dart';
import '../ui/common.dart';

class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  ConsumerState<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _Entry {
  _Entry(this.widgetId, this.config, this.selected);
  final String widgetId;
  Map<String, dynamic> config; // per-export, editable & duplicable
  bool selected;

  PdfBlock get block => (widgetId: widgetId, config: config);

  String label() {
    final module = moduleById(widgetId);
    if (module == null) return widgetId;
    final summary = module.configSummary(config);
    return summary == null
        ? module.meta.title
        : '${module.meta.title} · $summary';
  }

  _Entry copy() => _Entry(widgetId, Map.of(config), true);
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

    // The report composition is persisted separately from the
    // dashboard: what a jyotish works with on screen is not what they
    // hand to a client. A saved report config wins; the dashboard only
    // seeds the very first export.
    final saved = await ref.read(exportRepoProvider).load(widget.kundliId);
    if (saved != null) {
      _hasSavedConfig = true;
      _paper = saved.paper == 'letter' ? PdfPaper.letter : PdfPaper.a4;
      _coverPage = saved.coverPage;
      _brandingController.text = saved.branding;
      final entries = <_Entry>[
        for (final b in saved.blocks)
          _Entry(b.widgetId, Map.of(b.config), true),
      ];
      final used = entries.map((e) => e.widgetId).toSet();
      for (final m in moduleRegistry.values) {
        if (!used.contains(m.meta.id)) {
          entries.add(_Entry(m.meta.id, {}, false));
        }
      }
      _entries = entries;
      if (mounted) setState(() {});
      return;
    }

    _entries = await _dashboardSeed();
    if (mounted) setState(() {});
  }

  Future<List<_Entry>> _dashboardSeed() async {
    final entries = <_Entry>[];
    final seen = <String>{};
    final views =
        await ref.read(dashboardRepoProvider).views();
    if (views.isNotEmpty) {
      final placed =
          await ref.read(dashboardRepoProvider).widgetsFor(views.first.id);
      for (final p in placed) {
        if (moduleById(p.widgetId) == null) continue;
        entries.add(_Entry(p.widgetId, Map.of(p.config), true));
        seen.add(p.widgetId);
      }
    }
    for (final m in moduleRegistry.values) {
      if (!seen.contains(m.meta.id)) {
        entries.add(_Entry(m.meta.id, {}, false));
      }
    }
    return entries;
  }

  Future<void> _resetFromDashboard() async {
    await ref.read(exportRepoProvider).clear(widget.kundliId);
    final entries = await _dashboardSeed();
    if (mounted) {
      setState(() {
        _hasSavedConfig = false;
        _entries = entries;
      });
    }
  }

  Future<void> _saveConfig() async {
    await ref.read(exportRepoProvider).save(
          widget.kundliId,
          SavedExportConfig(
            blocks: [
              for (final e in _entries!)
                if (e.selected) (widgetId: e.widgetId, config: e.config),
            ],
            paper: _paper == PdfPaper.letter ? 'letter' : 'a4',
            coverPage: _coverPage,
            branding: _brandingController.text.trim(),
          ),
        );
    _hasSavedConfig = true;
  }

  Future<void> _run(bool print) async {
    setState(() => _working = true);
    try {
      final ctx =
          await ref.read(moduleContextProvider(widget.kundliId).future);
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
      if (print) {
        await exporter.printDialog(ctx, options);
      } else {
        await exporter.exportAndShare(ctx, options);
      }
      // A successful export defines this kundli's report template.
      await _saveConfig();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Per-export config for one block (same generic pattern as the
  /// dashboard's widget menu; changes affect this export only).
  Future<void> _configureEntry(_Entry e) async {
    final module = moduleById(e.widgetId);
    if (module == null) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: TEColors.paper,
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
                      Text(module.meta.title,
                          style: TETheme.serif(size: 18)),
                      for (final choice in module.configChoices()) ...[
                  const SizedBox(height: 14),
                  TESectionLabel(choice.label),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (value, label) in choice.options)
                        ChoiceChip(
                          label: Text(label,
                              style: const TextStyle(fontSize: 12.5)),
                          selected: (e.config[choice.key] ??
                                  choice.effectiveDefault) ==
                              value,
                          labelStyle: TextStyle(
                              fontSize: 12.5,
                              color: (e.config[choice.key] ??
                                          choice.effectiveDefault) ==
                                      value
                                  ? TEColors.paper
                                  : TEColors.ink),
                          onSelected: (_) {
                            e.config = {...e.config, choice.key: value};
                            setSheetState(() {});
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ],
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
                    child: const Text('Done'),
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
        appBar: AppBar(title: const Text('Export / Print')),
        body: const EmptyState(
          message: 'PDF export is available for your own kundlis only. '
              'Community charts stay anonymized — their birth time is '
              'never exported.',
        ),
      );
    }

    _initSelection();
    final entries = _entries;
    final selectedCount =
        entries?.where((e) => e.selected).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Export / Print')),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: formPadding(context),
              children: [
                Text('MODULES IN THIS EXPORT',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        color: TEColors.inkSoft,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _hasSavedConfig
                            ? 'Your saved report for this kundli — kept '
                                'separate from the dashboard.'
                            : 'First export starts from your dashboard; '
                                'after that the report is remembered '
                                'separately.',
                        style: TextStyle(
                            fontSize: 12.5, color: TEColors.inkSoft),
                      ),
                    ),
                    if (_hasSavedConfig)
                      TextButton(
                        onPressed: _resetFromDashboard,
                        child: const Text('Reset',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final e in entries)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            activeColor: TEColors.maroon,
                            value: e.selected,
                            title: Text(e.label()),
                            onChanged: (v) =>
                                setState(() => e.selected = v ?? false),
                          ),
                        ),
                        if (moduleById(e.widgetId)
                                ?.configChoices()
                                .isNotEmpty ??
                            false)
                          IconButton(
                            icon: const Icon(Icons.tune, size: 18),
                            tooltip: 'Configure this block',
                            onPressed: () => _configureEntry(e),
                          ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Duplicate this block',
                          onPressed: () => setState(() => entries.insert(
                              entries.indexOf(e) + 1, e.copy())),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text('OPTIONS',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        color: TEColors.inkSoft,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Paper', style: TextStyle(fontSize: 13.5)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('A4'),
                      selected: _paper == PdfPaper.a4,
                      labelStyle: TextStyle(
                          color: _paper == PdfPaper.a4
                              ? TEColors.paper
                              : TEColors.ink),
                      onSelected: (_) =>
                          setState(() => _paper = PdfPaper.a4),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Letter'),
                      selected: _paper == PdfPaper.letter,
                      labelStyle: TextStyle(
                          color: _paper == PdfPaper.letter
                              ? TEColors.paper
                              : TEColors.ink),
                      onSelected: (_) =>
                          setState(() => _paper = PdfPaper.letter),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: TEColors.maroon,
                  value: _coverPage,
                  onChanged: (v) => setState(() => _coverPage = v),
                  title: const Text('Cover page',
                      style: TextStyle(fontSize: 13.5)),
                ),
                TextField(
                  controller: _brandingController,
                  decoration: const InputDecoration(
                    labelText: 'Practitioner branding (optional)',
                    helperText:
                        'Shown on the cover and footer — e.g. your name '
                        'and contact, so the report reads as coming from you',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: selectedCount == 0 || _working
                      ? null
                      : () => _run(false),
                  child:
                      Text(_working ? 'Generating…' : 'Generate & share'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: selectedCount == 0 || _working
                      ? null
                      : () => _run(true),
                  child: const Text('Print'),
                ),
                const SizedBox(height: 12),
                Text(
                  'PDF export is free for any of your kundlis, on any plan.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
                ),
              ],
            ),
    );
  }
}
