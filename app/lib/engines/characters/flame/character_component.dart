import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

import '../../../core/domain/character_id.dart';
import '../domain/character_action.dart';
import '../domain/character_motion.dart';
import '../domain/character_pose.dart';

/// The same brother + motions as `AnimatedCharacter`, for Flame games.
/// Position is the point between the feet (anchor = bottom center).
///
/// ```dart
/// add(CharacterComponent(character: CharacterId.nono, roster: roster)
///   ..position = Vector2(200, 400));
/// nono.play(CharacterAction.run);
/// ```
class CharacterComponent extends PositionComponent {
  CharacterComponent({
    required this.character,
    required this.roster,
    this.characterSize = 200,
    this.mirror = false,
    CharacterAction initial = CharacterAction.idle,
  }) : _action = initial,
       super(anchor: Anchor.bottomCenter);

  /// Character images use full asset paths, not Flame's `assets/images/`.
  static final Images _images = Images(prefix: '');

  final CharacterId character;
  final CharacterRoster roster;

  /// Nono's standing height in game units (same meaning as in the widget).
  final double characterSize;
  bool mirror;

  final Map<CharacterAction, Image> _sprites = {};
  CharacterAction _action;
  MotionSpec _spec = CharacterMotions.breathe;
  double _time = 0;

  CharacterAction get action => _action;
  double get _k => characterSize / roster.referenceHeight;

  @override
  Future<void> onLoad() async {
    for (final pose in roster.posesOf(character)) {
      _sprites[pose.action] = await _images.load(pose.asset);
    }
    final idle = roster.pose(character, CharacterAction.idle)!;
    size = Vector2(idle.width * _k, idle.height * _k);
    play(_action);
  }

  /// Whether this brother has an image for [action] (else idle is shown).
  bool hasPose(CharacterAction action) =>
      roster.pose(character, action)?.action == action;

  /// Where the fishing rod's tip is, relative to [position] (the feet), or
  /// null if the current pose holds no rod.
  Offset? get rodTip => _fromFeet((pose) => pose.rodTip);

  /// Where the raised fist holding balloon strings is, relative to
  /// [position] (the feet), or null if the current pose has none.
  Offset? get hand => _fromFeet((pose) => pose.hand);

  Offset? _fromFeet(Offset? Function(CharacterPose pose) point) {
    final pose = roster.pose(character, _action);
    final p = pose == null ? null : point(pose);
    if (pose == null || p == null) return null;
    final k = _k * scale.x;
    final x = (p.dx - pose.headCenter.dx) * k;
    return Offset(mirror ? -x : x, (p.dy - pose.height) * k);
  }

  void play(CharacterAction action) {
    _action = action;
    _spec = CharacterMotions.of(action);
    _time = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final period = _spec.period.inMicroseconds / 1e6;
    if (!_spec.loop && _time >= period) {
      _spec = CharacterMotions.breathe;
      _time = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final pose = roster.pose(character, _action);
    final image = pose == null ? null : _sprites[pose.action];
    if (pose == null || image == null) return;

    final period = _spec.period.inMicroseconds / 1e6;
    final f = _spec.frameAt((_time % period) / period);
    final h = size.y;

    canvas.save();
    // Origin at the feet (bottom center of the component box).
    canvas.translate(size.x / 2, h);
    if (mirror) canvas.scale(-1, 1);
    canvas.translate(f.dx * h, f.dy * h);
    canvas.rotate(f.rotation);
    canvas.scale(f.scaleX, f.scaleY);

    final dst = Rect.fromLTWH(
      -pose.headCenter.dx * _k,
      -pose.height * _k,
      pose.width * _k,
      pose.height * _k,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }
}
