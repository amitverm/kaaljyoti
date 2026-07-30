/// Manual place dialog: DMS input end-to-end — parsing echo, the
/// swapped-hemisphere-letter inline errors (the real-user mistake:
/// "18E58" typed as a latitude), timezone auto-derivation, and submit.
/// The real PlaceLookupService is used — the dialog only touches its
/// offline timezone methods, never the network geocoder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/services/place_lookup_service.dart';
import 'package:kaaljyoti/ui/manual_place_dialog.dart';

void main() {
  final lookup = PlaceLookupService();

  Future<void> pumpDialog(WidgetTester tester,
      {void Function(PlaceResult?)? onResult}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final r = await showDialog<PlaceResult>(
                  context: context,
                  builder: (_) => ManualPlaceDialog(lookup: lookup),
                );
                onResult?.call(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder fieldByLabel(String label) => find.ancestor(
      of: find.text(label), matching: find.byType(TextField));

  testWidgets('DMS entry echoes decimal and auto-derives the timezone',
      (tester) async {
    await pumpDialog(tester);
    await tester.enterText(fieldByLabel('Latitude'), "18N58'");
    await tester.pump();
    expect(find.text('= 18.9667°'), findsOneWidget);
    await tester.enterText(fieldByLabel('Longitude'), "72E50'");
    await tester.pump();
    expect(find.text('= 72.8333°'), findsOneWidget);
    // Mumbai coordinates → offline polygon lookup fills the zone.
    expect(find.text('Asia/Kolkata'), findsWidgets);
  });

  testWidgets('swapped hemisphere letters get specific inline errors',
      (tester) async {
    await pumpDialog(tester);
    // The reported real-world mistake: E in latitude, N in longitude.
    await tester.enterText(fieldByLabel('Latitude'), "18E58'");
    await tester.enterText(fieldByLabel('Longitude'), "72N50'");
    await tester.pump();
    expect(find.textContaining('Latitude uses N or S'), findsOneWidget);
    expect(find.textContaining('Longitude uses E or W'), findsOneWidget);
    // No decimal echo for unparseable values.
    expect(find.textContaining('= '), findsNothing);
  });

  testWidgets('out-of-range and junk values get the format error',
      (tester) async {
    await pumpDialog(tester);
    await tester.enterText(fieldByLabel('Latitude'), '95');
    await tester.pump();
    expect(find.textContaining('−90 to 90'), findsOneWidget);
    await tester.enterText(fieldByLabel('Latitude'), 'abc');
    await tester.pump();
    expect(find.textContaining('−90 to 90'), findsOneWidget);
    // Errors clear once the value parses.
    await tester.enterText(fieldByLabel('Latitude'), "18N58'");
    await tester.pump();
    expect(find.textContaining('−90 to 90'), findsNothing);
  });

  testWidgets('valid DMS entry submits a PlaceResult with decimal coords',
      (tester) async {
    PlaceResult? result;
    await pumpDialog(tester, onResult: (r) => result = r);
    await tester.enterText(fieldByLabel('Place of birth'), 'Girgaon');
    await tester.enterText(fieldByLabel('Latitude'), "18N58'");
    await tester.enterText(fieldByLabel('Longitude'), "72E50'");
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.latitude, closeTo(18 + 58 / 60, 1e-9));
    expect(result!.longitude, closeTo(72 + 50 / 60, 1e-9));
    expect(result!.timezoneName, 'Asia/Kolkata');
  });
}
