/// "Long screenshot" capture — rasterizes a widget at its FULL content
/// height, however far past the screen that runs.
///
/// Neither iOS nor Android offers a scrolling screenshot of a Flutter
/// surface, and `RenderRepaintBoundary.toImage` on an on-screen board
/// only ever yields the visible screenful. The way out is to mount a
/// second, throwaway copy of the content offscreen inside a scroll
/// viewport: the viewport hands its child UNBOUNDED height, so the
/// boundary lays out at full length even though a single screenful is
/// all that would ever be visible — and it isn't visible at all, because
/// the whole thing sits one screen-width to the right.
///
/// How big a texture the GPU will actually allocate can't be asked from
/// Dart, and the honest answers differ by an order of magnitude in area:
/// every iPhone the app supports and most current Android GPUs take
/// 16384 a side, while budget and older Android parts stop at 8192 or
/// 4096. Assuming the floor throws away the resolution the majority
/// could have had — a 6000pt board clamped to 8192 renders at ratio 1.4
/// instead of the device's 3.0, which is the difference between a shared
/// screenshot you can read and one you can't — so the capture guesses
/// high and steps down instead (see [captureRatioLadder]).
///
/// Guessing high means asking for textures a device may refuse, and the
/// refusals are not uniform: an engine throw, a silently blank image, or
/// — the nastiest — a silent crop to the cap that looks like a perfectly
/// good screenshot with the bottom missing. Each rung is therefore
/// checked before it is accepted, and a rung that fails any check is
/// just the next one's cue.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/theme/theme.dart';

/// Texture-side limits to try, most optimistic first: 16384 is what
/// A9-and-later iPhones and current Android GPUs report, 8192 and 4096
/// are where older and budget Android parts stop.
@visibleForTesting
const captureTextureCaps = <double>[16384, 8192, 4096];

/// Rasterization scale for one rung of the ladder: the device ratio,
/// bounded by [maxPixelRatio] and by what [cap] leaves for a board
/// [longestSide] logical pixels long. Not floored — the caller decides
/// whether a sub-1.0 result is worth attempting.
@visibleForTesting
double captureRatioFor(
  double longestSide,
  double dpr,
  double cap, {
  double? maxPixelRatio,
}) {
  final wanted = math.min(dpr, maxPixelRatio ?? 3.0);
  return math.min(wanted, cap / longestSide);
}

/// The scales to attempt, in order, for a board [longestSide] long.
///
/// Every cap gets a rung, including the ones that don't bind. It is
/// tempting to stop as soon as a cap leaves the full device ratio
/// intact — nothing below it could look better — but a GPU under its
/// stated limit doesn't announce itself: it crops (see
/// [captureDimsMatch]). A 2390pt board asks for 7170px at ratio 3.0,
/// which a 4096-limited part will answer with a half-height image, and
/// the only recovery is a rung that asks for less. Rungs below the
/// first cost nothing unless the one above them fails.
///
/// The last rung is floored at 1.0 for boards so long that nothing will
/// rasterize them: better to fail into the null path than to ship a
/// postage stamp.
@visibleForTesting
List<double> captureRatioLadder(
  double longestSide,
  double dpr, {
  double? maxPixelRatio,
}) {
  final ratios = [
    for (final cap in captureTextureCaps)
      captureRatioFor(longestSide, dpr, cap, maxPixelRatio: maxPixelRatio),
  ];
  ratios[ratios.length - 1] = math.max(ratios.last, 1.0);
  // Consecutive duplicates only: a cap that doesn't bind repeats the rung
  // above it, and the floor can land on one too. Re-rasterizing identical
  // pixels after a failure just spends another second failing.
  return [
    for (var i = 0; i < ratios.length; i++)
      if (i == 0 || ratios[i] != ratios[i - 1]) ratios[i],
  ];
}

/// Whether a rasterized image came back the size that was asked for.
///
/// `toImage` is not obliged to honour the request. Past the GPU's real
/// limit this engine build neither throws nor blanks — it silently
/// CROPS to the cap: a 686x16384 request answered with 686x8192, the
/// bottom half of the board and the footer simply gone, in a
/// plausible-looking 330KB PNG that every other check waves through.
/// Expected pixels are known exactly, so comparing them catches the
/// crop, a uniform downscale, and anything else the engine substitutes,
/// with no guessing. Two pixels of slack for the rounding between
/// `logical * ratio` and the engine's own integer arithmetic.
@visibleForTesting
bool captureDimsMatch(int width, int height, Size logical, double ratio) {
  const slack = 2;
  return (width - (logical.width * ratio).round()).abs() <= slack &&
      (height - (logical.height * ratio).round()).abs() <= slack;
}

/// Whether an encoded capture is implausibly small for its dimensions.
///
/// Some engine/GPU combinations answer an oversized allocation with a
/// silently blank image instead of throwing, and reading megabytes of
/// raw pixels back to check is far more expensive than the capture
/// itself. The PNG length is the cheap tell: a real board at this size
/// encodes to hundreds of kilobytes, while a flat paper-coloured
/// rectangle deflates to a few. Deliberately lopsided thresholds — a
/// false positive only costs one extra attempt, a false negative ships
/// an empty screenshot.
bool _looksBlank(int width, int height, int byteLength) =>
    width * height > 2000000 && byteLength < 24 * 1024;

/// Renders [child] offscreen at [width] logical pixels wide and returns
/// it as PNG bytes, at whatever height the content needs.
///
/// [maxPixelRatio] caps the rasterization scale (default 3.0); the
/// effective ratio is whatever the first texture cap in
/// [captureRatioLadder] the GPU actually honours allows. Returns null —
/// never throws — if the overlay, the layout, or every rung of the
/// ladder fails: a share that quietly declines is recoverable, a crash
/// mid-share is not.
Future<Uint8List?> captureLongWidget(
  BuildContext context, {
  required Widget child,
  required double width,
  double? maxPixelRatio,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final screen = MediaQuery.sizeOf(context);
  final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  final captureKey = GlobalKey();

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      // Parked one screen-width to the right rather than hidden behind
      // Offstage/Opacity(0): both skip the paint phase, and a boundary
      // that never painted has no layer for toImage to rasterize.
      left: screen.width,
      top: 0,
      width: width,
      height: screen.height,
      child: IgnorePointer(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: captureKey,
            // Material supplies the canvas colour and the text/icon
            // defaults the cards expect; the overlay already inherits
            // Directionality and the app theme from MaterialApp.
            child: Material(color: KJColors.paper, child: child),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Two frames, not one: the first lays the new subtree out, the
    // second paints it. Rasterizing after only the first gets a
    // boundary with no picture.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || boundary.size.isEmpty) return null;

    final size = boundary.size;
    final ladder = captureRatioLadder(
      math.max(size.width, size.height),
      devicePixelRatio,
      maxPixelRatio: maxPixelRatio,
    );

    for (final ratio in ladder) {
      ui.Image? image;
      try {
        image = await boundary.toImage(pixelRatio: ratio);
        // Before paying for the PNG encode: a cropped rung is worthless
        // however well it encodes.
        if (!captureDimsMatch(image.width, image.height, size, ratio)) continue;
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = data?.buffer.asUint8List();
        if (bytes != null &&
            !_looksBlank(image.width, image.height, bytes.length)) {
          return bytes;
        }
      } catch (_) {
        // An over-allocation throws from deep in the engine, in shapes
        // that vary by platform; whatever it was, the next rung asks for
        // less. If this was the last one the loop falls out to null.
      } finally {
        image?.dispose();
      }
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    entry.remove();
  }
}
