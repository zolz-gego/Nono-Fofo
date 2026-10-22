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
import '../../balloons/game/balloons_layout.dart';
import '../../balloons/game/village_background.dart';
import '../domain/magic_basket_config.dart';
import '../domain/magic_basket_round.dart';
import '../presentation/magic_basket_cubit.dart';
import 'apple_component.dart';
import 'apple_tree.dart';
import 'magic_basket_layout.dart';

/// The village apple tree: the other brother throws apples with sounds on
/// them, and the child moves the buddy (mouse, arrow keys or a finger) to
/// catch the letter's sounds in the basket. Rules and scores live in
/// [cubit].
class MagicBasketGame extends VillageGame {
  MagicBasketGame({
    required this.cubit,
    required this.hero,
    required this.roster,
    required this.sound,
    required this.arabic,
    this.onThrow,
    Random? random,
  }) : _random = random ?? Random();

  final MagicBasketCubit cubit;

  /// The brother with the basket (the child's buddy).
  final CharacterId hero;
  final CharacterRoster roster;
  final SoundService sound;

  /// Sounds are Arabic letters (else Latin).
  final bool arabic;

  /// Called when the brother in the tree throws an apple.
  final void Function()? onThrow;
  final Random _random;

  static final Images _images = Images(prefix: '');

  @override
  late MagicBasketLayout layout = layoutFor(const ui.Size(800, 600));

  /// Set by the page from the UI language: the thrower sits on the start
  /// side and the slots fill from the right in Arabic.
  bool rtl = false;

  /// The background and tree pictures once loaded (the layout lines up
  /// with them).
  VillageArt? art;
  TreeArt? tree;

  /// Pictures for the tree, the apples and the basket (null = drawn in
  /// code).
  ui.Image? treePicture;
  ui.Image? applePicture;
  ui.Image? basketPicture;

  /// Where the scene's parts go for [size] (the page uses it too, so the
  /// card and the brother in the tree line up with the game).
  MagicBasketLayout layoutFor(ui.Size size) => MagicBasketLayout(
    size,
    goal: cubit.round.goal,
    soundCount: cubit.round.sounds.length,
    rtl: rtl,
    art: art,
    tree: tree,
    throwerSeat: _throwerPoint(CharacterAction.sit, (p) => p.seat),
    throwerToss: _throwerPoint(CharacterAction.toss, (p) => p.hand),
  );

  /// A point of the thrower's [action] pose, relative to his feet, in units
  /// of his size.
  ui.Offset? _throwerPoint(
    CharacterAction action,
    ui.Offset? Function(CharacterPose pose) point,
  ) {
    final pose = roster.pose(hero.other, action);
    final p = pose == null || pose.action != action ? null : point(pose);
    if (p == null) return null;
    return pose!.fromFeet(p, 1 / roster.referenceHeight);
  }

  /// How high the hands carrying the basket are above the buddy's feet, in
  /// units of his size (null without a "carry" pose).
  late final double? _carryLift = () {
    final pose = roster.pose(hero, CharacterAction.carry);
    final hand = pose?.hand;
    if (pose == null || hand == null || pose.action != CharacterAction.carry) {
      return null;
    }
    return -pose.fromFeet(hand, 1 / roster.referenceHeight).dy;
  }();

  MagicBasketConfig get config => cubit.round.config;

  late final CharacterComponent _hero;
  late final BasketComponent _basket = BasketComponent(
    picture: basketPicture,
    opening: config.basketOpening,
  );

  /// The basket's front, drawn again over the apples in it.
  late final BasketComponent _basketFront = BasketComponent(
    picture: basketPicture,
    opening: config.basketOpening,
    frontOnly: true,
  );

  /// Apples in the air (thrown or falling).
  final List<_Flight> _flying = [];

  /// Right apples in the basket.
  final List<AppleComponent> _inBasket = [];

  /// Apples bouncing out or squashed on the path, until they fade.
  final List<AppleComponent> _leaving = [];

  /// The first apple waits for the question to be read.
  double _throwIn = 2.4;
  int _lastColumn = -1;

  /// Apples thrown since the last right one; never more than
  /// [_maxBetweenRight] in a row, so the child never waits long.
  int _sinceRight = 0;
  static const int _maxBetweenRight = 2;

