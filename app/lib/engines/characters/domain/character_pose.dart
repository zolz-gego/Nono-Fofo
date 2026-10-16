import 'dart:ui' show Offset;

import 'package:equatable/equatable.dart';

import '../../../core/domain/character_id.dart';
import 'character_action.dart';

/// One pose image. Sizes are in "manifest pixels": both brothers share one
/// pixel scale (Fofo is ~75% of Nono's height), so poses line up when drawn
/// with the same scale.
class CharacterPose extends Equatable {
  const CharacterPose({
    required this.character,
    required this.action,
    required this.asset,
    required this.smallAsset,
    required this.width,
    required this.height,
    required this.headCenter,
    this.rodTip,
    this.hand,
  });

  final CharacterId character;
  final CharacterAction action;
  final String asset;
  final String smallAsset;
  final double width;
  final double height;
  final Offset headCenter;

  /// Tip of the fishing rod, for poses that hold one (in manifest px).
  final Offset? rodTip;

  /// Raised fist that holds balloon strings, for poses that have one (in
  /// manifest px).
  final Offset? hand;

  @override
  List<Object?> get props => [character, action, asset];
}

/// All poses of both brothers.
class CharacterRoster {
  const CharacterRoster(this._poses);

  static const empty = CharacterRoster({});

  final Map<CharacterId, Map<CharacterAction, CharacterPose>> _poses;

  /// Height (manifest px) that maps to the `size` given to the widgets:
  /// Nono's idle pose.
  double get referenceHeight =>
      _poses[CharacterId.nono]?[CharacterAction.idle]?.height ?? 1000;

  /// Falls back to idle if a pose is missing.
  CharacterPose? pose(CharacterId c, CharacterAction a) =>
      _poses[c]?[a] ?? _poses[c]?[CharacterAction.idle];

  Iterable<CharacterPose> posesOf(CharacterId c) =>
      _poses[c]?.values ?? const [];
}
