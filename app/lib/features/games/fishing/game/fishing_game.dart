import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

import '../../../../core/domain/character_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/flame/character_component.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../domain/fishing_config.dart';
import '../presentation/fishing_cubit.dart';
import 'fish_component.dart';
import 'fishing_layout.dart';
import 'nile_background.dart';
import 'rod_component.dart';

/// The fishing scene: fish swim across the Nile; tapping one makes the hero
/// cast the rod, hook it and reel it up. Correct fish fly into the basket,
/// wrong ones go back to the water. Rules and scores live in [cubit].
class FishingGame extends FlameGame {
  FishingGame({
    required this.cubit,
    required this.hero,
    required this.roster,
    required this.sound,
    Random? random,
  }) : _random = random ?? Random();

  final FishingCubit cubit;

  /// The brother holding the rod (the child's buddy).
  final CharacterId hero;
  final CharacterRoster roster;
  final SoundService sound;
  final Random _random;

  static final Images _images = Images(prefix: '');

  late FishingLayout layout = _layoutFor(const ui.Size(800, 600));

  /// Set by the page from the UI language; the basket fills from the right
  /// in Arabic.
  bool rtl = false;

  /// The background picture once loaded (the layout lines up with it).
  NileArt? art;

  FishingLayout _layoutFor(ui.Size size) =>
      FishingLayout(size, goal: cubit.round.goal, rtl: rtl, art: art);
  FishingConfig get config => cubit.round.config;

  late final CharacterComponent _hero;
  late final RodComponent _rod;
  final List<ui.Image> _fishSprites = [];
  final List<FishComponent> _fish = [];

  /// Each lane keeps one speed so fish in a lane never overlap.
  final Map<int, double> _laneSpeed = {};
  double _spawnIn = 0;
  int _lastColor = -1;

  /// Fish spawned since the last target fish; never more than
  /// [_maxBetweenTargets] in a row, so the child never waits long.
  int _sinceTarget = 0;
  static const int _maxBetweenTargets = 2;
  _Cast? _cast;

  /// Correct fish still flying to the basket.
  final List<_Cast> _flying = [];
  double _heroIdleIn = 0;
  bool _loaded = false;

  @override
  ui.Color backgroundColor() => AppColors.skyBottom;

  @override
  Future<void> onLoad() async {
    final picture = await _tryLoad(config.background);
    if (picture != null) {
      art = NileArt(
        ui.Size(picture.width.toDouble(), picture.height.toDouble()),
        config.backgroundMarks,
      );
      layout = _layoutFor(layout.size);
    }
    for (final path in config.fishImages) {
      final img = await _tryLoad(path);
      if (img != null) _fishSprites.add(img);
    }
    _hero = CharacterComponent(
      character: hero,
      roster: roster,
      characterSize: layout.characterSize,
    )..priority = 15;
    _rod = RodComponent()..drawRod = !_hero.hasPose(CharacterAction.fish);
    _hero.play(_restPose);
    await addAll([NileBackground(picture: picture), _hero, _rod]);
    _loaded = true;
    _place();
    _fillRiver();
  }

  Future<ui.Image?> _tryLoad(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await _images.load(path);
    } catch (_) {
      return null; // Not added yet: draw it in code instead.
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    layout = _layoutFor(ui.Size(size.x, size.y));
    if (_loaded) _place();
  }

  /// With fishing poses the hero holds the drawn rod; without them he
  /// stands idle and the rod is drawn in code.
  bool get _holdsRod => !_rod.drawRod;
  CharacterAction get _restPose =>
      _holdsRod ? CharacterAction.fish : CharacterAction.idle;

  /// Keeps the line on the tip of the rod in the hero's hands (it moves
  /// when the pose changes), and hides it while he puts the rod down.
  void _followRod() {
    if (!_holdsRod) return;
    final tip = _hero.rodTip;
    _rod.visible = tip != null;
    if (tip == null) return;
    _rod.restTip = layout.heroFeet + tip;
    _rod.bobber = ui.Offset(
      max(_rod.restTip.dx + 8, layout.leftBankEdge + 14),
      layout.waterTop + 3,
    );
  }

  /// Puts the hero, rod and fish where the current layout says.
  void _place() {
    final l = layout;
    // The character's size is fixed when created, so scale it on resize.
    _hero
      ..position = Vector2(l.heroFeet.dx, l.heroFeet.dy)
      ..scale = Vector2.all(l.characterSize / _hero.characterSize);
    final s = l.characterSize;
    final heroH = _hero.size.y * _hero.scale.y;
    _rod
      ..hand = l.heroFeet + ui.Offset(s * 0.1, -heroH * 0.45)
      // Keep the tip below the target card at the top.
      ..restTip = ui.Offset(
        l.heroFeet.dx + s * 0.85,
        max(l.heroFeet.dy - heroH * 0.82, l.cardBottom + 14),
      );
    _rod.bobber = ui.Offset(_rod.restTip.dx + 6, l.waterTop + 3);
    _followRod();
    for (final f in _fish) {
      f
        ..size = Vector2(l.fishWidth, l.fishHeight)
        ..lane = min(f.lane, l.laneCount - 1)
        ..baseY = l.laneY(f.lane);
    }
    _laneSpeed.clear();
  }

