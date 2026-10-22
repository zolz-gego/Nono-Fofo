import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

import '../../../../core/domain/character_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/flame/character_component.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../domain/balloons_config.dart';
import '../presentation/balloons_cubit.dart';
import 'balloon_component.dart';
import 'balloons_layout.dart';
import 'village_background.dart';

/// The village scene: letter balloons rise into the sky. Tapping one sends
/// the child's buddy running under it; he jumps, grabs the string and
/// brings it to the other brother. Correct balloons join the bunch the
/// other brother holds; wrong ones pop. Rules and scores live in [cubit].
class BalloonsGame extends VillageGame {
  BalloonsGame({
    required this.cubit,
    required this.hero,
    required this.roster,
    required this.sound,
    Random? random,
  }) : _random = random ?? Random();

  final BalloonsCubit cubit;

  /// The brother who catches the balloons (the child's buddy).
  final CharacterId hero;
  final CharacterRoster roster;
  final SoundService sound;
  final Random _random;

  static final Images _images = Images(prefix: '');

  @override
  late BalloonsLayout layout = _layoutFor(const ui.Size(800, 600));

  /// Set by the page from the UI language; the progress slots fill from
  /// the right in Arabic.
  bool rtl = false;

  /// The background picture once loaded (the layout lines up with it).
  VillageArt? art;

  BalloonsLayout _layoutFor(ui.Size size) => BalloonsLayout(
    size,
    goal: cubit.round.goal,
    rtl: rtl,
    art: art,
    receiverFist: receiverFist,
  );

  /// The other brother's raised fist in his "hold" pose (he stands on the
  /// right, mirrored), relative to his feet in units of his size; null if
  /// he has no such pose.
  late final ui.Offset? receiverFist = () {
    final pose = roster.pose(hero.other, CharacterAction.hold);
    final hand = pose?.hand;
    if (pose == null || hand == null || pose.action != CharacterAction.hold) {
      return null;
    }
    return ui.Offset(-(hand.dx - pose.headCenter.dx), hand.dy - pose.height) /
        roster.referenceHeight;
  }();

  /// The buddy's pose for jumping up to a string.
  CharacterAction get _jumpPose => _hero.hasPose(CharacterAction.jump)
      ? CharacterAction.jump
      : CharacterAction.cheer;
  BalloonsConfig get config => cubit.round.config;

  late final CharacterComponent _hero;
  final List<ui.Image> _sprites = [];

  /// Balloons still floating up.
  final List<BalloonComponent> _rising = [];

  /// Correct balloons the other brother holds (in catch order).
  final List<BalloonComponent> _bunch = [];

  /// Correct balloons on their way to the bunch.
  final List<_Fly> _flying = [];

  _Catch? _catch;
  double _spawnIn = 0;
  int _lastColor = -1;
  int _lastColumn = -1;

  /// Balloons spawned since the last target; never more than
  /// [_maxBetweenTargets] in a row, so the child never waits long.
  int _sinceTarget = 0;
  static const int _maxBetweenTargets = 2;

  /// Where the buddy is along the path, and how high he is jumping.
  double _heroX = 0;
  double _heroLift = 0;

  /// After a catch the buddy walks back here (null = stay).
  double? _walkTo;
  double _heroIdleIn = 0;
  bool _loaded = false;

  @override
  ui.Color backgroundColor() => AppColors.skyBottom;

  @override
  Future<void> onLoad() async {
    // Load everything at once; one by one the scene stays empty for seconds.
    final loaded = await Future.wait([
      _tryLoad(config.background),
      for (final path in config.balloonImages) _tryLoad(path),
    ]);
    final picture = loaded.first;
    if (picture != null) {
      art = VillageArt(
        ui.Size(picture.width.toDouble(), picture.height.toDouble()),
        config.feetY,
      );
      layout = _layoutFor(layout.size);
    }
    _sprites.addAll(loaded.skip(1).whereType<ui.Image>());
    _hero = CharacterComponent(
      character: hero,
      roster: roster,
      characterSize: layout.characterSize,
    )..priority = 15;
    _heroX = layout.buddyHomeX;
    await addAll([VillageBackground(picture: picture), _hero]);
    _loaded = true;
    _place();
    _fillSky();
  }

  /// Every bundled asset, so missing art is skipped without a load error.
  static final Future<Set<String>> _bundled = AssetManifest.loadFromAssetBundle(
    rootBundle,
  ).then((m) => m.listAssets().toSet());

