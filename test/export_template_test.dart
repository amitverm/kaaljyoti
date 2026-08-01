/// The PDF report composition going GLOBAL (schema v9).
///
/// Two things must hold. First, the v8 → v9 migration has to fold the
/// legacy per-kundli `export_configs` into the single template row and
/// drop the old table — every existing user runs this on their first
/// launch after the update. Second, a block must FOLLOW the dashboard
/// instance it came from: the reported bug was an export that froze the
/// dashboard's widget settings at first export, so a birth chart whose
/// degree display was changed later still printed the old way.
///
/// Runs against sqflite_common_ffi (plain sqlite3), like db_recovery_test.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/db.dart';
import 'package:kaaljyoti/data/export_repository.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _ffiOpener(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) =>
    databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      ),
    );

/// The kundlis table as v8 shipped it.
const _v8Kundlis = '''
  CREATE TABLE kundlis (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    relation_tag TEXT NOT NULL DEFAULT 'Self',
    note TEXT,
    labels TEXT,
    birth_utc INTEGER NOT NULL,
    lat REAL NOT NULL,
    lon REAL NOT NULL,
    tz_name TEXT NOT NULL,
    utc_offset_min INTEGER NOT NULL,
    place_name TEXT NOT NULL,
    ayanamsa_id INTEGER,
    chart_style TEXT DEFAULT 'north',
    is_prashna INTEGER NOT NULL DEFAULT 0,
    is_ephemeral INTEGER NOT NULL DEFAULT 0,
    sync_enabled INTEGER NOT NULL DEFAULT 0,
    mahakosh_code TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
''';

const _v8ExportConfigs = '''
  CREATE TABLE export_configs (
    kundli_id TEXT PRIMARY KEY,
    blocks TEXT NOT NULL,
    paper TEXT NOT NULL DEFAULT 'a4',
    cover_page INTEGER NOT NULL DEFAULT 1,
    branding TEXT NOT NULL DEFAULT ''
  )
''';

PlacedWidget _placed(
        String instanceId, String widgetId, Map<String, dynamic> config) =>
    PlacedWidget(
      instanceId: instanceId,
      viewId: 'v1',
      widgetId: widgetId,
      position: 0,
      config: config,
    );

