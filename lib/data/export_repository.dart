import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

import 'db.dart';
import 'models.dart';

/// One block of the report: which module, which dashboard instance it
/// tracks (if any), and the config to use when it doesn't track one.
///
/// [instanceId] is the link back to a dashboard widget instance. While
/// [overridden] is false the block RENDERS WITH THAT INSTANCE'S CURRENT
/// CONFIG — change the birth chart's degree display on the dashboard and
/// the report follows. [config] is the frozen fallback, used once the
/// user customizes the block here (overridden) or when the linked
/// instance has been removed from the dashboard.
typedef ExportBlock = ({
  String widgetId,
  String? instanceId,
  bool overridden,
  Map<String, dynamic> config,
});

/// The GLOBAL PDF report composition — one template for every kundli.
///
/// It used to be saved per kundli, which meant deselecting Panchang for
/// one client left it in every other client's report. The layout is a
/// lens, the kundli is the data (the same call the dashboard views made
/// when they went global in schema v5).
class SavedExportConfig {
  const SavedExportConfig({
    required this.blocks, // ordered, all selected
    required this.paper, // 'a4' | 'letter'
    required this.coverPage,
    required this.branding,
  });

  final List<ExportBlock> blocks;
  final String paper;
  final bool coverPage;
  final String branding;
}

/// Resolves saved template blocks against the dashboard's live widget
/// instances, so the report follows the dashboard instead of snapshotting
/// it at first export.
///
/// A block adopts the live instance's config only when it still points at
/// an instance that exists AND the user hasn't customized it on the export
/// screen. Everything else keeps its frozen [ExportBlock.config] — a block
/// whose dashboard widget was deleted still renders what it last showed
/// rather than reverting to module defaults.
List<ExportBlock> resolveTemplateBlocks(
  List<ExportBlock> saved,
  Map<String, PlacedWidget> liveInstances,
) {
  return [
    for (final b in saved)
      if (!b.overridden &&
          b.instanceId != null &&
          liveInstances.containsKey(b.instanceId))
        (
          widgetId: b.widgetId,
          instanceId: b.instanceId,
          overridden: false,
          config: Map<String, dynamic>.of(liveInstances[b.instanceId]!.config),
        )
      else
        b,
  ];
}

class ExportRepository {
  ExportRepository({AppDb? db}) : _db = db ?? AppDb.instance;
  final AppDb _db;

  static const _rowId = 1;

  Future<SavedExportConfig?> load() async {
    final db = await _db.database;
    final rows =
        await db.query('export_template', where: 'id = ?', whereArgs: [_rowId]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final decoded = jsonDecode(r['blocks'] as String) as List;
    return SavedExportConfig(
      blocks: [
        for (final b in decoded)
          (
            widgetId: (b as Map)['widget_id'] as String,
            instanceId: b['instance_id'] as String?,
            // Tolerate blocks written before the field existed.
            overridden: b['overridden'] == true,
            config: (b['config'] as Map?)?.cast<String, dynamic>() ?? {},
          ),
      ],
      paper: r['paper'] as String,
      coverPage: (r['cover_page'] as int) == 1,
      branding: r['branding'] as String,
    );
  }

  Future<void> save(SavedExportConfig config) async {
    final db = await _db.database;
    await db.insert(
      'export_template',
      {
        'id': _rowId,
        'blocks': jsonEncode([
          for (final b in config.blocks)
            {
              'widget_id': b.widgetId,
              'instance_id': b.instanceId,
              'overridden': b.overridden,
              'config': b.config,
            },
        ]),
        'paper': config.paper,
        'cover_page': config.coverPage ? 1 : 0,
        'branding': config.branding,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('export_template', where: 'id = ?', whereArgs: [_rowId]);
  }
}
