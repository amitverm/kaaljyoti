/// Design tokens — the shared scales that back every screen so spacing,
/// corner radii, icon sizing, and tint opacities read as one system
/// instead of per-widget guesses.
///
/// Colour lives in [KJColors] (theme.dart) and type in [KJType]
/// (type_scale.dart); this file covers the geometry tokens. Prefer
/// these over raw literals: `KJSpace.md` not `12`, `KJRadius.lg` not
/// `BorderRadius.circular(16)`.
library;

import 'package:flutter/widgets.dart';

/// Spacing scale on a 4pt grid. Gaps between elements, list rhythm,
/// and padding all pull from here so vertical rhythm stays regular.
abstract final class KJSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Vertical gap. `KJSpace.gap(KJSpace.md)` reads better than a bare
  /// `SizedBox(height: 12)` and keeps the value on the scale.
  static SizedBox gap(double v) => SizedBox(height: v);

  /// Horizontal gap.
  static SizedBox gapW(double v) => SizedBox(width: v);
}

/// Corner-radius scale. The theme's Card uses [lg] and inputs use [md];
/// hand-rolled surfaces should pick from the same four steps rather
/// than inventing a radius per widget.
abstract final class KJRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Fully rounded — pills, the nav bar, avatars. Large constant reads
  /// as a stadium at any realistic element height.
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Icon-size scale. Inline glyphs (in a text run) use [inline]; the
/// rest map to the common UI sizes so icons don't drift across screens.
abstract final class KJIcon {
  static const double inline = 12;
  static const double sm = 16;
  static const double md = 18;
  static const double lg = 20;
  static const double xl = 24;
}

/// Tint opacities for translucent fills and overlays (a maroon wash
/// behind a selected chip, a faint hairline shadow, disabled ink).
/// A handful of named steps replaces the ~20 ad-hoc alpha values the
/// screens had grown.
abstract final class KJTint {
  /// Barely-there ground wash (selected-row background, zebra fill).
  static const double faint = 0.06;

  /// Soft tint — subtle emphasis behind chips / badges.
  static const double soft = 0.10;

  /// Visible tint — borders on accented chips, light shadows.
  static const double medium = 0.18;

  /// Muted foreground — secondary glyphs, drag handles.
  static const double muted = 0.35;

  /// Dim-but-legible — de-emphasised labels over paper.
  static const double dim = 0.55;

  /// Inactive-on-accent — unselected nav labels on the dark pill.
  static const double inactive = 0.75;
}
