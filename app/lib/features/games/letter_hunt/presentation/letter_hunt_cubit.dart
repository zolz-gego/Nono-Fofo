import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../letters/domain/coptic_letter.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/letter_hunt_round.dart';
import '../domain/letter_hunt_rules.dart';

/// Something that just happened, for the referee and the HUD to react to.
enum LetterHuntEvent { start, correct, wrong, missed, finished }

class LetterHuntState<C extends LetterHuntRules> extends Equatable {
  const LetterHuntState({
    required this.round,
    this.landed = 0,
    this.event = LetterHuntEvent.start,
    this.eventId = 0,
    this.letter,
    this.isNewBest = false,
  });

  final LetterHuntRound<C> round;

  /// Correct items that already reached their spot (the basket, the
  /// balloon bunch). They travel there after the catch, so this trails
  /// `round.caught` a little.
  final int landed;

  final LetterHuntEvent event;

  /// Changes on every event, even a repeated one.
  final int eventId;

  /// The letter of the item the event is about.
  final CopticLetter? letter;

  /// Set when finished: the stars beat the saved best for this letter.
  final bool isNewBest;

  bool get isFinished => event == LetterHuntEvent.finished;

  LetterHuntState<C> _next(
    LetterHuntEvent event, {
    LetterHuntRound<C>? round,
    int? landed,
    CopticLetter? letter,
    bool? isNewBest,
  }) => LetterHuntState(
    round: round ?? this.round,
    landed: landed ?? this.landed,
    event: event,
    eventId: eventId + 1,
    letter: letter,
    isNewBest: isNewBest ?? this.isNewBest,
  );

  @override
  List<Object?> get props => [round, landed, event, eventId, letter, isNewBest];
}

/// Runs one "find the letter" game. The Flame game reports catches here;
/// the page listens to show the progress, the referee and the result.
class LetterHuntCubit<C extends LetterHuntRules>
    extends Cubit<LetterHuntState<C>> {
  LetterHuntCubit(LetterHuntRound<C> round, this._progress, this.gameId)
    : super(LetterHuntState(round: round));

  final GameProgressRepository _progress;

  /// Key the best stars are saved under.
  final String gameId;

  LetterHuntRound<C> get round => state.round;

  /// Returns whether [letter] was the one to catch.
  bool pick(CopticLetter letter) {
    if (state.isFinished) return false;
    final correct = round.isTarget(letter);
    emit(
      state._next(
        correct ? LetterHuntEvent.correct : LetterHuntEvent.wrong,
        round: round.pick(letter),
        letter: letter,
      ),
    );
    return correct;
  }

  void missTarget() {
    if (state.isFinished || round.isFinished) return;
    emit(
      state._next(
        LetterHuntEvent.missed,
        round: round.missTarget(),
        letter: round.target,
      ),
    );
  }

  /// A caught item reached its spot.
  Future<void> landed() async {
    if (state.isFinished) return;
    final landed = state.landed + 1;
    if (landed < round.goal) {
      emit(
        LetterHuntState(
          round: round,
          landed: landed,
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
        LetterHuntEvent.finished,
        landed: landed,
        letter: round.target,
        isNewBest: isNewBest,
      ),
    );
  }
}
