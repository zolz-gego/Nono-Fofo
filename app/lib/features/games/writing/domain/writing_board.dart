import 'dart:ui' show Rect, Size;

/// The chalkboard's own coordinate space. Everything on the board (the
/// letter, the chalk, the stroke order) is in these units; the widget
/// scales the whole board to fit the screen.
///
/// The board is always [width] wide. It is [standardHeight] tall on wide
/// screens and taller on upright ones, so the letter can grow there.
class WritingBoard {
  const WritingBoard({this.height = standardHeight})
    : assert(height >= standardHeight && height <= maxHeight);

  static const double width = 800;
  static const double standardHeight = 470;

  /// The tallest board (upright phones).
  static const double maxHeight = 1400;

  static const WritingBoard standard = WritingBoard();

  /// Grid cell used to measure the chalk.
  static const double cell = 4;

  final double height;

  Size get size => Size(width, height);

  bool get isStandard => height == standardHeight;

  /// Where the letter may go: centered, leaving room around the edges (less
  /// at the sides on a tall board, where the height isn't the limit).
  Rect get letterArea {
    final side = isStandard ? 0.17 : 0.08;
    return Rect.fromLTWH(
      width * side,
      height * 0.1,
      width * (1 - side * 2),
      height * 0.8,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WritingBoard && other.height == height;

  @override
  int get hashCode => height.hashCode;
}
