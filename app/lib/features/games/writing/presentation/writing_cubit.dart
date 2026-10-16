import 'dart:ui' show Offset;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../progress/domain/game_progress_repository.dart';
import '../domain/chalk_coverage.dart';
import '../domain/letter_mask.dart';
import '../domain/letter_strokes.dart';
import '../domain/writing_config.dart';

enum WritingPhase {
  /// The board's letter is being prepared.
  loading,

  /// The chalk demo shows how the letter is written.
  demo,

  /// The child colours.
  drawing,

  /// Too messy: the other brother is wiping the board.
  wiping,

  /// This board is done; the capital one comes next.
  boardPassed,

  /// Both boards done.
  passed,

  /// Wiped too many times.
  failed,
}

/// One-off moments the page reacts to (speech, sounds, poses).
enum WritingEvent {
  none,
  boardStart,
  halfway,
  warn,
  wipe,
  boardPassed,
  levelPassed,
  levelFailed,
}

class WritingState extends Equatable {
  const WritingState({
    this.form = LetterForm.small,
    this.phase = WritingPhase.loading,
    this.filled = 0,
    this.mess = 0,
    this.wipes = 0,
    this.event = WritingEvent.none,
    this.eventId = 0,
  });

  final LetterForm form;
  final WritingPhase phase;

  /// 0..1 of the letter coloured.
  final double filled;

  /// 0..1 of the mess meter.
  final double mess;

  /// Wipes so far in this level (both boards).
  final int wipes;
  final WritingEvent event;
  final int eventId;

  bool get canDraw => phase == WritingPhase.drawing;

  WritingState copyWith({
    LetterForm? form,
    WritingPhase? phase,
    double? filled,
    double? mess,
    int? wipes,
    WritingEvent? event,
  }) => WritingState(
    form: form ?? this.form,
    phase: phase ?? this.phase,
    filled: filled ?? this.filled,
    mess: mess ?? this.mess,
    wipes: wipes ?? this.wipes,
    event: event ?? this.event,
    eventId: event == null ? eventId : eventId + 1,
  );

  @override
  List<Object?> get props => [form, phase, filled, mess, wipes, eventId];
}

/// Runs one writing level: the small letter, then the capital, each passed
/// by colouring [WritingConfig.passAt] of it without making too much mess.
class WritingCubit extends Cubit<WritingState> {
  WritingCubit(this._progress, {required this.config, required this.letterId})
    : super(const WritingState());

  static const String id = 'writing';

  final WritingConfig config;
  final String letterId;
  final GameProgressRepository _progress;

  ChalkCoverage? _coverage;
  bool _warned = false;
  bool _cheered = false;

  /// The letter for the current board is ready; [withDemo] plays the
  /// stroke-order demo first.
  void boardReady(LetterMask mask, {bool withDemo = true}) {
    _coverage = ChalkCoverage(mask);
    _warned = false;
    _cheered = false;
    emit(
      state.copyWith(
        phase: withDemo ? WritingPhase.demo : WritingPhase.drawing,
        filled: 0,
        mess: 0,
        event: WritingEvent.boardStart,
      ),
    );
  }

  /// The demo finished (or was skipped).
  void demoDone() {
    if (state.phase == WritingPhase.demo) {
      emit(state.copyWith(phase: WritingPhase.drawing));
    }
  }

  /// A chalk line from [a] to [b] (board units), [radius] wide.
  void chalk(Offset a, Offset b, double radius) {
    final coverage = _coverage;
    if (coverage == null || !state.canDraw) return;
    coverage.addLine(a, b, radius);
    final filled = coverage.filled;
    final mess = (coverage.mess / config.messLimit).clamp(0.0, 1.0);

    if (filled >= config.passAt) {
      final last = state.form == LetterForm.values.last;
      if (last) _progress.savePassed(id, letterId);
      return emit(
        state.copyWith(
          filled: filled,
          mess: mess,
          phase: last ? WritingPhase.passed : WritingPhase.boardPassed,
          event: last ? WritingEvent.levelPassed : WritingEvent.boardPassed,
        ),
      );
    }
    if (mess >= 1) {
      final wipes = state.wipes + 1;
      final failed = wipes >= config.wipesToFail;
      return emit(
        state.copyWith(
          filled: filled,
          mess: mess,
          wipes: wipes,
          phase: failed ? WritingPhase.failed : WritingPhase.wiping,
          event: failed ? WritingEvent.levelFailed : WritingEvent.wipe,
        ),
      );
    }
    WritingEvent? event;
    if (!_warned && mess >= config.warnAt) {
      _warned = true;
      event = WritingEvent.warn;
    } else if (!_cheered && filled >= config.halfwayCheerAt) {
      _cheered = true;
      event = WritingEvent.halfway;
    }
    emit(state.copyWith(filled: filled, mess: mess, event: event));
  }

  /// The eraser went from [a] to [b] (board units), [radius] wide. Rubbing
  /// out chalk lowers the colouring and the mess meter alike.
  void erase(Offset a, Offset b, double radius) {
    final coverage = _coverage;
    if (coverage == null || !state.canDraw) return;
    coverage.eraseLine(a, b, radius);
    emit(
      state.copyWith(
        filled: coverage.filled,
        mess: (coverage.mess / config.messLimit).clamp(0.0, 1.0),
      ),
    );
  }

  /// The sponge went over the board: start this board again (no demo,
  /// the start dots are still there).
  void wipeDone() {
    if (state.phase != WritingPhase.wiping) return;
    _coverage?.clear();
    _warned = false;
    _cheered = false;
    emit(state.copyWith(phase: WritingPhase.drawing, filled: 0, mess: 0));
  }

  /// Moves on from a passed small letter to the capital one.
  void nextBoard() {
    if (state.phase != WritingPhase.boardPassed) return;
    _coverage = null;
    emit(
      state.copyWith(
        form: LetterForm.values[state.form.index + 1],
        phase: WritingPhase.loading,
        filled: 0,
        mess: 0,
      ),
    );
  }
}
