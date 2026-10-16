import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/domain/character_reaction.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/characters/presentation/speech_bubble.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../data/fishing_config_repository.dart';
import '../domain/fishing_config.dart';
import '../domain/fishing_round.dart';
import '../game/fishing_game.dart';
import '../game/fishing_layout.dart';
import '../../letter_hunt/presentation/coptic_mixed_text.dart';
import '../../letter_hunt/presentation/letter_hunt_cubit.dart';
import '../../letter_hunt/presentation/letter_hunt_hud.dart';
import '../../letter_hunt/presentation/letter_hunt_result.dart';
import '../../letter_hunt/presentation/letter_pick_page.dart';
import 'fishing_cubit.dart';

/// The fishing game screen: the Flame scene with the hero and his rod, the
/// target card and basket on top, and the other brother as the referee.
class FishingPage extends StatefulWidget {
  const FishingPage({super.key, required this.args});

  final LetterHuntArgs args;

  @override
  State<FishingPage> createState() => _FishingPageState();
}

class _FishingPageState extends State<FishingPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterId _refereeId = widget.args.setup.buddy.other;
  late final CharacterController _referee = CharacterController(
    _refereeId,
    sound: _sound,
  );
  final Future<FishingConfig> _config = sl<FishingConfigRepository>().load();
  final Random _random = Random();

  FishingCubit? _cubit;
  FishingGame? _game;

  /// The referee's speech bubble (kept here so Coptic letters can be mixed
  /// into the text).
  MixedText? _bubble;
  Timer? _bubbleTimer;
  DateTime _lastMissedLine = DateTime(0);
  bool _showResult = false;
  Timer? _resultTimer;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.nile);
    _config.then((config) {
      if (mounted) _start(config);
    });
  }

  void _start(FishingConfig config) {
    _cubit?.close();
    final cubit = FishingCubit(
      FishingRound.start(
        config: config,
        target: widget.args.target,
        pool: widget.args.pool,
        random: _random,
      ),
      sl<GameProgressRepository>(),
    );
    final game = FishingGame(
      cubit: cubit,
      hero: widget.args.setup.buddy,
      roster: context.read<CharacterRoster>(),
      sound: _sound,
      random: _random,
    );
    setState(() {
      _cubit = cubit;
      _game = game;
      _showResult = false;
    });
    // The background picture decides where the banks are: place the
    // referee again once it has loaded.
    game.loaded.then((_) {
      if (mounted && _game == game) setState(() {});
    });
    _referee.idle();
    _sound.play(SoundEvent.levelStart);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final l10n = context.l10n;
      _say(
        _mixed(l10n.fishingStart(widget.args.setup.name, copticSlot1), {
          copticSlot1: widget.args.target.small,
        }),
      );
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _resultTimer?.cancel();
    _referee.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Referee
  // ---------------------------------------------------------------------------

  MixedText _mixed(String text, [Map<String, String> coptic = const {}]) =>
      copticMixedText(context, text, coptic);

  void _say(
    MixedText bubble, {
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    _bubbleTimer?.cancel();
    setState(() => _bubble = bubble);
    _bubbleTimer = Timer(duration, () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  String _cheer(AppLocalizations l10n) => switch (_random.nextInt(4)) {
    0 => l10n.fishingCheer1,
    1 => l10n.fishingCheer2(widget.args.setup.name),
    2 => l10n.fishingCheer3,
    _ => l10n.fishingCheer4,
  };

  void _onEvent(BuildContext context, FishingState state) {
    final l10n = context.l10n;
    final target = state.round.target.small;
    switch (state.event) {
      case LetterHuntEvent.start:
        break;
      case LetterHuntEvent.correct:
        _referee.react(CharacterReaction.correct);
        _say(_mixed(_cheer(l10n), const {}));
      case LetterHuntEvent.wrong:
        _referee.react(CharacterReaction.wrong);
        _say(
          _mixed(l10n.fishingWrong(copticSlot1, copticSlot2), {
            copticSlot1: state.letter!.small,
            copticSlot2: target,
          }),
          duration: const Duration(milliseconds: 2800),
        );
      case LetterHuntEvent.missed:
        // Don't nag: at most one "it got away" every few seconds.
        final now = DateTime.now();
        if (now.difference(_lastMissedLine) < const Duration(seconds: 4)) {
          return;
        }
        _lastMissedLine = now;
        _referee.react(CharacterReaction.surprised, withSound: false);
        _say(_mixed(l10n.fishingMissed(copticSlot1), {copticSlot1: target}));
      case LetterHuntEvent.finished:
        _game?.celebrate();
        _referee.play(CharacterAction.celebrate);
        _sound.play(SoundEvent.levelComplete);
        _say(_mixed(_cheer(l10n), const {}));
        _resultTimer = Timer(const Duration(milliseconds: 1200), () {
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
      context.go(AppRoutes.fishing, extra: widget.args.setup);
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
    final game = _game;
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.gameFishing,
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
      body: cubit == null || game == null
          ? const Center(child: CircularProgressIndicator())
          : BlocProvider.value(
              value: cubit,
              child: BlocListener<FishingCubit, FishingState>(
                listenWhen: (a, b) => a.eventId != b.eventId,
                listener: _onEvent,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rtl = Directionality.of(context) == TextDirection.rtl;
                    game.rtl = rtl;
                    return _scene(
                      FishingLayout(
                        constraints.biggest,
                        goal: cubit.round.goal,
                        rtl: rtl,
                        art: game.art,
                      ),
                      game,
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _scene(FishingLayout layout, FishingGame game) {
    final roster = context.read<CharacterRoster>();
    final idle = roster.pose(_refereeId, CharacterAction.idle);
    final k = layout.characterSize / roster.referenceHeight;
    final boxW = (idle?.width ?? 0) * k;
    final boxH = (idle?.height ?? 0) * k;
    final feet = layout.refereeFeet;
    final bubble = _bubble;
    const bubbleWidth = 240.0;
    final headTop = feet.dy - boxH;

    // Above the referee's head when there's room and it doesn't cover the
    // top card; otherwise beside him (left), below the card, so it never
    // runs under the top bar or hides the basket.
    const roomNeeded = 110.0;
    final aboveLeft = (feet.dx - bubbleWidth / 2).clamp(
      AppDimens.spaceSm,
      layout.width - bubbleWidth - AppDimens.spaceSm,
    );
    final card = Rect.fromLTRB(
      (layout.width - layout.cardWidth) / 2,
      layout.cardTop,
      (layout.width + layout.cardWidth) / 2,
      layout.cardBottom,
    );
    final aboveRect = Rect.fromLTWH(
      aboveLeft,
      headTop - roomNeeded,
      bubbleWidth,
      roomNeeded,
    );
    final above = headTop >= roomNeeded && !aboveRect.overlaps(card);
    final Widget bubbleBox;
    final speech = SpeechBubble(
      text: bubble?.key,
      richText: bubble?.span,
      maxWidth: bubbleWidth,
      showTail: above,
    );
    if (above) {
      bubbleBox = Positioned(
        left: aboveLeft,
        width: bubbleWidth,
        bottom: layout.height - headTop + AppDimens.spaceXs,
        child: Align(alignment: Alignment.bottomCenter, child: speech),
      );
    } else {
      final right = feet.dx - boxW * 0.35;
      final left = max(AppDimens.spaceSm, right - bubbleWidth);
      final top = left < card.right
          ? max(
              headTop + AppDimens.spaceSm,
              layout.cardBottom + AppDimens.spaceSm,
            )
          : max(headTop + AppDimens.spaceSm, AppDimens.spaceSm);
      bubbleBox = Positioned(
        left: left,
        width: right - left,
        top: top,
        child: Align(alignment: Alignment.topRight, child: speech),
      );
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: GameWidget(key: ObjectKey(game), game: game),
        ),
        LetterHuntHud(
          layout: layout,
          cubit: _cubit!,
          label: context.l10n.catchLetter,
          icon: AppIcons.fishing,
        ),
        Positioned(
          left: feet.dx - boxW / 2,
          top: feet.dy - boxH,
          child: AnimatedCharacter(
            controller: _referee,
            size: layout.characterSize,
            mirror: true,
          ),
        ),
        bubbleBox,
        if (_showResult)
          Positioned.fill(
            child: LetterHuntResult(
              stars: _cubit!.state.round.stars,
              isNewBest: _cubit!.state.isNewBest,
              onPlayAgain: _playAgain,
              onOtherLetter: _otherLetter,
              onBackToGames: _backToGames,
            ),
          ),
      ],
    );
  }
}
