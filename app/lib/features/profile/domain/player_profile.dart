import 'package:equatable/equatable.dart';

import '../../../core/domain/character_id.dart';

/// Who is playing: the child's name and the brother they play with. Saved
/// on this device so it is asked only once.
class PlayerProfile extends Equatable {
  const PlayerProfile({required this.name, required this.buddy});

  final String name;

  /// The brother the child plays with; the other one is the opponent.
  final CharacterId buddy;

  @override
  List<Object?> get props => [name, buddy];
}
