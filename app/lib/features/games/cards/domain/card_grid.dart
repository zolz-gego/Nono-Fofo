import 'dart:math';
import 'dart:ui' show Rect, Size;

/// How [count] cards fill an area with no scrolling: the column count that
/// gives the biggest cards, and where each card goes.
class CardGrid {
  const CardGrid._({
    required this.columns,
    required this.rows,
    required this.cardSize,
    required this.gap,
    required this.origin,
  });

  /// Lays out [count] cards of width:height [aspect] in [area], [gap]
  /// (a share of the card width, clamped) between them.
  factory CardGrid.fit(
    int count,
    Size area, {
    double aspect = 0.75,
    double gapShare = 0.1,
    double maxGap = 14,
    double maxCardWidth = 180,
  }) {
    var best = const CardGrid._(
      columns: 1,
      rows: 1,
      cardSize: Size.zero,
      gap: 0,
      origin: Rect.zero,
    );
    for (var cols = 1; cols <= count; cols++) {
      final rows = (count / cols).ceil();
      // Card width w, gap g = min(w * gapShare, maxGap): solve for the
      // biggest w that fits both ways (first assuming the gap is a share).
      double widthFor(double g) => min(
        (area.width - g * (cols - 1)) / cols,
        ((area.height - g * (rows - 1)) / rows) * aspect,
      );
      var w = min(
        area.width / (cols + gapShare * (cols - 1)),
        area.height / (rows + gapShare * (rows - 1)) * aspect,
      );
      if (w * gapShare > maxGap) w = widthFor(maxGap);
      w = min(w, maxCardWidth);
      if (w <= best.cardSize.width) continue;
      final g = min(w * gapShare, maxGap);
      final size = Size(w, w / aspect);
      final total = Size(
        cols * w + (cols - 1) * g,
        rows * size.height + (rows - 1) * g,
      );
      best = CardGrid._(
        columns: cols,
        rows: rows,
        cardSize: size,
        gap: g,
        origin: Rect.fromLTWH(
          (area.width - total.width) / 2,
          (area.height - total.height) / 2,
          total.width,
          total.height,
        ),
      );
    }
    return best;
  }

  final int columns;
  final int rows;
  final Size cardSize;
  final double gap;

  /// Where the whole grid sits in the area (centred).
  final Rect origin;

  /// Card [index]'s rectangle in the area, filling rows left to right
  /// ([rtl]: right to left). A short last row is centred.
  Rect cardRect(int index, int count, {bool rtl = false}) {
    final row = index ~/ columns;
    var col = index % columns;
    final inRow = row == rows - 1 ? count - row * columns : columns;
    final shift = (columns - inRow) * (cardSize.width + gap) / 2;
    if (rtl) col = inRow - 1 - col;
    return Rect.fromLTWH(
      origin.left + shift + col * (cardSize.width + gap),
      origin.top + row * (cardSize.height + gap),
      cardSize.width,
      cardSize.height,
    );
  }
}
