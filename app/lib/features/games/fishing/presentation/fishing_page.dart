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
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/domain/character_reaction.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/characters/presentation/speech_bubble.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../../../levels/domain/game_level.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../data/fishing_config_repository.dart';
import '../domain/fishing_config.dart';
import '../domain/fishing_round.dart';
import '../game/fishing_game.dart';
import '../game/fishing_layout.dart';
import 'fishing_cubit.dart';
import 'fishing_hud.dart';
import 'fishing_result.dart';

/// What the fishing game needs: who plays, the letter to catch and the
/// letters the other fish may carry.
class FishingArgs {
  const FishingArgs({
    required this.setup,
    required this.target,
    required this.pool,
  });

  final PlayerSetup setup;
  final CopticLetter target;
  final List<CopticLetter> pool;
}

/// The fishing game screen: the Flame scene with the hero and his rod, the
/// target card and basket on top, and the other brother as the referee.
class FishingPage extends StatefulWidget {
  const FishingPage({super.key, required this.args});

  final FishingArgs args;

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
  ({String key, InlineSpan span})? _bubble;
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
    setState(() {
      _cubit = cubit;
      _game = FishingGame(
        cubit: cubit,
        hero: widget.args.setup.buddy,
        roster: context.read<CharacterRoster>(),
        sound: _sound,
        random: _random,
      );
      _showResult = false;
    });
    _referee.idle();
    _sound.play(SoundEvent.levelStart);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final l10n = context.l10n;
      _say(
        _mixed(l10n.fishingStart(widget.args.setup.name, _m1), {
          _m1: widget.args.target.small,
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

  // Placeholders put into translated text where a Coptic letter goes.
  static const String _m1 = '\u0001';
  static const String _m2 = '\u0002';

  /// Builds text in the UI language with Coptic letters swapped in for the
  /// [coptic] placeholders.
  ({String key, InlineSpan span}) _mixed(
    String text,
    Map<String, String> coptic,
  ) {
    final ui = Localizations.localeOf(context).languageCode == 'ar'
        ? AppTextStyles.arabic(AppTextVariant.body)
        : AppTextStyles.english(AppTextVariant.body);
    final letter = AppTextStyles.coptic(AppTextVariant.h3);
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(text: buffer.toString(), style: ui));
      buffer.clear();
    }

    for (final ch in text.split('')) {
      final key = coptic[ch];
      if (key == null) {
        buffer.write(ch);
      } else {
        flush();
        // Isolated, so the letter never pulls punctuation around it.
        spans.add(TextSpan(text: '\u2068 $key \u2069', style: letter));
      }
    }
    flush();
    final key = text.replaceAllMapped(
      RegExp('[$_m1$_m2]'),
      (m) => coptic[m[0]] ?? '',
    );
    return (key: key, span: TextSpan(children: spans));
  }

  void _say(
    ({String key, InlineSpan span}) bubble, {
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
      case FishingEvent.start:
        break;
      case FishingEvent.correct:
        _referee.react(CharacterReaction.correct);
        _say(_mixed(_cheer(l10n), const {}));
      case FishingEvent.wrong:
        _referee.react(CharacterReaction.wrong);
        _say(
          _mixed(l10n.fishingWrong(_m1, _m2), {
            _m1: state.letter!.small,
            _m2: target,
          }),
          duration: const Duration(milliseconds: 2800),
        );
      case FishingEvent.missed:
        // Don't nag: at most one "it got away" every few seconds.
        final now = DateTime.now();
        if (now.difference(_lastMissedLine) < const Duration(seconds: 4)) {
          return;
        }
        _lastMissedLine = now;
        _referee.react(CharacterReaction.surprised, withSound: false);
        _say(_mixed(l10n.fishingMissed(_m1), {_m1: target}));
      case FishingEvent.finished:
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
    final bubbleLeft = (feet.dx - bubbleWidth / 2).clamp(
      AppDimens.spaceSm,
      layout.width - bubbleWidth - AppDimens.spaceSm,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: GameWidget(key: ObjectKey(game), game: game),
        ),
        FishingHud(layout: layout),
        Positioned(
          left: feet.dx - boxW / 2,
          top: feet.dy - boxH,
          child: AnimatedCharacter(
            controller: _referee,
            size: layout.characterSize,
            mirror: true,
          ),
        ),
        Positioned(
          left: bubbleLeft,
          width: bubbleWidth,
          bottom: layout.height - (feet.dy - boxH) + AppDimens.spaceXs,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SpeechBubble(
              text: bubble?.key,
              richText: bubble?.span,
              maxWidth: bubbleWidth,
            ),
          ),
        ),
        if (_showResult)
          Positioned.fill(
            child: FishingResult(
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