  double _speedOf(int lane) => _laneSpeed.putIfAbsent(
    lane,
    () =>
        (layout.width + layout.fishWidth) /
        config.swimSeconds *
        (0.8 + _random.nextDouble() * 0.4),
  );

  int _directionOf(int lane) => switch (config.swimDirection) {
    SwimDirection.ltr => 1,
    SwimDirection.rtl => -1,
    SwimDirection.both => lane.isEven ? 1 : -1,
  };

  bool get _isOver => cubit.state.isFinished || cubit.round.isFinished;

  int get _targetsSwimming =>
      _fish.where((f) => f.isSwimming && cubit.round.isTarget(f.letter)).length;

  /// A few fish already in the water when the game starts.
  void _fillRiver() {
    final lanes = List.generate(layout.laneCount, (i) => i)..shuffle(_random);
    for (final (i, lane) in lanes.take(3).indexed) {
      final dir = _directionOf(lane);
      final x = layout.width * (0.25 + 0.25 * i);
      _spawn(lane, x: dir > 0 ? x : layout.width - x, isTarget: i == 1);
    }
    _spawnIn = config.spawnEverySeconds;
  }

  /// [isTarget] forces the fish to carry the target (true) or another
  /// letter (false); null lets the round decide.
  void _spawn(int lane, {double? x, bool? isTarget}) {
    final dir = _directionOf(lane);
    final round = cubit.round;
    final letter = switch (isTarget ??
        (_sinceTarget >= _maxBetweenTargets ? true : null)) {
      true => round.target,
      false => round.randomDistractor(_random),
      null => round.nextLetter(_random, targetsShowing: _targetsSwimming),
    };
    _sinceTarget = round.isTarget(letter) ? 0 : _sinceTarget + 1;
    final colors = _fishSprites.isEmpty
        ? AppColors.fish.length
        : _fishSprites.length;
    var color = _random.nextInt(colors);
    if (color == _lastColor) color = (color + 1) % colors;
    _lastColor = color;
    final w = layout.fishWidth;
    final fish =
        FishComponent(
            letter: letter,
            lane: lane,
            direction: dir,
            speed: _speedOf(lane),
            color: AppColors.fish[color % AppColors.fish.length],
            sprite: _fishSprites.isEmpty ? null : _fishSprites[color],
            letterSpot: config.fishLetterSpot,
            fishSize: Vector2(w, layout.fishHeight),
          )
          ..baseY = layout.laneY(lane)
          ..x = x ?? (dir > 0 ? -w / 2 : layout.width + w / 2)
          ..y = layout.laneY(lane);
    _fish.add(fish);
    add(fish);
  }

