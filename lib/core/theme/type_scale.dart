/// Type scale — the single source of truth for text styling, from the
/// Claude Design typography handout (v1, 7 Jul 2026).
///
/// Three families, each with one job:
///   • Marcellus (400)        — display: wordmark, screen titles, subheads.
///   • IBM Plex Sans (400/500/600) — every interactive & body element.
///   • IBM Plex Mono (400/500) — measured data (degrees, dates, IDs) AND
///                               uppercase kicker / eyebrow labels, so data
///                               always reads as data.
/// Weights 400/500/600 only — nothing uses 700.
///
/// Colour follows the active palette: full ink for display / body / data,
/// muted ink ([TEColors.inkSoft]) for kickers, captions and meta. Accent
/// colours (maroon / forest) are passed explicitly only where colour
/// carries meaning (active state, confirmation) — never for plain emphasis.
///
/// `letterSpacing` here is in logical pixels; the handout's `em` tracking
/// is converted at each token (px = size × em).
///
/// Prefer these tokens over one-off `TextStyle(...)`. In "Simple" font
/// mode ([TETheme.useSerif] == false) the display tokens fall back to
/// Plex Sans 600 for legibility at large sizes.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

abstract final class TEType {
  static Color get _ink => TEColors.ink;
  static Color get _muted => TEColors.inkSoft;

  // ── Display · Marcellus (Plex Sans 600 in Simple mode) ────────────────
  static TextStyle _display(double size,
      {double height = 1.1, Color? color}) {
    final c = color ?? _ink;
    return TETheme.useSerif
        ? GoogleFonts.marcellus(fontSize: size, height: height, color: c)
        : GoogleFonts.ibmPlexSans(
            fontSize: size,
            height: height,
            fontWeight: FontWeight.w600,
            color: c);
  }

  /// Display / Hero — app wordmark, onboarding title. 34 / 1.1.
  static TextStyle hero({Color? color}) => _display(34, color: color);

  /// Display / Screen title — hub headers ("Kundlis"), kundli name,
  /// large numerals. 22–26 / 1.1.
  static TextStyle screenTitle({double size = 22, Color? color}) =>
      _display(size, color: color);

  /// Display / Subhead — card & section titles within a screen. 16.5 / 1.2.
  static TextStyle subhead({Color? color}) =>
      _display(16.5, height: 1.2, color: color);

  // ── UI · IBM Plex Sans ────────────────────────────────────────────────
  /// UI / Button — primary CTA, input values, emphasised rows. 15 / 1, 600.
  static TextStyle button({Color? color}) => GoogleFonts.ibmPlexSans(
      fontSize: 15,
      height: 1.0,
      fontWeight: FontWeight.w600,
      color: color ?? _ink);

  /// UI / Body — descriptions, readings, list rows. 13–14 / 1.5, 400.
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) =>
      GoogleFonts.ibmPlexSans(
          fontSize: size, height: 1.5, fontWeight: weight, color: color ?? _ink);

  /// UI / Body, emphasised — secondary links, emphasised rows. 500.
  static TextStyle bodyStrong({double size = 14, Color? color}) =>
      body(size: size, weight: FontWeight.w500, color: color);

  /// UI / Chip — pills, chips, screen-jumper labels. 11.5–12.5 / 1, 500.
  static TextStyle chip({double size = 12, Color? color}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: size,
          height: 1.0,
          fontWeight: FontWeight.w500,
          color: color ?? _ink);

  /// UI / Field label — form input labels (NAME, PLACE OF BIRTH).
  /// 11 / 1.2, 500, +0.06em. Muted by default; caller uppercases.
  static TextStyle fieldLabel({Color? color}) => GoogleFonts.ibmPlexSans(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 11 * 0.06,
      color: color ?? _muted);

  /// UI / Caption — helper text, disclaimers, footnotes. 11.5–12 / 1.5.
  /// Muted ink by default.
  static TextStyle caption({double size = 11.5, Color? color}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: size,
          height: 1.5,
          fontWeight: FontWeight.w400,
          color: color ?? _muted);

  // ── Mono · IBM Plex Mono ──────────────────────────────────────────────
  /// Mono / Kicker — uppercase section eyebrows (SCREENS, SYSTEM,
  /// CAST YOUR KUNDALI). 10 / 1, 500, +0.18em. Caller uppercases the
  /// text; muted ink by default. See [TESectionLabel] for the widget.
  static TextStyle kicker({Color? color}) => GoogleFonts.ibmPlexMono(
      fontSize: 10,
      height: 1.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 10 * 0.18,
      color: color ?? _muted);

  /// Mono / Data — degrees, dasha durations, coordinates, IDs (MK-4831).
  /// 13 / 1.2, 500, +0.02em. Full ink by default.
  static TextStyle data({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.ibmPlexMono(
          fontSize: size,
          height: 1.2,
          fontWeight: weight,
          letterSpacing: size * 0.02,
          color: color ?? _ink);

  /// Mono / Meta — timezone tags, counts, timestamps, sub-annotations.
  /// 10–11 / 1.3, 400. Muted ink by default.
  static TextStyle meta({double size = 10.5, Color? color}) =>
      GoogleFonts.ibmPlexMono(
          fontSize: size,
          height: 1.3,
          fontWeight: FontWeight.w400,
          color: color ?? _muted);
}
