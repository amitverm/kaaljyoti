import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../astro/models.dart';
import 'tokens.dart';
import 'type_scale.dart';

/// Traditional label colour for a planet under the ACTIVE palette —
/// used anywhere a planet's name appears in the app (charts, tables,
/// dasha lords, chips), so grahas read consistently everywhere.
Color planetInk(Planet planet) {
  final c = TEColors.planets;
  return switch (planet) {
    Planet.sun => c.sun,
    Planet.moon => c.moon ?? TEColors.ink,
    Planet.mars => c.mars,
    Planet.mercury => c.mercury,
    Planet.jupiter => c.jupiter,
    Planet.venus => c.venus,
    Planet.saturn => c.saturn,
    Planet.rahu => c.rahu,
    Planet.ketu => c.ketu,
  };
}

/// Rashi label colour: a sign takes its lord's [planetInk] colour
/// (Vedic lords — Scorpio → Mars, Aquarius → Saturn), so sign names
/// read consistently with their ruling grahas everywhere.
Color signInk(ZodiacSign sign) => planetInk(sign.lord);

/// Traditional per-planet label colours (Parashar Light convention):
/// Sun dark red/golden, Moon ink (white is illegible on paper), Mars
/// red, Mercury green, Jupiter saffron, Venus pink, Saturn blue, Rahu
/// grey, Ketu dark brown. Each palette carries its own set so the
/// hues stay legible on that palette's paper.
class TEPlanetInk {
  const TEPlanetInk({
    required this.sun,
    this.moon, // null → falls back to the palette's ink
    required this.mars,
    required this.mercury,
    required this.jupiter,
    required this.venus,
    required this.saturn,
    required this.rahu,
    required this.ketu,
  });

  final Color sun;
  final Color? moon;
  final Color mars;
  final Color mercury;
  final Color jupiter;
  final Color venus;
  final Color saturn;
  final Color rahu;
  final Color ketu;
}

/// A complete color palette. Three variants ship: classic (the
/// finalized Claude Design warm-paper look), high-contrast (elderly-
/// friendly: black ink, strong borders), and dark.
class TEPalette {
  const TEPalette({
    required this.name,
    required this.paper,
    required this.paperAlt,
    required this.paperDeep,
    required this.maroon,
    required this.maroonPressed,
    required this.forest,
    required this.ink,
    required this.inkSoft,
    required this.hairline,
    this.isDark = false,
    Color? transit,
    this.planets = _classicPlanets,
  }) : transit = transit ?? forest;

  final String name;
  final Color paper; // lightest ground / card surface
  final Color paperAlt; // section ground / inputs
  final Color paperDeep; // scaffold ground
  final Color maroon; // primary accent
  final Color maroonPressed;
  final Color forest; // secondary accent
  final Color ink; // text
  final Color inkSoft; // secondary text
  final Color hairline; // borders / dividers
  final bool isDark;

  /// A brighter, more legible green than [forest] — used to mark
  /// transit (current-sky) overlays on the birth chart, where [forest]
  /// reads as barely distinguishable from [ink] at small sizes.
  final Color transit;

  /// Per-planet chart label colours for this palette.
  final TEPlanetInk planets;

  static const _classicPlanets = TEPlanetInk(
    sun: Color(0xFFB4540A), // dark red / golden
    mars: Color(0xFFC62828), // red
    mercury: Color(0xFF2E7D32), // green
    jupiter: Color(0xFFE07B00), // saffron
    venus: Color(0xFFD81B8C), // pink
    saturn: Color(0xFF2049B0), // blue
    rahu: Color(0xFF6B675C), // grey
    ketu: Color(0xFF5D4037), // dark brown
  );

  static const _contrastPlanets = TEPlanetInk(
    sun: Color(0xFF8F3F00),
    mars: Color(0xFFA31515),
    mercury: Color(0xFF1B5E20),
    jupiter: Color(0xFFB45F00),
    venus: Color(0xFFB00E6E),
    saturn: Color(0xFF16389C),
    rahu: Color(0xFF4A463C),
    ketu: Color(0xFF4E342E),
  );

  static const _darkPlanets = TEPlanetInk(
    sun: Color(0xFFE8B25E),
    mars: Color(0xFFE57373),
    mercury: Color(0xFF81C784),
    jupiter: Color(0xFFF2A95C),
    venus: Color(0xFFF48FB1),
    saturn: Color(0xFF8FA8FF),
    rahu: Color(0xFF9E988A),
    ketu: Color(0xFFBCAAA4),
  );

  static const classic = TEPalette(
    name: 'classic',
    paper: Color(0xFFFCFAF4),
    paperAlt: Color(0xFFF7F3EA),
    paperDeep: Color(0xFFF4F0E5),
    maroon: Color(0xFF7A1F2B),
    maroonPressed: Color(0xFF6A1A25),
    forest: Color(0xFF2F4136),
    ink: Color(0xFF221F18),
    inkSoft: Color(0xFF56503F),
    hairline: Color(0xFFEAE5D8),
    transit: Color(0xFF1F7A4D),
  );

  /// High contrast: black ink, darker accents, strong borders — for
  /// readers who find the classic palette too soft.
  static const highContrast = TEPalette(
    name: 'contrast',
    paper: Color(0xFFFFFDF7),
    paperAlt: Color(0xFFFFF8E8),
    paperDeep: Color(0xFFFFFBF0),
    maroon: Color(0xFF5E1017),
    maroonPressed: Color(0xFF4A0C12),
    forest: Color(0xFF1E2E24),
    ink: Color(0xFF000000),
    inkSoft: Color(0xFF33302A),
    hairline: Color(0xFF8A8371),
    transit: Color(0xFF0F6B34),
    planets: _contrastPlanets,
  );

