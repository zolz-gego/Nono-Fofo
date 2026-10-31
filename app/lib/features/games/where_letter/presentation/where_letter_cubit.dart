import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../letter_puzzle/presentation/letter_puzzle_cubit.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/gap_question.dart';
import '../domain/where_letter_config.dart';

/// Something the page reacts to (sounds, the brothers, moving on).
enum WhereLetterEvent {
  none,

  /// The right Coptic letter was picked: it goes into the gap.
  letterRight,

  /// A wrong option was picked (red, out).
  wrong,

  /// A hint took a wrong option away.
  hint,

  /// The right sound was picked: the word is done, the next one comes
  /// after a moment.
  wordDone,

  /// The last word is done: [WhereLetterState.stars] are in.
  finished,
}

class WhereLetterState extends Equatable {
  const WhereLetterState({
    required this.items,
    required this.index,
    required this.question,
    this.mistakes = 0,
    this.stars = 0,
    this.isNewBest = false,
    this.event = WhereLetterEvent.none,
    this.eventId = 0,
  });

  final List<PuzzleItem> items;

  /// The word being played.
  final int index;
  final GapQuestion question;

  /// Wrong picks plus hints (each costs stars).
  final int mistakes;

  /// 0 while playing.
  final int stars;
  final bool isNewBest;
  final WhereLetterEvent event;
  final int eventId;

  PuzzleItem get item => items[index];
  bool get finished => stars > 0;
  bool get canPlay => !finished && !question.done;

  WhereLetterState copyWith({
    int? index,
    GapQuestion? question,
    int? mistakes,
    int? stars,
    bool? isNewBest,
    WhereLetterEvent? event,
  }) => WhereLetterState(
    items: items,
    index: index ?? this.index,
    question: question ?? this.question,
    mistakes: mistakes ?? this.mistakes,
    stars: stars ?? this.stars,
    isNewBest: isNewBest ?? this.isNewBest,
    event: event ?? this.event,
    eventId: event == null ? eventId : eventId + 1,
  );

  @override
  List<Object?> get props => [
    index,
    question,
    mistakes,
    stars,
    isNewBest,
    event,
    eventId,
  ];
}

/// Rules of Where's the letter: each word's Coptic letters show with one
/// missing. The child picks the missing letter, then what it sounds like in
/// the word. Every wrong pick and every hint is a mistake; the stars come
/// from the mistakes over the round. The best stars are kept per word
/// length.
class WhereLetterCubit extends Cubit<WhereLetterState> {
  WhereLetterCubit(
    this._progress, {
    required this.config,
    required this.length,
    required List<PuzzleItem> items,
    required GapMaker maker,
    Random? random,
  }) : _maker = maker,
       _random = random ?? Random(),
       super(
         WhereLetterState(
           items: items,
           index: 0,
           question: maker.make(items.first, random ?? Random()),
         ),
       );

  /// Key the best stars are saved under (per word length, like the puzzle:
  /// see [LetterPuzzleCubit.levelKey]).
  static const String id = 'whereLetter';

  final GameProgressRepository _progress;
  final WhereLetterConfig config;
  final int length;
  final GapMaker _maker;
  final Random _random;

  /// Picks option [i] of the current choice.
  void pick(int i) {
    if (!state.canPlay) return;
    final step = state.question.step;
    final result = state.question.pick(i);
    if (result == null) return;
    if (!result.right) {
      emit(
        state.copyWith(
          question: result.question,
          mistakes: state.mistakes + 1,
          event: WhereLetterEvent.wrong,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        question: result.question,
        event: step == GapStep.letter
            ? WhereLetterEvent.letterRight
            : WhereLetterEvent.wordDone,
      ),
    );
  }

  /// Takes one wrong option away (costs a mistake).
  void hint() {
    if (!state.canPlay) return;
    final question = state.question.hint(_random);
    if (question == null) return;
    emit(
      state.copyWith(
        question: question,
        mistakes: state.mistakes + 1,
        event: WhereLetterEvent.hint,
      ),
    );
  }

  /// After a word is done: the next word, or the end of the round.
  Future<void> next() async {
    if (!state.question.done || state.finished) return;
    final i = state.index + 1;
    if (i < state.items.length) {
      emit(
        state.copyWith(
          index: i,
          question: _maker.make(state.items[i], _random),
          event: WhereLetterEvent.none,
        ),
      );
      return;
    }
    final stars = config.starsFor(state.mistakes);
    final isNewBest = await _progress.saveStars(
      id,
      LetterPuzzleCubit.levelKey(length),
      stars,
    );
    emit(
      state.copyWith(
        stars: stars,
        isNewBest: isNewBest,
        event: WhereLetterEvent.finished,
      ),
    );
  }
}
