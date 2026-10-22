import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../letters/domain/coptic_letter.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/letter_puzzle_config.dart';
import '../domain/puzzle_board.dart';

/// Something the page reacts to (sounds, the brothers, moving on).
enum LetterPuzzleEvent {
  none,

  /// A tile went into a cube or came back out.
  moved,

  /// A check found wrong letters (red); they go back after a moment.
  wrong,

  /// A hint put a right letter in.
  hint,

  /// The word is spelled right; the next one comes after a moment.
  wordDone,

  /// The last word is done: [LetterPuzzleState.stars] are in.
  finished,
}

/// One word of the round, with its letters looked up.
class PuzzleItem {
  const PuzzleItem({required this.word, required this.letters});

  final PuzzleWord word;
  final List<CopticLetter> letters;
}

class LetterPuzzleState extends Equatable {
  const LetterPuzzleState({
    required this.items,
    required this.index,
    required this.board,
    this.mistakes = 0,
    this.hints = 0,
    this.checking = false,
    this.stars = 0,
    this.isNewBest = false,
    this.event = LetterPuzzleEvent.none,
    this.eventId = 0,
  });

  final List<PuzzleItem> items;

  /// The word being spelled.
  final int index;
  final PuzzleBoard board;

  /// Failed checks plus hints (each costs stars).
  final int mistakes;
  final int hints;

  /// Red marks are showing; tiles can't move until they go back.
  final bool checking;

  /// 0 while playing.
  final int stars;
  final bool isNewBest;
  final LetterPuzzleEvent event;
  final int eventId;

  PuzzleItem get item => items[index];
  bool get finished => stars > 0;

  /// Tiles can be moved and checked.
  bool get canPlay => !finished && !checking && !board.solved;

  LetterPuzzleState copyWith({
    int? index,
    PuzzleBoard? board,
    int? mistakes,
    int? hints,
    bool? checking,
    int? stars,
    bool? isNewBest,
    LetterPuzzleEvent? event,
  }) => LetterPuzzleState(
    items: items,
    index: index ?? this.index,
    board: board ?? this.board,
    mistakes: mistakes ?? this.mistakes,
    hints: hints ?? this.hints,
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
    hints,
    checking,
    stars,
    isNewBest,
    event,
    eventId,
  ];
}

/// Rules of the Letter puzzle: spell each word by putting its shuffled
/// Coptic letters in order, then check. Right letters turn green and stay;
/// wrong ones turn red and go back to the tray. Every failed check and every
/// hint is a mistake; the stars come from the mistakes over the round. The
/// best stars are kept per word length.
class LetterPuzzleCubit extends Cubit<LetterPuzzleState> {
  LetterPuzzleCubit(
    this._progress, {
    required this.config,
    required this.length,
    required List<PuzzleItem> items,
    Random? random,
  }) : _random = random ?? Random(),
       super(_first(items, random ?? Random()));

  /// Key the best stars are saved under (per word length).
  static const String id = 'letterPuzzle';

  /// The level a word length's best stars are saved under.
  static String levelKey(int length) =>
      length == LetterPuzzleConfig.mix ? 'mix' : '$length';

  final GameProgressRepository _progress;
  final LetterPuzzleConfig config;
  final int length;
  final Random _random;

  static LetterPuzzleState _first(List<PuzzleItem> items, Random random) =>
      LetterPuzzleState(
        items: items,
        index: 0,
        board: PuzzleBoard.start(items.first.letters, random),
      );

  /// Picks the round's words: [count] of [pool] at random, letters looked
  /// up in [alphabet] (words with an unknown letter are skipped). A word
  /// never comes twice in a round, even when the list has it twice (same
  /// text, or same spelling).
  static List<PuzzleItem> pickItems({
    required List<PuzzleWord> pool,
    required Map<String, CopticLetter> alphabet,
    required int count,
    required Random random,
  }) {
    final items = [
      for (final w in pool)
        if (w.letters.every(alphabet.containsKey))
          PuzzleItem(
            word: w,
            letters: [for (final id in w.letters) alphabet[id]!],
          ),
    ]..shuffle(random);
    final texts = <String>{}, spellings = <String>{};
    return [
      for (final item in items)
        if (texts.add(item.word.text) &&
            spellings.add(item.word.letters.join(' ')))
          item,
    ].take(count).toList();
  }

  void _move(PuzzleBoard? board) {
    if (board == null || board == state.board) return;
    emit(state.copyWith(board: board, event: LetterPuzzleEvent.moved));
  }

  /// Tile [tile] dropped on cube [slot].
  void place(int tile, int slot) {
    if (state.canPlay) _move(state.board.place(tile, slot));
  }

  /// Tile [tile] tapped in the tray: into the first empty cube.
  void placeNext(int tile) {
    if (state.canPlay) _move(state.board.placeNext(tile));
  }

  /// The tile in cube [slot] tapped (or dragged to the tray): back it goes.
  void remove(int slot) {
    if (state.canPlay) _move(state.board.remove(slot));
  }

  /// Checks the word (every cube must be filled).
  void check() {
    if (!state.canPlay || !state.board.full) return;
    final board = state.board.check();
    if (board.solved) {
      emit(state.copyWith(board: board, event: LetterPuzzleEvent.wordDone));
      return;
    }
    emit(
      state.copyWith(
        board: board,
        mistakes: state.mistakes + 1,
        checking: true,
        event: LetterPuzzleEvent.wrong,
      ),
    );
  }

  /// After a failed check: the red tiles go back to the tray.
  void clearWrong() {
    if (!state.checking) return;
    emit(
      state.copyWith(
        board: state.board.clearWrong(),
        checking: false,
        event: LetterPuzzleEvent.moved,
      ),
    );
  }

  /// Puts one right letter in (costs a mistake).
  void hint() {
    if (!state.canPlay) return;
    final board = state.board.hint();
    if (board == null) return;
    emit(
      state.copyWith(
        board: board,
        mistakes: state.mistakes + 1,
        hints: state.hints + 1,
        event: board.solved
            ? LetterPuzzleEvent.wordDone
            : LetterPuzzleEvent.hint,
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
          board: PuzzleBoard.start(state.items[i].letters, _random),
          event: LetterPuzzleEvent.none,
        ),
      );
      return;
    }
    final stars = config.starsFor(state.mistakes);
    final isNewBest = await _progress.saveStars(id, levelKey(length), stars);
    emit(
      state.copyWith(
        stars: stars,
        isNewBest: isNewBest,
        event: LetterPuzzleEvent.finished,
      ),
    );
  }
}
