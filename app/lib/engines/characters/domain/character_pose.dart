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
    this.seat,
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

  /// Where a sitting pose sits (under the shorts), so a game can put it on
  /// a branch (in manifest px).
  final Offset? seat;

  /// [point] of this pose relative to the feet (the spot every pose is
  /// anchored at: the head's x, the bottom of the picture), at scale [k].
  Offset fromFeet(Offset point, double k, {bool mirror = false}) {
    final x = (point.dx - headCenter.dx) * k;
    return Offset(mirror ? -x : x, (point.dy - height) * k);
  }

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

  /// Falls back to [CharacterAction.fallback], then idle, if a pose is
  /// missing.
  CharacterPose? pose(CharacterId c, CharacterAction a) =>
      _poses[c]?[a] ??
      (a.fallback == null ? null : _poses[c]?[a.fallback!]) ??
      _poses[c]?[CharacterAction.idle];

  Iterable<CharacterPose> posesOf(CharacterId c) =>
      _poses[c]?.values ?? const [];
}
