import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/domain/character_reaction.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../letter_hunt/presentation/letter_pick_page.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../data/letter_mask_builder.dart';
import '../data/writing_config_repository.dart';
import '../data/writing_drawings_repository.dart';
import '../domain/letter_mask.dart';
import '../domain/letter_strokes.dart';
import '../domain/writing_config.dart';
import 'chalk_tray.dart';
import 'chalkboard.dart';
import 'study_background.dart';
import 'writing_cubit.dart';
import 'writing_hud.dart';
import 'writing_result.dart';

/// "Write the letter" in Grandpa's study: the chosen hero stands by the
/// green chalkboard, the child colours the big hollow letter (small, then
/// capital), and the other brother cheers, warns and wipes the board when
/// it gets too messy.
class WritingPage extends StatefulWidget {
  const WritingPage({super.key, required this.args});

  final LetterHuntArgs args;

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterId _heroId = widget.args.setup.buddy;
  late final CharacterId _otherId = _heroId.other;
  late final CharacterController _hero = CharacterController(
    _heroId,
    sound: _sound,
    initial: CharacterAction.chalk,
  )..rest = CharacterAction.chalk;
  late final CharacterController _other = CharacterController(
    _otherId,
    sound: _sound,
  );
  final ChalkboardController _board = ChalkboardController();
  final WritingConfigRepository _repo = sl<WritingConfigRepository>();
  final WritingDrawingsRepository _drawings = sl<WritingDrawingsRepository>();
  late final Future<(WritingConfig, StrokeBook)> _content = (
    _repo.load(),
    _repo.strokes(),
  ).wait;

  WritingConfig? _config;
  StrokeBook? _book;
  WritingCubit? _cubit;
  LetterMask? _mask;
  int _colorIndex = 0;
  int _sizeIndex = 1;
  bool _drawing = false;
  DateTime _lastChalkSound = DateTime(0);
  final Map<LetterForm, Uint8List> _shots = {};
  bool? _resultPassed;
  final List<Timer> _timers = [];
  final Random _random = Random();

