import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Two-finger pinch zoom + pan for custom-painted charts, safe inside
/// vertical scrollables (dashboard grid, detail ListView /
/// SingleChildScrollView).
///
/// Why this is hand-rolled instead of using `InteractiveViewer`:
/// the charts live inside vertically-scrolling parents. In the gesture
/// arena a vertical drag is claimed by the parent Scrollable, so with
/// `InteractiveViewer` vertical pinch and vertical pan get stolen by the
/// page scroll — only the horizontal axis works. `InteractiveViewer`
/// offers no way to win that vertical contest from inside a scroll view.
///
/// So we drive the transform ourselves through a scale recognizer that
/// force-wins the arena *only when the chart should be interacting*:
///
/// * fitted (scale == 1) + one finger  -> we do NOT claim, the page
///   scrolls and taps/long-press/double-tap pass through as before;
/// * two fingers (pinch)               -> we claim on BOTH axes, so
///   vertical pinch zooms instead of scrolling the page;
/// * zoomed (scale > 1) + any drag     -> we claim on BOTH axes, so
///   vertical panning pans the chart instead of scrolling the page.
///
/// Panning is clamped so the chart always covers the viewport (no empty
/// margins), matching the old minScale-1 fit behaviour. Pinching back to
/// scale 1 restores the scroll-friendly state.
class PinchZoom extends StatefulWidget {
  const PinchZoom({super.key, required this.child, this.maxScale = 6});

  final Widget child;
  final double maxScale;

  @override
  State<PinchZoom> createState() => _PinchZoomState();
}

class _PinchZoomState extends State<PinchZoom> {
  static const double _minScale = 1;

  double _scale = 1;
  Offset _translation = Offset.zero;

  // Captured at the start of each scale/pan gesture.
  double _startScale = 1;
  Offset _startTranslation = Offset.zero;
  Offset _startFocal = Offset.zero;

  bool get _zoomed => _scale > _minScale + 0.001;

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = _scale;
    _startTranslation = _translation;
    _startFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size viewport) {
    // d.scale can momentarily be 0 or non-finite as pointers change;
    // fall back to the gesture's starting scale rather than propagating
    // NaN/Infinity through the transform.
    final double raw = _startScale * d.scale;
    final double newScale =
        (raw.isFinite ? raw : _startScale).clamp(_minScale, widget.maxScale);

    // Point of the child (in child coordinates) that sat under the focal
    // point when the gesture began; keep it under the focal point now.
    final Offset childFocal = (_startFocal - _startTranslation) / _startScale;
    Offset newTranslation = d.localFocalPoint - childFocal * newScale;

    // Clamp so the scaled child never exposes empty margins. Guard against
    // an unbounded viewport dimension: the chart can be laid out with an
    // infinite constraint inside a scrollable, and at fit scale
    // (1 - newScale) is 0, so `infinity * 0` yields NaN — which would make
    // the clamp bounds NaN and throw ArgumentError.
    final double minX =
        viewport.width.isFinite ? viewport.width * (1 - newScale) : 0.0;
    final double minY =
        viewport.height.isFinite ? viewport.height * (1 - newScale) : 0.0;
    newTranslation = Offset(
      newTranslation.dx.isFinite ? newTranslation.dx.clamp(minX, 0.0) : 0.0,
      newTranslation.dy.isFinite ? newTranslation.dy.clamp(minY, 0.0) : 0.0,
    );

    if (newScale != _scale || newTranslation != _translation) {
      setState(() {
        _scale = newScale;
        _translation = newTranslation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size viewport = constraints.biggest;
        // An unbounded axis silently degrades panning: the clamp guard
        // below zeroes that axis's translation, so a zoomed chart can't
        // pan (this is exactly what broke the chakra widgets, which
        // nested AspectRatio INSIDE PinchZoom). Host this widget inside
        // something bounded — SizedBox / AspectRatio outside, as
        // chart_view does.
        assert(
            viewport.width.isFinite && viewport.height.isFinite,
            'PinchZoom needs bounded constraints on both axes '
            '(got $constraints); wrap it in a SizedBox/AspectRatio.');
        return ClipRect(
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              _ChartScaleRecognizer:
                  GestureRecognizerFactoryWithHandlers<_ChartScaleRecognizer>(
                () => _ChartScaleRecognizer(() => _zoomed),
                (r) => r
                  ..onStart = _onScaleStart
                  ..onUpdate = (d) => _onScaleUpdate(d, viewport),
              ),
            },
            child: Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.identity()
                ..translate(_translation.dx, _translation.dy)
                ..scale(_scale),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Scale recognizer that claims the gesture arena *eagerly* — the instant
/// a second finger lands (a pinch) or the first finger lands while the
/// chart is already zoomed. Winning at touch-down, before the parent
/// Scrollable reaches its drag slop, stops the page from scrolling at the
/// same time as the chart pans/zooms. At fit scale with one finger it
/// stays passive, so the page scrolls normally.
class _ChartScaleRecognizer extends ScaleGestureRecognizer {
  _ChartScaleRecognizer(this._zoomed);

  final bool Function() _zoomed;
  final Set<int> _activePointers = <int>{};

  bool get _shouldOwn => _activePointers.length >= 2 || _zoomed();

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _activePointers.add(event.pointer);
    if (_shouldOwn) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _activePointers.remove(event.pointer);
    }
    super.handleEvent(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _activePointers.clear();
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    // Refuse late rejection when we should own the gesture (e.g. the
    // parent tried to claim a vertical drag first).
    if (_shouldOwn) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}