  /// Where the buddy is, and where the pointer wants him (null = stay).
  double _heroX = 0;
  double? _aimX;
  double _heroPoseIn = 0;
  bool _loaded = false;

  @override
  ui.Color backgroundColor() => AppColors.skyBottom;

  @override
  Future<void> onLoad() async {
    // Load everything at once; one by one the scene stays empty for seconds.
    final loaded = await Future.wait([
      _tryLoad(config.background),
      _tryLoad(config.treeImage),
      _tryLoad(config.appleImage),
      _tryLoad(config.basketImage),
    ]);
    final picture = loaded[0];
    if (picture != null) {
      art = VillageArt(
        ui.Size(picture.width.toDouble(), picture.height.toDouble()),
        config.feetY,
      );
    }
    treePicture = loaded[1];
    applePicture = loaded[2];
    basketPicture = loaded[3];
    if (treePicture case final t?) {
      tree = TreeArt(
        ui.Size(t.width.toDouble(), t.height.toDouble()),
        config.treeMarks,
      );
    }
    layout = layoutFor(layout.size);
    _hero = CharacterComponent(
      character: hero,
      roster: roster,
      characterSize: layout.characterSize,
    )..priority = 15;
    _heroX = layout.width / 2;
    await addAll([
      VillageBackground(picture: picture),
      AppleTree(),
      _hero,
      _basket,
      _basketFront,
    ]);
    _loaded = true;
    _place();
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
    layout = layoutFor(ui.Size(size.x, size.y));
    if (!_loaded) return;
    _heroX = (_heroX / oldWidth * layout.width).clamp(
      layout.heroMinX,
      layout.heroMaxX,
    );
    _aimX = null;
    _place();
  }

  /// Puts the buddy, the basket and the apples where the layout says.
  void _place() {
    final l = layout;
    // The character's size is fixed when created, so scale it on resize.
    _hero.scale = Vector2.all(l.characterSize / _hero.characterSize);
    for (final a in [..._inBasket, ..._leaving]) {
      a.size = Vector2.all(
        l.appleSize * (a.state == AppleState.basket ? 0.62 : 1),
      );
    }
    for (final f in _flying) {
      f.apple.size = Vector2.all(l.appleSize);
    }
    _placeHero();
  }

  double get _heroHeight => _hero.size.y * _hero.scale.y;

  /// The middle of the basket's opening: at the hands of his "carry" pose,
  /// else at his waist (Fofo is shorter than Nono).
  double get _basketHeight {
    final p = basketPicture;
    return p == null
        ? layout.basketHeight
        : layout.basketWidth * p.height / p.width;
  }

  ui.Offset get _rim {
    final lift = _carryLift;
    return ui.Offset(
      _heroX,
      layout.groundY -
          (lift != null
              ? lift * layout.characterSize
              : _heroHeight > 0
              ? _heroHeight * 0.4
              : layout.characterSize * 0.4),
    );
  }

  void _placeHero() {
    final l = layout;
    _hero.position = Vector2(_heroX, l.groundY);
    for (final b in [_basket, _basketFront]) {
      b
        ..size = Vector2(l.basketWidth, _basketHeight)
        ..position = Vector2(_rim.dx, _rim.dy);
    }
    for (final (i, a) in _inBasket.indexed) {
      final p = _basketSpot(i);
      a.position = Vector2(p.dx, p.dy);
    }
  }

  /// Where the [i]th apple sits in the basket: a row along the rim, then a
  /// second row on top.
  ui.Offset _basketSpot(int i) {
    final l = layout;
    final perRow = 4;
    final row = i ~/ perRow;
    final col = i % perRow;
    final step = l.basketWidth * 0.8 / perRow;
    final x =
        _rim.dx -
        l.basketWidth * 0.4 +
        step * (col + 0.5) +
        (row.isOdd ? step * 0.5 : 0);
    return ui.Offset(x, _rim.dy - l.appleSize * (0.12 + row * 0.3));
  }

  bool get _isOver => cubit.state.isFinished || cubit.round.isFinished;

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  /// The mouse moved or a finger touched / dragged at [x].
  void aimAt(double x) => _aimX = x.clamp(layout.heroMinX, layout.heroMaxX);

  /// An arrow key was just pressed: a quick tap moves the buddy one step
  /// (held keys keep him running, see [_keyDirection]).
  void nudge(int direction) {
    _aimX = (_heroX + direction * layout.basketWidth * 0.6).clamp(
      layout.heroMinX,
      layout.heroMaxX,
    );
  }