  /// A lane is free when its last fish has swum far enough from the edge.
  int? _freeLane() {
    final free = <int>[];
    for (var lane = 0; lane < layout.laneCount; lane++) {
      final dir = _directionOf(lane);
      final start = dir > 0 ? 0.0 : layout.width;
      final blocked = _fish.any(
        (f) =>
            f.lane == lane &&
            f.state != FishState.caught &&
            (f.x - start).abs() < layout.fishWidth * 1.8,
      );
      if (!blocked) free.add(lane);
    }
    return free.isEmpty ? null : free[_random.nextInt(free.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;
    if (_heroIdleIn > 0) {
      _heroIdleIn -= dt;
      if (_heroIdleIn <= 0 && !_isOver) _hero.play(_restPose);
    }
    _followRod();
    if (!_isOver) {
      _spawnIn -= dt;
      final swimming = _fish.where((f) => f.state != FishState.caught).length;
      if (_spawnIn <= 0 && swimming < config.maxFishOnScreen) {
        final lane = _freeLane();
        if (lane != null) {
          _spawn(lane);
          _spawnIn =
              config.spawnEverySeconds * (0.8 + _random.nextDouble() * 0.4);
        }
      }
    }
    _cast?.update(dt);
    for (final c in [..._flying]) {
      c.update(dt);
    }
  }

  // ---------------------------------------------------------------------------
  // Fish callbacks
  // ---------------------------------------------------------------------------

  void fishTapped(FishComponent fish) {
    if (_cast != null || _isOver || !fish.isSwimming) return;
    _cast = _Cast(this, fish);
  }

  void fishLeft(FishComponent fish) {
    if (fish.isSwimming && cubit.round.isTarget(fish.letter)) {
      cubit.missTarget();
    }
    _removeFish(fish);
  }

  void _removeFish(FishComponent fish) {
    _fish.remove(fish);
    fish.removeFromParent();
  }

  void _heroPose(CharacterAction action, {double seconds = 1.6}) {
    _hero.play(action);
    _heroIdleIn = seconds;
  }

  /// Both brothers cheer when the basket is full.
  void celebrate() {
    _heroIdleIn = 0;
    _hero.play(CharacterAction.celebrate);
  }
}

enum _Phase { cast, reel, judge, fly }

/// One throw of the rod, from tap to the fish landing in the basket (or
/// back in the water).
class _Cast {
  _Cast(this.game, this.fish) {
    fish.state = FishState.hooked;
    game._heroIdleIn = 0;
    game._hero.play(game._restPose);
    game._followRod();
    _from = game._rod.bobber;
    game.sound.playKey('fishing.fish_cast');
  }

  final FishingGame game;
  final FishComponent fish;
  _Phase _phase = _Phase.cast;
  double _t = 0;
  late ui.Offset _from;
  late ui.Offset _fishFrom;
  ui.Offset _hang = ui.Offset.zero;
  late ui.Offset _slot;
  bool _correct = false;

  static const double _castTime = 0.35;
  static const double _reelTime = 0.75;
  static const double _wrongHold = 1.4;
  static const double _flyTime = 0.65;

  RodComponent get _rod => game._rod;
  FishingLayout get _l => game.layout;

  ui.Offset get _fishCenter => ui.Offset(fish.x, fish.y);

  /// Where the hook sits on the fish: the mouth, or the top while hanging.
  ui.Offset _mouth(ui.Offset center, double hang) {
    final w = fish.size.x;
    final side = ui.Offset(fish.direction * w * 0.42, 0);
    final up = ui.Offset(0, -w * 0.48);
    return center + ui.Offset.lerp(side, up, hang)!;
  }

  ui.Offset _hangPoint() {
    final w = fish.size.x;
    final tip = _rod.drawRod ? _rod.tip : _rod.restTip;
    return ui.Offset(tip.dx, min(_l.bankTop - w * 0.45, tip.dy + w * 0.62));
  }

  void _go(_Phase next) {
    _phase = next;
    _t = 0;
  }

  void update(double dt) {
    _t += dt;
    switch (_phase) {
      case _Phase.cast:
        final k = Curves.easeOut.transform(min(1, _t / _castTime));
        _rod.bend = -0.25 * sin(k * pi);
        _rod.hook = ui.Offset.lerp(_from, _mouth(_fishCenter, 0), k);
        if (_t >= _castTime) {
          game.sound
            ..playKey('fishing.fish_bite')
            ..playKey('fishing.fish_splash');
          _fishFrom = _fishCenter;
          game.sound.playKey('fishing.fish_reel');
          if (game._holdsRod) {
            game._hero.play(CharacterAction.reel);
            game._followRod();
          }
          _go(_Phase.reel);
        }
      case _Phase.reel:
        final k = Curves.easeInOut.transform(min(1, _t / _reelTime));
        _rod.bend = 0.14 * sin(k * pi);
        // The fish rises to just under the rod tip.
        _hang = _hangPoint();
        fish.hang = k;
        final c = ui.Offset.lerp(_fishFrom, _hang, k)!;
        fish.position = Vector2(c.dx, c.dy);
        _rod.hook = _mouth(c, k);
        if (_t >= _reelTime) _judge();
      case _Phase.judge:
        _rod.hook = _mouth(_fishCenter, 1);
        if (_t >= _wrongHold) {
          _rod.hook = null;
          game.sound
            ..playKey('fishing.fish_escape')
            ..playKey('fishing.fish_splash');
          fish
            ..baseY = _l.laneY(fish.lane)
            ..release();
          game._hero.play(game._restPose);
          game._cast = null;
        }
      case _Phase.fly:
        final k = Curves.easeInOutCubic.transform(min(1, _t / _flyTime));
        final arc = sin(k * pi) * _l.fishWidth * 0.8;
        final c = ui.Offset.lerp(_hang, _slot, k)! - ui.Offset(0, arc);
        fish
          ..position = Vector2(c.dx, c.dy)
          ..hang = 1 - k
          ..scale = Vector2.all(
            ui.lerpDouble(1, _l.slotSize / _l.fishWidth, k)!,
          );
        if (_t >= _flyTime) {
          game._removeFish(fish);
          game.cubit.landed();
          game._flying.remove(this);
        }
    }
  }

  void _judge() {
    _correct = game.cubit.pick(fish.letter);
    if (_correct) {
      fish.state = FishState.caught;
      game.sound.playKey('fishing.fish_catch');
      game._heroPose(CharacterAction.cheer);
      _rod
        ..hook = null
        ..bend = 0;
      _slot = game._layoutFor(_l.size).slotCenter(game.cubit.round.caught - 1);
      // The fish flies on its own; the rod is free for the next cast.
      game._flying.add(this);
      game._cast = null;
      _go(_Phase.fly);
    } else {
      // Holding the rod he keeps the wrong fish on the line; the referee
      // does the talking.
      if (!game._holdsRod) game._heroPose(CharacterAction.wrong);
      _go(_Phase.judge);
    }
  }
}