  Future<ui.Image?> _tryLoad(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (!(await _bundled).contains(path)) return null;
    try {
      return await _images.load(path);
    } catch (_) {
      return null; // Not added yet: draw it in code instead.
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final oldWidth = layout.width;
    layout = _layoutFor(ui.Size(size.x, size.y));
    if (!_loaded) return;
    // Keep the buddy at the same spot relative to the width.
    _heroX = (_heroX / oldWidth * layout.width).clamp(
      layout.buddyMinX,
      layout.deliverX,
    );
    _place();
  }

  double get _heroHeight => _hero.size.y * _hero.scale.y;

  /// The buddy's hand: his raised fist when the pose has one, else above
  /// his head (jumping, cheering) or at his side (running with a balloon).
  ui.Offset _heroHand({required bool up}) {
    final feet = ui.Offset(_heroX, layout.groundY - _heroLift);
    final fist = _hero.hand;
    if (fist != null) return feet + fist;
    return feet +
        ui.Offset(
          (_hero.mirror ? -1 : 1) * layout.characterSize * 0.08,
          -_heroHeight * (up ? 1.02 : 0.6),
        );
  }

  /// Puts the buddy and the balloons where the current layout says.
  void _place() {
    final l = layout;
    // The character's size is fixed when created, so scale it on resize.
    _hero.scale = Vector2.all(l.characterSize / _hero.characterSize);
    _placeHero();
    for (final b in [..._rising, ..._bunch]) {
      b
        ..size = Vector2(
          l.balloonWidth,
          b.sprite == null
              ? l.balloonHeight
              : l.balloonWidth * b.sprite!.height / b.sprite!.width,
        )
        ..stringLength = l.stringLength;
    }
    for (final (i, b) in _bunch.indexed) {
      final slot = l.bunchSlot(i);
      b
        ..position = Vector2(slot.dx, slot.dy)
        ..stringEnd = l.receiverHand;
    }
  }

  void _placeHero() =>
      _hero.position = Vector2(_heroX, layout.groundY - _heroLift);

  bool get _isOver => cubit.state.isFinished || cubit.round.isFinished;

  int get _targetsShowing =>
      _rising.where((b) => cubit.round.isTarget(b.letter)).length;

  /// A few balloons already in the sky when the game starts.
  void _fillSky() {
    final columns = List.generate(layout.columnCount, (i) => i)
      ..shuffle(_random);
    for (final (i, column) in columns.take(4).indexed) {
      _spawn(
        column,
        y: layout.groundY * (0.3 + 0.17 * i),
        isTarget: i == 1 ? true : null,
      );
    }
    _spawnIn = config.spawnEverySeconds;
  }

  /// [isTarget] forces the balloon to carry the target (true) or another
  /// letter (false); null lets the round decide.
  void _spawn(int column, {double? y, bool? isTarget}) {
    final round = cubit.round;
    final letter = switch (isTarget ??
        (_sinceTarget >= _maxBetweenTargets ? true : null)) {
      true => round.target,
      false => round.randomDistractor(_random),
      null => round.nextLetter(_random, targetsShowing: _targetsShowing),
    };
    _sinceTarget = round.isTarget(letter) ? 0 : _sinceTarget + 1;
    final colors = _sprites.isEmpty
        ? AppColors.balloons.length
        : _sprites.length;
    var color = _random.nextInt(colors);
    if (color == _lastColor) color = (color + 1) % colors;
    _lastColor = color;
    _lastColumn = column;
    final l = layout;
    final balloon =
        BalloonComponent(
            letter: letter,
            color: AppColors.balloons[color % AppColors.balloons.length],
            sprite: _sprites.isEmpty ? null : _sprites[color],
            letterSpot: config.balloonLetterSpot,
            speed:
                (l.height + l.balloonHeight * 2) /
                config.riseSeconds *
                (0.85 + _random.nextDouble() * 0.3),
            stringLength: l.stringLength,
            width: l.balloonWidth,
            height: l.balloonHeight,
          )
          ..baseX = l.columnX(column)
          ..x = l.columnX(column)
          ..y = y ?? l.spawnY;
    _rising.add(balloon);
    add(balloon);
  }

  /// A column is free when its last balloon has risen far enough.
  int? _freeColumn() {
    final free = <int>[];
    final l = layout;
    for (var c = 0; c < l.columnCount; c++) {
      if (c == _lastColumn) continue;
      final x = l.columnX(c);
      final blocked = _rising.any(
        (b) =>
            (b.baseX - x).abs() < l.balloonWidth &&
            b.y > l.spawnY - l.balloonHeight * 2.6,
      );
      if (!blocked) free.add(c);
    }
    return free.isEmpty ? null : free[_random.nextInt(free.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;
    if (_heroIdleIn > 0) {
      _heroIdleIn -= dt;
      if (_heroIdleIn <= 0 && !_isOver && _catch == null) {
        _hero.play(CharacterAction.idle);
      }
    }
    if (!_isOver) {
      _spawnIn -= dt;
      if (_spawnIn <= 0 && _rising.length < config.maxBalloonsOnScreen) {
        final column = _freeColumn();
        if (column != null) {
          _spawn(column);
          _spawnIn =
              config.spawnEverySeconds * (0.8 + _random.nextDouble() * 0.4);
        }
      }
    }
    final c = _catch;
    if (c != null) {
      c.update(dt);
    } else if (_walkTo != null && _heroIdleIn <= 0) {
      if (_runTowards(_walkTo!, dt)) {
        _walkTo = null;
        _hero
          ..mirror = false
          ..play(_isOver ? CharacterAction.celebrate : CharacterAction.idle);
      }
    }
    for (final f in [..._flying]) {
      f.update(dt);
    }
  }

  /// Moves the buddy toward [x]; returns true once he is there.
  bool _runTowards(double x, double dt) {
    final step = layout.runSpeed * dt;
    final dx = x - _heroX;
    if (dx.abs() <= step) {
      _heroX = x;
      _placeHero();
      return true;
    }
    _hero.mirror = dx < 0;
    if (_hero.action != CharacterAction.run) _hero.play(CharacterAction.run);
    _heroX += step * dx.sign;
    _placeHero();
    return false;
  }

  // ---------------------------------------------------------------------------
  // Balloon callbacks
  // ---------------------------------------------------------------------------

  void balloonTapped(BalloonComponent balloon) {
    if (_catch != null || _isOver || !balloon.isRising) return;
    _rising.remove(balloon);
    _walkTo = null;
    _heroIdleIn = 0;
    _catch = _Catch(this, balloon);
  }

  void balloonLeft(BalloonComponent balloon) {
    if (balloon.isRising && cubit.round.isTarget(balloon.letter)) {
      cubit.missTarget();
    }
    _rising.remove(balloon);
    balloon.removeFromParent();
  }

  void _heroPose(CharacterAction action, {double seconds = 1.2}) {
    _hero.play(action);
    _heroIdleIn = seconds;
  }

  /// Both brothers cheer when the bunch is complete; the balloons dance.
  void celebrate() {
    _heroIdleIn = 0;
    _hero.play(CharacterAction.celebrate);
    for (final b in _bunch) {
      b.bob = 0.16;
    }
  }
}

enum _Phase { approach, jump, carry, judge }

/// One catch, from the tap to handing the balloon over (and, for a wrong
/// letter, the pop).
class _Catch {
  _Catch(this.game, this.balloon) {
    balloon
      ..state = BalloonState.held
      ..priority = 20;
    final l = game.layout;
    _startX = game._heroX;
    _targetX = balloon.x.clamp(l.buddyMinX, l.buddyMaxX);
    _from = ui.Offset(balloon.x, balloon.y);
    // At the top of the jump, the end of the string is in his hand.
    final fist = _fistHeight();
    final reach = l.groundY - fist - _jumpHeight - l.stringLength;
    _to = ui.Offset(_targetX, reach - balloon.size.y / 2);
    _approachTime = max(
      0.55,
      (_targetX - _startX).abs() / game.layout.runSpeed,
    );
    game.sound.playKey('balloons.balloon_float');
  }

  final BalloonsGame game;
  final BalloonComponent balloon;
  _Phase _phase = _Phase.approach;
  double _t = 0;
  late final double _startX;
  late final double _targetX;
  late final ui.Offset _from;
  late final ui.Offset _to;
  late final double _approachTime;
  bool _grabbed = false;

  double get _jumpHeight => game._heroHeight * 0.32;

  /// How high above his feet the buddy's hand is in the jump pose.
  double _fistHeight() {
    final pose = game.roster.pose(game.hero, game._jumpPose);
    final hand = pose?.hand;
    if (pose == null || hand == null) return game._heroHeight * 1.02;
    final k = game.layout.characterSize / game.roster.referenceHeight;
    return (pose.height - hand.dy) * k;
  }

  static const double _jumpTime = 0.5;
  static const double _wrongHold = 1.3;

  void _go(_Phase next) {
    _phase = next;
    _t = 0;
  }

  /// The balloon hangs right above the hand holding its string.
  void _hangFrom(ui.Offset hand, double dt) {
    final want =
        hand - ui.Offset(0, game.layout.stringLength + balloon.size.y / 2);
    // A little lag so it floats behind the hand.
    final k = min(1.0, dt * 10);
    final now = ui.Offset.lerp(ui.Offset(balloon.x, balloon.y), want, k)!;
    balloon
      ..position = Vector2(now.dx, now.dy)
      ..stringEnd = hand;
  }

  void update(double dt) {
    _t += dt;
    switch (_phase) {
      case _Phase.approach:
        final k = min(1.0, _t / _approachTime);
        if ((_targetX - _startX).abs() > 4) {
          game._hero.mirror = _targetX < _startX;
          if (game._hero.action != CharacterAction.run) {
            game._hero.play(CharacterAction.run);
          }
        }
        game._heroX = ui.lerpDouble(
          _startX,
          _targetX,
          Curves.easeInOut.transform(k),
        )!;
        game._placeHero();
        final p = ui.Offset.lerp(_from, _to, Curves.easeOut.transform(k))!;
        balloon.position = Vector2(p.dx, p.dy);
        if (k >= 1) {
          game._hero
            ..mirror = false
            ..play(game._jumpPose);
          game.sound.play(SoundEvent.charJump);
          _go(_Phase.jump);
        }
      case _Phase.jump:
        final k = min(1.0, _t / _jumpTime);
        game._heroLift = sin(k * pi) * _jumpHeight;
        game._placeHero();
        if (k >= 0.5) _grabbed = true;
        if (_grabbed) {
          _hangFrom(game._heroHand(up: true), dt);
        }
        if (k >= 1) {
          game._heroLift = 0;
          game._placeHero();
          game.sound.play(SoundEvent.charLand);
          _go(_Phase.carry);
        }
      case _Phase.carry:
        final arrived = game._runTowards(game.layout.deliverX, dt);
        _hangFrom(game._heroHand(up: !arrived), dt);
        if (arrived) {
          game._hero
            ..mirror = false
            ..play(CharacterAction.idle);
          _judge();
        }
      case _Phase.judge:
        _hangFrom(game._heroHand(up: true), dt);
        if (_t >= _wrongHold) {
          balloon.pop();
          game.sound.playKey('balloons.balloon_pop');
          game._heroPose(CharacterAction.surprised, seconds: 0.6);
          game._walkTo = game.layout.buddyHomeX;
          game._catch = null;
        }
    }
  }

  void _judge() {
    final correct = game.cubit.pick(balloon.letter);
    if (correct) {
      // The balloon floats over to the bunch on its own; the buddy is free
      // for the next one.
      final slot = game._bunch.length + game._flying.length;
      game._flying.add(_Fly(game, balloon, slot));
      game._heroPose(CharacterAction.cheer, seconds: 0.7);
      game._walkTo = game.layout.buddyHomeX;
      game._catch = null;
    } else {
      // He holds it up while the other brother says no, then it pops.
      game._hero.play(CharacterAction.wrong);
      _go(_Phase.judge);
    }
  }
}

/// A correct balloon floating from the buddy's hand into the bunch.
class _Fly {
  _Fly(this.game, this.balloon, this.slot)
    : _from = ui.Offset(balloon.x, balloon.y),
      _handFrom = balloon.stringEnd ?? ui.Offset(balloon.x, balloon.y);

  final BalloonsGame game;
  final BalloonComponent balloon;
  final int slot;
  final ui.Offset _from;
  final ui.Offset _handFrom;
  double _t = 0;

  static const double _time = 0.7;

  void update(double dt) {
    _t += dt;
    final l = game.layout;
    final k = Curves.easeInOutCubic.transform(min(1, _t / _time));
    final to = l.bunchSlot(slot);
    final arc = sin(k * pi) * l.balloonWidth * 0.6;
    final c = ui.Offset.lerp(_from, to, k)! - ui.Offset(0, arc);
    balloon
      ..position = Vector2(c.dx, c.dy)
      ..scale = Vector2.all(ui.lerpDouble(1, l.bunchScale, k)!)
      ..stringEnd = ui.Offset.lerp(_handFrom, l.receiverHand, k);
    if (_t >= _time) {
      balloon
        ..state = BalloonState.bunch
        ..priority = 5;
      game._bunch.add(balloon);
      game._flying.remove(this);
      game.cubit.landed();
    }
  }
}