  /// -1 = left, 1 = right, 0 = no arrow key held.
  int get _keyDirection {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final left =
        keys.contains(LogicalKeyboardKey.arrowLeft) ||
        keys.contains(LogicalKeyboardKey.keyA);
    final right =
        keys.contains(LogicalKeyboardKey.arrowRight) ||
        keys.contains(LogicalKeyboardKey.keyD);
    return (right ? 1 : 0) - (left ? 1 : 0);
  }

  // ---------------------------------------------------------------------------
  // Loop
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;
    _moveHero(dt);
    if (!_isOver) {
      _throwIn -= dt;
      if (_throwIn <= 0 && _flying.length < config.maxApplesOnScreen) {
        _throw();
        _throwIn = config.dropEverySeconds * (0.8 + _random.nextDouble() * 0.4);
      }
    }
    for (final f in [..._flying]) {
      f.update(dt);
    }
    for (final a in [..._leaving]) {
      _updateLeaving(a, dt);
    }
  }

  void _moveHero(double dt) {
    final l = layout;
    // A held key keeps the aim one step ahead; on release he finishes
    // that step.
    final keys = _keyDirection;
    if (keys != 0) {
      _aimX = (_heroX + keys * l.basketWidth * 0.6).clamp(
        l.heroMinX,
        l.heroMaxX,
      );
    }
    final to = _aimX;
    var moving = false;
    if (to != null) {
      final step = l.runSpeed * dt;
      final dx = to - _heroX;
      if (dx.abs() > 2) {
        moving = dx.abs() > step * 0.5;
        _hero.mirror = dx < 0;
        _heroX += dx.abs() <= step ? dx : step * dx.sign;
        _placeHero();
      }
    }
    if (_heroPoseIn > 0) {
      _heroPoseIn -= dt;
      return;
    }
    final want = moving
        ? CharacterAction.run
        : _isOver
        ? CharacterAction.celebrate
        : CharacterAction.carry;
    if (_hero.action != want) _hero.play(want);
  }

  void _heroPose(CharacterAction action, {double seconds = 0.8}) {
    _hero.play(action);
    _heroPoseIn = seconds;
  }

  int get _rightShowing =>
      _flying.where((f) => cubit.round.isNeeded(f.apple.sound)).length;

  void _throw() {
    final round = cubit.round;
    final picked = round.nextSound(
      _random,
      rightShowing: _rightShowing,
      right: _sinceRight >= _maxBetweenRight ? true : null,
    );
    _sinceRight = round.isRight(picked) ? 0 : _sinceRight + 1;
    final l = layout;
    var column = _random.nextInt(l.columnCount);
    // Not the same column twice, and not right on top of a falling apple.
    for (var tries = 0; tries < 6; tries++) {
      final x = l.columnX(column);
      final busy = _flying.any(
        (f) =>
            (f.toX - x).abs() < l.appleSize * 1.1 &&
            f.apple.y < l.dropY + l.appleSize * 2,
      );
      if (column != _lastColumn && !busy) break;
      column = _random.nextInt(l.columnCount);
    }
    _lastColumn = column;
    final apple = AppleComponent(
      sound: picked,
      arabic: arabic,
      size: l.appleSize,
      picture: applePicture,
      letterSpot: config.appleLetterSpot,
    );
    _flying.add(_Flight(this, apple, l.columnX(column)));
    add(apple);
    onThrow?.call();
    sound.play(SoundEvent.swipe);
  }

  // ---------------------------------------------------------------------------
  // Catching
  // ---------------------------------------------------------------------------

  /// Whether an apple whose bottom just went from [before] to [after]
  /// (y) at [x] dropped into the basket.
  bool _intoBasket(double x, double before, double after) {
    final rim = _rim;
    final half = layout.basketWidth * 0.5;
    return before <= rim.dy + 4 &&
        after >= rim.dy - 4 &&
        (x - rim.dx).abs() <= half;
  }

  void _caught(_Flight flight) {
    _flying.remove(flight);
    final apple = flight.apple;
    switch (cubit.pick(apple.sound)) {
      case BasketCatch.correct:
        apple
          ..state = AppleState.basket
          ..size = Vector2.all(layout.appleSize * 0.62);
        _inBasket.add(apple);
        _placeHero();
        sound.play(SoundEvent.correctAnswer);
        _heroPose(CharacterAction.cheer, seconds: 0.5);
        cubit.landed();
      case BasketCatch.notNeeded:
        _bounceOut(apple, soft: true);
        sound.play(SoundEvent.tap);
      case BasketCatch.wrong:
        _bounceOut(apple);
        sound.play(SoundEvent.wrongAnswer);
        _heroPose(CharacterAction.wrong, seconds: 0.9);
    }
  }

  void _bounceOut(AppleComponent apple, {bool soft = false}) {
    final side = _random.nextBool() ? 1 : -1;
    apple
      ..state = AppleState.bouncing
      ..velocity = Vector2(
        side * layout.appleSize * (soft ? 2.5 : 4),
        -layout.appleSize * (soft ? 5 : 7),
      );
    _leaving.add(apple);
  }

  void _hitGround(_Flight flight) {
    _flying.remove(flight);
    final apple = flight.apple;
    apple
      ..state = AppleState.splat
      ..y = layout.floorY
      ..velocity = Vector2.zero();
    _leaving.add(apple);
    sound.play(SoundEvent.charLand);
    if (cubit.round.isNeeded(apple.sound)) cubit.miss(apple.sound);
  }

  void _updateLeaving(AppleComponent a, double dt) {
    switch (a.state) {
      case AppleState.bouncing:
        a.velocity.y += layout.appleSize * 16 * dt;
        a.position += a.velocity * dt;
        a.opacity -= dt * 0.9;
      case AppleState.splat:
        a.opacity -= dt * 1.2;
      default:
        break;
    }
    if (a.opacity <= 0 || a.y > layout.height + a.size.y) {
      _leaving.remove(a);
      a.removeFromParent();
    }
  }

  /// The basket is full: the apples hop and the buddy cheers.
  void celebrate() {
    _heroPoseIn = 0;
    _hero.play(CharacterAction.celebrate);
    for (final f in [..._flying]) {
      _flying.remove(f);
      f.apple.state = AppleState.splat;
      _leaving.add(f.apple);
    }
  }
}

