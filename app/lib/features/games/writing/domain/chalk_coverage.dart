import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'letter_mask.dart';

/// Measures the chalk on one board: how much of the letter is coloured
/// ([filled]) and how much chalk went well outside it ([mess]).
class ChalkCoverage {
  ChalkCoverage(this.mask) : _chalk = Uint8List(mask.cols * mask.rows);

  final LetterMask mask;
  final Uint8List _chalk;
  int _inside = 0;
  int _outside = 0;

  /// 0..1 of the letter's cells that have chalk.
  double get filled => mask.insideCount == 0 ? 0 : _inside / mask.insideCount;

  /// Chalk cells outside the letter (and its small margin), as a fraction
  /// of the letter's own size: 1.0 = as much chalk outside as the whole
  /// letter.
  double get mess => mask.insideCount == 0 ? 0 : _outside / mask.insideCount;

  /// Adds a chalk line from [a] to [b] (board units), [radius] wide.
  void addLine(Offset a, Offset b, double radius) {
    final step = mask.cell / 2;
    final d = (b - a).distance;
    final n = math.max(1, (d / step).ceil());
    for (var i = 0; i <= n; i++) {
      _dab(Offset.lerp(a, b, i / n)!, radius);
    }
  }

  void _dab(Offset p, double radius) {
    final cell = mask.cell;
    final c0 = math.max(0, ((p.dx - radius) / cell).floor());
    final c1 = math.min(mask.cols - 1, ((p.dx + radius) / cell).floor());
    final r0 = math.max(0, ((p.dy - radius) / cell).floor());
    final r1 = math.min(mask.rows - 1, ((p.dy + radius) / cell).floor());
    final rr = radius * radius;
    for (var r = r0; r <= r1; r++) {
      final cy = (r + 0.5) * cell - p.dy;
      for (var c = c0; c <= c1; c++) {
        final cx = (c + 0.5) * cell - p.dx;
        if (cx * cx + cy * cy > rr) continue;
        final i = r * mask.cols + c;
        if (_chalk[i] == 1) continue;
        _chalk[i] = 1;
        if (mask.letter[i] == 1) {
          _inside++;
        } else if (mask.near[i] == 0) {
          _outside++;
        }
      }
    }
  }

  /// Wipes the board clean.
  void clear() {
    _chalk.fillRange(0, _chalk.length, 0);
    _inside = 0;
    _outside = 0;
  }
}
