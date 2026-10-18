import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../../../core/domain/character_id.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../domain/adventure_config.dart';
import '../domain/adventure_level.dart';
import '../presentation/adventure_cubit.dart';
import 'adventure_art.dart';

/// What the child is pressing. Keyboard and touch controls both write here.
class AdventureInput {
  bool left = false;
  bool right = false;
  bool jumpHeld = false;

  /// A jump press waits this long for the hero to land (so an early press
  /// still jumps).
  double _buffer = 0;

  void pressJump() {
    if (!jumpHeld) _buffer = 0.15;
    jumpHeld = true;
  }

  void releaseJump() => jumpHeld = false;

  void clear() {
    left = right = jumpHeld = false;
    _buffer = 0;
  }
}

enum _HeroState { alive, dying, finishing, done }

/// The side-scrolling level: Fofo (or big Nono) runs, jumps, hits blocks,
/// stomps enemies and brings the letters to Grandpa's book. Everything is
/// measured in tiles; [tile] world units each. Lives, coins, letters and
/// questions live in [cubit].
class AdventureGame extends FlameGame {
  AdventureGame({
    required this.cubit,
    required this.level,
    required this.config,
    required this.roster,
    required this.sound,
  }) : _art = AdventureArt(level.place);

  final AdventureCubit cubit;
  final AdventureLevel level;
  final AdventureConfig config;
  final CharacterRoster roster;
  final SoundService sound;
  final AdventureArt _art;

  final AdventureInput input = AdventureInput();

  /// World units per tile.
  static const double tile = 32;

  static const double _smallW = 0.7, _smallH = 1.35;
  static const double _bigW = 0.8, _bigH = 1.85;

  /// Set by the page while the device is upright (the game waits).
  bool blocked = false;

  // Camera, in tiles.
  double _camX = 0, _camY = 0;
  double _viewW = 24, _viewH = 14;

  // Hero.
  late double _x, _y;
  double _vx = 0, _vy = 0;
  bool _onGround = false;
  bool _facingLeft = false;
  double _coyote = 0;
  double _hurt = 0;
  double _runTime = 0;
  double _morph = 0;
  bool _wasBig = false;
  _HeroState _state = _HeroState.alive;
  double _stateTime = 0;
  _Platform? _riding;

  // Map state.
  final Map<Cell, Tile> _changed = {};
  final Map<Cell, double> _bumps = {};
  final Set<Cell> _taken = {};
  final Set<Cell> _reached = {};
  late Cell _respawn;
  bool _gateOpen = false;
  double _gateTime = 0;
  double _gateCooldown = 0;

  final List<_Enemy> _enemies = [];
  final List<_Platform> _platforms = [];
  final List<_Fx> _fx = [];
  _PageItem? _page;
  _LetterPop? _letterPop;

  /// Waiting on a question or an animation outside the cubit.
  bool _frozen = false;
  double _time = 0;
  double _clock = 0;

  static final Images _images = Images(prefix: '');
  final Map<String, ui.Image> _poseImages = {};

  bool get _big => cubit.state.big;
  double get _w => _big ? _bigW : _smallW;
  double get _h => _big ? _bigH : _smallH;

  /// Time spent playing (pauses and questions don't count).
  Duration get playTime => Duration(milliseconds: (_time * 1000).round());