void main() {
  sqfliteFfiInit();

  late Directory dir;
  late String dbPath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kaaljyoti_export_template_test');
    dbPath = '${dir.path}/kaaljyoti.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  AppDb newDb() => AppDb.forTest(
      path: dbPath, opener: _ffiOpener, passphrase: 'test-passphrase');

  /// A v8 database carrying [legacy] per-kundli export rows.
  Future<void> seedV8(Map<String, List<Map<String, dynamic>>> legacy) async {
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: (db, _) async {
          await db.execute(_v8Kundlis);
          await db.execute(_v8ExportConfigs);
        },
      ),
    );
    for (final entry in legacy.entries) {
      await db.insert('export_configs', {
        'kundli_id': entry.key,
        'blocks': jsonEncode(entry.value),
        'paper': 'letter',
        'cover_page': 0,
        'branding': 'Acharya Amit Verma',
      });
    }
    await db.close();
  }

  group('v8 → v9 migration', () {
    test('promotes one legacy row into the global template', () async {
      await seedV8({
        'kundli-a': [
          {
            'widget_id': 'birth_chart',
            'config': {'degrees': 'on'}
          },
          {'widget_id': 'dasha', 'config': <String, dynamic>{}},
        ],
      });

      final appDb = newDb();
      final saved = await ExportRepository(db: appDb).load();

      expect(saved, isNotNull);
      expect(saved!.paper, 'letter');
      expect(saved.coverPage, isFalse);
      expect(saved.branding, 'Acharya Amit Verma');
      expect(saved.blocks.map((b) => b.widgetId), ['birth_chart', 'dasha']);
      expect(saved.blocks.first.config, {'degrees': 'on'});
      // A legacy row records no instance link, so it CANNOT follow a
      // dashboard card — it has to keep the config it was saved with.
      expect(saved.blocks.every((b) => b.overridden), isTrue);
      expect(saved.blocks.every((b) => b.instanceId == null), isTrue);
      await appDb.close();
    });

    test('drops the legacy per-kundli table', () async {
      await seedV8({
        'kundli-a': [
          {'widget_id': 'dasha', 'config': <String, dynamic>{}}
        ],
      });

      final appDb = newDb();
      final db = await appDb.database;
      expect(await db.getVersion(), 10);
      expect(
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='export_configs'"),
        isEmpty,
        reason: 'two competing report tables must not coexist',
      );
      await appDb.close();
    });

    test('picks the first row deterministically when several kundlis had one',
        () async {
      // There is no principled merge of N per-kundli compositions into
      // one; whichever wins, it must be the same one every time.
      await seedV8({
        'kundli-c': [
          {'widget_id': 'yogas', 'config': <String, dynamic>{}}
        ],
        'kundli-a': [
          {'widget_id': 'panchang', 'config': <String, dynamic>{}}
        ],
        'kundli-b': [
          {'widget_id': 'dasha', 'config': <String, dynamic>{}}
        ],
      });

      final appDb = newDb();
      final saved = await ExportRepository(db: appDb).load();
      expect(saved!.blocks.single.widgetId, 'panchang');
      await appDb.close();
    });

    test('an empty legacy table leaves no template at all', () async {
      await seedV8(const {});

      final appDb = newDb();
      final repo = ExportRepository(db: appDb);
      expect(await repo.load(), isNull,
          reason: 'no saved report means the screen seeds from the dashboard');
      await appDb.close();
    });

    test('re-running the migration is a no-op', () async {
      await seedV8({
        'kundli-a': [
          {'widget_id': 'dasha', 'config': <String, dynamic>{}}
        ],
      });

      final first = newDb();
      await first.database;
      await first.close();

      final second = newDb();
      final db = await second.database;
      expect(await db.getVersion(), 10);
      expect(await db.query('export_template'), hasLength(1));
      expect((await ExportRepository(db: second).load())!.blocks, hasLength(1));
      await second.close();
    });
  });

  group('global template round-trip', () {
    test('save/load preserves the block shape', () async {
      final appDb = newDb();
      final repo = ExportRepository(db: appDb);
      await repo.save(const SavedExportConfig(
        blocks: [
          (
            widgetId: 'birth_chart',
            instanceId: 'inst-1',
            overridden: false,
            config: {'style': 'south'},
          ),
          (
            widgetId: 'divisional',
            instanceId: null,
            overridden: true,
            config: {'varga': 'd9'},
          ),
        ],
        paper: 'a4',
        coverPage: true,
        branding: '',
      ));

      final loaded = await repo.load();
      expect(loaded!.blocks, hasLength(2));
      expect(loaded.blocks[0].instanceId, 'inst-1');
      expect(loaded.blocks[0].overridden, isFalse);
      expect(loaded.blocks[0].config, {'style': 'south'});
      expect(loaded.blocks[1].instanceId, isNull);
      expect(loaded.blocks[1].overridden, isTrue);
      expect(loaded.paper, 'a4');
      expect(loaded.coverPage, isTrue);
      await appDb.close();
    });

    test('saving twice replaces rather than accumulates', () async {
      final appDb = newDb();
      final repo = ExportRepository(db: appDb);
      const block = (
        widgetId: 'dasha',
        instanceId: null,
        overridden: true,
        config: <String, dynamic>{},
      );
      await repo.save(const SavedExportConfig(
          blocks: [block], paper: 'a4', coverPage: true, branding: ''));
      await repo.save(const SavedExportConfig(
          blocks: [block, block],
          paper: 'letter',
          coverPage: false,
          branding: 'x'));

      expect(
          await (await appDb.database).query('export_template'), hasLength(1));
      final loaded = await repo.load();
      expect(loaded!.blocks, hasLength(2));
      expect(loaded.paper, 'letter');
      await appDb.close();
    });

    test('clear removes the template so the dashboard seeds again', () async {
      final appDb = newDb();
      final repo = ExportRepository(db: appDb);
      await repo.save(const SavedExportConfig(
        blocks: [
          (
            widgetId: 'dasha',
            instanceId: null,
            overridden: true,
            config: <String, dynamic>{},
          )
        ],
        paper: 'a4',
        coverPage: true,
        branding: '',
      ));
      await repo.clear();
      expect(await repo.load(), isNull);
      await appDb.close();
    });
  });

  group('resolveTemplateBlocks', () {
    const tracking = (
      widgetId: 'birth_chart',
      instanceId: 'inst-1',
      overridden: false,
      config: <String, dynamic>{'degrees': 'off'},
    );

    test('a tracking block adopts the live instance config', () {
      // The reported bug: the user turned degrees on for the dashboard's
      // birth chart and the export kept printing the frozen 'off'.
      final resolved = resolveTemplateBlocks(
        [tracking],
        {
          'inst-1': _placed('inst-1', 'birth_chart', {'degrees': 'on'})
        },
      );
      expect(resolved.single.config, {'degrees': 'on'});
      expect(resolved.single.instanceId, 'inst-1');
      expect(resolved.single.overridden, isFalse);
    });

    test('an overridden block keeps its own config', () {
      const overridden = (
        widgetId: 'birth_chart',
        instanceId: 'inst-1',
        overridden: true,
        config: <String, dynamic>{'degrees': 'off'},
      );
      final resolved = resolveTemplateBlocks(
        [overridden],
        {
          'inst-1': _placed('inst-1', 'birth_chart', {'degrees': 'on'})
        },
      );
      expect(resolved.single.config, {'degrees': 'off'},
          reason: 'a choice made for the report is not overwritten');
    });

    test('a block whose instance is gone falls back to the frozen config', () {
      final resolved = resolveTemplateBlocks([tracking], const {});
      expect(resolved.single.config, {'degrees': 'off'});
      expect(resolved.single.instanceId, 'inst-1',
          reason: 'the link survives — the card may come back');
    });

    test('a block with no instance link is left alone', () {
      const orphan = (
        widgetId: 'dasha',
        instanceId: null,
        overridden: false,
        config: <String, dynamic>{'system': 'yogini'},
      );
      final resolved = resolveTemplateBlocks(
        [orphan],
        {
          'inst-1': _placed('inst-1', 'dasha', {'system': 'vimshottari'})
        },
      );
      expect(resolved.single.config, {'system': 'yogini'});
    });

    test('order is preserved', () {
      final resolved = resolveTemplateBlocks(
        const [
          (
            widgetId: 'a',
            instanceId: null,
            overridden: false,
            config: <String, dynamic>{}
          ),
          (
            widgetId: 'b',
            instanceId: 'inst-1',
            overridden: false,
            config: <String, dynamic>{}
          ),
          (
            widgetId: 'c',
            instanceId: null,
            overridden: true,
            config: <String, dynamic>{}
          ),
        ],
        {'inst-1': _placed('inst-1', 'b', const {})},
      );
      expect(resolved.map((b) => b.widgetId), ['a', 'b', 'c']);
    });

    test('resolution does not alias the live instance config', () {
      final live = _placed('inst-1', 'birth_chart', {'degrees': 'on'});
      final resolved = resolveTemplateBlocks([tracking], {'inst-1': live});
      resolved.single.config['degrees'] = 'off';
      expect(live.config['degrees'], 'on',
          reason: 'editing the export block must not rewrite the dashboard');
    });
  });
}
