import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/assets/asset_paths.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/share/web_files.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../../../letters/domain/letter_repository.dart';
import '../../../levels/domain/game_level.dart';
import '../../../questions/domain/letter_question.dart';
import '../../../questions/domain/load_questions.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../../snakes_ladders/presentation/question_card.dart';
import '../data/adventure_config_repository.dart';
import '../domain/adventure_config.dart';
import '../domain/adventure_level.dart';
import '../game/adventure_game.dart';
import 'adventure_cubit.dart';
import 'adventure_hud.dart';
import 'adventure_level_picker.dart';
import 'adventure_overlays.dart';
import 'adventure_share_card.dart';

/// Nono & Fofo Adventure: a side-scroller in three levels. Small Fofo runs
/// and jumps, hits ? blocks for coins and the lost letters (each won with a
/// right answer), grows into Nono with Grandpa's page, and brings every
/// letter through the gate to Grandpa's book. Landscape only.
class AdventurePage extends StatefulWidget {
  const AdventurePage({super.key, required this.setup});

  final PlayerSetup setup;

  @override
  State<AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  late final SoundService _sound = context.read<SoundService>();

  late final Future<
    (AdventureConfig, List<LetterQuestionTemplate>, List<CopticLetter>)
  >
  _content =
      (
        sl<AdventureConfigRepository>().load(),
        sl<LoadQuestions>()(LetterQuestionTemplate.typeId),
        sl<LetterRepository>().lettersOf(widget.setup.level),
      ).wait.then(
        (c) => (
          c.$1,
          [
            for (final q in c.$2)
              if (q is LetterQuestionTemplate &&
                  q.level == widget.setup.level.number)
                q,
          ],
          c.$3,
        ),
      );

  AdventureCubit? _cubit;
  AdventureGame? _game;

  /// Built once per game, so HUD updates never rebuild the game view.
  Widget? _gameView;

  /// Null on the level picker.
  int? _level;

