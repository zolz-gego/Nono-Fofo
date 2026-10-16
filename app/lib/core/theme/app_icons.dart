import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Font Awesome icons used across the app. Render with [FaIcon].
abstract final class AppIcons {
  static const FaIconData language = FontAwesomeIcons.globe;
  static const FaIconData info = FontAwesomeIcons.circleInfo;
  static const FaIconData lessons = FontAwesomeIcons.bookOpen;
  static const FaIconData speech = FontAwesomeIcons.solidComment;
  static const FaIconData stop = FontAwesomeIcons.stop;
  static const FaIconData soundOn = FontAwesomeIcons.volumeHigh;
  static const FaIconData soundOff = FontAwesomeIcons.volumeXmark;
  static const FaIconData star = FontAwesomeIcons.solidStar;
  static const FaIconData play = FontAwesomeIcons.play;
  static const FaIconData close = FontAwesomeIcons.xmark;
  static const FaIconData check = FontAwesomeIcons.solidCircleCheck;
  static const FaIconData random = FontAwesomeIcons.dice;
  static const FaIconData replay = FontAwesomeIcons.rotateRight;
  static const FaIconData letters = FontAwesomeIcons.tableCellsLarge;
  static const FaIconData road = FontAwesomeIcons.route;
  static const FaIconData starEmpty = FontAwesomeIcons.star;

  // Writing game.
  static const FaIconData chalkFilled = FontAwesomeIcons.paintbrush;
  static const FaIconData sponge = FontAwesomeIcons.eraser;
  static const FaIconData passed = FontAwesomeIcons.solidCircleCheck;
  static const FaIconData share = FontAwesomeIcons.shareNodes;

  // Game placeholders, shown until a game's illustration is added.
  static const FaIconData fishing = FontAwesomeIcons.fish;
  static const FaIconData writeLetter = FontAwesomeIcons.pencil;
  static const FaIconData balloons = FontAwesomeIcons.burst;
  static const FaIconData challenge = FontAwesomeIcons.trophy;
}
