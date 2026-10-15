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

  /// Confetti / celebration colors.
  static const List<Color> celebration = [
    sunYellow,
    coral,
    leafGreen,
    mistBlue,
    deepTeal,
  ];
}
