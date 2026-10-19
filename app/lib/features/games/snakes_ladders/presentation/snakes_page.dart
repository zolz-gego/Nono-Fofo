import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/share/web_files.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/domain/character_reaction.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../../../letters/domain/letter_repository.dart';
import '../../../levels/domain/game_level.dart';
import '../../../questions/domain/letter_question.dart';
import '../../../questions/domain/load_questions.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../shell/domain/game_timers.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../data/snakes_config_repository.dart';
import '../domain/snakes_config.dart';
import 'pyramids_background.dart';
import 'question_card.dart';
import 'snakes_board_view.dart';
import 'snakes_cubit.dart';
import 'snakes_dice.dart';
import 'snakes_mode_picker.dart';
import 'snakes_result.dart';
import 'snakes_share_card.dart';

/// The level's challenge: snakes & ladders by the Pyramids against the
/// other brother (the computer) or a friend on the same device. Every human
/// turn starts with a letter question; a right answer rolls the dice, a
/// wrong one passes the turn.
class SnakesPage extends StatefulWidget {
  const SnakesPage({super.key, required this.setup});

  final PlayerSetup setup;

  @override
  State<SnakesPage> createState() => _SnakesPageState();
}

class _SnakesPageState extends State<SnakesPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterId _buddy = widget.setup.buddy;

  /// The brothers beside the board: the child's buddy, then the other one.
  late final List<CharacterController> _brothers = [
    CharacterController(_buddy, sound: _sound),
    CharacterController(_buddy.other, sound: _sound),
  ];

  late final Future<
    (SnakesConfig, List<LetterQuestionTemplate>, List<CopticLetter>)
  >
  _content =
      (
        sl<SnakesConfigRepository>().load(),
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

  SnakesConfig? _config;
  List<LetterQuestionTemplate> _templates = const [];
  List<CopticLetter> _pool = const [];

  /// Null on the start screen.
  SnakesMode? _mode;
  String? _friendName;
  SnakesCubit? _cubit;

  bool _showResult = false;

  /// The picture to share, drawn as soon as someone wins.
  Future<Uint8List>? _card;
  final GameTimers _timers = GameTimers();

  List<Color> get _colors => [_accent(_buddy), _accent(_buddy.other)];

  static Color _accent(CharacterId id) =>
      id == CharacterId.nono ? AppColors.nonoAccent : AppColors.fofoAccent;

  String _brotherName(CharacterId id) =>
      id == CharacterId.nono ? context.l10n.nono : context.l10n.fofo;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.pyramids);
    _content.then((c) {
      if (!mounted) return;
      final (config, templates, pool) = c;
      setState(() {
        _config = config;
        _templates = templates;
        _pool = pool;
      });
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    for (final b in _brothers) {
      b.dispose();
    }
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  void _cancelTimers() {
    _timers.cancelAll();
  }

  void _later(Duration d, VoidCallback f) => _timers.later(d, () {
    if (mounted) f();
  });

  // ---------------------------------------------------------------------------
  // Starting
  // ---------------------------------------------------------------------------

  void _startComputer() {
    _mode = SnakesMode.computer;
    _friendName = null;
    _start();
  }

  void _startFriend(String name) {
    _mode = SnakesMode.friend;
    _friendName = name;
    _start();
  }

  void _start() {
    _cancelTimers();
    _cubit?.close();
    final vsComputer = _mode == SnakesMode.computer;
    final cubit = SnakesCubit(
      sl<GameProgressRepository>(),
      config: _config!,
      level: widget.setup.level,
      templates: _templates,
      pool: _pool,
      players: [
        SnakesPlayer(character: _buddy, name: widget.setup.name),
        SnakesPlayer(
          character: _buddy.other,
          name: vsComputer ? _brotherName(_buddy.other) : _friendName!,
          computer: vsComputer,
        ),
      ],
    );
    setState(() {
      _cubit = cubit;
      _showResult = false;
      _card = null;
    });
    for (final b in _brothers) {
      b
        ..hideSpeech()
        ..idle();
    }
    _brothers[0].say(context.l10n.snakesStart(widget.setup.name));
    // Give the start bubble a moment before the first question.
    _later(const Duration(milliseconds: 1200), cubit.start);
  }

  void _changePlayers() {
    _sound.play(SoundEvent.back);
    _cancelTimers();
    _cubit?.close();
    setState(() {
      _cubit = null;
      _mode = null;
      _showResult = false;
    });
    for (final b in _brothers) {
      b
        ..hideSpeech()
        ..idle();
    }
  }

  // ---------------------------------------------------------------------------
  // Turns
  // ---------------------------------------------------------------------------

  void _onRoll() {
    _brothers[_cubit!.state.current].hideSpeech();
    _cubit?.roll();
  }

  void _onPick(int i) {
    _sound.play(SoundEvent.tap);
    _cubit?.answer(i);
  }

  void _onState(BuildContext context, SnakesState state) {
    final l10n = context.l10n;
    final me = _brothers[state.current];
    final config = _config!;
    if (state.phase == SnakesPhase.rolling) {
      _sound.playKey('board.dice_roll');
    }
    switch (state.event) {
      case SnakesEvent.none:
        break;
      case SnakesEvent.turnStart:
        if (state.player.computer) {
          _sound.play(SoundEvent.opponentTurn);
          me
            ..play(CharacterAction.hint, hold: config.computerWait)
            ..say(l10n.snakesComputerThinks, duration: config.computerWait);
        } else {
          _sound.play(SoundEvent.yourTurn);
        }
      case SnakesEvent.correct:
        // Just the sound and a bubble: the brother celebrates only on a
        // ladder or a win, not before every roll.
        _sound.play(SoundEvent.correctAnswer, by: me.character);
        me
          ..idle()
          ..say(l10n.snakesCorrect);
      case SnakesEvent.wrong:
        me.react(CharacterReaction.wrong, say: l10n.snakesWrong);
      case SnakesEvent.rolled:
        _sound.playKey('board.dice_land');
      case SnakesEvent.hop:
        _sound.playKey('board.piece_hop');
      case SnakesEvent.overshoot:
        final need = config.board.squares - state.positions[state.current];
        me.react(CharacterReaction.surprised, say: l10n.snakesOvershoot(need));
      case SnakesEvent.climb:
        _sound.playKey('board.ladder_climb');
        me
          ..play(CharacterAction.celebrate, hold: const Duration(seconds: 2))
          ..say(l10n.snakesLadder, duration: const Duration(seconds: 2));
      case SnakesEvent.slide:
        _sound.playKey('board.snake_slide');
        me
          ..play(CharacterAction.surprised, hold: const Duration(seconds: 2))
          ..say(l10n.snakesSnake, duration: const Duration(seconds: 2));
      case SnakesEvent.won:
        final w = state.winner!;
        _brothers[w].react(CharacterReaction.win);
        _brothers[1 - w].play(
          CharacterAction.encourage,
          hold: const Duration(seconds: 3),
        );
        _later(const Duration(milliseconds: 1800), () {
          setState(() => _showResult = true);
          // Draw the share picture now: browsers only allow sharing right
          // after the tap, so it can't be drawn then.
          _card = _buildShareCard();
        });
    }
  }

  // ---------------------------------------------------------------------------
  // Result actions
  // ---------------------------------------------------------------------------

  void _playAgain() {
    _sound.play(SoundEvent.tap);
    _start();
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level, extra: widget.setup);
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  Future<Uint8List> _buildShareCard() {
    final l10n = context.l10n;
    final s = _cubit!.state;
    final w = s.winner!;
    final winner = s.players[w], loser = s.players[1 - w];
    final roster = context.read<CharacterRoster>();
    final child = s.players[0];
    return SnakesShareCard(
      title: l10n.snakesShareTitle(winner.name),
      line: l10n.snakesShareVs(winner.name, loser.name),
      stats: [
        ('${s.correct[0]}/${s.asked[0]}', l10n.snakesRight),
        ('${s.turns[0]}', l10n.snakesRolls),
      ],
      badge: s.firstWin ? l10n.snakesChallengeDone : null,
      subtitle: l10n.snakesShareWith(_brotherName(child.character)),
      appTitle: l10n.appTitle,
      script: _lang == 'ar' ? AppScript.arabic : AppScript.english,
      direction: Directionality.of(context),
      heroAssets: [
        ?roster.pose(winner.character, CharacterAction.celebrate)?.asset,
        ?roster.pose(loser.character, CharacterAction.encourage)?.asset,
      ],
    ).render();
  }

  Future<void> _share(Rect origin) async {
    _sound.play(SoundEvent.tap);
    final l10n = context.l10n;
    final s = _cubit!.state;
    final text = l10n.snakesShareText(
      s.players[s.winner!].name,
      s.correct[0],
      s.asked[0],
    );
    const fileName = 'nono-fofo-snakes-ladders.png';
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
      card = await (_card ??= _buildShareCard());
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = _cubit;
    final playing = cubit != null && _mode != null;
    return GameScaffold(
      title: l10n.gameSnakes,
      playing: playing,
      onPause: _timers.pause,
      onResume: _timers.resume,
      actions: [
        if (playing)
          GameAction(
            icon: AppIcons.changePlayers,
            label: (l) => l.snakesChangePlayers,
            onPressed: _changePlayers,
          ),
      ],
      body: Stack(
        children: [
          const Positioned.fill(child: PyramidsBackground()),
          if (_config == null)
            const Center(child: CircularProgressIndicator())
          else if (cubit == null || _mode == null)
            Positioned.fill(
              child: SnakesModePicker(
                buddy: _buddy,
                onComputer: _startComputer,
                onFriend: _startFriend,
              ),
            )
          else
            Positioned.fill(
              child: BlocConsumer<SnakesCubit, SnakesState>(
                bloc: cubit,
                listenWhen: (a, b) =>
                    a.eventId != b.eventId ||
                    (a.phase != b.phase && b.phase == SnakesPhase.rolling),
                listener: _onState,
                builder: (context, state) => _game(state),
              ),
            ),
        ],
      ),
    );
  }

  Widget _game(SnakesState state) {
    final config = _config!;
    final board = config.board;
    final asking =
        !state.player.computer &&
        (state.phase == SnakesPhase.question ||
            state.phase == SnakesPhase.answered) &&
        state.question != null;
    return LayoutBuilder(
      builder: (context, c) {
        const pad = AppDimens.spaceMd;
        final boardRatio = 1 + BoardGeometry.startStrip / board.columns;
        final wide = c.maxWidth >= c.maxHeight * 1.15;
        final double side;
        final Widget panel;
        if (wide) {
          final panelW = (c.maxWidth * 0.3).clamp(220.0, 360.0);
          side = min(
            (c.maxHeight - pad * 2) / boardRatio,
            c.maxWidth - panelW - pad * 3,
          );
          panel = SizedBox(
            width: panelW,
            height: c.maxHeight - pad * 2,
            child: _panel(state, vertical: true, height: c.maxHeight - pad * 2),
          );
        } else {
          side = min(c.maxWidth - pad * 2, (c.maxHeight - pad * 3) * 0.62);
          final panelH = c.maxHeight - pad * 3 - side * boardRatio;
          panel = SizedBox(
            width: c.maxWidth - pad * 2,
            height: panelH,
            child: _panel(state, vertical: false, height: panelH),
          );
        }
        final boardView = SnakesBoardView(
          board: board,
          side: side,
          tokens: [
            for (final p in state.players) (p.character, _accent(p.character)),
          ],
          positions: state.positions,
          current: state.current,
          moveDuration:
              state.event == SnakesEvent.climb ||
                  state.event == SnakesEvent.slide
              ? config.jump
              : config.hop * 0.9,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(pad),
                child: Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: wide
                      ? [boardView, const SizedBox(width: pad), panel]
                      : [panel, const SizedBox(height: pad), boardView],
                ),
              ),
            ),
            if (asking)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.scrim,
                  child: QuestionCard(
                    key: ValueKey(
                      '${state.current}-${state.asked[state.current]}',
                    ),
                    question: state.question!,
                    playerName: state.player.name,
                    character: state.player.character,
                    color: _accent(state.player.character),
                    picked: state.picked,
                    onPick: _onPick,
                  ),
                ),
              ),
            if (_showResult && state.finished)
              Positioned.fill(
                child: SnakesResult(
                  state: state,
                  colors: _colors,
                  squares: board.squares,
                  onPlayAgain: _playAgain,
                  onChangePlayers: _changePlayers,
                  onBackToGames: _backToGames,
                  onShare: _share,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Both players (brother, name, square) with the dice between them.
  Widget _panel(
    SnakesState state, {
    required bool vertical,
    required double height,
  }) {
    final l10n = context.l10n;
    final canRoll = state.phase == SnakesPhase.roll && !state.player.computer;
    final diceSize = vertical
        ? (height * 0.16).clamp(64.0, 110.0)
        : (height * 0.42).clamp(52.0, 96.0);
    final charSize = vertical
        ? ((height - 56) * 0.26).clamp(70.0, 160.0)
        : (height * 0.6).clamp(50.0, 170.0);
    final dice = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SnakesDice(
          size: diceSize,
          value: state.roll,
          rolling: state.phase == SnakesPhase.rolling,
          enabled: canRoll,
          color: canRoll || state.phase == SnakesPhase.rolling
              ? Color.lerp(AppColors.white, _colors[state.current], 0.35)!
              : AppColors.diceFace,
          onTap: _onRoll,
        ),
        const SizedBox(height: AppDimens.spaceXs),
        SizedBox(
          height: 28,
          child: AnimatedSwitcher(
            duration: AppDimens.fast,
            child: canRoll
                ? _Pill(
                    key: const ValueKey('tap'),
                    text: l10n.snakesTapDice,
                    color: _colors[state.current],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
    Widget player(int i) => _PlayerCard(
      controller: _brothers[i],
      name: state.players[i].name,
      square: state.positions[i],
      color: _colors[i],
      active: state.current == i && !state.finished,
      charSize: charSize,
      vertical: vertical,
      facesLeft: (i == 1) != (Directionality.of(context) == TextDirection.rtl),
    );
    // Short screens: each part shrinks to fit instead of overflowing.
    Widget fit(Widget child, Alignment alignment) => LayoutBuilder(
      builder: (context, c) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: SizedBox(width: c.maxWidth, child: child),
      ),
    );
    return vertical
        // Room above the top brother for his speech bubble.
        ? Padding(
            padding: const EdgeInsets.only(top: 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(child: fit(player(0), Alignment.center)),
                Flexible(child: fit(dice, Alignment.center)),
                Flexible(child: fit(player(1), Alignment.center)),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: fit(player(0), Alignment.bottomCenter)),
              // Narrow, so the names beside it keep their room (the "Tap
              // the dice!" pill shrinks to fit).
              SizedBox(
                width: diceSize * 1.25,
                child: fit(dice, Alignment.bottomCenter),
              ),
              Expanded(child: fit(player(1), Alignment.bottomCenter)),
            ],
          );
  }
}

/// One player beside the board: their brother (who reacts and talks), name
/// and square, glowing when it's their turn.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.controller,
    required this.name,
    required this.square,
    required this.color,
    required this.active,
    required this.charSize,
    required this.vertical,
    required this.facesLeft,
  });

  final CharacterController controller;
  final String name;
  final int square;
  final Color color;
  final bool active;
  final double charSize;
  final bool vertical;
  final bool facesLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCharacter(
          controller: controller,
          size: charSize,
          mirror: facesLeft,
          tapReaction: null,
        ),
        const SizedBox(height: AppDimens.spaceXs),
        AnimatedContainer(
          duration: AppDimens.normal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceSm,
            vertical: AppDimens.spaceXs,
          ),
          decoration: BoxDecoration(
            color: active ? color : AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: color, width: 3),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AppText(
                  name,
                  variant: AppTextVariant.h3,
                  color: active ? AppColors.ink : AppColors.textHeading,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: AppText.h3('$square'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: FittedBox(child: AppText.h3(text, color: AppColors.ink)),
    );
  }
}
