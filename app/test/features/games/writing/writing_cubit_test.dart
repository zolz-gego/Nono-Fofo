import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/games/writing/domain/letter_mask.dart';
import 'package:nonofofo/features/games/writing/domain/letter_strokes.dart';
import 'package:nonofofo/features/games/writing/domain/writing_config.dart';
import 'package:nonofofo/features/games/writing/presentation/writing_cubit.dart';

class _Progress extends Mock implements GameProgressRepository {}

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

const _fill = (Offset(20, 40), Offset(140, 40));

void main() {
  late _Progress progress;
  late WritingCubit cubit;

  setUp(() {
    progress = _Progress();
    when(() => progress.savePassed(any(), any())).thenAnswer((_) async {});
    cubit = WritingCubit(
      progress,
      config: const WritingConfig(messLimit: 0.5, wipesToFail: 2),
      letterId: 'alpha',
    );
  });

  tearDown(() => cubit.close());

  void scribbleOutside() {
    for (var y = 70.0; y < 80; y += 4) {
      cubit.chalk(Offset(0, y), Offset(160, y), 4);
    }
  }

  test('no chalk during the demo; then small, then capital passes', () {
    cubit.boardReady(_bar());
    expect(cubit.state.phase, WritingPhase.demo);
    cubit.chalk(_fill.$1, _fill.$2, 10);
    expect(cubit.state.filled, 0);

    cubit
      ..demoDone()
      ..chalk(_fill.$1, _fill.$2, 10);
    expect(cubit.state.phase, WritingPhase.boardPassed);
    expect(cubit.state.event, WritingEvent.boardPassed);
    verifyNever(() => progress.savePassed(any(), any()));

    cubit.nextBoard();
    expect(cubit.state.form, LetterForm.capital);
    expect(cubit.state.phase, WritingPhase.loading);

    cubit
      ..boardReady(_bar(), withDemo: false)
      ..chalk(_fill.$1, _fill.$2, 10);
    expect(cubit.state.phase, WritingPhase.passed);
    expect(cubit.state.event, WritingEvent.levelPassed);
    verify(() => progress.savePassed(WritingCubit.id, 'alpha')).called(1);
  });

  test('too much chalk outside wipes the board; wipesToFail fails', () {
    cubit.boardReady(_bar(), withDemo: false);
    scribbleOutside();
    expect(cubit.state.phase, WritingPhase.wiping);
    expect(cubit.state.wipes, 1);

    cubit.wipeDone();
    expect(cubit.state.phase, WritingPhase.drawing);
    expect(cubit.state.mess, 0);

    scribbleOutside();
    expect(cubit.state.phase, WritingPhase.failed);
    expect(cubit.state.event, WritingEvent.levelFailed);
    verifyNever(() => progress.savePassed(any(), any()));
  });

  test('erasing lowers the mess, so the board is not wiped', () {
    cubit.boardReady(_bar(), withDemo: false);
    cubit.chalk(const Offset(0, 74), const Offset(150, 74), 2);
    final mess = cubit.state.mess;
    expect(mess, greaterThan(0));
    cubit.erase(const Offset(0, 74), const Offset(150, 74), 4);
    expect(cubit.state.mess, 0);
    expect(cubit.state.phase, WritingPhase.drawing);
  });

  test('warns once before the mess meter is full', () {
    cubit.boardReady(_bar(), withDemo: false);
    final events = <WritingEvent>[];
    final sub = cubit.stream.listen((s) => events.add(s.event));
    // A bit of mess: past warnAt (half) but below the limit.
    cubit
      ..chalk(const Offset(0, 74), const Offset(150, 74), 2)
      ..chalk(const Offset(0, 74), const Offset(150, 74), 2);
    return Future<void>.delayed(Duration.zero, () {
      sub.cancel();
      expect(cubit.state.phase, WritingPhase.drawing);
      expect(events.where((e) => e == WritingEvent.warn), hasLength(1));
    });
  });
}
