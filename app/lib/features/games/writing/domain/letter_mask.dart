import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect;

/// Which cells of the board belong to the letter, on a grid of square
/// [cell]-sized cells in board units. Built once per board from the Coptic
/// glyph (see `LetterMaskBuilder`), then used to measure the chalk.
class LetterMask {
  LetterMask({
    required this.cols,
    required this.rows,
    required this.cell,
    required Uint8List letter,
    required this.inkRect,
    int nearCells = 3,
  }) : assert(letter.length == cols * rows),
       letter = letter,
       near = _dilate(letter, cols, rows, nearCells),
       insideCount = letter.where((v) => v == 1).length;

  final int cols;
  final int rows;

  /// Cell size in board units.
  final double cell;

  /// 1 = the cell is part of the (already thickened) letter.
  final Uint8List letter;

  /// 1 = the letter or a few cells around it: chalk here is "almost
  /// inside" and never counts as mess.
  final Uint8List near;

  /// Number of letter cells (what 100% means).
  final int insideCount;

  /// The glyph's own ink box on the board (the stroke order is given in
  /// fractions of it).
  final Rect inkRect;

  bool isLetter(int c, int r) => letter[r * cols + c] == 1;

  /// Point given in fractions of [inkRect] -> board units.
  Offset inkPoint(double x, double y) => Offset(
    inkRect.left + x * inkRect.width,
    inkRect.top + y * inkRect.height,
  );

  /// A copy whose letter is [cells] cells thicker on every side.
  LetterMask thickened(int cells, {int nearCells = 3}) => LetterMask(
    cols: cols,
    rows: rows,
    cell: cell,
    letter: _dilate(letter, cols, rows, cells),
    inkRect: inkRect,
    nearCells: nearCells,
  );

  /// The letter's outline as closed loops of board points (marching
  /// squares, then smoothed), for drawing the dotted edge.
  List<List<Offset>> outline() {
    // Each segment joins two cell-edge midpoints; keyed by a point id so
    // segments can be chained into loops.
    final next = <int, List<int>>{};
    int id(int x2, int y2) => y2 * (cols * 2 + 3) + x2;
    void link(int a, int b) {
      (next[a] ??= []).add(b);
      (next[b] ??= []).add(a);
    }

    int at(int c, int r) =>
        c < 0 || r < 0 || c >= cols || r >= rows ? 0 : letter[r * cols + c];

    // Corners are cell centers; edge midpoints in doubled coordinates.
    for (var r = -1; r < rows; r++) {
      for (var c = -1; c < cols; c++) {
        final tl = at(c, r), tr = at(c + 1, r);
        final br = at(c + 1, r + 1), bl = at(c, r + 1);
        final code = tl << 3 | tr << 2 | br << 1 | bl;
        if (code == 0 || code == 15) continue;
        // Doubled coords of cell-center grid (offset by 1 to stay >= 0).
        final x = (c + 1) * 2, y = (r + 1) * 2;
        final top = id(x + 1, y), right = id(x + 2, y + 1);
        final bottom = id(x + 1, y + 2), left = id(x, y + 1);
        switch (code) {
          case 1 || 14:
            link(left, bottom);
          case 2 || 13:
            link(bottom, right);
          case 3 || 12:
            link(left, right);
          case 4 || 11:
            link(top, right);
          case 6 || 9:
            link(top, bottom);
          case 7 || 8:
            link(left, top);
          case 5:
            link(left, top);
            link(bottom, right);
          case 10:
            link(top, right);
            link(left, bottom);
        }
      }
    }

    final w = cols * 2 + 3;
    Offset point(int pid) {
      final x2 = pid % w, y2 = pid ~/ w;
      return Offset((x2 / 2 - 1 + 0.5) * cell, (y2 / 2 - 1 + 0.5) * cell);
    }

    final loops = <List<Offset>>[];
    final used = <int>{};
    for (final start in next.keys) {
      if (used.contains(start)) continue;
      final loop = <Offset>[];
      var prev = -1;
      var cur = start;
      while (!used.contains(cur)) {
        used.add(cur);
        loop.add(point(cur));
        final options = next[cur]!;
        final n = options.firstWhere(
          (o) => o != prev && !used.contains(o),
          orElse: () => -1,
        );
        if (n < 0) break;
        prev = cur;
        cur = n;
      }
      if (loop.length >= 4) loops.add(_smooth(_smooth(loop)));
    }
    return loops;
  }

  /// Chaikin corner cutting on a closed loop.
  static List<Offset> _smooth(List<Offset> p) {
    final out = <Offset>[];
    for (var i = 0; i < p.length; i++) {
      final a = p[i], b = p[(i + 1) % p.length];
      out
        ..add(Offset.lerp(a, b, 0.25)!)
        ..add(Offset.lerp(a, b, 0.75)!);
    }
    return out;
  }

  static Uint8List _dilate(Uint8List src, int cols, int rows, int radius) {
    if (radius <= 0) return Uint8List.fromList(src);
    final out = Uint8List(src.length);
    final r2 = radius * radius;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (src[r * cols + c] != 1) continue;
        for (var dy = -radius; dy <= radius; dy++) {
          final y = r + dy;
          if (y < 0 || y >= rows) continue;
          for (var dx = -radius; dx <= radius; dx++) {
            final x = c + dx;
            if (x < 0 || x >= cols || dx * dx + dy * dy > r2) continue;
            out[y * cols + x] = 1;
          }
        }
      }
    }
    return out;
  }

  /// Grid size that covers a [width] x [height] board with [cell] cells.
  static (int, int) gridFor(double width, double height, double cell) =>
      (math.max(1, (width / cell).ceil()), math.max(1, (height / cell).ceil()));
}
