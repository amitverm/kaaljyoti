/// Kundli list screen rendering. Providers are overridden so no DB,
/// network, or ephemeris is touched — the point is layout and what the
/// row actually shows at each density, which unit tests over
/// [kundliListDataProvider] can't catch.
///
/// Any RenderFlex overflow fails these tests automatically: the widget
/// tester reports layout exceptions as test failures.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/screens/kundli_list_screen.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Kundli _k({
  required String id,
  required String name,
  String relationTag = 'Client',
  String? note,
  List<String> labels = const [],
  bool syncEnabled = false,
  bool isArchived = false,
}) =>
    Kundli(
      id: id,
      name: name,
      relationTag: relationTag,
      note: note,
      labels: labels,
      isArchived: isArchived,
      birthUtc: DateTime.utc(1987, 3, 12, 3, 22),
      latitude: 18.52,
      longitude: 73.86,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
      placeName: 'Pune, Maharashtra, India',
      syncEnabled: syncEnabled,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester,
    List<Kundli> kundlis, {
    KundliDensity density = KundliDensity.comfortable,
  }) async {
    final container = ProviderContainer(overrides: [
      kundlisProvider.overrideWith((ref) async => kundlis),
    ]);
    addTearDown(container.dispose);
    container.read(kundliDensityProvider.notifier).select(density);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const KundliListScreen()),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('comfortable rows show name and birth stamp, not the place',
      (tester) async {
    await pump(tester, [_k(id: 'a', name: 'Ramesh Sharma')]);

    expect(find.text('Ramesh Sharma'), findsOneWidget);
    expect(find.textContaining('08:52'), findsOneWidget,
        reason: 'birth time, converted to the +5:30 birth zone');
    // Place was the longest thing on the row and the least identifying.
    expect(find.textContaining('Pune'), findsNothing);
  });

  testWidgets('the note replaces the birth stamp when there is one',
      (tester) async {
    // A note identifies a person; a date of birth mostly doesn't.
    await pump(tester, [
      _k(id: 'a', name: 'Ramesh Sharma', note: "Ramesh's daughter — match"),
    ]);

    expect(find.text("Ramesh's daughter — match"), findsOneWidget);
    expect(find.textContaining('08:52'), findsNothing);
  });

  testWidgets('sync state renders as a cloud glyph, in both states',
      (tester) async {
    await pump(tester, [
      _k(id: 'a', name: 'Synced', syncEnabled: true),
      _k(id: 'b', name: 'Local', syncEnabled: false),
    ]);

    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('the list options icon does not reuse the dashboard glyph',
      (tester) async {
    // Icons.tune is the dashboard's "arrange widgets" control, in the
    // same app-bar slot one tap away. Same glyph + same position +
    // different verb is the case where a repeated icon misleads.
    await pump(tester, [_k(id: 'a', name: 'Ramesh Sharma')]);

    expect(find.byIcon(Icons.sort), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsNothing);
  });

  testWidgets('the per-row edit pencil is gone', (tester) async {
    // It cost header width on every row for an action wanted rarely; the
    // dashboard app bar carries it now.
    await pump(tester, [_k(id: 'a', name: 'Ramesh Sharma')]);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('the default density computes no lagna/moon quick reads',
      (tester) async {
    // snapshotProvider is deliberately NOT overridden: if a default-density
    // row watched it, this would throw trying to reach the real ephemeris.
    await pump(tester, [
      for (var i = 0; i < 30; i++) _k(id: '$i', name: 'Chart $i'),
    ]);

    expect(find.text('Chart 0'), findsOneWidget);
    expect(find.textContaining('Lagna'), findsNothing);
  });

  testWidgets('compact density drops the second line', (tester) async {
    await pump(
      tester,
      [_k(id: 'a', name: 'Ramesh Sharma', note: 'career reading')],
      density: KundliDensity.compact,
    );

    expect(find.text('Ramesh Sharma'), findsOneWidget);
    expect(find.text('career reading'), findsNothing);
  });

  testWidgets('a long library builds lazily rather than all at once',
      (tester) async {
    // The old screen used the eager ListView(children:) constructor, so
    // 200 kundlis meant 200 rows built — and, back then, 200 ephemeris
    // computations — on every visit to the home screen.
    await pump(tester, [
      for (var i = 0; i < 200; i++)
        _k(id: '$i', name: 'Chart ${i.toString().padLeft(3, '0')}'),
    ]);

    expect(find.text('Chart 000'), findsOneWidget);
    expect(find.text('Chart 199'), findsNothing,
        reason: 'offscreen rows must not be built');
  });

  testWidgets('search is shown for a large library and hidden for a small one',
      (tester) async {
    await pump(tester, [_k(id: 'a', name: 'Solo')]);
    expect(find.byType(TextField), findsNothing,
        reason: 'a handful of charts needs no search box');

    await pump(tester, [
      for (var i = 0; i < 20; i++) _k(id: '$i', name: 'Chart $i'),
    ]);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('typing in the search box filters the rows', (tester) async {
    await pump(tester, [
      for (var i = 0; i < 20; i++) _k(id: '$i', name: 'Chart $i'),
      _k(id: 'x', name: 'Ramesh Sharma'),
    ]);

    await tester.enterText(find.byType(TextField), 'ramesh');
    await tester.pumpAndSettle();

    expect(find.text('Ramesh Sharma'), findsOneWidget);
    expect(find.text('Chart 0'), findsNothing);
  });

  testWidgets('a search with no matches offers a way back out',
      (tester) async {
    final container = await pump(tester, [
      for (var i = 0; i < 20; i++) _k(id: '$i', name: 'Chart $i'),
    ]);

    await tester.enterText(find.byType(TextField), 'nothing matches this');
    await tester.pumpAndSettle();
    expect(find.text('No kundlis match that search.'), findsOneWidget);

    await tester.tap(find.text('Clear search and filters'));
    await tester.pumpAndSettle();
    expect(container.read(kundliSearchProvider), isEmpty);
    expect(find.text('Chart 0'), findsOneWidget);
  });

  testWidgets('pinned charts get their own section above the rest',
      (tester) async {
    final container = await pump(tester, [
      _k(id: 'a', name: 'Aarti'),
      _k(id: 'b', name: 'Bela'),
    ]);

    container.read(pinnedKundlisProvider.notifier).toggle('b');
    await tester.pumpAndSettle();

    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('ALL KUNDLIS'), findsOneWidget);
    // The pinned row sits above the unpinned one.
    final pinnedY = tester.getTopLeft(find.text('Bela')).dy;
    final otherY = tester.getTopLeft(find.text('Aarti')).dy;
    expect(pinnedY, lessThan(otherY));
  });

  testWidgets('long-press enters multi-select with bulk actions',
      (tester) async {
    final container = await pump(tester, [
      _k(id: 'a', name: 'Aarti'),
      _k(id: 'b', name: 'Bela'),
    ]);

    await tester.longPress(find.text('Aarti'));
    await tester.pumpAndSettle();

    expect(container.read(kundliMultiSelectProvider), {'a'});
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('bulk pin applies to the whole selection', (tester) async {
    final container = await pump(tester, [
      _k(id: 'a', name: 'Aarti'),
      _k(id: 'b', name: 'Bela'),
    ]);

    await tester.longPress(find.text('Aarti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bela'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pumpAndSettle();

    expect(container.read(pinnedKundlisProvider), {'a', 'b'});
    expect(container.read(kundliMultiSelectProvider), isNull,
        reason: 'the bulk action exits select mode');
  });

  testWidgets('filter chips appear for labels and filter the list',
      (tester) async {
    await pump(tester, [
      _k(id: 'a', name: 'Aarti', labels: const ['matchmaking']),
      _k(id: 'b', name: 'Bela'),
    ]);

    await tester.tap(find.text('matchmaking'));
    await tester.pumpAndSettle();

    expect(find.text('Aarti'), findsOneWidget);
    expect(find.text('Bela'), findsNothing);
  });

  testWidgets('the recents strip shows recently opened charts',
      (tester) async {
    final container = await pump(tester, [
      for (var i = 0; i < 20; i++) _k(id: '$i', name: 'Chart $i'),
    ]);

    expect(find.text('RECENT'), findsNothing,
        reason: 'nothing has been opened yet');

    container.read(recentKundlisProvider.notifier).touch('7');
    await tester.pumpAndSettle();

    expect(find.text('RECENT'), findsOneWidget);
    // Once in the strip and once in the list proper.
    expect(find.text('Chart 7'), findsNWidgets(2));
  });

  group('the archived filter chip', () {
    /// Scoped to the app bar: the chip carries the archive glyph too, so
    /// a bare byIcon finder cannot tell the bulk action from the filter.
    Finder barIcon(IconData icon) => find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(icon),
        );

    testWidgets('does not render when nothing is archived', (tester) async {
      await pump(tester, [
        _k(id: 'a', name: 'Aarti', labels: const ['matchmaking']),
      ]);
      expect(find.textContaining('Archived'), findsNothing);
    });

    testWidgets('shows the count and sits last in the row', (tester) async {
      await pump(tester, [
        _k(id: 'a', name: 'Aarti', labels: const ['matchmaking']),
        _k(id: 'b', name: 'Bela', isArchived: true),
        _k(id: 'c', name: 'Chetan', isArchived: true),
      ]);

      expect(find.text('Archived (2)'), findsOneWidget);
      // Last: to the right of the "All" chip and of the label chip.
      double x(String t) => tester.getTopLeft(find.text(t)).dx;
      expect(x('Archived (2)'), greaterThan(x('All')));
      expect(x('Archived (2)'), greaterThan(x('matchmaking')));
    });

    testWidgets('appears even when it is the only thing to filter by',
        (tester) async {
      // No labels and a single relation tag, so the row's other two
      // reasons to exist are both absent — and the archive would
      // otherwise be unreachable.
      await pump(tester, [
        _k(id: 'a', name: 'Aarti'),
        _k(id: 'b', name: 'Bela', isArchived: true),
      ]);
      expect(find.text('Archived (1)'), findsOneWidget);
    });

    testWidgets('archived charts stay out of the list until it is tapped',
        (tester) async {
      await pump(tester, [
        _k(id: 'a', name: 'Aarti'),
        _k(id: 'b', name: 'Bela', isArchived: true),
      ]);
      expect(find.text('Aarti'), findsOneWidget);
      expect(find.text('Bela'), findsNothing);
    });

    testWidgets('selecting it swaps the body for the archived charts',
        (tester) async {
      await pump(tester, [
        _k(id: 'a', name: 'Aarti'),
        _k(id: 'b', name: 'Bela', isArchived: true),
      ]);

      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Bela'), findsOneWidget);
      expect(find.text('Aarti'), findsNothing,
          reason: 'the archived view replaces the list, it does not append');
    });

    testWidgets('tapping it again returns to the active library',
        (tester) async {
      final container = await pump(tester, [
        _k(id: 'a', name: 'Aarti'),
        _k(id: 'b', name: 'Bela', isArchived: true),
      ]);

      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();

      expect(container.read(kundliFilterProvider), isNull);
      expect(find.text('Aarti'), findsOneWidget);
      expect(find.text('Bela'), findsNothing);
    });

    testWidgets('search composes with it', (tester) async {
      await pump(tester, [
        for (var i = 0; i < 20; i++) _k(id: '$i', name: 'Chart $i'),
        _k(id: 'x', name: 'Ramesh Sharma', isArchived: true),
        _k(id: 'y', name: 'Sunita Patil', isArchived: true),
      ]);

      await tester.tap(find.text('Archived (2)'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ramesh');
      await tester.pumpAndSettle();

      expect(find.text('Ramesh Sharma'), findsOneWidget);
      expect(find.text('Sunita Patil'), findsNothing);
    });

    testWidgets('no pinned section inside the archived view', (tester) async {
      // Archiving drops the pin, but a chart can arrive archived from
      // another device while this one still holds the pin locally.
      final container = await pump(tester, [
        _k(id: 'a', name: 'Aarti'),
        _k(id: 'b', name: 'Bela', isArchived: true),
      ]);
      container.read(pinnedKundlisProvider.notifier).toggle('b');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();

      expect(find.text('PINNED'), findsNothing);
      expect(find.text('Bela'), findsOneWidget);
    });

    testWidgets('bulk-select there offers Unarchive', (tester) async {
      await pump(tester, [
        _k(id: 'a', name: 'Aarti'),
        _k(id: 'b', name: 'Bela', isArchived: true),
      ]);

      await tester.longPress(find.text('Aarti'));
      await tester.pumpAndSettle();
      expect(barIcon(Icons.archive_outlined), findsOneWidget);
      expect(barIcon(Icons.unarchive_outlined), findsNothing);

      // An all-archived selection flips the one button round.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archived (1)'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Bela'));
      await tester.pumpAndSettle();
      expect(barIcon(Icons.unarchive_outlined), findsOneWidget);
      expect(barIcon(Icons.archive_outlined), findsNothing);
    });
  });

  testWidgets('first run shows the empty state, not the search chrome',
      (tester) async {
    await pump(tester, []);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('New Kundli'), findsOneWidget);
  });

  // The nav pill clipped on the right on narrow real phones (seen on a
  // 360dp Android) and in every phone-width test — five sections of text
  // can outgrow the screen, and the test font's square glyphs make the
  // labels wider still. KJNavPill now scales down instead of clipping,
  // and these pins hold at the sizes that used to fail. Overflow needs
  // no explicit assert: the tester turns RenderFlex overflow into a
  // test failure on its own.
  group('the nav pill fits phone widths', () {
    Future<void> pumpAt(WidgetTester tester, Size logical,
        {double textScale = 1.0}) async {
      tester.view.physicalSize = logical;
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pump(tester, [_k(id: 'a', name: 'Ramesh Sharma')]);
    }

    testWidgets('393x852 (iPhone 15) — used to overflow by 106px',
        (tester) async {
      await pumpAt(tester, const Size(393, 852));
    });

    testWidgets('360x800 (narrow Android) — used to overflow by 139px',
        (tester) async {
      await pumpAt(tester, const Size(360, 800));
    });

    testWidgets('360x800 with a raised system font size', (tester) async {
      // The classmate case: narrow screen AND a user-scaled font. The
      // pill must absorb both at once.
      await pumpAt(tester, const Size(360, 800), textScale: 1.3);
    });
  });
}
