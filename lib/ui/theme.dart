import 'package:flutter/material.dart';

import '../models/goals.dart';

/// Text that reads on [background]: cream on dark colours, plum on light
/// ones.
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? Palette.cream : Palette.ink;

/// The plum palette, taken from the moving background's reference (4th
/// artboard of the design): dark plum underneath, pale pink, butter,
/// lavender and a soft turquoise accent. Cream text on the dark parts,
/// plum text on the light ones.
abstract final class Palette {
  static const plumDark = Color(0xFF3B1F2E); // background base
  static const plum = Color(0xFF7A4A6B); // "Mark exit", the background's middle tone
  static const ink = plumDark; // text, big numbers, "JAN", grid
  static const inkDeep = Color(0xFF2E1823); // hours inside cells, hourglass ink
  static const turquoise = Color(0xFF9EE6E0); // "Mark entry", progress, goal card (accent)
  static const butter = Color(0xFFE8E08A); // hours-left card
  static const rose = Color(0xFFF2C4D3); // today, Log in / Sign up, the bar
  static const lavender = Color(0xFFCFC8FF); // days with hours
  static const mist = Color(0xFFE9DCE4); // progress track
  static const cream = Color(0xFFFFF6EC); // text on dark, sheets
  static const berry = Color(0xFFA33A55); // destructive actions (6.5:1 under cream text)
}

/// Cards, buttons, the timer and the bar sit on the moving background:
/// nearly opaque, with a soft plum shadow that lifts them off it.
abstract final class Surface {
  static const alpha = 0.9;
  static const shadow = [BoxShadow(color: Color(0x383B1F2E), blurRadius: 14, offset: Offset(0, 4))];
}

extension GoalColorPaint on GoalColor {
  Color get color => switch (this) {
        GoalColor.green => Palette.turquoise,
        GoalColor.orange => Palette.lavender,
        GoalColor.pink => Palette.rose,
        GoalColor.yellow => Palette.butter,
      };

  /// Chips and boxes sit in butter, except on a butter goal.
  Color get accent => this == GoalColor.yellow ? Palette.rose : Palette.butter;
}

abstract final class Fonts {
  static const sans = 'Epilogue';
  static const display = 'Anton';
  static const numbers = 'Outfit';
}

/// Outfit ships as a variable font; the weight goes through `wght`.
TextStyle outfit(double size, {double weight = 500, Color color = Palette.ink}) => TextStyle(
      fontFamily: Fonts.numbers,
      fontSize: size,
      color: color,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', weight)],
      height: 1,
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.ink,
    primary: Palette.ink,
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
        borderSide: const BorderSide(color: Palette.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.berry, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.berry, width: 1.5),
      ),
    ),
  );
}
