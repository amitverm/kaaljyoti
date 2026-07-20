import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'db.dart';
import 'models.dart';

/// A widget entry used when seeding a view (from a template).
typedef SeedWidget = ({
  String widgetId,
  CardSpan span,
  Map<String, dynamic> config
});

/// Persists named dashboard views and their widget-instance
/// arrangements — the customizable dashboard is the product's primary
/// differentiator, so this state is first-class data.
class DashboardRepository {
  DashboardRepository({AppDb? db}) : _db = db ?? AppDb.instance;
  final AppDb _db;
  static const _uuid = Uuid();

  /// Default "Overview" seed for a fresh kundli (matches the design
  /// prototype's Overview view).
  static const List<SeedWidget> defaultOverview = [
    (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
    (widgetId: 'dasha', span: CardSpan.full, config: {}),
    (widgetId: 'panchang', span: CardSpan.half, config: {}),
    (widgetId: 'moon_nakshatra', span: CardSpan.half, config: {}),
    (widgetId: 'planetary_positions', span: CardSpan.full, config: {}),
    (widgetId: 'yogas', span: CardSpan.half, config: {}),
  ];

  /// Global views — seeded with the default Overview on first use.
  Future<List<DashboardView>> views() async {
    final db = await _db.database;
    final rows = await db.query('dashboard_views', orderBy: 'position ASC');
    if (rows.isEmpty) {
      final view = await createView('Overview', seed: defaultOverview);
      return [view];
    }
    final views = rows.map(DashboardView.fromRow).toList();
    // Self-heal: if NO view has any widgets at all (migration edge
    // case or everything was removed), seed the starter set into the
    // first view — the first kundli should never open onto a blank
    // board.
    final cnt = (await db.rawQuery('SELECT COUNT(*) AS c FROM view_widgets'))
        .first['c'] as int;
    if (cnt == 0) await seedWidgets(views.first.id, defaultOverview);
    return views;
  }

  Future<DashboardView> createView(
    String name, {
    List<SeedWidget> seed = const [],
  }) async {
    final db = await _db.database;
    final existing = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS m FROM dashboard_views',
    );
    final view = DashboardView(
      id: _uuid.v4(),
      name: name,
      position: (existing.first['m'] as int) + 1,
    );
    await db.insert('dashboard_views', view.toRow());
    await seedWidgets(view.id, seed);
    return view;
  }

  /// Append a set of widgets to an existing view — used by templates
  /// and as the one-tap starter set on an empty board.
  Future<void> seedWidgets(String viewId, List<SeedWidget> seed) async {
    final db = await _db.database;
    final existing = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS m FROM view_widgets '
      'WHERE view_id = ?',
      [viewId],
    );
    var pos = (existing.first['m'] as int) + 1;
    for (final s in seed) {
      await db.insert('view_widgets', {
        'instance_id': _uuid.v4(),
        'view_id': viewId,
        'widget_id': s.widgetId,
        'position': pos++,
        'span': s.span.name,
        'config': jsonEncode(s.config),
      });
    }
  }

  Future<void> renameView(String viewId, String name) async {
    final db = await _db.database;
    await db.update('dashboard_views', {'name': name},
        where: 'id = ?', whereArgs: [viewId]);
  }

  Future<void> deleteView(String viewId) async {
    final db = await _db.database;
    await db.delete('dashboard_views', where: 'id = ?', whereArgs: [viewId]);
  }

  Future<List<PlacedWidget>> widgetsFor(String viewId) async {
    final db = await _db.database;
    final rows = await db.query(
      'view_widgets',
      where: 'view_id = ?',
      whereArgs: [viewId],
      orderBy: 'position ASC',
    );
    return rows.map(_fromRow).toList();
  }

  PlacedWidget _fromRow(Map<String, Object?> r) => PlacedWidget(
        instanceId: r['instance_id'] as String,
        viewId: r['view_id'] as String,
        widgetId: r['widget_id'] as String,
        position: r['position'] as int,
        span: CardSpan.byName(r['span'] as String?),
        config:
            (jsonDecode(r['config'] as String) as Map).cast<String, dynamic>(),
      );

  Future<PlacedWidget> addWidget(
    String viewId,
    String widgetId, {
    CardSpan span = CardSpan.half,
    Map<String, dynamic> config = const {},
  }) async {
    final db = await _db.database;
    final existing = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS m FROM view_widgets WHERE view_id = ?',
      [viewId],
    );
    final placed = PlacedWidget(
      instanceId: _uuid.v4(),
      viewId: viewId,
      widgetId: widgetId,
      position: (existing.first['m'] as int) + 1,
      span: span,
      config: config,
    );
    await db.insert('view_widgets', {
      'instance_id': placed.instanceId,
      'view_id': viewId,
      'widget_id': widgetId,
      'position': placed.position,
      'span': span.name,
      'config': jsonEncode(config),
    });
    return placed;
  }

  /// Duplicate an instance (same module, same config/span) right after
  /// the original — the "3 divisional charts" workflow.
  Future<PlacedWidget> duplicate(PlacedWidget source) async {
    final copy = await addWidget(
      source.viewId,
      source.widgetId,
      span: source.span,
      config: Map.of(source.config),
    );
    // Move the copy next to the original.
    final all = await widgetsFor(source.viewId);
    final ids = all.map((p) => p.instanceId).toList()
      ..remove(copy.instanceId)
      ..insert(all.indexWhere((p) => p.instanceId == source.instanceId) + 1,
          copy.instanceId);
    await reorder(source.viewId, ids);
    return copy;
  }

  Future<void> removeInstance(String instanceId) async {
    final db = await _db.database;
    await db.delete('view_widgets',
        where: 'instance_id = ?', whereArgs: [instanceId]);
  }

  Future<void> reorder(String viewId, List<String> orderedInstanceIds) async {
    final db = await _db.database;
    final batch = db.batch();
    for (var i = 0; i < orderedInstanceIds.length; i++) {
      batch.update(
        'view_widgets',
        {'position': i},
        where: 'instance_id = ?',
        whereArgs: [orderedInstanceIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> setSpan(String instanceId, CardSpan span) async {
    final db = await _db.database;
    await db.update('view_widgets', {'span': span.name},
        where: 'instance_id = ?', whereArgs: [instanceId]);
  }

  Future<void> setConfig(String instanceId, Map<String, dynamic> config) async {
    final db = await _db.database;
    await db.update('view_widgets', {'config': jsonEncode(config)},
        where: 'instance_id = ?', whereArgs: [instanceId]);
  }
}
