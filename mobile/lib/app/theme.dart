import 'package:flutter/material.dart';

/// CRICIT tokens. Source of truth: /DESIGN.md. Keep in sync with admin/src/app/globals.css.
class CricitColors {
  const CricitColors._();

  static const outfield = Color(0xFF17402B);
  static const onOutfield = Color(0xFFFFFFFF);
  static const ball = Color(0xFFC1272D);
  static const scoreboard = Color(0xFFE8A317);
  static const sightscreen = Color(0xFFF7F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B2430);
  static const inkMuted = Color(0xFF5B6672);
  static const seam = Color(0xFFD9DEE3);
  static const success = Color(0xFF2F7A52);

  static const outfieldDark = Color(0xFF7BC79A);
  static const ballDark = Color(0xFFF0646A);
  static const scoreboardDark = Color(0xFFF2BE4E);
  static const sightscreenDark = Color(0xFF0F1A15);
  static const surfaceDark = Color(0xFF13221B);
  static const inkDark = Color(0xFFE6ECE8);
  static const inkMutedDark = Color(0xFF9FB0A7);
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

class CricitSpace {
  const CricitSpace._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class CricitRadius {
  const CricitRadius._();

  static const sm = 6.0;
  static const md = 12.0;
  static const full = 999.0;
}

class CricitFonts {
  const CricitFonts._();

  static const display = 'BarlowCondensed';
  static const body = 'SourceSans3';
  static const hindi = 'NotoSansDevanagari';
}

TextTheme _text({
  required Color ink,
  required Color muted,
  required bool hindi,
}) {
  final bodyFamily = hindi ? CricitFonts.hindi : CricitFonts.body;
  final bodyHeight = hindi ? 26 / 16 : 24 / 16;
  return TextTheme(
    headlineLarge: TextStyle(
      fontFamily: CricitFonts.display,
      fontWeight: FontWeight.w600,
      fontSize: 26,
      height: 30 / 26,
      letterSpacing: -0.01,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: CricitFonts.display,
      fontWeight: FontWeight.w600,
      fontSize: 26,
      height: 30 / 26,
      letterSpacing: -0.01,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontFamily: CricitFonts.display,
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.2,
      letterSpacing: -0.01,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontFamily: bodyFamily,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: bodyHeight,
      color: ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: bodyFamily,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: bodyHeight,
      color: ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: bodyFamily,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.5,
      color: ink,
    ),
    labelLarge: TextStyle(
      fontFamily: bodyFamily,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.4,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontFamily: bodyFamily,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.4,
      color: muted,
    ),
  );
}

ThemeData _build({
  required Brightness brightness,
  required Color primary,
  required Color onPrimary,
  required Color error,
  required Color tertiary,
  required Color scaffold,
  required Color surface,
  required Color ink,
  required Color muted,
  required Color seam,
  required bool hindi,
}) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    secondary: primary,
    onSecondary: onPrimary,
    tertiary: tertiary,
    onTertiary: ink,
    error: error,
    onError: CricitColors.onOutfield,
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: muted,
    outline: seam,
    outlineVariant: seam,
  );
  final radiusSm = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(CricitRadius.sm),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffold,
    canvasColor: scaffold,
    textTheme: _text(ink: ink, muted: muted, hindi: hindi),
    dividerColor: seam,
    splashFactory: InkRipple.splashFactory,
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CricitRadius.md),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scaffold,
      foregroundColor: ink,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: CricitSpace.xxl + CricitSpace.md,
      elevation: 0,
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(size: 24, color: selected ? primary : muted);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: muted,
      indicatorColor: primary,
      dividerColor: seam,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: CricitSpace.md),
      overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.08)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: radiusSm,
        minimumSize: const Size(CricitSpace.xxl, CricitSpace.xxl),
        textStyle: TextStyle(
          fontFamily: hindi ? CricitFonts.hindi : CricitFonts.body,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(CricitSpace.xxl, CricitSpace.xxl),
        shape: radiusSm,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: seam),
        shape: radiusSm,
        minimumSize: const Size(CricitSpace.xxl, CricitSpace.xxl),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(CricitSpace.xxl, CricitSpace.xxl),
        foregroundColor: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CricitRadius.sm),
        borderSide: BorderSide(color: seam),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CricitRadius.sm),
        borderSide: BorderSide(color: seam),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CricitRadius.sm),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CricitRadius.sm),
        borderSide: BorderSide(color: error),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scaffold,
      selectedColor: primary.withValues(alpha: 0.12),
      side: BorderSide(color: seam),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CricitRadius.full),
      ),
      labelStyle: TextStyle(
        fontFamily: hindi ? CricitFonts.hindi : CricitFonts.body,
        color: ink,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CricitSpace.sm,
        vertical: CricitSpace.xs,
      ),
    ),
  );
}

ThemeData cricitTheme({required Brightness brightness, required bool hindi}) {
  final dark = brightness == Brightness.dark;
  return _build(
    brightness: brightness,
    primary: dark ? CricitColors.outfieldDark : CricitColors.outfield,
    onPrimary: dark ? CricitColors.sightscreenDark : CricitColors.onOutfield,
    error: dark ? CricitColors.ballDark : CricitColors.ball,
    tertiary: dark ? CricitColors.scoreboardDark : CricitColors.scoreboard,
    scaffold: dark ? CricitColors.sightscreenDark : CricitColors.sightscreen,
    surface: dark ? CricitColors.surfaceDark : CricitColors.surface,
    ink: dark ? CricitColors.inkDark : CricitColors.ink,
    muted: dark ? CricitColors.inkMutedDark : CricitColors.inkMuted,
    seam: dark ? CricitColors.seamDark : CricitColors.seam,
    hindi: hindi,
  );
}

final lightTheme = cricitTheme(brightness: Brightness.light, hindi: false);
final darkTheme = cricitTheme(brightness: Brightness.dark, hindi: false);
