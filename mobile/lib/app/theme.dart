import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CRICIT tokens. Source of truth: /DESIGN.md. Keep in sync with admin/src/app/globals.css.
class CricitColors {
  const CricitColors._();

  static const outfield = Color(0xFF17402B);
  static const ball = Color(0xFFC1272D);
  static const scoreboard = Color(0xFFE8A317);
  static const sightscreen = Color(0xFFF7F9FA);
  static const ink = Color(0xFF1B2430);
  static const seam = Color(0xFFD9DEE3);

  static const outfieldDark = Color(0xFF7BC79A);
  static const ballDark = Color(0xFFF0646A);
  static const scoreboardDark = Color(0xFFF2BE4E);
  static const sightscreenDark = Color(0xFF0F1A15);
  static const inkDark = Color(0xFFE6ECE8);
  static const seamDark = Color(0xFF26362D);

  /// Team edge strip colours (4 px on the left of a card when a team tag exists).
  static const teams = <String, Color>{
    'india': Color(0xFF1F5FAD),
    'australia': Color(0xFFD9A900),
    'england': Color(0xFF0B2A5B),
    'pakistan': Color(0xFF0B6E3B),
    'south africa': Color(0xFF00744A),
    'new zealand': Color(0xFF111111),
    'sri lanka': Color(0xFF1B3F8B),
    'west indies': Color(0xFF7A1F2B),
    'bangladesh': Color(0xFF006A4E),
    'afghanistan': Color(0xFF0057B8),
  };
}

TextTheme _text(Color ink) {
  final display = GoogleFonts.barlowCondensedTextTheme();
  final body = GoogleFonts.sourceSans3TextTheme();
  return body
      .copyWith(
        headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.15),
        headlineMedium: display.headlineMedium?.copyWith(
          fontSize: 26,
          height: 30 / 26,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 24 / 16),
      )
      .apply(bodyColor: ink, displayColor: ink);
}

ThemeData _build({
  required Brightness brightness,
  required Color primary,
  required Color error,
  required Color tertiary,
  required Color surface,
  required Color ink,
  required Color seam,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
    primary: primary,
    error: error,
    tertiary: tertiary,
    surface: surface,
    onSurface: ink,
    outline: seam,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    textTheme: _text(ink),
    dividerColor: seam,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
  );
}

final lightTheme = _build(
  brightness: Brightness.light,
  primary: CricitColors.outfield,
  error: CricitColors.ball,
  tertiary: CricitColors.scoreboard,
  surface: CricitColors.sightscreen,
  ink: CricitColors.ink,
  seam: CricitColors.seam,
);

final darkTheme = _build(
  brightness: Brightness.dark,
  primary: CricitColors.outfieldDark,
  error: CricitColors.ballDark,
  tertiary: CricitColors.scoreboardDark,
  surface: CricitColors.sightscreenDark,
  ink: CricitColors.inkDark,
  seam: CricitColors.seamDark,
);
