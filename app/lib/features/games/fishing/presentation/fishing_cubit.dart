import '../../letter_hunt/presentation/letter_hunt_cubit.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/fishing_config.dart';
import '../domain/fishing_round.dart';

typedef FishingState = LetterHuntState<FishingConfig>;

/// Runs one fishing game; the basket is [LetterHuntState.landed].
class FishingCubit extends LetterHuntCubit<FishingConfig> {
  FishingCubit(FishingRound round, GameProgressRepository progress)
    : super(round, progress, id);

  static const String id = 'fishing';
}
