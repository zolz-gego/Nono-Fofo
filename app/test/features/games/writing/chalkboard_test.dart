import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/features/games/writing/domain/letter_mask.dart';
import 'package:nonofofo/features/games/writing/domain/letter_strokes.dart';
import 'package:nonofofo/features/games/writing/domain/writing_board.dart';
import 'package:nonofofo/features/games/writing/presentation/chalkboard.dart';
import 'package:nonofofo/features/games/writing/presentation/writing_cubit.dart';

LetterMask _mask() {
  final (cols, rows) = LetterMask.gridFor(
    WritingBoard.width,
    WritingBoard.height,
    WritingBoard.cell,
  );
  final cells = Uint8List(cols * rows);
  for (var r = 40; r < 60; r++) {
    for (var c = 50; c < 150; c++) {
      cells[r * cols + c] = 1;
    }
  }
  return LetterMask(
    cols: cols,
    rows: rows,
    cell: WritingBoard.cell,
    letter: cells,
    inkRect: const Rect.fromLTWH(200, 160, 400, 80),
  );
}

/// The page around the board: it rebuilds when the finger goes up or down,
/// like the real page does.
class _Host extends StatefulWidget {
  const _Host({required this.phase, required this.controller});

  final WritingPhase phase;
  final ChalkboardController controller;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final LetterMask mask = _mask();
  bool drawing = false;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: Chalkboard(
        controller: widget.controller,
        mask: mask,
        strokes: LetterStrokes.none,
        phase: widget.phase,
        chalkColor: const Color(0xFFFFFFFF),
        chalkRadius: 10,
        demoStrokeSeconds: 1,
        onChalk: (_, _, _) {},
        onErase: (_, _, _) {},
        onDrawing: (d) => setState(() => drawing = d),
        onDemoDone: () {},
        onWipeDone: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('the board can pass while the finger is still down', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChalkboardController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _Host(phase: WritingPhase.drawing, controller: controller),
    );
    final gesture = await tester.startGesture(const Offset(300, 250));
    await tester.pump();
    await gesture.moveTo(const Offset(400, 250));
    await tester.pump();
    expect(controller.isDrawing, isTrue);

    // The letter got full mid-stroke: the page rebuilds the board passed.
    await tester.pumpWidget(
      _Host(phase: WritingPhase.boardPassed, controller: controller),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.isDrawing, isFalse);
    expect(tester.state<_HostState>(find.byType(_Host)).drawing, isFalse);
    await gesture.up();
  });
}
