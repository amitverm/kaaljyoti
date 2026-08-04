import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/ui/demo_touch_overlay.dart';

/// Counts pixels that are not pure black, i.e. pixels the overlay painted
/// on top of the black backdrop below it.
Future<int> _litPixels(WidgetTester tester, Key boundaryKey) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data;
  });
  var lit = 0;
  for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
    if (bytes.getUint8(i) != 0) lit++;
  }
  return lit;
}

void main() {
  const boundaryKey = ValueKey('boundary');

  Widget harness() => MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: const DemoTouchOverlay(
            child: ColoredBox(color: Colors.black, child: SizedBox.expand()),
          ),
        ),
      );

  testWidgets('paints nothing until a finger is down', (tester) async {
    await tester.pumpWidget(harness());
    expect(await _litPixels(tester, boundaryKey), 0);
  });

  testWidgets('marks each active pointer, and clears after the lift ripple',
      (tester) async {
    await tester.pumpWidget(harness());

    final one = await tester.startGesture(const Offset(100, 100));
    await tester.pump();
    final single = await _litPixels(tester, boundaryKey);
    expect(single, greaterThan(0));

    // A second finger — the pinch case — must draw its own dot.
    final two = await tester.startGesture(const Offset(240, 300));
    await tester.pump();
    expect(await _litPixels(tester, boundaryKey), greaterThan(single));

    // Dots follow the fingers rather than sticking where they landed.
    await one.moveTo(const Offset(60, 400));
    await two.moveTo(const Offset(300, 420));
    await tester.pump();
    expect(await _litPixels(tester, boundaryKey), greaterThan(single));

    await one.up();
    await two.up();
    await tester.pump();
    // Ripple is still fading here.
    expect(await _litPixels(tester, boundaryKey), greaterThan(0));

    // ...and is gone once it completes, leaving no residue on screen.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(await _litPixels(tester, boundaryKey), 0);
  });

  test('is compiled out unless DEMO_MODE is defined', () {
    expect(DemoTouchOverlay.enabled, isFalse);
  });
}