  CopticLetter get _letter => widget.args.target;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.grandpaHouse);
    _content.then((c) {
      if (!mounted) return;
      final (config, book) = c;
      _config = config;
      _book = book;
      _sizeIndex = config.startSize.clamp(0, config.chalkSizes.length - 1);
      _start();
    });
  }

  void _start() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _cubit?.close();
    _board.clear();
    _shots.clear();
    final cubit = WritingCubit(
      sl<GameProgressRepository>(),
      config: _config!,
      letterId: _letter.id,
    );
    setState(() {
      _cubit = cubit;
      _mask = null;
      _resultPassed = null;
    });
    _hero.play(CharacterAction.chalk);
    _other
      ..rest = CharacterAction.idle
      ..idle();
    _sound.play(SoundEvent.levelStart);
    _prepareBoard(LetterForm.small);
  }

  Future<void> _prepareBoard(LetterForm form) async {
    final cubit = _cubit!;
    final glyph = form == LetterForm.small ? _letter.small : _letter.capital;
    var mask = await const LetterMaskBuilder().build(
      glyph,
      thicken: _config!.letterThicken,
    );
    // The font may still be loading on the very first board: try again.
    for (var i = 0; i < 5 && mask.insideCount == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      mask = await const LetterMaskBuilder().build(
        glyph,
        thicken: _config!.letterThicken,
      );
    }
    if (!mounted || _cubit != cubit) return;
    _board.clear();
    setState(() => _mask = mask);
    cubit.boardReady(mask);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _hero.dispose();
    _other.dispose();
    _board.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.add(
    Timer(d, () {
      if (mounted) f();
    }),
  );

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  String _cheer(AppLocalizations l10n) => switch (_random.nextInt(4)) {
    0 => l10n.fishingCheer1,
    1 => l10n.fishingCheer2(widget.args.setup.name),
    2 => l10n.fishingCheer3,
    _ => l10n.fishingCheer4,
  };

  void _onEvent(BuildContext context, WritingState state) {
    final l10n = context.l10n;
    switch (state.event) {
      case WritingEvent.none:
        break;
      case WritingEvent.boardStart:
        if (state.form == LetterForm.small) {
          _hero.say(l10n.writingStart(widget.args.setup.name));
          _later(
            const Duration(milliseconds: 1800),
            () => _other.say(l10n.writingWatch),
          );
        } else {
          _other.say(l10n.writingWatch);
        }
      case WritingEvent.halfway:
        _other.react(CharacterReaction.correct, say: l10n.writingHalfway);
      case WritingEvent.warn:
        _sound.playKey('writing.stroke_off');
        _other.react(CharacterReaction.think, say: l10n.writingWarn);
      case WritingEvent.wipe:
        _wipeReaction(l10n);
      case WritingEvent.levelFailed:
        _wipeReaction(l10n);
      case WritingEvent.boardPassed:
        _sound.playKey('writing.letter_traced');
        _hero.react(CharacterReaction.correct);
        _other.react(CharacterReaction.celebrate, say: l10n.writingCapitalNext);
        _snapshot(state.form);
        _later(const Duration(milliseconds: 2200), () {
          _hero.play(CharacterAction.chalk);
          _cubit?.nextBoard();
          _prepareBoard(LetterForm.capital);
        });
      case WritingEvent.levelPassed:
        _sound.playKey('writing.letter_traced');
        _hero.react(CharacterReaction.celebrate);
        _other.react(CharacterReaction.celebrate, say: _cheer(l10n));
        _snapshot(state.form).then((_) {
          _saveDrawings();
          _later(const Duration(milliseconds: 1400), () {
            _sound.play(SoundEvent.levelComplete);
            setState(() => _resultPassed = true);
          });
        });
    }
  }

  void _wipeReaction(AppLocalizations l10n) {
    _sound.playKey('writing.sponge_wipe');
    _other
      ..play(CharacterAction.sponge, hold: const Duration(seconds: 2))
      ..say(l10n.writingWipe);
  }

  Future<void> _snapshot(LetterForm form) async {
    // Wait a frame so the green "passed" outline is in the picture.
    await WidgetsBinding.instance.endOfFrame;
    // Just the letter (with a little board around it), never too narrow.
    final ink = _mask?.inkRect.inflate(36);
    final crop = ink == null
        ? null
        : Rect.fromCenter(
            center: ink.center,
            width: max(ink.width, ink.height * 0.75),
            height: ink.height,
          );
    final png = await _board.capturePng(crop: crop);
    if (png != null) _shots[form] = png;
  }

  void _saveDrawings() {
    for (final MapEntry(:key, :value) in _shots.entries) {
      _drawings.save(_letter.id, key, value);
    }
  }

  void _onWipeDone() {
    final cubit = _cubit;
    if (cubit == null) return;
    if (cubit.state.phase == WritingPhase.failed) {
      _sound.play(SoundEvent.levelFailed);
      _other.react(CharacterReaction.encourage);
      setState(() => _resultPassed = false);
    } else {
      cubit.wipeDone();
    }
  }

  void _onChalk(Offset a, Offset b, double radius) {
    _cubit?.chalk(a, b, radius);
    final now = DateTime.now();
    if (now.difference(_lastChalkSound) > const Duration(milliseconds: 750)) {
      _lastChalkSound = now;
      _sound.playKey('writing.chalk_stroke');
    }
  }

  void _onDrawing(bool drawing) {
    if (drawing != _drawing) setState(() => _drawing = drawing);
  }

  // ---------------------------------------------------------------------------
  // Result actions
  // ---------------------------------------------------------------------------

  void _playAgain() {
    _sound.play(SoundEvent.tap);
    _start();
  }

  void _otherLetter() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.writing, extra: widget.args.setup);
    }
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level, extra: widget.args.setup);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = _cubit;
    final config = _config;
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.gameWriteLetter,
        onLogoTap: () => context.go(AppRoutes.home),
        actions: [
          IconButton(
            tooltip: l10n.otherLetter,
            onPressed: _otherLetter,
            icon: const FaIcon(AppIcons.letters),
          ),
          const LanguageButton(),
          const MuteButton(),
          const SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: cubit == null || config == null
          ? const Center(child: CircularProgressIndicator())
          : BlocConsumer<WritingCubit, WritingState>(
              bloc: cubit,
              listenWhen: (a, b) => a.eventId != b.eventId,
              listener: _onEvent,
              builder: (context, state) => LayoutBuilder(
                builder: (context, constraints) =>
                    _scene(constraints.biggest, state, config),
              ),
            ),
    );
  }

  Widget _scene(Size size, WritingState state, WritingConfig config) {
    final roster = context.read<CharacterRoster>();
    final rtl = Directionality.of(context) == TextDirection.rtl;

    const hudH = 64.0, trayH = 60.0, gap = AppDimens.spaceSm;
    final boardMaxW = size.width * 0.6;
    final boardMaxH = size.height - hudH - trayH - gap * 4;
    final scale = min(
      boardMaxW / Chalkboard.designSize.width,
      boardMaxH / Chalkboard.designSize.height,
    );
    final boardW = Chalkboard.designSize.width * scale;
    final boardH = Chalkboard.designSize.height * scale;
    final boardLeft = (size.width - boardW) / 2;
    const boardTop = hudH + gap;

    // Characters stand on the floor beside the board: the hero on the
    // reading-start side, the other brother on the far side.
    final charSize = min(size.height * 0.6, 460.0);
    final leftX = boardLeft / 2;
    final rightX = boardLeft + boardW + boardLeft / 2;
    final feetY = size.height - AppDimens.spaceSm;

    Positioned standing(
      CharacterController c,
      double x, {
      required bool mirror,
    }) {
      final idle = roster.pose(c.character, CharacterAction.idle);
      final k = charSize / roster.referenceHeight;
      final w = (idle?.width ?? 0) * k, h = (idle?.height ?? 0) * k;
      return Positioned(
        left: x - w / 2,
        top: feetY - h,
        child: AnimatedCharacter(controller: c, size: charSize, mirror: mirror),
      );
    }

    final heroOnLeft = !rtl;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: StudyBackground(
            image: config.background == null
                ? null
                : AssetImage(config.background!),
          ),
        ),
        Positioned(
          left: boardLeft,
          top: boardTop,
          width: boardW,
          height: boardH,
          child: FittedBox(
            child: Chalkboard(
              controller: _board,
              mask: _mask,
              strokes: _book?.of(_letter.id, state.form) ?? LetterStrokes.none,
              phase: state.phase,
              chalkColor: _chalkColor,
              chalkRadius: config.chalkSizes[_sizeIndex],
              demoStrokeSeconds: config.demoStrokeSeconds,
              onChalk: _onChalk,
              onDrawing: _onDrawing,
              onDemoDone: () => _cubit?.demoDone(),
              onDemoStroke: () => _sound.playKey('writing.chalk_stroke'),
              onWipeDone: _onWipeDone,
              art: config.board == null ? null : AssetImage(config.board!),
            ),
          ),
        ),
        if (_mask == null)
          Positioned(
            left: boardLeft,
            top: boardTop,
            width: boardW,
            height: boardH,
            child: const Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          top: AppDimens.spaceSm,
          left: 0,
          right: 0,
          height: hudH - AppDimens.spaceSm,
          child: Center(
            child: FittedBox(
              child: WritingHud(
                letter: _letter,
                state: state,
                passAt: config.passAt,
                warnAt: config.warnAt,
                wipesToFail: config.wipesToFail,
              ),
            ),
          ),
        ),
        Positioned(
          top: boardTop + boardH + gap,
          left: 0,
          right: 0,
          height: trayH,
          child: Center(
            child: FittedBox(
              child: ChalkTray(
                colorIndex: _colorIndex,
                sizeIndex: _sizeIndex,
                sizes: config.chalkSizes,
                onColor: (i) {
                  _sound.play(SoundEvent.select);
                  setState(() => _colorIndex = i);
                },
                onSize: (i) {
                  _sound.play(SoundEvent.select);
                  setState(() => _sizeIndex = i);
                },
              ),
            ),
          ),
        ),
        // The hero's arm "writes" while the child draws.
        _Scribbling(
          active: _drawing,
          child: standing(
            _hero,
            heroOnLeft ? leftX : rightX,
            mirror: !heroOnLeft,
          ),
        ),
        standing(_other, heroOnLeft ? rightX : leftX, mirror: heroOnLeft),
        if (_resultPassed != null)
          Positioned.fill(
            child: WritingResult(
              passed: _resultPassed!,
              wipesToFail: config.wipesToFail,
              drawings: [
                if (_resultPassed!)
                  for (final form in LetterForm.values) ?_shots[form],
              ],
              onPlayAgain: _playAgain,
              onOtherLetter: _otherLetter,
              onBackToGames: _backToGames,
            ),
          ),
      ],
    );
  }

  Color get _chalkColor => AppColors.chalk[_colorIndex];
}

/// Wiggles a positioned child a little, fast, while [active] (the hero
/// writing along with the child).
class _Scribbling extends StatefulWidget {
  const _Scribbling({required this.active, required this.child});

  final bool active;
  final Positioned child;

  @override
  State<_Scribbling> createState() => _ScribblingState();
}

class _ScribblingState extends State<_Scribbling>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(_Scribbling old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.child;
    return Positioned(
      left: p.left,
      top: p.top,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.rotate(
          angle: sin(_c.value * 2 * pi) * 0.025,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(sin(_c.value * 4 * pi) * 2, 0),
            child: child,
          ),
        ),
        child: p.child,
      ),
    );
  }
}
