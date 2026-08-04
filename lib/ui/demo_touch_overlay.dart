import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Paints a finger-sized dot under every active pointer, plus a short
/// expanding ripple when the finger lifts, so screen recordings show
/// where the user touched.
///
/// Why this has to live in the app: `xcrun simctl io recordVideo`
/// captures the device framebuffer only. The Simulator's own two grey
/// pinch circles are drawn as a window overlay and never reach the file,
/// and a single tap draws nothing anywhere — so nothing outside the app
/// can put a touch indicator into an iOS recording. Painting it here
/// works for taps and multi-finger pinches alike, on device as well as
/// simulator, and is captured by any recorder.
///
/// Compiled out unless you pass `--dart-define=DEMO_MODE=true`:
/// [enabled] is a `const`, so release builds carry neither the [Listener]
/// nor the ticker.
class DemoTouchOverlay extends StatefulWidget {
  const DemoTouchOverlay({super.key, required this.child});

  /// Whether demo indicators should be wired in at all.
  static const bool enabled = bool.fromEnvironment('DEMO_MODE');

  /// Radius of the dot under a resting finger, in logical pixels. Roughly
  /// a fingertip — big enough to read after the footage is scaled down to
  /// a 1080-wide Reel.
  static const double radius = 26;

  /// Indicator colour — the palette's Jupiter saffron. Hardcoded rather
  /// than read from KJColors so the demo overlay stays independent of
  /// which palette is active while recording.
  static const Color tint = Color(0xFFE07B00);

  final Widget child;

  @override
  State<DemoTouchOverlay> createState() => _DemoTouchOverlayState();
}

class _Ripple {
  const _Ripple(this.position, this.start);

  final Offset position;
  final Duration start;
}

class _DemoTouchOverlayState extends State<DemoTouchOverlay>
    with SingleTickerProviderStateMixin {
  /// How long a lift-off ripple takes to fade. Long enough that a quick
  /// tap still registers on camera, short enough not to trail behind a
  /// fast sequence of taps.
  static const Duration _fade = Duration(milliseconds: 420);

  final Map<int, Offset> _active = {};
  final List<_Ripple> _ripples = [];

  late final Ticker _ticker;
  Duration _now = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Drives only the ripple fade; pointer movement repaints via the
    // Listener callbacks, so this returns immediately while idle.
    _ticker = createTicker((elapsed) {
      _now = elapsed;
      if (_ripples.isEmpty) return;
      _ripples.removeWhere((r) => elapsed - r.start > _fade);
      setState(() {});
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _track(PointerEvent event) {
    setState(() => _active[event.pointer] = event.localPosition);
  }

  void _release(PointerEvent event) {
    setState(() {
      final last = _active.remove(event.pointer);
      if (last != null) _ripples.add(_Ripple(last, _now));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Observe every pointer, including ones over empty areas. Listener
      // never consumes events, so the app below behaves normally.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _track,
      onPointerMove: _track,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TouchPainter(
                  active: _active.values.toList(growable: false),
                  ripples: _ripples,
                  now: _now,
                  fade: _fade,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TouchPainter extends CustomPainter {
  const _TouchPainter({
    required this.active,
    required this.ripples,
    required this.now,
    required this.fade,
  });

  final List<Offset> active;
  final List<_Ripple> ripples;
  final Duration now;
  final Duration fade;

  @override
  void paint(Canvas canvas, Size size) {
    const r = DemoTouchOverlay.radius;

    for (final p in active) {
      _dot(canvas, p, r, 1);
    }

    for (final ripple in ripples) {
      final t = ((now - ripple.start).inMicroseconds / fade.inMicroseconds)
          .clamp(0.0, 1.0);
      // Expand slightly and fade out, so a lift reads as a released tap
      // rather than the finger simply vanishing.
      _dot(canvas, ripple.position, r + 18 * t, 1 - t);
    }
  }

  void _dot(Canvas canvas, Offset centre, double radius, double opacity) {
    const tint = DemoTouchOverlay.tint;
    canvas.drawCircle(
      centre,
      radius,
      Paint()..color = tint.withValues(alpha: 0.26 * opacity),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = tint.withValues(alpha: 0.85 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TouchPainter old) => true;
}
