import 'package:flutter/material.dart';

/// The ONLY place in the app where colors are defined.
///
/// Widgets must never use `Color(0x...)` or `Colors.*` directly — they read
/// a semantic color from here (or from `Theme.of(context)`, which is built
/// from here in `AppTheme`). To re-theme the app, change the values below.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand palette (base)
  // ---------------------------------------------------------------------------
  static const Color deepTeal = Color(0xFF0F4C5C);
  static const Color mistBlue = Color(0xFFA8DADC);
  static const Color sand = Color(0xFFEFE6D8);
  static const Color slateTeal = Color(0xFF4F7C82);
  static const Color cocoa = Color(0xFF5B4B3A);

  // ---------------------------------------------------------------------------
  // Bright accents (fun / feedback)
  // ---------------------------------------------------------------------------
  static const Color sunYellow = Color(0xFFFFC845);
  static const Color coral = Color(0xFFFF7A5C);
  static const Color leafGreen = Color(0xFF6CC24A);

  // ---------------------------------------------------------------------------
  // Neutrals
  // ---------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFFFBF4);
  static const Color ink = Color(0xFF2B2420);
  static const Color transparent = Color(0x00000000);

  // ---------------------------------------------------------------------------
  // Semantic roles — use these in widgets
  // ---------------------------------------------------------------------------
  static const Color background = sand;
  static const Color surface = cream;
  static const Color primary = deepTeal;
  static const Color onPrimary = white;
  static const Color secondary = coral;
  static const Color onSecondary = white;
  static const Color tertiary = mistBlue;
  static const Color outline = slateTeal;

  static const Color textHeading = deepTeal;
  static const Color textBody = ink;
  static const Color textMuted = slateTeal;
  static const Color textOnDark = white;
  static const Color coptic = cocoa;

  static const Color correct = leafGreen;
  static const Color wrong = coral;
  static const Color hint = sunYellow;
  static const Color star = sunYellow;

  static const Color nonoAccent = coral;
  static const Color fofoAccent = sunYellow;

  static const Color speechBubble = white;
  static const Color speechBubbleBorder = cocoa;
  static Color shadow = ink.withValues(alpha: 0.18);
  static Color scrim = ink.withValues(alpha: 0.45);

  // ---------------------------------------------------------------------------
  // Fishing game (the Nile scene)
  // ---------------------------------------------------------------------------
  static const Color skyTop = Color(0xFF8FD0E0);
  static const Color skyBottom = Color(0xFFE8F4EE);
  static const Color sunGlow = Color(0x55FFC845);
  static const Color farBank = Color(0xFFB9C98A);
  static const Color palmTrunk = Color(0xFF8A6B4E);
  static const Color palmLeaf = Color(0xFF5E9E45);
  static const Color waterTop = Color(0xFF6FC3D0);
  static const Color waterDeep = deepTeal;
  static const Color waterShine = Color(0x99FFFFFF);
  static const Color riverBed = Color(0xFFC9B48E);
  static const Color pebble = Color(0xFFA48F6E);
  static const Color reed = Color(0xFF4E9A5A);
  static const Color bankEarth = Color(0xFFB08A5E);
  static const Color rod = cocoa;
  static const Color rodHandle = Color(0xFF3E3227);
  static const Color fishingLine = Color(0xFF3E3227);
  static const Color bobberTop = coral;
  static const Color bobberBottom = white;

  /// Fish body colors (bright and different from each other).
  static const List<Color> fish = [
    coral,
    sunYellow,
    leafGreen,
    Color(0xFFB57EDC), // lilac
    Color(0xFFFF9FC4), // pink
    Color(0xFFFF9F43), // orange
    Color(0xFF5EC8E5), // sky blue
    Color(0xFF3FBFA0), // mint
  ];

  /// Confetti / celebration colors.
  static const List<Color> celebration = [
    sunYellow,
    coral,
    leafGreen,
    mistBlue,
    deepTeal,
  ];
}
