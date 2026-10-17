import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../progress/domain/game_progress_repository.dart';
import '../../progress/domain/timed_record.dart';
import '../domain/memory_card.dart';

/// Something the page reacts to (sounds, the brothers, the popup).
enum CardsEvent {
  none,

  /// A card was turned (the first, or the second of a pair).
  flipped,

  /// The two cards up are a pair.
  match,

  /// The two cards up are not a pair; they turn back after a moment
  /// ([CardsCubit.hideMismatch]).
  mismatch,

  /// Every pair is found.
  solved,
}

class CardsState extends Equatable {
  const CardsState({
    required this.cards,
    this.moves = 0,
    this.open,
    this.locked = false,
    this.started = false,
    this.solvedIn,
    this.newRecord = false,
    this.lastFlipped,
    this.event = CardsEvent.none,
    this.eventId = 0,
  });

  final List<MemoryCard> cards;

  /// Pairs of cards turned so far.
  final int moves;

  /// The first card of the pair being turned, if any.
  final int? open;

  /// Two different cards are showing: no flips until they turn back.
  final bool locked;

  /// The clock runs from the first flip.
  final bool started;

  /// The finished time (null while playing).
  final Duration? solvedIn;

  /// The finished run beat the best time for this many cards.
  final bool newRecord;
  final int? lastFlipped;
  final CardsEvent event;
  final int eventId;

  bool get solved => solvedIn != null;
  int get pairsFound => cards.where((c) => c.matched).length ~/ 2;

  bool canFlip(int i) =>
      !solved && !locked && !cards[i].faceUp && !cards[i].matched;

  CardsState copyWith({
    List<MemoryCard>? cards,
    int? moves,
    int? Function()? open,
    bool? locked,
    bool? started,
    Duration? solvedIn,
    bool? newRecord,
    int? lastFlipped,
    CardsEvent? event,
  }) => CardsState(
    cards: cards ?? this.cards,
    moves: moves ?? this.moves,
    open: open == null ? this.open : open(),
    locked: locked ?? this.locked,
    started: started ?? this.started,
    solvedIn: solvedIn ?? this.solvedIn,
    newRecord: newRecord ?? this.newRecord,
    lastFlipped: lastFlipped ?? this.lastFlipped,
    event: event ?? this.event,
    eventId: event == null ? eventId : eventId + 1,
  );

  @override
  List<Object?> get props => [
    cards,
    moves,
    open,
    locked,
    started,
    solvedIn,
    newRecord,
    lastFlipped,
    event,
    eventId,
  ];
}

/// Rules of Grandpa's Cards: turn two cards; a letter's capital and small
/// card are a pair and stay up, anything else turns back. The clock starts
/// at the first flip; every second card turned is one move.
class CardsCubit extends Cubit<CardsState> {
  CardsCubit(
    this._progress, {
    required List<MemoryCard> cards,
    Stopwatch? stopwatch,
  }) : _clock = stopwatch ?? Stopwatch(),
       super(CardsState(cards: cards));

  /// Key the best times are saved under (per number of cards).
  static const String id = 'cards';

  final GameProgressRepository _progress;
  final Stopwatch _clock;

  /// Time on the clock now.
  Duration get elapsed => state.solvedIn ?? _clock.elapsed;

  Future<void> flip(int i) async {
    if (!state.canFlip(i)) return;
    if (!state.started) _clock.start();
    final cards = [...state.cards];
    cards[i] = cards[i].copyWith(faceUp: true);
    final open = state.open;
    if (open == null) {
      emit(
        state.copyWith(
          cards: cards,
          open: () => i,
          started: true,
          lastFlipped: i,
          event: CardsEvent.flipped,
        ),
      );
      return;
    }
    final moves = state.moves + 1;
    if (!cards[open].pairsWith(cards[i])) {
      emit(
        state.copyWith(
          cards: cards,
          moves: moves,
          open: () => null,
          locked: true,
          lastFlipped: i,
          event: CardsEvent.mismatch,
        ),
      );
      return;
    }
    cards[open] = cards[open].copyWith(matched: true);
    cards[i] = cards[i].copyWith(matched: true);
    if (cards.any((c) => !c.matched)) {
      emit(
        state.copyWith(
          cards: cards,
          moves: moves,
          open: () => null,
          lastFlipped: i,
          event: CardsEvent.match,
        ),
      );
      return;
    }
    _clock.stop();
    final run = TimedRecord(time: _clock.elapsed, moves: moves);
    final level = '${cards.length}';
    final best = _progress.bestTime(id, level);
    emit(
      state.copyWith(
        cards: cards,
        moves: moves,
        open: () => null,
        solvedIn: run.time,
        newRecord: best == null || run.beats(best),
        lastFlipped: i,
        event: CardsEvent.solved,
      ),
    );
    await _progress.saveTime(id, level, run);
  }

  /// Turns the two different cards back down.
  void hideMismatch() {
    if (!state.locked) return;
    emit(
      state.copyWith(
        cards: [
          for (final c in state.cards)
            c.matched ? c : c.copyWith(faceUp: false),
        ],
        locked: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _clock.stop();
    return super.close();
  }
}
