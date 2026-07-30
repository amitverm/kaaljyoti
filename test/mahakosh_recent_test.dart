/// Mahakosh "recently opened" — device-local, keyed by mk_code and kept
/// deliberately separate from the kundli recents so the two id spaces
/// can't cross.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('records opens, most recent first', () {
    final c = container();
    final n = c.read(recentMahakoshProvider.notifier);
    n.touch('MK-1');
    n.touch('MK-2');
    expect(c.read(recentMahakoshProvider), ['MK-2', 'MK-1']);
  });

  test('re-opening moves a chart back to the head without duplicating', () {
    final c = container();
    final n = c.read(recentMahakoshProvider.notifier);
    n.touch('MK-1');
    n.touch('MK-2');
    n.touch('MK-1');
    expect(c.read(recentMahakoshProvider), ['MK-1', 'MK-2']);
  });

  test('re-touching the head writes nothing', () {
    final c = container();
    final n = c.read(recentMahakoshProvider.notifier);
    n.touch('MK-1');
    final before = c.read(recentMahakoshProvider);
    n.touch('MK-1');
    expect(identical(before, c.read(recentMahakoshProvider)), isTrue);
  });

  test('forget drops a hidden or reported chart', () {
    // Otherwise the Recent tab hands back the chart the user just hid.
    final c = container();
    final n = c.read(recentMahakoshProvider.notifier);
    n.touch('MK-1');
    n.touch('MK-2');
    n.forget(['MK-1']);
    expect(c.read(recentMahakoshProvider), ['MK-2']);
  });

  test('forget on an absent code changes nothing', () {
    final c = container();
    final n = c.read(recentMahakoshProvider.notifier);
    n.touch('MK-1');
    final before = c.read(recentMahakoshProvider);
    n.forget(['MK-9']);
    expect(identical(before, c.read(recentMahakoshProvider)), isTrue);
  });

  test('persists across containers', () async {
    final first = container();
    first.read(recentMahakoshProvider.notifier).touch('MK-7');
    // Let the debounce-free write reach the mock prefs store.
    await Future<void>.delayed(Duration.zero);

    final second = container();
    second.read(recentMahakoshProvider);
    await Future<void>.delayed(Duration.zero);
    expect(second.read(recentMahakoshProvider), contains('MK-7'));
  });

  test('is stored separately from the kundli recents', () async {
    // Mixing the id spaces would let a withdrawn community chart hold a
    // slot in the kundli strip, and vice versa.
    final c = container();
    c.read(recentMahakoshProvider.notifier).touch('MK-1');
    c.read(recentKundlisProvider.notifier).touch('kundli-uuid');
    await Future<void>.delayed(Duration.zero);

    expect(c.read(recentMahakoshProvider), ['MK-1']);
    expect(c.read(recentKundlisProvider), ['kundli-uuid']);

    final repo = SettingsRepository();
    expect(await repo.recentMahakoshCodes(), ['MK-1']);
    expect(await repo.recentKundliIds(), ['kundli-uuid']);
  });

  test('the stored list is capped', () async {
    final c = container();
    final n = c.read(recentMahakoshProvider.notifier);
    for (var i = 0; i < SettingsRepository.recentCap + 20; i++) {
      n.touch('MK-$i');
    }
    await Future<void>.delayed(Duration.zero);
    final stored = await SettingsRepository().recentMahakoshCodes();
    expect(stored, hasLength(SettingsRepository.recentCap));
    // The cap trims the tail, never the head.
    expect(stored.first, 'MK-${SettingsRepository.recentCap + 19}');
  });
}