  @override
  ui.Color backgroundColor() => _art.skyBottom;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    for (final c in CharacterId.values) {
      for (final a in _actions) {
        final pose = roster.pose(c, a);
        if (pose != null && !_poseImages.containsKey(pose.smallAsset)) {
          _poseImages[pose.smallAsset] = await _images.load(pose.smallAsset);
        }
      }
    }
    for (final e in level.enemies) {
      _enemies.add(_Enemy(e.kind, e.cell));
    }
    for (final p in level.platforms) {
      _platforms.add(_Platform(p.kind, p.cell));
    }
    _respawn = level.start;
    _placeHero(level.start);
    _wasBig = _big;
    camera.backdrop.add(_Backdrop(this));
    world.add(_Stage(this));
    _snapCamera();
  }

  static const List<CharacterAction> _actions = [
    CharacterAction.idle,
    CharacterAction.run,
    CharacterAction.cheer,
    CharacterAction.surprised,
    CharacterAction.celebrate,
  ];

  void _placeHero(Cell cell) {
    _x = cell.col + 0.5;
    _y = cell.row + 1.0;
    _vx = _vy = 0;
    _riding = null;
    _facingLeft = false;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _viewH = min(level.height.toDouble(), size.y >= 460 ? 14.0 : 11.0);
    final zoom = size.y / (_viewH * tile);
    camera.viewfinder.zoom = zoom;
    _viewW = size.x / (zoom * tile);
    if (isLoaded) _snapCamera();
  }

  // ---------------------------------------------------------------------------
  // Map
  // ---------------------------------------------------------------------------

  Tile _tileAt(int c, int r) {
    if (r < 0 || r >= level.height || c < 0 || c >= level.width) {
      return Tile.air;
    }
    return _changed[Cell(c, r)] ?? level.tiles[r][c];
  }

  bool _gateCell(int c, int r) =>
      !_gateOpen && c == level.gate.col && r <= level.gate.row;

  bool _solid(int c, int r) {
    if (c < 0 || c >= level.width) return true;
    if (r < 0 || r >= level.height) return false;
    return _tileAt(c, r).solid || _gateCell(c, r);
  }

  // ---------------------------------------------------------------------------
  // Loop
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    final step = min(dt, 1 / 20);
    _clock += step;
    _updateFx(step);
    _letterPop?.update(step);
    if (_letterPop?.gone ?? false) _letterPop = null;
    if (_morph > 0) _morph = max(0, _morph - step);

    final phase = cubit.state.phase;
    if (_state == _HeroState.dying || phase == AdventurePhase.dead) {
      _updateDying(step);
      return;
    }
    if (_state == _HeroState.finishing || _state == _HeroState.done) {
      _updateFinishing(step);
      _updateCamera(step);
      return;
    }
    if (!cubit.state.running || _frozen || blocked) return;

    _time += step;
    if (_big != _wasBig) {
      _morph = 0.9;
      _wasBig = _big;
    }
    final n = (step / (1 / 120)).ceil();
    final sub = step / n;
    for (var i = 0; i < n; i++) {
      _updatePlatforms(sub);
      _updateHero(sub);
      if (_state != _HeroState.alive || _frozen) break;
    }
    if (_state == _HeroState.alive && !_frozen) {
      _updateEnemies(step);
      _updatePage(step);
      _collect();
      _checkpoints();
      _gate(step);
      if (_y > level.height + 1.5) _die(fell: true);
    }
    for (final c in _bumps.keys.toList()) {
      final t = _bumps[c]! - step;
      if (t <= 0) {
        _bumps.remove(c);
      } else {
        _bumps[c] = t;
      }
    }
    _updateCamera(step);
  }

  // ---------------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------------

  void _updateHero(double dt) {
    final p = config.physics;
    final dir = (input.right ? 1 : 0) - (input.left ? 1 : 0);
    final target = dir * p.runSpeed;
    final accel = _onGround ? p.accel : p.airAccel;
    if (dir != 0) {
      _facingLeft = dir < 0;
      _vx = _approach(_vx, target, accel * dt);
    } else {
      _vx = _approach(_vx, 0, accel * 1.2 * dt);
    }

    if (input._buffer > 0) input._buffer -= dt;
    _coyote = _onGround ? 0.1 : _coyote - dt;
    if (input._buffer > 0 && _coyote > 0) {
      _vy = -p.jump;
      _onGround = false;
      _coyote = 0;
      _riding = null;
      input._buffer = 0;
      sound.play(SoundEvent.charJump);
    }
    if (!input.jumpHeld && _vy < -p.jump * 0.45) _vy = -p.jump * 0.45;
    _vy = min(_vy + p.gravity * dt, p.maxFall);

    // Ride the platform under the feet.
    final riding = _riding;
    if (riding != null) {
      _x += riding.dx;
      if (_vy >= 0) _y = riding.y;
    }

    _moveX(_vx * dt);
    final wasGround = _onGround;
    final prevBottom = _y;
    _onGround = false;
    _moveY(_vy * dt);
    _landOnPlatforms(prevBottom);
    if (_onGround && !wasGround && _vy == 0) {
      // Landing squash is drawn from _runTime reset.
      _runTime = 0;
    }
    if (_onGround && _vx.abs() > 0.3) _runTime += dt;
    if (_hurt > 0) _hurt -= dt;
  }

  static double _approach(double v, double target, double by) =>
      v < target ? min(v + by, target) : max(v - by, target);

  void _moveX(double d) {
    if (d == 0) return;
    _x += d;
    final top = _y - _h, bottom = _y;
    final r0 = (top + 0.01).floor(), r1 = (bottom - 0.01).floor();
    if (d > 0) {
      final c = (_x + _w / 2).floor();
      for (var r = r0; r <= r1; r++) {
        if (_solid(c, r)) {
          _x = c - _w / 2 - 0.001;
          _vx = 0;
          break;
        }
      }
    } else {
      final c = (_x - _w / 2).floor();
      for (var r = r0; r <= r1; r++) {
        if (_solid(c, r)) {
          _x = c + 1 + _w / 2 + 0.001;
          _vx = 0;
          break;
        }
      }
    }
  }

  void _moveY(double d) {
    _y += d;
    final c0 = (_x - _w / 2 + 0.01).floor(), c1 = (_x + _w / 2 - 0.01).floor();
    if (d >= 0) {
      final r = _y.floor();
      for (var c = c0; c <= c1; c++) {
        if (_solid(c, r) && _y - d <= r + 0.02) {
          _y = r.toDouble();
          _vy = 0;
          _onGround = true;
          _riding = null;
          return;
        }
      }
    } else {
      final r = (_y - _h).floor();
      Cell? hit;
      var best = double.infinity;
      for (var c = c0; c <= c1; c++) {
        if (_solid(c, r)) {
          final dist = (c + 0.5 - _x).abs();
          if (dist < best) {
            best = dist;
            hit = Cell(c, r);
          }
        }
      }
      if (hit != null) {
        _y = r + 1 + _h + 0.001;
        _vy = 0;
        _hitBlock(hit);
      }
    }
  }

  void _landOnPlatforms(double prevBottom) {
    if (_vy < 0) return;
    for (final p in _platforms) {
      if (p.gone) continue;
      final l = _x - _w / 2, r = _x + _w / 2;
      if (r <= p.x + 0.05 || l >= p.x + p.w - 0.05) continue;
      if (prevBottom <= p.y + 0.08 && _y >= p.y) {
        _y = p.y;
        _vy = 0;
        _onGround = true;
        _riding = p;
        p.stoodOn = true;
        return;
      }
    }
    // Walked off the platform's edge.
    final riding = _riding;
    if (riding != null &&
        (_x + _w / 2 <= riding.x || _x - _w / 2 >= riding.x + riding.w)) {
      _riding = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  void _hitBlock(Cell cell) {
    final t = _tileAt(cell.col, cell.row);
    switch (t) {
      case Tile.coinBlock:
        _changed[cell] = Tile.usedBlock;
        _bumps[cell] = 0.2;
        _fx.add(_Fx.coin(cell.col + 0.5, cell.row.toDouble()));
        sound.play(SoundEvent.coin);
        cubit.addCoins();
      case Tile.letterBlock:
        _bumps[cell] = 0.2;
        final i = level.letterBlocks.indexOf(cell);
        if (i >= 0 && i < cubit.state.letters.length) _askLetter(cell, i);
      case Tile.pageBlock:
        _changed[cell] = Tile.usedBlock;
        _bumps[cell] = 0.2;
        _page = _PageItem(cell);
        sound.play(SoundEvent.charAppear);
      case Tile.brick:
        if (_big) {
          _changed[cell] = Tile.air;
          for (var i = 0; i < 4; i++) {
            _fx.add(_Fx.debris(cell.col + 0.5, cell.row + 0.5, i));
          }
          sound.playKey('adventure.brick');
        } else {
          _bumps[cell] = 0.2;
          sound.playKey('adventure.bump');
        }
      default:
        sound.playKey('adventure.bump');
    }
  }

  Future<void> _askLetter(Cell cell, int i) async {
    _frozen = true;
    input.clear();
    _letterPop = _LetterPop(cell, cubit.state.letters[i].capital);
    sound.play(SoundEvent.letterFound);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (cubit.isClosed) return;
    final right = await cubit.ask(AskKind.letter, letterIndex: i);
    if (right) {
      _changed[cell] = Tile.usedBlock;
      _letterPop?.fly();
    } else {
      _letterPop?.sink();
      _hurt = 1.2;
    }
    _frozen = false;
  }

  // ---------------------------------------------------------------------------
  // Grandpa's page
  // ---------------------------------------------------------------------------

  void _updatePage(double dt) {
    final page = _page;
    if (page == null) return;
    if (page.rise < 1) {
      page.rise = min(1, page.rise + dt / 0.6);
      page.y = page.cell.row - page.rise * 0.9;
    } else if (!page.settled) {
      // Slides off its blocks, floats down like paper and stays where it
      // lands, so it can't run away into a hole.
      page.vy = min(page.vy + config.physics.gravity * 0.3 * dt, 5);
      final nx = page.x + page.vx * dt;
      final row = (page.y - 0.4).floor();
      if (_solid((nx + 0.4 * page.vx.sign).floor(), row)) {
        page.vx = -page.vx;
      } else {
        page.x = nx;
      }
      final ny = page.y + page.vy * dt;
      final c = page.x.floor();
      if (page.vy > 0 && _solid(c, ny.floor()) && page.y <= ny.floor() + 0.05) {
        page.y = ny.floor().toDouble();
        page.vy = 0;
        if (page.air > 0.2) page.settled = true;
        page.air = 0;
      } else {
        page.y = ny;
        page.air += dt;
      }
      if (page.y > level.height + 1) _page = null;
    }
    // Touching the hero.
    if (_page != null &&
        page.rise >= 1 &&
        (page.x - _x).abs() < (_w / 2 + 0.4) &&
        page.y > _y - _h - 0.1 &&
        page.y - 0.8 < _y) {
      _page = null;
      if (_big) {
        sound.play(SoundEvent.coin);
        cubit.pageWhileBig();
      } else {
        _askPage();
      }
    }
  }

  Future<void> _askPage() async {
    _frozen = true;
    input.clear();
    final right = await cubit.ask(AskKind.page);
    if (right) {
      _morph = 0.9;
      _wasBig = true;
      sound.playKey('adventure.grow');
    }
    _frozen = false;
  }

  // ---------------------------------------------------------------------------
  // Enemies
  // ---------------------------------------------------------------------------

  void _updateEnemies(double dt) {
    final g = config.physics.gravity;
    for (final e in _enemies) {
      if (e.dead) {
        e.deadTime += dt;
        continue;
      }
      if (!e.active) {
        if (e.x < _camX + _viewW + 2) {
          e.active = true;
          e.vx = -config.speedOf(e.kind);
        } else {
          continue;
        }
      }
      e.t += dt;
      if (e.kind == EnemyKind.seagull) {
        e.x += e.vx * dt;
        if ((e.x - e.originX).abs() > 4.5) {
          e.x = e.originX + 4.5 * (e.x - e.originX).sign;
          e.vx = -e.vx;
        }
        e.y = e.originY + sin(e.t * 2.2) * 0.9;
      } else {
        e.vy = min(e.vy + g * dt, 20);
        final nx = e.x + e.vx * dt;
        final lead = (nx + e.vx.sign * e.w / 2).floor();
        final bodyRow = (e.y - 0.3).floor();
        final ground = e.y.floor();
        final wall = _solid(lead, bodyRow);
        final edge = e.onGround && !_solid(lead, ground);
        if (wall || edge) {
          e.vx = -e.vx;
        } else {
          e.x = nx;
        }
        final ny = e.y + e.vy * dt;
        final c = e.x.floor();
        e.onGround = false;
        if (_solid(c, ny.floor()) && e.y <= ny.floor() + 0.05) {
          e.y = ny.floor().toDouble();
          e.vy = 0;
          e.onGround = true;
        } else {
          e.y = ny;
        }
        if (e.y > level.height + 2) e.dead = true;
      }
      _touchEnemy(e);
      if (_state != _HeroState.alive) return;
    }
    _enemies.removeWhere((e) => e.dead && e.deadTime > 0.6);
  }

  void _touchEnemy(_Enemy e) {
    final hl = _x - _w / 2, hr = _x + _w / 2, ht = _y - _h, hb = _y;
    final el = e.x - e.w / 2, er = e.x + e.w / 2, et = e.y - e.h, eb = e.y;
    if (hr <= el || hl >= er || hb <= et || ht >= eb) return;
    if (_vy > 0 && hb - et < 0.45) {
      e.dead = true;
      e.squashed = true;
      _vy = -config.physics.stompBounce * (input.jumpHeld ? 1.35 : 1);
      _onGround = false;
      _riding = null;
      _fx.add(_Fx.puff(e.x, e.y - e.h / 2));
      sound.playKey('adventure.stomp');
      return;
    }
    if (_hurt > 0) return;
    if (_big) {
      cubit.shrink();
      _wasBig = false;
      _morph = 0.9;
      _hurt = config.physics.hurtTime;
      sound.playKey('adventure.shrink');
    } else {
      _die();
    }
  }

  // ---------------------------------------------------------------------------
  // Platforms
  // ---------------------------------------------------------------------------

  void _updatePlatforms(double dt) {
    for (final p in _platforms) {
      final ox = p.x, oy = p.y;
      p.t += dt;
      switch (p.kind) {
        case PlatformKind.sideways:
          p.x = p.originX + (1 - cos(p.t * pi / 2.2)) / 2 * 3;
        case PlatformKind.upDown:
          p.y = p.originY - (1 - cos(p.t * pi / 2.2)) / 2 * 3;
        case PlatformKind.falling:
          if (p.stoodOn && !p.falling) {
            p.shake += dt;
            if (p.shake > 0.45) p.falling = true;
          }
          if (p.falling) {
            p.vy = min(p.vy + config.physics.gravity * 0.7 * dt, 18);
            p.y += p.vy * dt;
            if (p.y > level.height + 2) p.gone = true;
          }
      }
      p.dx = p.x - ox;
      p.dy = p.y - oy;
    }
  }

  // ---------------------------------------------------------------------------
  // Coins, flags, gate
  // ---------------------------------------------------------------------------

  void _collect() {
    final l = _x - _w / 2, r = _x + _w / 2, t = _y - _h, b = _y;
    for (final c in level.coins) {
      if (_taken.contains(c)) continue;
      final cx = c.col + 0.5, cy = c.row + 0.5;
      if (cx + 0.3 > l && cx - 0.3 < r && cy + 0.4 > t && cy - 0.4 < b) {
        _taken.add(c);
        _fx.add(_Fx.sparkle(cx, cy));
        sound.play(SoundEvent.coin);
        cubit.addCoins();
      }
    }
  }

  void _checkpoints() {
    for (final k in level.checkpoints) {
      if (_reached.contains(k) || _x < k.col + 0.3) continue;
      _reached.add(k);
      _respawn = k;
      sound.play(SoundEvent.placeUnlocked);
      cubit.checkpoint();
    }
  }

  void _gate(double dt) {
    if (_gateCooldown > 0) _gateCooldown -= dt;
    final g = level.gate.col;
    if (_gateOpen) {
      _gateTime += dt;
      if (_x > g + 1.6) {
        _state = _HeroState.finishing;
        _stateTime = 0;
        input.clear();
      }
      return;
    }
    if (_x + _w / 2 < g - 0.05) return;
    if (cubit.state.missing > 0) {
      if (_gateCooldown <= 0) {
        _gateCooldown = 2.5;
        sound.play(SoundEvent.locked);
        cubit.gateLocked();
      }
      _vx = -4;
    } else {
      _gateOpen = true;
      _gateTime = 0;
      sound.play(SoundEvent.unlock);
      cubit.gateOpen();
    }
  }

  /// The letters fly into Grandpa's book, then the level is done.
  void _updateFinishing(double dt) {
    _stateTime += dt;
    _gateTime += dt;
    final book = _bookX;
    if (_state == _HeroState.finishing) {
      _vy = min(_vy + config.physics.gravity * dt, config.physics.maxFall);
      _moveY(_vy * dt);
      if (_x < book - 1.2) {
        _x += 4 * dt;
        _facingLeft = false;
        _runTime += dt;
      } else {
        _state = _HeroState.done;
        _stateTime = 0;
        sound.play(SoundEvent.levelComplete);
      }
    } else if (_stateTime > 1.4 &&
        cubit.state.phase != AdventurePhase.complete) {
      _stateTime = -100; // Only once.
      cubit.complete(playTime, level.totalCoins);
    }
  }

  double get _bookX => level.gate.col + 4.5;

  // ---------------------------------------------------------------------------
  // Dying and respawning
  // ---------------------------------------------------------------------------

  void _die({bool fell = false}) {
    if (_state != _HeroState.alive) return;
    _state = _HeroState.dying;
    _stateTime = 0;
    _vy = fell ? 0 : -14;
    _vx = 0;
    input.clear();
    sound.playKey('adventure.die');
    cubit.died();
  }

  void _updateDying(double dt) {
    _stateTime += dt;
    if (_y < level.height + 3) {
      _vy = min(_vy + config.physics.gravity * dt, config.physics.maxFall);
      _y += _vy * dt;
    }
    if (_stateTime < 1.6) return;
    if (cubit.afterDeath()) _respawnHero();
    _state = _HeroState.alive;
  }

  void _respawnHero() {
    _placeHero(_respawn);
    _hurt = 1.5;
    _wasBig = false;
    for (final p in _platforms) {
      p.reset();
    }
    for (final e in _enemies) {
      if (!e.dead) e.reset();
    }
    _snapCamera();
  }

  // ---------------------------------------------------------------------------
  // Camera and effects
  // ---------------------------------------------------------------------------

  void _targetCamera(void Function(double x, double y) to) {
    final maxX = max(0.0, level.width - _viewW);
    final maxY = max(0.0, level.height - _viewH);
    to(
      (_x - _viewW * 0.4).clamp(0.0, maxX),
      (_y - _viewH * 0.62).clamp(0.0, maxY),
    );
  }

  void _snapCamera() {
    _targetCamera((x, y) {
      _camX = x;
      _camY = y;
    });
    _applyCamera();
  }

  void _updateCamera(double dt) {
    _targetCamera((x, y) {
      final k = min(1.0, dt * 8);
      _camX += (x - _camX) * k;
      _camY += (y - _camY) * min(1.0, dt * 4);
    });
    _applyCamera();
  }

  void _applyCamera() =>
      camera.viewfinder.position = Vector2(_camX * tile, _camY * tile);

  void _updateFx(double dt) {
    for (final f in _fx) {
      f.update(dt);
    }
    _fx.removeWhere((f) => f.done);
  }

  // ---------------------------------------------------------------------------
  // Drawing
  // ---------------------------------------------------------------------------

  void _renderWorld(ui.Canvas canvas) {
    const t = tile;
    final c0 = max(0, _camX.floor() - 1);
    final c1 = min(level.width - 1, (_camX + _viewW).ceil() + 1);

    // Checkpoints and the gate stand behind everything else.
    for (final k in level.checkpoints) {
      if (k.col < c0 - 2 || k.col > c1 + 2) continue;
      _art.flag(
        canvas,
        k.col + 0.5,
        k.row + 1.0,
        t,
        _reached.contains(k),
        _clock,
      );
    }
    final g = level.gate;
    if (g.col > c0 - 8 && g.col < c1 + 8) {
      _art.book(
        canvas,
        _bookX,
        g.row + 1.0,
        t,
        _clock,
        glowing: _state == _HeroState.done,
      );
      _art.gate(
        canvas,
        g.col,
        g.row + 1.0,
        t,
        open: _gateOpen ? min(1, _gateTime / 0.8) : 0,
        slots: cubit.state.letters.length,
        found: [
          for (var i = 0; i < cubit.state.letters.length; i++)
            cubit.state.found.contains(i)
                ? cubit.state.letters[i].capital
                : null,
        ],
      );
    }

    for (var r = 0; r < level.height; r++) {
      for (var c = c0; c <= c1; c++) {
        final tl = _tileAt(c, r);
        if (tl == Tile.air) continue;
        final cell = Cell(c, r);
        final bump = _bumps[cell];
        final lift = bump == null ? 0.0 : sin(bump / 0.2 * pi) * 0.25;
        _art.tile(
          canvas,
          tl,
          c.toDouble(),
          r - lift,
          t,
          topOpen: !_tileAt(c, r - 1).solid,
          clock: _clock,
        );
      }
    }

    for (final c in level.coins) {
      if (_taken.contains(c) || c.col < c0 || c.col > c1) continue;
      _art.coin(canvas, c.col + 0.5, c.row + 0.5, t, _clock + c.col * 0.13);
    }
    for (final p in _platforms) {
      if (p.gone) continue;
      final shake = p.falling || p.shake == 0 ? 0.0 : sin(_clock * 60) * 0.04;
      _art.platform(
        canvas,
        p.x + shake,
        p.y,
        p.w,
        t,
        falling: p.kind == PlatformKind.falling,
      );
    }
    final page = _page;
    if (page != null) _art.page(canvas, page.x, page.y, t, _clock);
    final pop = _letterPop;
    if (pop != null) {
      _art.letter(canvas, pop.x, pop.y, t, pop.glyph, pop.scale, _clock);
    }
    for (final e in _enemies) {
      if (e.x < c0 - 1 || e.x > c1 + 2) continue;
      _art.enemy(
        canvas,
        e.kind,
        e.x,
        e.y,
        t,
        facingLeft: e.vx < 0,
        clock: e.t,
        squashed: e.squashed,
        upsideDown: e.dead && !e.squashed,
      );
    }
    _renderHero(canvas);
    for (final f in _fx) {
      _art.fx(canvas, f, t);
    }
  }

  void _renderHero(ui.Canvas canvas) {
    if (_hurt > 0 &&
        _state == _HeroState.alive &&
        (_clock * 12).floor().isEven) {
      return;
    }
    var big = _big;
    if (_morph > 0) big = (_morph * 10).floor().isEven ? big : !big;
    final who = big ? CharacterId.nono : CharacterId.fofo;
    final action = switch (_state) {
      _HeroState.dying => CharacterAction.surprised,
      _HeroState.done => CharacterAction.celebrate,
      _HeroState.finishing => CharacterAction.run,
      _HeroState.alive when !_onGround => CharacterAction.cheer,
      _HeroState.alive when _vx.abs() > 0.4 => CharacterAction.run,
      _HeroState.alive => CharacterAction.idle,
    };
    final pose =
        roster.pose(who, action) ?? roster.pose(who, CharacterAction.idle);
    final idle = roster.pose(who, CharacterAction.idle);
    if (pose == null || idle == null) return;
    final image = _poseImages[pose.smallAsset];
    if (image == null) return;
    final height = (big ? 2.05 : 1.6) * tile;
    final k = height / idle.height;
    final running = action == CharacterAction.run;
    final bob = running ? sin(_runTime * 22).abs() * 0.06 * tile : 0.0;
    final tilt = running ? sin(_runTime * 22) * 0.05 : 0.0;
    canvas.save();
    canvas.translate(_x * tile, _y * tile - bob);
    if (_facingLeft) canvas.scale(-1, 1);
    canvas.rotate(tilt);
    final dst = ui.Rect.fromLTWH(
      -pose.headCenter.dx * k,
      -pose.height * k,
      pose.width * k,
      pose.height * k,
    );
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    canvas.restore();
  }

  void _renderBackdrop(ui.Canvas canvas) {
    _art.backdrop(canvas, size.x, size.y, _camX * size.y / _viewH, _clock);
  }
}

/// Draws the level in world space (the camera moves it).
class _Stage extends Component {
  _Stage(this.game);

  final AdventureGame game;

  @override
  void render(ui.Canvas canvas) => game._renderWorld(canvas);
}

/// Draws the sky and far scenery in screen space, behind the level.
class _Backdrop extends Component {
  _Backdrop(this.game);

  final AdventureGame game;

  @override
  void render(ui.Canvas canvas) => game._renderBackdrop(canvas);
}

class _Enemy {
  _Enemy(this.kind, this.spawn) {
    reset();
  }

  final EnemyKind kind;
  final Cell spawn;
  late double x, y, originX, originY;
  double vx = 0, vy = 0, t = 0, deadTime = 0;
  bool active = false, dead = false, squashed = false, onGround = false;

  double get w => switch (kind) {
    EnemyKind.duck => 0.9,
    EnemyKind.scorpion => 1.0,
    EnemyKind.crab => 1.0,
    EnemyKind.seagull => 1.0,
  };

  double get h => switch (kind) {
    EnemyKind.duck => 0.9,
    EnemyKind.scorpion => 0.6,
    EnemyKind.crab => 0.7,
    EnemyKind.seagull => 0.6,
  };

  void reset() {
    x = originX = spawn.col + 0.5;
    y = originY = spawn.row + 1.0;
    vx = vy = 0;
    active = false;
  }
}

class _Platform {
  _Platform(this.kind, this.spawn) {
    reset();
  }

  final PlatformKind kind;
  final Cell spawn;
  late double x, y, originX, originY;
  double t = 0, dx = 0, dy = 0, vy = 0, shake = 0;
  bool stoodOn = false, falling = false, gone = false;

  double get w => kind == PlatformKind.falling ? 1 : 3;

  void reset() {
    x = originX = spawn.col.toDouble();
    y = originY = spawn.row.toDouble();
    t = dx = dy = vy = shake = 0;
    stoodOn = falling = gone = false;
  }
}

class _PageItem {
  _PageItem(this.cell) : x = cell.col + 0.5, y = cell.row.toDouble();

  final Cell cell;
  double x, y;
  double vx = 2.2, vy = 0, rise = 0, air = 0;

  /// Landed after floating down; it stays put.
  bool settled = false;
}

/// A letter popping out of its block while its question is asked.
class _LetterPop {
  _LetterPop(Cell cell, this.glyph)
    : x = cell.col + 0.5,
      _baseY = cell.row.toDouble(),
      y = cell.row.toDouble();

  final String glyph;
  final double _baseY;
  double x, y;
  double scale = 0.4;
  double _t = 0;
  int _mode = 0; // 0 rising, 1 flying away (won), 2 sinking back
  bool gone = false;

  void fly() {
    _mode = 1;
    _t = 0;
  }

  void sink() {
    _mode = 2;
    _t = 0;
  }

  void update(double dt) {
    _t += dt;
    switch (_mode) {
      case 0:
        final k = min(1.0, _t / 0.4);
        y = _baseY - 0.4 - k * 0.9;
        scale = 0.4 + k * 0.8;
      case 1:
        y -= dt * 12;
        scale = max(0, scale - dt * 1.5);
        if (_t > 0.6) gone = true;
      case 2:
        final k = min(1.0, _t / 0.35);
        y = _baseY - 1.3 + k * 1.3;
        scale = 1.2 * (1 - k);
        if (k >= 1) gone = true;
    }
  }
}

/// A short effect: a coin popping from a block, brick pieces, a stomp puff.
class _Fx implements AdventureFx {
  _Fx(this.kind, this.x, this.y, {this.vx = 0, this.vy = 0, this.life = 0.5});

  factory _Fx.coin(double x, double y) =>
      _Fx(FxKind.coin, x, y - 0.5, vy: -9, life: 0.55);

  factory _Fx.debris(double x, double y, int i) => _Fx(
    FxKind.debris,
    x,
    y,
    vx: (i.isEven ? -1 : 1) * (2 + i * 0.4),
    vy: i < 2 ? -11 : -7,
    life: 1.0,
  );

  factory _Fx.puff(double x, double y) => _Fx(FxKind.puff, x, y, life: 0.35);

  factory _Fx.sparkle(double x, double y) =>
      _Fx(FxKind.sparkle, x, y, life: 0.35);

  @override
  final FxKind kind;
  @override
  double x, y;
  double vx, vy;
  final double life;
  double age = 0;

  @override
  double get progress => min(1, age / life);
  bool get done => age >= life;

  void update(double dt) {
    age += dt;
    if (kind == FxKind.coin || kind == FxKind.debris) {
      vy += 30 * dt;
      x += vx * dt;
      y += vy * dt;
    }
  }
}
