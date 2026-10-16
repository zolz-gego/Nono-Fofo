import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/features/games/writing/domain/chalk_coverage.dart';
import 'package:nonofofo/features/games/writing/domain/letter_mask.dart';

/// A 40 x 20 grid of 4-unit cells with a solid bar at rows 8..11,
/// columns 5..34 (a thick "-").
LetterMask _bar() {
  const cols = 40, rows = 20;
  final cells = Uint8List(cols * rows);
  for (var r = 8; r < 12; r++) {
    for (var c = 5; c < 35; c++) {
      cells[r * cols + c] = 1;
    }
  }
  return LetterMask(
    cols: cols,
    rows: rows,
    cell: 4,
    letter: cells,
    inkRect: const Rect.fromLTWH(20, 32, 120, 16),
  );
}

void main() {
  test('chalk along the letter fills it; no mess', () {
    final coverage = ChalkCoverage(_bar());
    coverage.addLine(const Offset(20, 40), const Offset(140, 40), 10);
    expect(coverage.filled, greaterThan(0.95));
    expect(coverage.mess, 0);
  });

  test('chalk just next to the letter is not mess, far away is', () {
    final coverage = ChalkCoverage(_bar());
    coverage.addLine(const Offset(20, 54), const Offset(140, 54), 2);
    expect(coverage.mess, 0, reason: 'within the near margin');
    coverage.addLine(const Offset(20, 74), const Offset(140, 74), 2);
    expect(coverage.mess, greaterThan(0));
    expect(coverage.filled, 0);
  });

  test('the eraser takes chalk off, inside and outside the letter', () {
    final coverage = ChalkCoverage(_bar())
      ..addLine(const Offset(20, 40), const Offset(140, 40), 10)
      ..addLine(const Offset(20, 74), const Offset(140, 74), 2);
    final filled = coverage.filled, mess = coverage.mess;
    coverage.eraseLine(const Offset(20, 40), const Offset(80, 40), 10);
    expect(coverage.filled, lessThan(filled));
    expect(coverage.filled, greaterThan(0));
    coverage.eraseLine(const Offset(20, 74), const Offset(140, 74), 4);
    expect(coverage.mess, lessThan(mess));
    expect(coverage.mess, 0);
    // Erasing where there's no chalk changes nothing.
    final now = coverage.filled;
    coverage.eraseLine(const Offset(20, 74), const Offset(140, 74), 4);
    expect(coverage.filled, now);
  });

  test('clear wipes everything', () {
    final coverage = ChalkCoverage(_bar())
      ..addLine(const Offset(20, 40), const Offset(140, 40), 10)
      ..clear();
    expect(coverage.filled, 0);
    expect(coverage.mess, 0);
  });

  test('thickened grows the letter; outline is one closed loop', () {
    final mask = _bar();
    expect(mask.thickened(2).insideCount, greaterThan(mask.insideCount));
    final loops = mask.outline();
    expect(loops, hasLength(1));
    final xs = loops.single.map((p) => p.dx);
    expect(xs.reduce((a, b) => a < b ? a : b), closeTo(20, 4));
    expect(xs.reduce((a, b) => a > b ? a : b), closeTo(140, 4));
  });

  test('inkPoint maps fractions of the ink box to the board', () {
    expect(_bar().inkPoint(0.5, 1), const Offset(80, 48));
  });
}
