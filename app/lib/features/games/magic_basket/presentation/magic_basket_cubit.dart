import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../progress/domain/game_progress_repository.dart';
import '../domain/magic_basket_round.dart';

/// Something that just happened, for the thrower and the HUD to react to.
enum BasketEvent { start, correct, notNeeded, wrong, missed, finished }

class MagicBasketState extends Equatable {
  const MagicBasketState({
    required this.round,
    this.landed = 0,
    this.event = BasketEvent.start,
    this.eventId = 0,
    this.sound,
    this.isNewBest = false,
  });

  final MagicBasketRound round;

  /// Right apples already settled in the basket (they drop in a moment
  /// after the catch, so this trails `round.caught` a little).
  final int landed;

  final BasketEvent event;

  /// Changes on every event, even a repeated one.
  final int eventId;

  /// The sound of the apple the event is about.
  final String? sound;

  /// Set when finished: the stars beat the saved best for this letter.
  final bool isNewBest;

  bool get isFinished => event == BasketEvent.finished;

  MagicBasketState _next(
    BasketEvent event, {
    MagicBasketRound? round,
    int? landed,
    String? sound,
    bool? isNewBest,
  }) => MagicBasketState(
    round: round ?? this.round,
    landed: landed ?? this.landed,
    event: event,
    eventId: eventId + 1,
    sound: sound,
    isNewBest: isNewBest ?? this.isNewBest,
  );

  @override
  List<Object?> get props => [round, landed, event, eventId, sound, isNewBest];
}

/// Runs one Magic basket game. The Flame game reports catches here; the
/// page listens to show the progress, the thrower and the result.
class MagicBasketCubit extends Cubit<MagicBasketState> {
  MagicBasketCubit(MagicBasketRound round, this._progress)
    : super(MagicBasketState(round: round));

  static const String id = 'magicBasket';

  final GameProgressRepository _progress;

  MagicBasketRound get round => state.round;

  BasketCatch pick(String sound) {
    if (state.isFinished || round.isFinished) return BasketCatch.notNeeded;
    final result = round.judge(sound);
    emit(
      state._next(
        switch (result) {
          BasketCatch.correct => BasketEvent.correct,
          BasketCatch.notNeeded => BasketEvent.notNeeded,
          BasketCatch.wrong => BasketEvent.wrong,
        },
        round: round.pick(sound),
        sound: sound,
      ),
    );
    return result;
  }

  void miss(String sound) {
    if (state.isFinished || round.isFinished) return;
    emit(state._next(BasketEvent.missed, round: round.miss(), sound: sound));
  }

  /// A caught apple settled in the basket.
  Future<void> landed() async {
    if (state.isFinished) return;
    final landed = state.landed + 1;
    if (landed < round.goal) {
      emit(
        MagicBasketState(
          round: round,
          landed: landed,
          event: state.event,
          eventId: state.eventId,
          sound: state.sound,
        ),
      );
      return;
    }
    final isNewBest = await _progress.saveStars(
      id,
      round.target.id,
      round.stars,
    );
    emit(
      state._next(BasketEvent.finished, landed: landed, isNewBest: isNewBest),
    );
  }
}
