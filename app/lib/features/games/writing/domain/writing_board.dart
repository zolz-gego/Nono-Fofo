import 'dart:ui' show Rect, Size;

/// The chalkboard's own coordinate space. Everything on the board (the
/// letter, the chalk, the stroke order) is in these units; the widget
/// scales the whole board to fit the screen.
abstract final class WritingBoard {
  static const double width = 800;
  static const double height = 520;
  static const Size size = Size(width, height);

  /// Grid cell used to measure the chalk.
  static const double cell = 4;

  /// Where the letter may go: centered, leaving room around the edges.
  static const Rect letterArea = Rect.fromLTWH(
    width * 0.17,
    height * 0.1,
    width * 0.66,
    height * 0.8,
  );
}
