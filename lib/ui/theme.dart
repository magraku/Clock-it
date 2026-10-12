import 'package:flutter/material.dart';

/// Colors taken from `reference/Clock-it.vectorcraft` (CMYK converted to RGB).
abstract final class Palette {
  static const navy = Color(0xFF32486D); // big numbers, "JAN", grid
  static const navyText = Color(0xFF32466C); // "Hours left to do:"
  static const navyDeep = Color(0xFF2B3B5B); // hours inside cells
  static const green = Color(0xFF8DC740); // "Mark entry", progress, goal card
  static const yellow = Color(0xFFFFF8A5); // hours-left card
  static const track = Color(0xFFCFC7C0); // progress track
  static const pink = Color(0xFFFFB7FF); // today, Log in / Sign in
  static const orange = Color(0xFFFAAF3C); // days with hours
  static const sand = Color(0xFFDDD5CE); // text on the goal card
  static const cream = Color(0xFFF3F0E6); // splash background, sheets
  static const coral = Color(0xFFD9604A); // destructive actions
}

abstract final class Fonts {
  static const sans = 'SourceSans3';
  static const display = 'Anton';
  static const numbers = 'Outfit';
}

/// Outfit ships as a variable font; the weight goes through `wght`.
TextStyle outfit(double size, {double weight = 500, Color color = Palette.navy}) => TextStyle(
      fontFamily: Fonts.numbers,
      fontSize: size,
      color: color,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', weight)],
      height: 1,
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.navy,
    primary: Palette.navy,
    surface: Palette.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Fonts.sans,
    scaffoldBackgroundColor: Palette.cream,
    splashFactory: NoSplash.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.coral, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.coral, width: 1.5),
      ),
    ),
  );
}
