/// The moon-phase disc, rasterized.
///
/// The painter's whole job is that the LIT AREA tracks the Sun→Moon
/// elongation and sits on the correct limb, and neither claim survives
/// an inspection of the widget tree — so these render it and count
/// pixels. Explicit black/white inks (rather than the theme's) keep the
/// count a threshold rather than a colour match, so a palette change
/// can't quietly break the test.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/moon_phase_painter.dart';

const _size = 64.0;

MoonPhasePainter _painter(double elongation) => MoonPhasePainter(
      elongation: elongation,
      lit: const Color(0xFFFFFFFF),
      dark: const Color(0xFF000000),
      rim: const Color(0xFF000000),
    );

Future<ui.Image> _render(double elongation) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _size, _size));
  canvas.drawRect(
      const Rect.fromLTWH(0, 0, _size, _size), Paint()..color = Colors.black);
  _painter(elongation).paint(canvas, const Size(_size, _size));
  return recorder.endRecording().toImage(_size.round(), _size.round());
}

/// Lit pixels, and how many of them sit on each half of the disc.
Future<({int lit, int left, int right})> _measure(double elongation) async {
  final image = await _render(elongation);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  final bytes = data!.buffer.asUint8List();
  var lit = 0, left = 0, right = 0;
  for (var i = 0; i < bytes.length; i += 4) {
    if (bytes[i] < 200) continue; // dark ground / shadowed limb
    lit++;
    final x = (i ~/ 4) % _size.round();
    if (x < _size / 2) {
      left++;
    } else {
      right++;
    }
  }
  return (lit: lit, left: left, right: right);
}

void main() {
  testWidgets('the lit area grows from new moon to full and back',
      (tester) async {
    late int newMoon, firstQuarter, full, lastQuarter;
    await tester.runAsync(() async {
      newMoon = (await _measure(0)).lit;
      firstQuarter = (await _measure(90)).lit;
      full = (await _measure(180)).lit;
      lastQuarter = (await _measure(270)).lit;
    });

    expect(newMoon, lessThan(full ~/ 20),
        reason: 'a new moon should be all but unlit');
    expect(firstQuarter, greaterThan(newMoon));
    expect(full, greaterThan(firstQuarter));
    // The quarters are the same half-disc seen from opposite sides.
    expect(lastQuarter, closeTo(firstQuarter, full * 0.05));
    // A half-lit disc really is about half of a full one.
    expect(firstQuarter, closeTo(full / 2, full * 0.08));
  });

  testWidgets('waxing lights the right limb and waning the left',
      (tester) async {
    late ({int lit, int left, int right}) waxing, waning, full;
    await tester.runAsync(() async {
      waxing = await _measure(60); // Shukla crescent
      waning = await _measure(300); // Krishna crescent
      full = await _measure(180);
    });

    expect(waxing.right, greaterThan(waxing.left * 5));
    expect(waning.left, greaterThan(waning.right * 5));
    // The two crescents are mirror images of one another.
    expect(waxing.lit, closeTo(waning.lit, full.lit * 0.02));
  });

  testWidgets('the disc rasterizes to a real PNG', (tester) async {
    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await _render(120);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      bytes = data!.buffer.asUint8List();
    });
    expect(bytes.sublist(0, 8),
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        reason: 'not a PNG');
  });

  test('repaints only when something it draws from changed', () {
    expect(_painter(90).shouldRepaint(_painter(90)), isFalse);
    expect(_painter(90).shouldRepaint(_painter(91)), isTrue);
  });
}
