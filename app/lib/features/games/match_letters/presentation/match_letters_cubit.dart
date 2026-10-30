import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../letter_puzzle/presentation/letter_puzzle_cubit.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/match_board.dart';
import '../domain/match_letters_config.dart';

/// Something the page reacts to (sounds, the brothers, moving on).
enum MatchLettersEvent {
  none,

  /// A line was drawn (the page checks once every row has one).
  linked,

  /// A check found wrong lines (red); they go after a moment.
  wrong,

  /// A hint drew a right line.
  hint,

  /// Every line is right; the next word comes after a moment.
  wordDone,

  /// The last word is done: [MatchLettersState.stars] are in.
  finished,
}

class MatchLettersState extends Equatable {
  const MatchLettersState({
    required this.items,
    required this.index,
    required this.board,
    this.mistakes = 0,
    this.checking = false,
    this.stars = 0,
    this.isNewBest = false,
    this.event = MatchLettersEvent.none,
    this.eventId = 0,
  });

  final List<PuzzleItem> items;

  /// The word being matched.
  final int index;
  final MatchBoard board;

  /// Red lines plus hints (each costs stars).
  final int mistakes;

  /// Red lines are showing; nothing moves until they go.
  final bool checking;

  /// 0 while playing.
  final int stars;
  final bool isNewBest;
  final MatchLettersEvent event;
  final int eventId;

  PuzzleItem get item => items[index];
  bool get finished => stars > 0;

  /// Lines can be drawn (not while a check is on its way or showing).
  bool get canPlay => !finished && !checking && !board.solved && !board.full;

  MatchLettersState copyWith({
    int? index,
    MatchBoard? board,
    int? mistakes,
    bool? checking,
    int? stars,
    bool? isNewBest,
    MatchLettersEvent? event,
  }) => MatchLettersState(
    items: items,
    index: index ?? this.index,
    board: board ?? this.board,
    mistakes: mistakes ?? this.mistakes,
    checking: checking ?? this.checking,
    stars: stars ?? this.stars,
    isNewBest: isNewBest ?? this.isNewBest,
    event: event ?? this.event,
    eventId: event == null ? eventId : eventId + 1,
  );

  @override
  List<Object?> get props => [
    index,
    board,
    mistakes,
    checking,
    stars,
    isNewBest,
    event,
    eventId,
  ];
}

/// Rules of Match the letters: draw a line from each Coptic letter of the
/// word to what it sounds like. Once every letter has a line the page calls
/// [check]: right lines turn green and stay, wrong ones turn red and go.
/// Every red line and every hint is a mistake; the stars come from the
/// mistakes over the round. The best stars are kept per word length.
class MatchLettersCubit extends Cubit<MatchLettersState> {
  MatchLettersCubit(
    this._progress, {
    required this.config,
    required this.length,
    required List<PuzzleItem> items,
    Random? random,
  }) : _random = random ?? Random(),
       super(_first(items, random ?? Random()));

  /// Key the best stars are saved under (per word length, like the puzzle:
  /// see [LetterPuzzleCubit.levelKey]).
  static const String id = 'matchLetters';

  final GameProgressRepository _progress;
  final MatchLettersConfig config;
  final int length;
  final Random _random;

  static MatchBoard _board(PuzzleItem item, Random random) =>
      MatchBoard.start(item.letters, item.word.sounds, random);

  static MatchLettersState _first(List<PuzzleItem> items, Random random) =>
      MatchLettersState(
        items: items,
        index: 0,
        board: _board(items.first, random),
      );

  /// A line from row [row] to sound [sound].
  void link(int row, int sound) {
    if (!state.canPlay) return;
    final board = state.board.link(row, sound);
    if (board == state.board) return;
    emit(state.copyWith(board: board, event: MatchLettersEvent.linked));
  }

  /// Checks the lines (every row must have one).
  void check() {
    final board = state.board;
    if (state.finished || state.checking || board.solved || !board.full) {
      return;
    }
    final checked = board.check();
    if (checked.solved) {
      emit(state.copyWith(board: checked, event: MatchLettersEvent.wordDone));
      return;
    }
    emit(
      state.copyWith(
        board: checked,
        mistakes: state.mistakes + checked.wrongCount,
        checking: true,
        event: MatchLettersEvent.wrong,
      ),
    );
  }

  /// After a check: the red lines go.
  void clearWrong() {
    if (!state.checking) return;
    emit(
      state.copyWith(
        board: state.board.clearWrong(),
        checking: false,
        event: MatchLettersEvent.none,
      ),
    );
  }

  /// Draws one right line (costs a mistake).
  void hint() {
    if (!state.canPlay) return;
    final board = state.board.hint();
    if (board == null) return;
    emit(
      state.copyWith(
        board: board,
        mistakes: state.mistakes + 1,
        event: board.solved
            ? MatchLettersEvent.wordDone
            : MatchLettersEvent.hint,
      ),
    );
  }

  /// After a word is done: the next word, or the end of the round.
  Future<void> next() async {
    if (!state.board.solved || state.finished) return;
    final i = state.index + 1;
    if (i < state.items.length) {
      emit(
        state.copyWith(
          index: i,
          board: _board(state.items[i], _random),
          event: MatchLettersEvent.none,
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
        event: MatchLettersEvent.finished,
      ),
    );
  }
}
