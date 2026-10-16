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
import '../../letter_hunt/presentation/coptic_mixed_text.dart';
import '../../letter_hunt/presentation/letter_hunt_cubit.dart';
import '../../letter_hunt/presentation/letter_hunt_hud.dart';
import '../../letter_hunt/presentation/letter_hunt_result.dart';
import '../../letter_hunt/presentation/letter_pick_page.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../data/balloons_config_repository.dart';
import '../domain/balloons_config.dart';
import '../domain/balloons_round.dart';
import '../game/balloons_game.dart';
import '../game/balloons_layout.dart';
import 'balloons_cubit.dart';

/// The balloons game screen: the village scene with the buddy catching
/// balloons, the target card on top, and the other brother on the right
/// who keeps the correct balloons and says when one is wrong.
class BalloonsPage extends StatefulWidget {
  const BalloonsPage({super.key, required this.args});

  final LetterHuntArgs args;

  @override
  State<BalloonsPage> createState() => _BalloonsPageState();
}

class _BalloonsPageState extends State<BalloonsPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterId _receiverId = widget.args.setup.buddy.other;
  late final CharacterController _receiver = CharacterController(
    _receiverId,
    sound: _sound,
  );
  final Future<BalloonsConfig> _config = sl<BalloonsConfigRepository>().load();
  final Random _random = Random();

  BalloonsCubit? _cubit;
  BalloonsGame? _game;

  /// The receiver's speech bubble (kept here so Coptic letters can be
  /// mixed into the text).
  MixedText? _bubble;
  Timer? _bubbleTimer;
  DateTime _lastMissedLine = DateTime(0);
  bool _showResult = false;
  Timer? _resultTimer;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.village);
    _config.then((config) {
      if (mounted) _start(config);
    });
  }

  void _start(BalloonsConfig config) {
    _cubit?.close();
    final cubit = BalloonsCubit(
      BalloonsRound.start(
        config: config,
        target: widget.args.target,
        pool: widget.args.pool,
        random: _random,
      ),
      sl<GameProgressRepository>(),
    );
    final game = BalloonsGame(
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
    // The background picture decides where the path is: place the
    // receiver again once it has loaded.
    game.loaded.then((_) {
      if (mounted && _game == game) setState(() {});
    });
    _receiver.idle();
    _sound.play(SoundEvent.levelStart);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _say(
        _mixed(
          context.l10n.balloonsStart(widget.args.setup.name, copticSlot1),
          {copticSlot1: widget.args.target.small},
        ),
        duration: const Duration(milliseconds: 3200),
      );
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _resultTimer?.cancel();
    _receiver.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Receiver
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

  void _onEvent(BuildContext context, BalloonsState state) {
    final l10n = context.l10n;
    final target = state.round.target.small;
    switch (state.event) {
      case LetterHuntEvent.start:
        break;
      case LetterHuntEvent.correct:
        _receiver.react(CharacterReaction.correct);
        _say(_mixed(_cheer(l10n)));
      case LetterHuntEvent.wrong:
        _receiver.react(CharacterReaction.wrong);
        _say(
          _mixed(l10n.fishingWrong(copticSlot1, copticSlot2), {
            copticSlot1: state.letter!.small,
            copticSlot2: target,
          }),
          duration: const Duration(milliseconds: 2800),
        );
      case LetterHuntEvent.missed:
        // Don't nag: at most one "it floated away" every few seconds.
        final now = DateTime.now();
        if (now.difference(_lastMissedLine) < const Duration(seconds: 4)) {
          return;
        }
        _lastMissedLine = now;
        _receiver.react(CharacterReaction.surprised, withSound: false);
        _say(_mixed(l10n.balloonsMissed(copticSlot1), {copticSlot1: target}));
      case LetterHuntEvent.finished:
        _game?.celebrate();
        _receiver.play(CharacterAction.celebrate);
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
      context.go(AppRoutes.balloons, extra: widget.args.setup);
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
        title: l10n.gameBalloons,
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
          : BlocListener<BalloonsCubit, BalloonsState>(
              bloc: cubit,
              listenWhen: (a, b) => a.eventId != b.eventId,
              listener: _onEvent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  game.rtl = rtl;
                  return _scene(
                    BalloonsLayout(
                      constraints.biggest,
                      goal: cubit.round.goal,
                      rtl: rtl,
                      art: game.art,
                    ),
                    game,
                    cubit,
                  );
                },
              ),
            ),
    );
  }

  Widget _scene(BalloonsLayout layout, BalloonsGame game, BalloonsCubit cubit) {
    final roster = context.read<CharacterRoster>();
    final idle = roster.pose(_receiverId, CharacterAction.idle);
    final k = layout.characterSize / roster.referenceHeight;
    final boxW = (idle?.width ?? 0) * k;
    final boxH = (idle?.height ?? 0) * k;
    final feet = layout.receiverFeet;
    final headTop = feet.dy - boxH;

    // Beside the receiver's head, on the side facing the buddy (his bunch
    // of balloons is above him), and never under the card.
    const bubbleWidth = 240.0;
    final right = feet.dx - boxW * 0.35;
    final left = max(AppDimens.spaceSm, right - bubbleWidth);
    final top = max(headTop - AppDimens.spaceMd, AppDimens.spaceSm);
    final bubbleTop =
        Rect.fromLTWH(left, top, right - left, 80).overlaps(layout.cardRect)
        ? layout.cardBottom + AppDimens.spaceSm
        : top;
    final speech = SpeechBubble(
      text: _bubble?.key,
      richText: _bubble?.span,
      maxWidth: bubbleWidth,
      showTail: false,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: GameWidget(key: ObjectKey(game), game: game),
        ),
        LetterHuntHud(
          layout: layout,
          cubit: cubit,
          label: context.l10n.balloonsCatch,
          icon: AppIcons.check,
        ),
        Positioned(
          left: feet.dx - boxW / 2,
          top: feet.dy - boxH,
          child: AnimatedCharacter(
            controller: _receiver,
            size: layout.characterSize,
            mirror: true,
          ),
        ),
        Positioned(
          left: left,
          width: right - left,
          top: bubbleTop,
          child: Align(alignment: Alignment.topRight, child: speech),
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
    );
  }
}
