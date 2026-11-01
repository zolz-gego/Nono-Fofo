import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/player_profile.dart';
import '../domain/profile_repository.dart';

/// The saved [PlayerProfile] (null until the child sets one).
class ProfileCubit extends Cubit<PlayerProfile?> {
  ProfileCubit(this._repository) : super(_repository.read());

  final ProfileRepository _repository;

  void save(PlayerProfile profile) {
    emit(profile);
    _repository.save(profile);
  }
}
