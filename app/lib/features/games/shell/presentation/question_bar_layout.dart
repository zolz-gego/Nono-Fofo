import 'dart:ui';

import 'game_scaffold.dart';

/// Where the [GameQuestionBar] sits at the top of a game scene, in two
/// compact rows: the progress row beside the settings button, and the
/// letter's row under it. Each game's layout mixes this in, so the Flame
/// scene and the Flutter bar line up.
mixin QuestionBarLayout {
  double get width;
  double get height;

  /// Short screens (phones in landscape) get a slimmer bar.
  bool get compact => height < 520;

  double get hudTop => GameScaffold.buttonInset;

  /// The progress row is as tall as the settings button, between the two
  /// top corners (the button is in one of them).
  double get progressHeight => GameScaffold.buttonSize;
  double get progressLeft => GameScaffold.cornerSize;
  double get progressWidth => width - GameScaffold.cornerSize * 2;

  double get nameTop => hudTop + progressHeight + (compact ? 4 : 6);
  double get nameHeight => compact ? 34 : 42;

  /// Bottom of the whole bar.
  double get cardBottom => nameTop + nameHeight;

  /// The whole bar (speech bubbles and game items stay out of it).
  Rect get cardRect =>
      Rect.fromLTRB(progressLeft, hudTop, width - progressLeft, cardBottom);

  /// Size of the progress icon, for items that fly into it.
  double get progressIconSize => progressHeight * 0.78 * 0.5;

  /// Center of the progress icon when the row has no chips (the count pill
  /// is then centered), for items that fly into it.
  Offset progressIconCenter({required bool rtl}) {
    // The pill is about as wide as its icon, a gap and "3/5".
    final pill = progressHeight * 0.78;
    final half = (pill * 0.35 * 2 + progressIconSize + pill * 0.18 + pill) / 2;
    final fromCenter = half - pill * 0.35 - progressIconSize / 2;
    return Offset(
      width / 2 + (rtl ? fromCenter : -fromCenter),
      hudTop + progressHeight / 2,
    );
  }
}