/// One apple to the basket or the ground. When it starts below the
/// thrower's hand, he throws it in a short arc out of the tree; when it
/// starts higher (the drop line is just under the top rows), it pops out
/// of the leaves there. Then it falls straight down.
class _Flight {
  _Flight(this.game, this.apple, this.toX) {
    final from = game.layout.throwerHand;
    _fromLeaves = game.layout.dropY < from.dy - game.layout.appleSize;
    final start = _fromLeaves ? ui.Offset(toX, game.layout.dropY) : from;
    apple.position = Vector2(start.dx, start.dy);
    if (_fromLeaves) apple.scale = Vector2.zero();
    _from = start;
  }

  final MagicBasketGame game;
  final AppleComponent apple;
  final double toX;
  late final ui.Offset _from;
  late final bool _fromLeaves;
  double _t = 0;

  static const double _arcTime = 0.6;
  static const double _popTime = 0.35;

  void update(double dt) {
    final l = game.layout;
    switch (apple.state) {
      case AppleState.thrown when _fromLeaves:
        _t += dt;
        final k = min(1.0, _t / _popTime);
        apple.scale = Vector2.all(Curves.easeOutBack.transform(k));
        if (k >= 1) apple.state = AppleState.falling;
      case AppleState.thrown:
        _t += dt;
        final k = min(1.0, _t / _arcTime);
        final e = Curves.easeOut.transform(k);
        final to = ui.Offset(toX, l.dropY);
        final p = ui.Offset.lerp(_from, to, e)!;
        final lift = sin(k * pi) * l.appleSize * 1.2;
        apple.position = Vector2(p.dx, p.dy - lift);
        if (k >= 1) apple.state = AppleState.falling;
      case AppleState.falling:
        final speed = (l.floorY - l.dropY) / game.config.fallSeconds;
        final r = apple.size.y * 0.45;
        final before = apple.y + r;
        apple.y += speed * dt;
        final after = apple.y + r;
        if (game._intoBasket(apple.x, before, after)) {
          game._caught(this);
        } else if (apple.y >= l.floorY) {
          game._hitGround(this);
        }
      default:
        break;
    }
  }
}
