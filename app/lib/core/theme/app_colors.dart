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

  // ---------------------------------------------------------------------------
  // Balloons game (the village scene)
  // ---------------------------------------------------------------------------
  static const Color villageField = Color(0xFF8CC66A);
  static const Color villageFieldRow = Color(0xFF6FAE52);
  static const Color villageCanal = Color(0xFF6FC3D0);
  static const Color villagePath = Color(0xFFD9BE8F);
  static const Color villagePathEdge = Color(0xFFC2A271);
  static const Color houseDoor = Color(0xFF6B4F3A);
  static const Color houseWindow = slateTeal;
  static const Color roofStraw = Color(0xFFD9B26A);
  static const Color pigeonTower = Color(0xFFF1E6D2);

  /// Mud-brick house walls (soft pastels).
  static const List<Color> houses = [
    Color(0xFFF3D9B1), // sand
    Color(0xFFF6C6A8), // peach
    Color(0xFFBFE0E6), // pale blue
    Color(0xFFF4C7CF), // pale pink
    Color(0xFFF7E3A1), // pale yellow
    Color(0xFFE9E1D3), // cream
  ];

  static const Color balloonString = cocoa;

  /// Balloon colors (the same bright set as the fish).
  static const List<Color> balloons = fish;

  // ---------------------------------------------------------------------------
  // Writing game (the chalkboard in Grandpa's study)
  // ---------------------------------------------------------------------------
  static const Color board = Color(0xFF2F5D4E);
  static const Color boardDark = Color(0xFF244A3E);
  static const Color boardSmudge = Color(0x14FFFFFF);
  static const Color boardFrame = Color(0xFF8A5A3B);
  static const Color boardFrameLight = Color(0xFFA9744F);
  static const Color boardFrameDark = Color(0xFF6B4430);
  static const Color letterHollow = Color(0x12FFFFFF);
  static const Color letterDots = Color(0xE6FFFBF4);
  static const Color demoChalk = Color(0xD9FFFBF4);
  static const Color guide = sunYellow;
  static const Color guideText = cocoa;
  static const Color sponge = Color(0xFFFFD65C);
  static const Color spongeHoles = Color(0xFFE8B43A);
  static const Color passGlow = leafGreen;

  /// Chalk sticks in the tray (bright, so they show on the green board).
  static const List<Color> chalk = [
    Color(0xFFF7F4EC), // white
    Color(0xFFFFF3A0), // pale yellow
    Color(0xFFFFD23F), // yellow
    Color(0xFFFFB36B), // orange
    Color(0xFFFF8A65), // coral
    Color(0xFFFF6B6B), // red
    Color(0xFFFFB3C7), // pink
    Color(0xFFF78FD1), // magenta
    Color(0xFFD7B4F3), // lilac
    Color(0xFFA78BFA), // violet
    Color(0xFF9FD8F0), // sky blue
    Color(0xFF6CB4FF), // blue
    Color(0xFF7EE0C3), // mint
    Color(0xFF9BE36B), // green
    Color(0xFFD9C3A0), // sand
  ];

  // Grandpa's study (placeholder art).
  static const Color studyWall = Color(0xFFEBDCC3);
  static const Color studyWallShade = Color(0xFFDCC8A8);
  static const Color studyFloor = Color(0xFFB98A5E);
  static const Color studyFloorLine = Color(0xFFA27650);
  static const Color studyShelf = Color(0xFF7A5238);
  static const Color studyRug = Color(0xFF4F7C82);
  static const Color studyRugBorder = Color(0xFFFF9F7F);
  static const Color studyWindow = Color(0xFFFFE9B0);
  static const Color studyMashrabiya = Color(0xFF7A5238);
  static const Color studyArmchair = Color(0xFFB4533C);
  static const Color studyLight = Color(0x33FFE9B0);

  /// Book spines on the shelves.
  static const List<Color> books = [
    deepTeal,
    coral,
    sunYellow,
    slateTeal,
    cocoa,
    leafGreen,
    Color(0xFFB57EDC),
  ];

  // ---------------------------------------------------------------------------
  // Grandpa's Cards (Alexandria & the sea, placeholder art)
  // ---------------------------------------------------------------------------
  static const Color seaSkyTop = Color(0xFF8FD3EA);
  static const Color seaSkyBottom = Color(0xFFDDF2F2);
  static const Color seaFar = Color(0xFF3FA7C0);
  static const Color seaNear = Color(0xFF2B8BA6);
  static const Color seaFoam = Color(0xCCFFFFFF);
  static const Color beachSand = Color(0xFFF2DDB0);
  static const Color beachSandDark = Color(0xFFE3C68E);
  static const Color fortWall = Color(0xFFE9D8B4);
  static const Color fortShade = Color(0xFFD4BE93);
  static const Color cardBack = deepTeal;
  static const Color cardBackPattern = Color(0x33A8DADC);
  static const Color cardBackBorder = mistBlue;
  static const Color cardFace = cream;

  /// Confetti / celebration colors.
  static const List<Color> celebration = [
    sunYellow,
    coral,
    leafGreen,
    mistBlue,
    deepTeal,
  ];
}