  static const dark = TEPalette(
    name: 'dark',
    paper: Color(0xFF201D15),
    paperAlt: Color(0xFF2A261C),
    paperDeep: Color(0xFF17150F),
    maroon: Color(0xFFC25B66),
    maroonPressed: Color(0xFFA84955),
    forest: Color(0xFF7FA98D),
    ink: Color(0xFFF4F0E5),
    inkSoft: Color(0xFFC9C2AF),
    hairline: Color(0xFF3D3829),
    isDark: true,
    transit: Color(0xFF8FE6B5),
    planets: _darkPlanets,
  );

  static const all = [classic, highContrast, dark];

  static TEPalette byName(String? name) =>
      all.firstWhere((p) => p.name == name, orElse: () => classic);
}

/// Runtime color access used across the app (screens, painters, PDF
/// chrome). Reads from the ACTIVE palette — set by the appearance
/// settings before the widget tree rebuilds. Not const on purpose.
abstract final class TEColors {
  static TEPalette current = TEPalette.classic;

  static Color get paper => current.paper;
  static Color get paperAlt => current.paperAlt;
  static Color get paperDeep => current.paperDeep;
  static Color get maroon => current.maroon;
  static Color get maroonPressed => current.maroonPressed;
  static Color get forest => current.forest;
  static Color get transit => current.transit;
  static Color get ink => current.ink;
  static Color get inkSoft => current.inkSoft;
  static Color get hairline => current.hairline;
  static TEPlanetInk get planets => current.planets;
}

abstract final class TETheme {
  /// When false ("Simple" font style), headings use IBM Plex Sans too —
  /// more legible at large text sizes.
  static bool useSerif = true;

  static ThemeData build({
    TEPalette palette = TEPalette.classic,
    bool serifHeadings = true,
  }) {
    // TEType reads these statics; set them first so the type scale below
    // resolves against the palette + font mode this theme is built for.
    TEColors.current = palette;
    TETheme.useSerif = serifHeadings;

    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.paperDeep,
      colorScheme: (palette.isDark
              ? const ColorScheme.dark()
              : const ColorScheme.light())
          .copyWith(
        primary: palette.maroon,
        onPrimary: palette.paper,
        secondary: palette.forest,
        onSecondary: palette.paper,
        surface: palette.paper,
        onSurface: palette.ink,
        outline: palette.hairline,
        error: palette.isDark
            ? const Color(0xFFE08A8A)
            : const Color(0xFF8C2B2B),
      ),
    );

    // Text theme mapped from the Claude Design typography handout so that
    // framework-driven text (app bars, dialogs, list tiles, buttons,
    // chips, inputs) follows the scale without one-off styles.
    final text = TextTheme(
      displayLarge: TEType.hero(color: palette.ink), // Marcellus 34
      displayMedium: TEType.screenTitle(size: 26, color: palette.ink),
      displaySmall: TEType.screenTitle(size: 22, color: palette.ink),
      headlineMedium: TEType.subhead(color: palette.ink),
      headlineSmall: TEType.subhead(color: palette.ink),
      titleLarge: TEType.subhead(color: palette.ink), // Marcellus 16.5
      titleMedium: TEType.button(color: palette.ink), // Plex Sans 15/600
      titleSmall: TEType.bodyStrong(size: 13, color: palette.ink),
      bodyLarge: TEType.body(size: 14, color: palette.ink),
      bodyMedium: TEType.body(size: 13, color: palette.ink),
      bodySmall: TEType.caption(color: palette.inkSoft),
      labelLarge: TEType.button(color: palette.ink), // buttons
      labelMedium: TEType.chip(color: palette.ink), // chips
      labelSmall: TEType.kicker(color: palette.inkSoft), // eyebrows
    );

    final appBarTitle = TEType.screenTitle(
        size: serifHeadings ? 24 : 22, color: palette.ink);

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.paperDeep,
        foregroundColor: palette.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: appBarTitle,
      ),
      cardTheme: CardThemeData(
        color: palette.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: TERadius.all(TERadius.lg),
          side: BorderSide(color: palette.hairline),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.maroon,
          foregroundColor: palette.paper,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
              horizontal: TESpace.xxl, vertical: TESpace.md + 2),
          textStyle: TEType.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.ink),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
              horizontal: TESpace.xl, vertical: TESpace.md),
          textStyle: TEType.button(),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.paperAlt,
        selectedColor: palette.maroon,
        side: BorderSide(color: palette.hairline),
        // Explicit ink — a colorless label style lets chips fall back
        // to framework defaults that can render invisibly on paper.
        labelStyle: TEType.chip(color: palette.ink, size: 12.5),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.paperAlt,
        border: OutlineInputBorder(
          borderRadius: TERadius.all(TERadius.md),
          borderSide: BorderSide(color: palette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TERadius.all(TERadius.md),
          borderSide: BorderSide(color: palette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TERadius.all(TERadius.md),
          borderSide: BorderSide(color: palette.maroon, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 1,
      ),
    );
  }

  /// Kept for compatibility: default light theme.
  static ThemeData light() => build();

  /// IBM Plex Mono — degrees / coordinates / tabular data.
  static TextStyle mono({
    double size = 13,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.ibmPlexMono(
          fontSize: size, color: color ?? TEColors.ink, fontWeight: weight);

  /// Display face — Marcellus in classic mode, Plex Sans in simple.
  static TextStyle serif({double size = 20, Color? color}) => useSerif
      ? GoogleFonts.marcellus(fontSize: size, color: color ?? TEColors.ink)
      : GoogleFonts.ibmPlexSans(
          fontSize: size,
          color: color ?? TEColors.ink,
          fontWeight: FontWeight.w600);
}