  /// Show the on-screen controls (phones, tablets, or after a touch).
  bool _touch =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  String? _message;
  bool _messageBack = false;
  Timer? _messageTimer;
  final FocusNode _focus = FocusNode(debugLabel: 'adventure');
  final GlobalKey<GameScaffoldState> _shell = GlobalKey();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _sound.playMusic(MusicTrack.actionGame);
    _content.then((c) {
      if (!mounted) return;
      final (config, templates, pool) = c;
      setState(() {
        _cubit = AdventureCubit(
          sl<GameProgressRepository>(),
          config: config,
          gameLevel: widget.setup.level,
          templates: templates,
          pool: pool,
        );
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const []);
    _messageTimer?.cancel();
    _focus.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Levels
  // ---------------------------------------------------------------------------

  void _startLevel(int i) {
    final cubit = _cubit!;
    final level = cubit.config.levels[i];
    // The old game must not touch the fresh level's lives.
    _game?.retire();
    cubit.startLevel(i);
    _sound
      ..play(SoundEvent.levelStart)
      ..playMusic(switch (level.place) {
        AdventurePlace.nile => MusicTrack.nile,
        AdventurePlace.desert => MusicTrack.pyramids,
        AdventurePlace.alexandria => MusicTrack.alexandria,
      });
    final game = AdventureGame(
      cubit: cubit,
      level: level,
      config: cubit.config,
      roster: context.read<CharacterRoster>(),
      sound: _sound,
    );
    setState(() {
      _level = i;
      _message = null;
      _game = game;
      // No autofocus: GameWidget swallows keys for games without
      // KeyboardEvents; the page's Focus handles them instead.
      _gameView = RepaintBoundary(
        child: GameWidget(key: ObjectKey(game), game: game, autofocus: false),
      );
    });
    _focus.requestFocus();
  }

  void _toLevels() {
    _sound.play(SoundEvent.back);
    _game?.retire();
    _cubit?.setPaused(false);
    _sound.playMusic(MusicTrack.actionGame);
    setState(() {
      _level = null;
      _game = null;
      _gameView = null;
      _message = null;
    });
  }

  void _backToRoad() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level, extra: widget.setup);
  }

  void _pause(bool paused) {
    final cubit = _cubit;
    if (cubit == null || _game == null) return;
    if (paused && !cubit.state.running) return;
    _game!.input.clear();
    cubit.setPaused(paused);
    if (!paused) _focus.requestFocus();
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final game = _game;
    if (game == null) return KeyEventResult.ignored;
    // A repeat also means "held": Flutter sends one instead of a down when
    // it missed the last key up (e.g. focus moved away meanwhile).
    final repeat = event is KeyRepeatEvent;
    final down = event is KeyDownEvent || repeat;
    final up = event is KeyUpEvent;
    if (!down && !up) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final input = game.input;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      input.left = down;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      input.right = down;
    } else if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      if (!repeat) down ? input.pressJump() : input.releaseJump();
    } else if (down &&
        !repeat &&
        (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP)) {
      _shell.currentState?.openSettings();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  void _say(String text, {bool back = false, Duration? duration}) {
    _messageTimer?.cancel();
    setState(() {
      _message = text;
      _messageBack = back;
    });
    _messageTimer = Timer(duration ?? const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _message = null);
    });
  }

  bool _wasRunning = false;

  void _onState(BuildContext context, AdventureState state) {
    final l10n = context.l10n;
    // Back to playing after a pop-up: keys go to the game again.
    if (state.running && !_wasRunning) _focus.requestFocus();
    _wasRunning = state.running;
    switch (state.event) {
      case AdventureEvent.start:
        _say(
          l10n.adventureStart(widget.setup.name, state.letters.length),
          duration: const Duration(seconds: 3),
        );
      case AdventureEvent.lifeUp:
        _sound.play(SoundEvent.rewardSticker);
        _say(l10n.adventureLifeUp);
      case AdventureEvent.letterWon:
        _sound.play(SoundEvent.correctAnswer, by: _hero(state));
      case AdventureEvent.wrongLetter:
        _sound.play(SoundEvent.wrongAnswer);
        if (state.lives > 0) _say(l10n.adventureWrongLetter);
      case AdventureEvent.grew:
        _sound.play(SoundEvent.correctAnswer, by: CharacterId.nono);
        _say(l10n.adventureGrew);
      case AdventureEvent.pageWrong:
        _sound.play(SoundEvent.wrongAnswer);
        _say(l10n.adventurePageWrong);
      case AdventureEvent.shrank:
        _say(l10n.adventureShrank);
      case AdventureEvent.checkpoint:
        _say(l10n.adventureCheckpoint);
      case AdventureEvent.gateLocked:
        _say(l10n.adventureGateLocked(state.missing), back: true);
      case AdventureEvent.gateOpen:
        _say(l10n.adventureGateOpen);
      case AdventureEvent.bonusFound:
        _sound.play(SoundEvent.star3);
        _say(l10n.adventureBonus);
      case AdventureEvent.coinShower:
        _say(l10n.adventureCoinShower);
      case AdventureEvent.complete:
        _messageTimer?.cancel();
        setState(() => _message = null);
        // Draw the share picture now: browsers only allow sharing right
        // after the tap, so it can't be drawn then.
        _card = _buildShareCard(state);
      case AdventureEvent.gameOver:
        _messageTimer?.cancel();
        setState(() => _message = null);
      case AdventureEvent.none ||
          AdventureEvent.coin ||
          AdventureEvent.pageCoins ||
          AdventureEvent.died:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Sharing
  // ---------------------------------------------------------------------------

  /// The picture to share, drawn as soon as a level is finished.
  Future<Uint8List>? _card;

  String _placeName(AdventurePlace place) =>
      AdventureLevelPicker.placeName(context.l10n, place);

  Future<Uint8List> _buildShareCard(AdventureState s) {
    final l10n = context.l10n;
    final level = _cubit!.config.levels[s.level];
    final roster = context.read<CharacterRoster>();
    final lang = Localizations.localeOf(context).languageCode;
    return AdventureShareCard(
      title: l10n.adventureShareTitle(widget.setup.name, s.level + 1),
      place: _placeName(level.place),
      background: AssetPaths.adventureArt('bg_${level.place.name}'),
      stars: s.stars,
      bonusStars: s.bonusStars,
      letters: [for (final l in s.letters) l.capital],
      stats: [
        ('${s.coins}/${level.totalCoins}', l10n.adventureCoins),
        (AdventureComplete.clock(s.time), l10n.adventureTime),
      ],
      badge: s.allDone ? l10n.adventureAllDone : null,
      appTitle: l10n.appTitle,
      script: lang == 'ar' ? AppScript.arabic : AppScript.english,
      direction: Directionality.of(context),
      heroAssets: [
        ?roster.pose(CharacterId.fofo, CharacterAction.celebrate)?.asset,
        ?roster.pose(CharacterId.nono, CharacterAction.celebrate)?.asset,
      ],
    ).render();
  }

  Future<void> _share(Rect origin) async {
    _sound.play(SoundEvent.tap);
    final l10n = context.l10n;
    final s = _cubit!.state;
    final level = _cubit!.config.levels[s.level];
    final text = l10n.adventureShareText(
      widget.setup.name,
      _placeName(level.place),
      s.stars + s.bonusStars,
    );
    const fileName = 'nono-fofo-adventure.png';
    const type = 'image/png';
    final messenger = ScaffoldMessenger.of(context);
    final saved = l10n.writingShareSaved;
    Future<void> download(Uint8List card) async {
      await webDownloadFile(card, fileName, type);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(saved)));
    }

    final Uint8List card;
    try {
      card = await (_card ??= _buildShareCard(s));
    } catch (_) {
      return; // The picture couldn't be drawn; nothing to share.
    }
    // Browsers without a share sheet save the picture instead, and say so.
    if (kIsWeb && !webCanShareFile(card, fileName, type)) {
      return download(card);
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(card, mimeType: type, name: fileName)],
          fileNameOverrides: [fileName],
          text: text,
          sharePositionOrigin: origin == Rect.zero ? null : origin,
        ),
      );
    } catch (_) {
      if (kIsWeb) await download(card);
    }
  }

  static CharacterId _hero(AdventureState s) =>
      s.big ? CharacterId.nono : CharacterId.fofo;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // The game is landscape only. Apps lock the screen sideways; where that
    // can't happen (a phone browser held upright) the whole game is drawn
    // turned a quarter, so it plays sideways until the phone is turned.
    final media = MediaQuery.of(context);
    if (_touch && media.size.width < media.size.height) {
      EdgeInsets turn(EdgeInsets p) =>
          EdgeInsets.fromLTRB(p.top, p.right, p.bottom, p.left);
      return RotatedBox(
        quarterTurns: 1,
        child: MediaQuery(
          data: media.copyWith(
            size: media.size.flipped,
            padding: turn(media.padding),
            viewPadding: turn(media.viewPadding),
            viewInsets: turn(media.viewInsets),
          ),
          child: _page(context),
        ),
      );
    }
    return _page(context);
  }

  Widget _page(BuildContext context) {
    final l10n = context.l10n;
    final cubit = _cubit;
    final playing = _level != null;
    return GameScaffold(
      key: _shell,
      title: l10n.gameAdventure,
      playing: playing,
      onPause: () => _pause(true),
      onResume: () => _pause(false),
      actions: [
        if (playing && cubit != null) ...[
          GameAction(
            icon: AppIcons.replay,
            label: (l) => l.adventureRestart,
            onPressed: () => _startLevel(cubit.state.level),
          ),
          GameAction(
            icon: AppIcons.levels,
            label: (l) => l.adventureLevels,
            onPressed: _toLevels,
          ),
        ],
      ],
      body: Listener(
        onPointerDown: (e) {
          if (_level != null) _focus.requestFocus();
          if (e.kind == PointerDeviceKind.touch && !_touch) {
            setState(() => _touch = true);
          }
        },
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: LayoutBuilder(
            builder: (context, c) {
              if (cubit == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return BlocConsumer<AdventureCubit, AdventureState>(
                bloc: cubit,
                listenWhen: (a, b) =>
                    a.eventId != b.eventId || a.running != b.running,
                listener: (context, state) {
                  _onState(context, state);
                },
                builder: (context, state) =>
                    _level == null ? _picker(cubit) : _play(cubit, state, c),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _picker(AdventureCubit cubit) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            AssetPaths.adventureArt('bg_nile'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned.fill(
          child: AdventureLevelPicker(
            touch: _touch,
            levels: [
              for (final (i, l) in cubit.config.levels.indexed)
                AdventureLevelCard(
                  place: l.place,
                  stars: cubit.bestStars(i),
                  unlocked: cubit.unlocked(i),
                ),
            ],
            onPick: _startLevel,
          ),
        ),
      ],
    );
  }

  Widget _play(AdventureCubit cubit, AdventureState state, BoxConstraints c) {
    final game = _game!;
    final config = cubit.config;
    final level = config.levels[state.level];
    final asking =
        (state.phase == AdventurePhase.question ||
            state.phase == AdventurePhase.answered) &&
        state.question != null;
    // Smaller arrows, closer to the edges, on short (phone) screens.
    final short = c.maxHeight < 450;
    final buttonSize = short ? 64.0 : 84.0;
    final buttonGap = short ? AppDimens.spaceSm : AppDimens.spaceLg;
    final hero = _hero(state);
    final heroName = hero.name;
    return Stack(
      children: [
        Positioned.fill(child: _gameView!),
        // Touch screens: tap anywhere (but the arrows) to jump.
        if (_touch && state.running)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => game.input.pressJump(),
              onPointerUp: (_) => game.input.releaseJump(),
              onPointerCancel: (_) => game.input.releaseJump(),
            ),
          ),
        // ◀ at the left edge, ▶ at the right edge (also in Arabic).
        if (_touch && state.running) ...[
          Positioned(
            left: buttonGap,
            bottom: buttonGap,
            child: AdventureHoldButton(
              size: buttonSize,
              icon: AppIcons.walkLeft,
              onHold: (down) => game.input.left = down,
            ),
          ),
          Positioned(
            right: buttonGap,
            bottom: buttonGap,
            child: AdventureHoldButton(
              size: buttonSize,
              icon: AppIcons.walkRight,
              onHold: (down) => game.input.right = down,
            ),
          ),
        ],
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AdventureHud(
            state: state,
            coinsPerLife: config.coinsPerLife,
            maxLives: config.maxLives,
          ),
        ),
        if (_message != null)
          Positioned(
            top: 64,
            left: AppDimens.spaceMd,
            right: AppDimens.spaceMd,
            child: IgnorePointer(
              child: Center(
                child: AdventureMessage(
                  key: ValueKey(_message),
                  text: _message!,
                  hero: heroName,
                  pointBack: _messageBack,
                ),
              ),
            ),
          ),
        if (asking)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.scrim,
              child: QuestionCard(
                key: ValueKey('q-${state.eventId}-${state.askKind}'),
                question: state.question!,
                playerName: widget.setup.name,
                title: state.askKind == AskKind.page
                    ? context.l10n.adventurePageAsk
                    : context.l10n.adventureLetterAsk,
                character: hero,
                color: hero == CharacterId.nono
                    ? AppColors.nonoAccent
                    : AppColors.fofoAccent,
                picked: state.picked,
                onPick: (i) {
                  _sound.play(SoundEvent.tap);
                  cubit.answer(i);
                },
              ),
            ),
          ),
        if (state.phase == AdventurePhase.letterShow &&
            state.shownLetter != null)
          Positioned.fill(
            child: AdventureLetterShow(
              letter: state.shownLetter!,
              hero: heroName,
            ),
          ),
        if (state.phase == AdventurePhase.gameOver)
          Positioned.fill(
            child: AdventureGameOver(
              onTryAgain: () => _startLevel(state.level),
              onBackToRoad: _backToRoad,
            ),
          ),
        if (state.phase == AdventurePhase.complete)
          Positioned.fill(
            child: AdventureComplete(
              state: state,
              totalCoins: level.totalCoins,
              hasNext: state.level + 1 < config.levels.length,
              onNext: () => _startLevel(state.level + 1),
              onPlayAgain: () => _startLevel(state.level),
              onLevels: _toLevels,
              onShare: _share,
            ),
          ),
      ],
    );
  }
}
