import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

import 'db.dart';

/// A kundli's saved PDF report composition — deliberately separate
/// from the dashboard: the widgets a jyotish works with on screen are
/// not necessarily what they hand to a client.
class SavedExportConfig {
  const SavedExportConfig({
    required this.blocks, // ordered (widgetId, config) pairs, all selected
    required this.paper, // 'a4' | 'letter'
    required this.coverPage,
    required this.branding,
  });

  final List<({String widgetId, Map<String, dynamic> config})> blocks;
  final String paper;
  final bool coverPage;
  final String branding;
}

class ExportRepository {
  ExportRepository({AppDb? db}) : _db = db ?? AppDb.instance;
  final AppDb _db;

  Future<SavedExportConfig?> load(String kundliId) async {
    final db = await _db.database;
    final rows = await db.query('export_configs',
        where: 'kundli_id = ?', whereArgs: [kundliId]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final decoded = jsonDecode(r['blocks'] as String) as List;
    return SavedExportConfig(
      blocks: [
        for (final b in decoded)
          (
            widgetId: (b as Map)['widget_id'] as String,
            config: (b['config'] as Map).cast<String, dynamic>(),
          ),
      ],
      paper: r['paper'] as String,
      coverPage: (r['cover_page'] as int) == 1,
      branding: r['branding'] as String,
    );
  }

  Future<void> save(String kundliId, SavedExportConfig config) async {
    final db = await _db.database;
    await db.insert(
      'export_configs',
      {
        'kundli_id': kundliId,
        'blocks': jsonEncode([
          for (final b in config.blocks)
            {'widget_id': b.widgetId, 'config': b.config},
        ]),
        'paper': config.paper,
        'cover_page': config.coverPage ? 1 : 0,
        'branding': config.branding,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clear(String kundliId) async {
    final db = await _db.database;
    await db.delete('export_configs',
        where: 'kundli_id = ?', whereArgs: [kundliId]);
  }
}
