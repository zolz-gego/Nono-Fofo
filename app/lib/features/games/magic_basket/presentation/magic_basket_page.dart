import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/layout/screen_size.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/domain/character_reaction.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/characters/presentation/speech_bubble.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../letter_hunt/presentation/coptic_mixed_text.dart';
import '../../letter_hunt/presentation/letter_hunt_result.dart';
import '../../letter_hunt/presentation/letter_pick_page.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../data/magic_basket_config_repository.dart';
import '../domain/magic_basket_config.dart';
import '../domain/magic_basket_round.dart';
import '../game/magic_basket_game.dart';
import '../game/magic_basket_layout.dart';
import 'magic_basket_cubit.dart';
import 'magic_basket_hud.dart';

/// The Magic basket screen (Level 2): the village apple tree with the
/// other brother on a branch asking how the letter sounds and throwing
/// apples, the buddy below with the basket, and the card on top.
class MagicBasketPage extends StatefulWidget {
  const MagicBasketPage({super.key, required this.args});

  final LetterHuntArgs args;

  @override
  State<MagicBasketPage> createState() => _MagicBasketPageState();
}

class _MagicBasketPageState extends State<MagicBasketPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterId _throwerId = widget.args.setup.buddy.other;
  late final CharacterController _thrower = CharacterController(
    _throwerId,
    sound: _sound,
  );
  final Future<MagicBasketConfig> _config = sl<MagicBasketConfigRepository>()
      .load();
  final Random _random = Random();

  MagicBasketCubit? _cubit;
  MagicBasketGame? _game;

  /// The thrower's speech bubble (kept here so the Coptic letter can be
  /// mixed into the text).
  MixedText? _bubble;
  Timer? _bubbleTimer;
  Timer? _howToTimer;
  DateTime _lastMissedLine = DateTime(0);
  bool _showResult = false;
  Timer? _resultTimer;

  String get _language => Localizations.localeOf(context).languageCode;

  /// The language the current round's sounds are in.
  String? _startedIn;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.village);
    _config.then((config) {
      if (mounted) _start(config);
    });
  }

  /// The sounds are Arabic or English letters: a new language starts a
  /// new round (the thrower also moves to the other side).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedIn != null && _startedIn != _language) _config.then(_start);
  }

  void _start(MagicBasketConfig config) {
    if (!mounted) return;
    _startedIn = _language;
    _cubit?.close();
    final cubit = MagicBasketCubit(
      MagicBasketRound.start(
        config: config,
        target: widget.args.target,
        pool: widget.args.pool,
        language: _language,
      ),
      sl<GameProgressRepository>(),
    );
    final game = MagicBasketGame(
      cubit: cubit,
      hero: widget.args.setup.buddy,
      roster: context.read<CharacterRoster>(),
      sound: _sound,
      arabic: _language == 'ar',
      random: _random,
      onThrow: _onThrow,
    );
    setState(() {
      _cubit = cubit;
      _game = game;
      _showResult = false;
    });
    // The background picture decides where the path is: place the
    // thrower again once it has loaded.
    game.loaded.then((_) {
      if (mounted && _game == game) setState(() {});
    });
    _thrower
      ..rest = CharacterAction.sit
      ..play(CharacterAction.sit);
    _sound.play(SoundEvent.levelStart);
    final l10n = context.l10n;
    final target = widget.args.target;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _say(
        _mixed(
          l10n.magicBasketQuestion(copticSlot1, target.nameIn(_language)),
          {copticSlot1: '${target.capital}${target.small}'},
        ),
        duration: const Duration(milliseconds: 3600),
      );
    });
    _howToTimer?.cancel();
    _howToTimer = Timer(const Duration(milliseconds: 4200), () {
      if (!mounted) return;
      // Phones and tablets (also in the browser) say "drag".
      final touch =
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      _say(_mixed(touch ? l10n.magicBasketHowToTouch : l10n.magicBasketHowTo));
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _howToTimer?.cancel();
    _resultTimer?.cancel();
    _thrower.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // The brother in the tree
  // ---------------------------------------------------------------------------

  MixedText _mixed(String text, [Map<String, String> coptic = const {}]) =>
      copticMixedText(context, text, coptic);

  void _say(
    MixedText bubble, {
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    // On phones the bubble would cover a big part of the game: the brother
    // reacts with his pose and sounds only (the card shows the letter).
    if (isPhone(context)) return;
    _bubbleTimer?.cancel();
    setState(() => _bubble = bubble);
    _bubbleTimer = Timer(duration, () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  /// A quick toss, unless he is busy reacting.
  void _onThrow() {
    if (_thrower.action != _thrower.rest) return;
    _thrower.play(
      CharacterAction.toss,
      hold: const Duration(milliseconds: 350),
    );
  }

  String _cheer(AppLocalizations l10n) => switch (_random.nextInt(4)) {
    0 => l10n.fishingCheer1,
    1 => l10n.fishingCheer2(widget.args.setup.name),
    2 => l10n.fishingCheer3,
    _ => l10n.fishingCheer4,
  };

  void _onEvent(BuildContext context, MagicBasketState state) {
    final l10n = context.l10n;
    final round = state.round;
    final letter = '${round.target.capital}${round.target.small}';
    switch (state.event) {
      case BasketEvent.start:
        break;
      case BasketEvent.correct:
        _howToTimer?.cancel();
        _thrower.react(CharacterReaction.correct);
        _say(_mixed(_cheer(l10n)));
      case BasketEvent.notNeeded:
        _say(
          // Never name the missing sound: that's the answer.
          _mixed(l10n.magicBasketHaveIt(state.sound ?? '')),
          duration: const Duration(milliseconds: 2800),
        );
      case BasketEvent.wrong:
        _howToTimer?.cancel();
        _thrower.react(CharacterReaction.wrong);
        _say(
          _mixed(l10n.magicBasketWrong(copticSlot1, state.sound ?? ''), {
            copticSlot1: letter,
          }),
          duration: const Duration(milliseconds: 2800),
        );
      case BasketEvent.missed:
        // Don't nag: at most one "it fell" every few seconds.
        final now = DateTime.now();
        if (now.difference(_lastMissedLine) < const Duration(seconds: 4)) {
          return;
        }
        _lastMissedLine = now;
        _thrower.react(CharacterReaction.surprised, withSound: false);
        _say(_mixed(l10n.magicBasketMissed));
      case BasketEvent.finished:
        _game?.celebrate();
        _thrower
          ..rest = CharacterAction.celebrate
          ..play(CharacterAction.celebrate);
        _sound.play(SoundEvent.levelComplete);
        _say(_mixed(_cheer(l10n)));
        _resultTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _showResult = true);
        });
    }
  }

  // ---------------------------------------------------------------------------
  // Result actions
  // ---------------------------------------------------------------------------

  void _playAgain() {
    _sound.play(SoundEvent.tap);
    _config.then(_start);
  }

  void _otherLetter() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.magicBasket);
    }
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level(widget.args.setup.level));
  }

  /// Arrow keys and A / D move the basket: a tap is one step, a held key
  /// keeps running (the game reads it). Handling them here also keeps them
  /// from moving the focus around.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final keys = {
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyD,
    };
    if (!keys.contains(event.logicalKey)) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      final left =
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA;
      _game?.nudge(left ? -1 : 1);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = _cubit;
    final game = _game;
    return GameScaffold(
      title: l10n.gameMagicBasket,
      onPause: () => game?.pauseEngine(),
      onResume: () => game?.resumeEngine(),
      actions: [
        GameAction(
          icon: AppIcons.letters,
          label: (l) => l.otherLetter,
          onPressed: _otherLetter,
        ),
      ],
      body: cubit == null || game == null
          ? const Center(child: CircularProgressIndicator())
          : BlocListener<MagicBasketCubit, MagicBasketState>(
              bloc: cubit,
              listenWhen: (a, b) => a.eventId != b.eventId,
              listener: _onEvent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  game.rtl = rtl;
                  return _scene(
                    game.layoutFor(constraints.biggest),
                    game,
                    cubit,
                  );
                },
              ),
            ),
    );
  }

  Widget _scene(
    MagicBasketLayout layout,
    MagicBasketGame game,
    MagicBasketCubit cubit,
  ) {
    final roster = context.read<CharacterRoster>();
    // The character's box is idle-sized, its feet at the bottom middle;
    // every pose is drawn from there.
    final idle = roster.pose(_throwerId, CharacterAction.idle);
    final k = layout.throwerSize / roster.referenceHeight;
    final boxW = (idle?.width ?? 0) * k;
    final boxH = (idle?.height ?? 0) * k;
    final feet = layout.throwerFeet;
    final rtl = layout.rtl;

    // Beside his head, toward the middle of the tree, and never under the
    // card.
    const bubbleWidth = 260.0;
    final near = rtl ? feet.dx - boxW * 0.45 : feet.dx + boxW * 0.45;
    final left = rtl ? max(AppDimens.spaceSm, near - bubbleWidth) : near;
    final width = min(bubbleWidth, rtl ? near - left : layout.width - near);
    final top = max(feet.dy - boxH, AppDimens.spaceSm);
    final bubbleTop =
        Rect.fromLTWH(left, top, width, 90).overlaps(layout.cardRect)
        ? layout.cardBottom + AppDimens.spaceSm
        : top;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            // The mouse aims without a click; a finger drags anywhere.
            child: Listener(
              onPointerHover: (e) => game.aimAt(e.localPosition.dx),
              onPointerDown: (e) => game.aimAt(e.localPosition.dx),
              onPointerMove: (e) => game.aimAt(e.localPosition.dx),
              child: GameWidget(key: ObjectKey(game), game: game),
            ),
          ),
          MagicBasketHud(layout: layout, cubit: cubit),
          Positioned(
            left: feet.dx - boxW / 2,
            top: feet.dy - boxH,
            child: IgnorePointer(
              child: AnimatedCharacter(
                controller: _thrower,
                size: layout.throwerSize,
                mirror: rtl,
              ),
            ),
          ),
          Positioned(
            left: left,
            width: width,
            top: bubbleTop,
            child: IgnorePointer(
              child: Align(
                alignment: rtl ? Alignment.topRight : Alignment.topLeft,
                child: SpeechBubble(
                  text: _bubble?.key,
                  richText: _bubble?.span,
                  maxWidth: width,
                  showTail: false,
                ),
              ),
            ),
          ),
          if (_showResult)
            Positioned.fill(
              child: LetterHuntResult(
                stars: cubit.state.round.stars,
                isNewBest: cubit.state.isNewBest,
                onPlayAgain: _playAgain,
                onOtherLetter: _otherLetter,
                onBackToGames: _backToGames,
              ),
            ),
        ],
      ),
    );
  }
}
