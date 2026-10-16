import '../../letter_hunt/presentation/letter_hunt_cubit.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/balloons_config.dart';
import '../domain/balloons_round.dart';

typedef BalloonsState = LetterHuntState<BalloonsConfig>;

/// Runs one balloons game; the bunch the other brother holds is
/// [LetterHuntState.landed].
class BalloonsCubit extends LetterHuntCubit<BalloonsConfig> {
  BalloonsCubit(BalloonsRound round, GameProgressRepository progress)
    : super(round, progress, id);

  static const String id = 'balloons';
}
