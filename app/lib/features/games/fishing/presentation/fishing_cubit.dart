import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../letters/domain/coptic_letter.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/fishing_round.dart';

/// Something that just happened, for the referee and the HUD to react to.
enum FishingEvent { start, correct, wrong, missed, finished }

class FishingState extends Equatable {
  const FishingState({
    required this.round,
    this.basket = 0,
    this.event = FishingEvent.start,
    this.eventId = 0,
    this.letter,
    this.isNewBest = false,
  });

  final FishingRound round;

  /// Correct fish that already landed in the basket (they fly there after
  /// the catch, so this trails `round.caught` a little).
  final int basket;

  final FishingEvent event;

  /// Changes on every event, even a repeated one.
  final int eventId;

  /// The letter of the fish the event is about.
  final CopticLetter? letter;

  /// Set when finished: the stars beat the saved best for this letter.
  final bool isNewBest;

  bool get isFinished => event == FishingEvent.finished;

  FishingState _next(
    FishingEvent event, {
    FishingRound? round,
    int? basket,
    CopticLetter? letter,
    bool? isNewBest,
  }) => FishingState(
    round: round ?? this.round,
    basket: basket ?? this.basket,
    event: event,
    eventId: eventId + 1,
    letter: letter,
    isNewBest: isNewBest ?? this.isNewBest,
  );

  @override
  List<Object?> get props => [round, basket, event, eventId, letter, isNewBest];
}

/// Runs one fishing game. The Flame game reports catches here; the page
/// listens to show the basket, the referee and the result.
class FishingCubit extends Cubit<FishingState> {
  FishingCubit(FishingRound round, this._progress)
    : super(FishingState(round: round));

  final GameProgressRepository _progress;

  static const String gameId = 'fishing';

  FishingRound get round => state.round;

  /// Returns whether [letter] was the one to catch.
  bool catchFish(CopticLetter letter) {
    if (state.isFinished) return false;
    final correct = round.isTarget(letter);
    emit(
      state._next(
        correct ? FishingEvent.correct : FishingEvent.wrong,
        round: round.catchFish(letter),
        letter: letter,
      ),
    );
    return correct;
  }

  void missTarget() {
    if (state.isFinished || round.isFinished) return;
    emit(
      state._next(
        FishingEvent.missed,
        round: round.missTarget(),
        letter: round.target,
      ),
    );
  }

  /// A caught fish reached its basket slot.
  Future<void> fishInBasket() async {
    if (state.isFinished) return;
    final basket = state.basket + 1;
    if (basket < round.goal) {
      emit(
        FishingState(
          round: round,
          basket: basket,
          event: state.event,
          eventId: state.eventId,
          letter: state.letter,
        ),
      );
      return;
    }
    final isNewBest = await _progress.saveStars(
      gameId,
      round.target.id,
      round.stars,
    );
    emit(
      state._next(
        FishingEvent.finished,
        basket: basket,
        letter: round.target,
        isNewBest: isNewBest,
      ),
    );
  }
}
