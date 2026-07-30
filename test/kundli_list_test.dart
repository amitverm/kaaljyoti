/// The kundli list's finding logic — search, filter, sort, pinning, and
/// the recents strip. These run against [kundliListDataProvider] rather
/// than the widget tree: the screen is a pure function of this object,
/// so the ordering rules are worth testing directly.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/screens/kundli_list_screen.dart' show initialFor;
import 'package:kaaljyoti/state/providers.dart';

Kundli _k({
  required String id,
  required String name,
  String relationTag = 'Client',
  String? note,
  List<String> labels = const [],
  String placeName = 'Pune, Maharashtra, India',
  DateTime? birth,
  DateTime? created,
}) =>
    Kundli(
      id: id,
      name: name,
      relationTag: relationTag,
      note: note,
      labels: labels,
      birthUtc: birth ?? DateTime.utc(1987, 3, 12, 8, 52),
      latitude: 18.52,
      longitude: 73.86,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
      placeName: placeName,
      createdAt: created ?? DateTime.utc(2026, 1, 1),
      updatedAt: created ?? DateTime.utc(2026, 1, 1),
    );

/// Feeds the list providers a fixed set of kundlis, bypassing the repo.
ProviderContainer _containerWith(List<Kundli> kundlis) {
  final container = ProviderContainer(overrides: [
    kundlisProvider.overrideWith((ref) async => kundlis),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<KundliListData> _read(ProviderContainer c) async {
  await c.read(kundlisProvider.future);
  return c.read(kundliListDataProvider).value!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sort/density/pins/recents persist through SharedPreferences; start
  // every test from an empty store so defaults are the ones in code.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('search', () {
    final library = [
      _k(id: 'a', name: 'Ramesh Sharma', note: 'career reading'),
      _k(id: 'b', name: 'Sunita Patil', placeName: 'Nashik, India'),
      _k(id: 'c', name: 'Renée Dubois', labels: const ['matchmaking']),
    ];

    test('matches on name, note, place, and label', () async {
      for (final (query, expected) in [
        ('ramesh', 'a'),
        ('career', 'a'),
        ('nashik', 'b'),
        ('matchmaking', 'c'),
      ]) {
        final c = _containerWith(library);
        c.read(kundliSearchProvider.notifier).state = query;
        final data = await _read(c);
        expect(data.visibleCount, 1, reason: 'query "$query"');
        expect(data.others.single.id, expected, reason: 'query "$query"');
      }
    });

    test('ignores case and Latin diacritics', () async {
      final c = _containerWith(library);
      c.read(kundliSearchProvider.notifier).state = 'RENEE';
      expect((await _read(c)).others.single.id, 'c');
    });

    test('multiple terms narrow rather than widen', () async {
      final c = _containerWith(library);
      // "sharma" alone matches a; "sharma nashik" must match nothing,
      // because every term has to be present.
      c.read(kundliSearchProvider.notifier).state = 'sharma nashik';
      expect((await _read(c)).isEmpty, isTrue);
    });

    test('reports the unfiltered library size alongside the matches',
        () async {
      final c = _containerWith(library);
      c.read(kundliSearchProvider.notifier).state = 'ramesh';
      final data = await _read(c);
      expect(data.visibleCount, 1);
      expect(data.totalCount, 3);
    });
  });

  group('filter chips', () {
    final library = [
      _k(id: 'a', name: 'Anil', relationTag: 'Client', labels: const ['2026']),
      _k(id: 'b', name: 'Bela', relationTag: 'Family'),
      _k(id: 'c', name: 'Chetan', relationTag: 'Client', labels: const ['2026']),
    ];

    test('relation filter keeps only that tag', () async {
      final c = _containerWith(library);
      c.read(kundliFilterProvider.notifier).state =
          (kind: KundliFilterKind.relation, value: 'Family');
      expect((await _read(c)).others.single.id, 'b');
    });

    test('label filter keeps only charts carrying the label', () async {
      final c = _containerWith(library);
      c.read(kundliFilterProvider.notifier).state =
          (kind: KundliFilterKind.label, value: '2026');
      final data = await _read(c);
      expect(data.others.map((k) => k.id), ['a', 'c']);
    });

    test('chip sources come from the whole library, not the filtered set',
        () async {
      // Otherwise selecting a chip would make the other chips vanish and
      // strand the user inside one filter.
      final c = _containerWith(library);
      c.read(kundliFilterProvider.notifier).state =
          (kind: KundliFilterKind.relation, value: 'Family');
      final data = await _read(c);
      expect(data.relationTags, ['Client', 'Family']);
      expect(data.labels, ['2026']);
    });

    test('search and filter compose', () async {
      final c = _containerWith(library);
      c.read(kundliFilterProvider.notifier).state =
          (kind: KundliFilterKind.relation, value: 'Client');
      c.read(kundliSearchProvider.notifier).state = 'chetan';
      expect((await _read(c)).others.single.id, 'c');
    });
  });

  group('sort', () {
    final library = [
      _k(
          id: 'old',
          name: 'Zubin',
          created: DateTime.utc(2020),
          birth: DateTime.utc(1990)),
      _k(
          id: 'new',
          name: 'Aarti',
          created: DateTime.utc(2026),
          birth: DateTime.utc(1970)),
    ];

    test('recently added puts the newest chart first', () async {
      // The old list was created_at ASC, which buried the chart you had
      // just cast at the bottom.
      final c = _containerWith(library);
      c.read(kundliSortProvider.notifier).select(KundliSort.added);
      expect((await _read(c)).others.map((k) => k.id), ['new', 'old']);
    });

    test('name sorts alphabetically', () async {
      final c = _containerWith(library);
      c.read(kundliSortProvider.notifier).select(KundliSort.name);
      expect((await _read(c)).others.map((k) => k.id), ['new', 'old']);
    });

    test('birth date sorts chronologically', () async {
      final c = _containerWith(library);
      c.read(kundliSortProvider.notifier).select(KundliSort.birth);
      expect((await _read(c)).others.map((k) => k.id), ['new', 'old']);
    });

    test('recently opened floats touched charts above untouched ones',
        () async {
      final c = _containerWith(library);
      c.read(kundliSortProvider.notifier).select(KundliSort.recent);
      c.read(recentKundlisProvider.notifier).touch('old');
      expect((await _read(c)).others.map((k) => k.id), ['old', 'new']);
    });

    test('equal sort keys still produce a stable, repeatable order',
        () async {
      // Dart's List.sort is not stable. A library imported in one go
      // shares a created_at, and nothing has been opened yet, so under
      // "recently opened" every key is equal — without a deterministic
      // tie-break the rows shuffle on each rebuild.
      final sameDay = [
        for (final name in ['Zubin', 'Aarti', 'Mohan', 'Bela', 'Kiran'])
          _k(id: name.toLowerCase(), name: name, created: DateTime.utc(2026)),
      ];
      final first = (await _read(_containerWith(sameDay)))
          .others
          .map((k) => k.id)
          .toList();
      final second = (await _read(_containerWith(sameDay.reversed.toList())))
          .others
          .map((k) => k.id)
          .toList();

      expect(first, second,
          reason: 'order must not depend on the input sequence');
      expect(first, ['aarti', 'bela', 'kiran', 'mohan', 'zubin']);
    });

    test('the most recent touch wins', () async {
      final c = _containerWith(library);
      final recents = c.read(recentKundlisProvider.notifier);
      recents.touch('old');
      recents.touch('new');
      expect((await _read(c)).others.map((k) => k.id), ['new', 'old']);
    });
  });

  group('pinning', () {
    final library = [
      _k(id: 'a', name: 'Aarti'),
      _k(id: 'b', name: 'Bela'),
    ];

    test('pinned charts are grouped out of the main list', () async {
      final c = _containerWith(library);
      c.read(pinnedKundlisProvider.notifier).toggle('b');
      final data = await _read(c);
      expect(data.pinned.single.id, 'b');
      expect(data.others.single.id, 'a');
      expect(data.visibleCount, 2);
    });

    test('toggle unpins', () async {
      final c = _containerWith(library);
      final pins = c.read(pinnedKundlisProvider.notifier);
      pins.toggle('b');
      pins.toggle('b');
      expect((await _read(c)).pinned, isEmpty);
    });

    test('pinned charts still respect search', () async {
      final c = _containerWith(library);
      c.read(pinnedKundlisProvider.notifier).toggle('b');
      c.read(kundliSearchProvider.notifier).state = 'aarti';
      final data = await _read(c);
      expect(data.pinned, isEmpty);
      expect(data.others.single.id, 'a');
    });
  });

  group('recents strip', () {
    final library = [
      _k(id: 'a', name: 'Aarti'),
      _k(id: 'b', name: 'Bela'),
    ];

    test('lists touched charts, most recent first', () async {
      final c = _containerWith(library);
      final recents = c.read(recentKundlisProvider.notifier);
      recents.touch('a');
      recents.touch('b');
      expect((await _read(c)).recents.map((k) => k.id), ['b', 'a']);
    });

    test('excludes pinned charts, which already sit at the top', () async {
      final c = _containerWith(library);
      c.read(recentKundlisProvider.notifier).touch('a');
      c.read(pinnedKundlisProvider.notifier).toggle('a');
      expect((await _read(c)).recents, isEmpty);
    });

    test('skips ids with no surviving kundli', () async {
      final c = _containerWith(library);
      final recents = c.read(recentKundlisProvider.notifier);
      recents.touch('deleted-id');
      expect((await _read(c)).recents, isEmpty);
    });

    test('forget drops deleted ids from the stored list', () async {
      final c = _containerWith(library);
      final recents = c.read(recentKundlisProvider.notifier);
      recents.touch('a');
      recents.touch('b');
      recents.forget(['a']);
      expect(c.read(recentKundlisProvider), ['b']);
    });

    test('forget leaves the list alone when nothing matches', () async {
      final c = _containerWith(library);
      final recents = c.read(recentKundlisProvider.notifier);
      recents.touch('a');
      final before = c.read(recentKundlisProvider);
      recents.forget(['not-here']);
      expect(identical(before, c.read(recentKundlisProvider)), isTrue);
    });

    test('re-touching the head is a no-op', () async {
      final c = _containerWith(library);
      final recents = c.read(recentKundlisProvider.notifier);
      recents.touch('a');
      final before = c.read(recentKundlisProvider);
      recents.touch('a');
      expect(identical(before, c.read(recentKundlisProvider)), isTrue);
    });
  });

  group('labels on the model', () {
    test('survive a row round-trip', () {
      final k = _k(id: 'a', name: 'Aarti', labels: const ['2026', 'matchmaking']);
      expect(Kundli.fromRow(k.toRow()).labels, ['2026', 'matchmaking']);
    });

    test('an empty list writes NULL rather than an empty JSON array', () {
      expect(_k(id: 'a', name: 'Aarti').toRow()['labels'], isNull);
    });

    test('a malformed column costs the labels, never the kundli', () {
      final row = _k(id: 'a', name: 'Aarti').toRow()
        ..['labels'] = 'not json at all';
      expect(Kundli.fromRow(row).labels, isEmpty);
      expect(Kundli.fromRow(row).name, 'Aarti');
    });

    test('non-string entries are dropped', () {
      final row = _k(id: 'a', name: 'Aarti').toRow()
        ..['labels'] = '["good", 7, null, "  "]';
      expect(Kundli.fromRow(row).labels, ['good']);
    });
  });

  group('A–Z grouping', () {
    test('files names under their initial', () {
      expect(initialFor('Ramesh'), 'R');
      expect(initialFor('  aarti'), 'A');
    });

    test('files non-Latin and empty names under #', () {
      // Otherwise a Devanagari-named chart creates a one-item group per
      // glyph and the letter headers stop being useful.
      expect(initialFor('रमेश'), '#');
      expect(initialFor('108'), '#');
      expect(initialFor('   '), '#');
    });
  });
}
