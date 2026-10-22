import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../letter_hunt/presentation/letter_hunt_result.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../shell/domain/game_timers.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../data/letter_puzzle_config_repository.dart';
import '../domain/letter_puzzle_config.dart';
import '../domain/puzzle_board.dart';
import 'church_background.dart';
import 'letter_puzzle_cubit.dart';

/// Who plays the Letter puzzle, and how long the words are
/// ([LetterPuzzleConfig.mix]: every length).
class LetterPuzzleArgs {
  const LetterPuzzleArgs({required this.setup, required this.length});

  final PlayerSetup setup;
  final int length;
}

/// Letter puzzle, in an old church: a saint's icon whose name card got
/// mixed up. The word shows on the card (Arabic, or English in English);
/// under it are empty cubes and the word's Coptic letters, shuffled. The
/// child drags (or taps) the letters into the cubes and checks: right ones
/// turn green and stay, wrong ones turn red and go back. On big screens the
/// buddy stands in one corner (cheers, gives hints) and the other brother in
/// the other (reacts to each check).
class LetterPuzzlePage extends StatefulWidget {
  const LetterPuzzlePage({super.key, required this.args});

  final LetterPuzzleArgs args;

  @override
  State<LetterPuzzlePage> createState() => _LetterPuzzlePageState();
}

class _LetterPuzzlePageState extends State<LetterPuzzlePage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterId _heroId = widget.args.setup.buddy;
  late final CharacterController _hero = CharacterController(
    _heroId,
    sound: _sound,
  );
  late final CharacterController _other = CharacterController(
    _heroId.other,
    sound: _sound,
  );
  late final Future<(LetterPuzzleConfig, List<CopticLetter>)> _content = (
    sl<LetterPuzzleConfigRepository>().load(),
    sl<LetterRepository>().allLetters(),
  ).wait;

  LetterPuzzleConfig? _config;
  Map<String, CopticLetter> _alphabet = const {};
  LetterPuzzleCubit? _cubit;
  bool _showResult = false;
  final GameTimers _timers = GameTimers();
  final Random _random = Random();

  /// How long red marks show before those tiles go back.
  static const Duration _redFor = Duration(milliseconds: 1300);

  /// How long a finished word stays before the next one.
  static const Duration _wordDoneFor = Duration(milliseconds: 1700);

  /// Phones: no brothers, the board gets the whole screen.
  static const double _smallScreen = 600;

  /// How long the buddy takes to run to a cube (or back to his corner).
  static const Duration _heroRun = Duration(milliseconds: 450);

  /// How long the buddy waits by a cube before going back to his corner.
  static const Duration _heroStay = Duration(milliseconds: 800);

  /// The cube the buddy ran to (null: in his corner).
  int? _heroAt;
  bool _heroFacesLeft = false;

  /// Bumped on every run, so an old "arrived" or "go home" doesn't cut in.
  int _moveToken = 0;

  /// A cube whose new letter shows once the buddy gets there.
  int? _waitingSlot;

  /// The cubes as of the last event, to see which one just got a letter.
  List<int?> _lastSlots = const [];
  int _lastIndex = -1;

  /// The game area and each cube, for working out where the buddy runs.
  final GlobalKey _stageKey = GlobalKey();
  List<GlobalKey> _cubeKeys = const [];
  int _cubeKeysFor = -1;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.monastery);
    _content.then((c) {
      if (!mounted) return;
      final (config, letters) = c;
      _config = config;
      _alphabet = {for (final l in letters) l.id: l};
      _start();
    });
  }

  /// The language the round's words are in. Each language has its own
  /// words, so switching it (in the settings pop-up) starts a new round.
  String? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == _lang) return;
    final restart = _lang != null && _config != null;
    _lang = lang;
    if (restart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
    }
  }

  void _start() {
    _timers.cancelAll();
    _cubit?.close();
    final config = _config!;
    final items = LetterPuzzleCubit.pickItems(
      pool: config.poolFor(_lang!, widget.args.length),
      alphabet: _alphabet,
      count: config.wordsPerRound,
      random: _random,
    );
    if (items.isEmpty) return;
    setState(() {
      _cubit = LetterPuzzleCubit(
        sl<GameProgressRepository>(),
        config: config,
        length: widget.args.length,
        items: items,
        random: _random,
      );
      _showResult = false;
      _heroAt = null;
      _waitingSlot = null;
      _lastSlots = const [];
      _lastIndex = -1;
    });
    _moveToken++;
    _hero.idle();
    _other.idle();
    _sound.play(SoundEvent.levelStart);
    _later(const Duration(milliseconds: 500), () {
      if (!_small) {
        _hero.say(context.l10n.letterPuzzleStart(widget.args.setup.name));
      }
    });
  }

  @override
  void dispose() {
    _timers.cancelAll();
    _hero.dispose();
    _other.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.later(d, () {
    if (mounted) f();
  });

  bool get _small => MediaQuery.sizeOf(context).shortestSide < _smallScreen;

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  void _onEvent(BuildContext context, LetterPuzzleState state) {
    final l10n = context.l10n;
    _followLetters(state);
    switch (state.event) {
      case LetterPuzzleEvent.none:
        break;
      case LetterPuzzleEvent.moved:
        _sound.play(SoundEvent.select);
      case LetterPuzzleEvent.wrong:
        if (_small) {
          _sound.play(SoundEvent.wrongAnswer);
        } else {
          _hero.hideSpeech();
          _other.react(CharacterReaction.wrong, say: l10n.letterPuzzleWrong);
        }
        _later(_redFor, () => _cubit?.clearWrong());
      case LetterPuzzleEvent.hint:
        _sound.play(SoundEvent.hintRevealed);
        if (!_small) {
          // He's already running to the cube (see _followLetters).
          _hero.say(
            l10n.letterPuzzleHintSay,
            duration: const Duration(seconds: 2),
          );
        }
      case LetterPuzzleEvent.wordDone:
        if (_small) {
          _sound.play(SoundEvent.correctAnswer);
        } else {
          _hero.hideSpeech();
          _hero.play(CharacterAction.cheer, hold: _wordDoneFor);
          _other.react(CharacterReaction.correct, say: l10n.letterPuzzleRight);
        }
        _later(_wordDoneFor, () => _cubit?.next());
      case LetterPuzzleEvent.finished:
        if (_small) {
          _sound.play(SoundEvent.levelComplete);
        } else {
          _hero.react(CharacterReaction.celebrate);
          _other.react(CharacterReaction.celebrate, withSound: false);
        }
        _later(const Duration(milliseconds: 1200), () {
          setState(() => _showResult = true);
        });
    }
  }

  /// A letter just went into a cube (a tap, a drop or a hint): the buddy
  /// runs there and the letter shows when he arrives. A new word sends him
  /// back to his corner.
  void _followLetters(LetterPuzzleState state) {
    final slots = state.board.slots;
    // A new word starts with every cube empty.
    final sameWord = state.index == _lastIndex;
    final before = sameWord
        ? _lastSlots
        : List<int?>.filled(slots.length, null);
    int? placed;
    for (var i = 0; i < slots.length; i++) {
      if (slots[i] != null && slots[i] != before[i]) {
        placed = i;
        break;
      }
    }
    _lastSlots = slots;
    _lastIndex = state.index;
    if (_small) return;
    if (placed != null) {
      _runTo(placed);
    } else if (!sameWord && _heroAt != null) {
      _goHome();
    }
  }

  void _runTo(int slot) {
    final token = ++_moveToken;
    final from = _heroRect(_heroAt);
    final to = _heroRect(slot);
    _hero
      ..hideSpeech()
      ..play(CharacterAction.run);
    _sound.play(SoundEvent.charRun, by: _heroId);
    setState(() {
      _heroAt = slot;
      _waitingSlot = slot;
      if (from != null &&
          to != null &&
          (to.center.dx - from.center.dx).abs() > 1) {
        _heroFacesLeft = to.center.dx < from.center.dx;
      }
    });
    _later(_heroRun, () {
      if (token != _moveToken) return;
      setState(() => _waitingSlot = null);
      _hero.play(CharacterAction.hint, hold: const Duration(milliseconds: 700));
      _later(_heroStay, () {
        if (token == _moveToken) _goHome();
      });
    });
  }

  void _goHome() {
    if (_heroAt == null) return;
    final token = ++_moveToken;
    _hero.play(CharacterAction.run);
    setState(() {
      _heroAt = null;
      _waitingSlot = null;
    });
    _later(_heroRun, () {
      if (token == _moveToken) _hero.idle();
    });
  }

  /// Layout of the last build, for the buddy's spots.
  ({Size size, double charSize, bool rtl})? _layout;

  /// The buddy's box in his corner, or beside cube [slot] with the cube at
  /// about his hands. Null before the first layout.
  Rect? _heroRect(int? slot) {
    final layout = _layout;
    if (layout == null) return null;
    final roster = context.read<CharacterRoster>();
    final idle = roster.pose(_heroId, CharacterAction.idle);
    final ref = roster.referenceHeight;
    final aspect = idle == null ? 0.45 : idle.width / idle.height;
    final homeH = layout.charSize * (idle?.height ?? ref) / ref;
    final homeW = homeH * aspect;
    final onLeft = !layout.rtl;
    final homeX = onLeft
        ? _cornerWidth / 2
        : layout.size.width - _cornerWidth / 2;
    final home = Rect.fromLTWH(
      homeX - homeW / 2,
      layout.size.height - homeH,
      homeW,
      homeH,
    );
    final cube = slot == null ? null : _cubeRect(slot);
    if (cube == null) return home;
    final h = (cube.height * 2.1).clamp(90.0, max(90.0, homeH)).toDouble();
    final w = h * aspect;
    final c = cube.center;
    final fromLeft = home.center.dx < c.dx;
    final x = fromLeft ? c.dx - w * 0.95 : c.dx - w * 0.05;
    return Rect.fromLTWH(
      x.clamp(0.0, max(0.0, layout.size.width - w)),
      (c.dy - h * 0.45).clamp(0.0, max(0.0, layout.size.height - h)),
      w,
      h,
    );
  }

  /// Where cube [slot] is on the game area (null until it's laid out).
  Rect? _cubeRect(int slot) {
    if (slot >= _cubeKeys.length) return null;
    final cube = _cubeKeys[slot].currentContext?.findRenderObject();
    final stage = _stageKey.currentContext?.findRenderObject();
    if (cube is! RenderBox || stage is! RenderBox || !cube.attached) {
      return null;
    }
    return Rect.fromPoints(
      cube.localToGlobal(Offset.zero, ancestor: stage),
      cube.localToGlobal(cube.size.bottomRight(Offset.zero), ancestor: stage),
    );
  }

  void _onHint() {
    _sound.play(SoundEvent.hint);
    _cubit?.hint();
  }

  void _onCheck() {
    _sound.play(SoundEvent.tap);
    _cubit?.check();
  }

  // ---------------------------------------------------------------------------
  // Result actions
  // ---------------------------------------------------------------------------

  void _playAgain() {
    _sound.play(SoundEvent.tap);
    _start();
  }

  void _otherLevel() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.letterPuzzle, extra: widget.args.setup);
    }
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level, extra: widget.args.setup);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    return GameScaffold(
      title: context.l10n.gameLetterPuzzle,
      onPause: _timers.pause,
      onResume: _timers.resume,
      actions: [
        GameAction(
          icon: AppIcons.wordLength,
          label: (l) => l.letterPuzzleOtherLevel,
          onPressed: _otherLevel,
        ),
      ],
      body: Stack(
        children: [
          Positioned.fill(child: _background()),
          if (cubit == null)
            const Center(child: CircularProgressIndicator())
          else
            Positioned.fill(
              child: BlocConsumer<LetterPuzzleCubit, LetterPuzzleState>(
                bloc: cubit,
                listenWhen: (a, b) => a.eventId != b.eventId,
                listener: _onEvent,
                builder: (context, state) => LayoutBuilder(
                  builder: (context, c) => _screen(c.biggest, state),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The church picture, or the church drawn in code until there is one.
  Widget _background() {
    final path = _config?.background;
    if (path == null) return const ChurchBackground();
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ChurchBackground(),
    );
  }

  Widget _screen(Size size, LetterPuzzleState state) {
    final l10n = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final small = _small;
    const hudH = 60.0;
    final charSize = small ? 0.0 : min(size.height * 0.32, 230.0);
    // Room for a brother at each side, wide enough for his speech bubble.
    final side = small ? AppDimens.spaceSm : _cornerWidth + AppDimens.spaceSm;
    final boardW = min(size.width - side * 2, 820.0);
    _layout = (size: size, charSize: charSize, rtl: rtl);
    if (_cubeKeysFor != state.index) {
      _cubeKeysFor = state.index;
      _cubeKeys = [for (var i = 0; i < state.board.length; i++) GlobalKey()];
    }

    return Stack(
      key: _stageKey,
      children: [
        Positioned(
          top: AppDimens.spaceSm,
          left: GameScaffold.cornerSize,
          right: GameScaffold.cornerSize,
          height: hudH - AppDimens.spaceSm,
          child: Center(
            child: FittedBox(
              child: _Hud(
                word: state.index + 1,
                total: state.items.length,
                mistakes: state.mistakes,
                onHint: state.canPlay ? _onHint : null,
              ),
            ),
          ),
        ),
        Positioned(
          top: hudH,
          bottom: AppDimens.spaceSm,
          left: (size.width - boardW) / 2,
          width: boardW,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: boardW,
                child: _Board(
                  key: ValueKey(state.index),
                  state: state,
                  width: boardW,
                  showHowTo: state.index == 0,
                  cubeKeys: _cubeKeys,
                  waitingSlot: _waitingSlot,
                  onPlace: (tile, slot) => _cubit?.place(tile, slot),
                  onPlaceNext: (tile) => _cubit?.placeNext(tile),
                  onRemove: (slot) => _cubit?.remove(slot),
                  onCheck: _onCheck,
                ),
              ),
            ),
          ),
        ),
        if (!small) ...[
          _corner(_other, charSize, onLeft: rtl),
          _runningHero(charSize, rtl),
        ],
        if (_showResult && state.finished)
          Positioned.fill(
            child: LetterHuntResult(
              stars: state.stars,
              isNewBest: state.isNewBest,
              onPlayAgain: _playAgain,
              onOtherLetter: _otherLevel,
              onBackToGames: _backToGames,
              otherLabel: (l) => l.letterPuzzleOtherLevel,
              otherIcon: AppIcons.wordLength,
            ),
          ),
        if (state.items.isEmpty)
          Center(child: AppText.body(l10n.gamesComingSoon)),
      ],
    );
  }

  /// The buddy: in his corner, or beside the cube he ran to.
  Widget _runningHero(double charSize, bool rtl) {
    final rect = _heroRect(_heroAt);
    final homeFacesLeft = rtl;
    final child = AnimatedCharacter(
      controller: _hero,
      size: charSize,
      mirror: _heroAt == null ? homeFacesLeft : _heroFacesLeft,
    );
    if (rect == null) {
      return _corner(_hero, charSize, onLeft: !rtl);
    }
    return AnimatedPositioned.fromRect(
      rect: rect,
      duration: _heroRun,
      curve: Curves.easeInOut,
      child: IgnorePointer(
        child: FittedBox(alignment: Alignment.bottomCenter, child: child),
      ),
    );
  }

  /// Each brother's corner: as wide as his speech bubble, so it never
  /// runs off the screen.
  static const double _cornerWidth = 240;

  /// A brother standing in a bottom corner, facing the board.
  Widget _corner(CharacterController c, double size, {required bool onLeft}) =>
      Positioned(
        bottom: 0,
        left: onLeft ? 0 : null,
        right: onLeft ? null : 0,
        width: _cornerWidth,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedCharacter(
              controller: c,
              size: size,
              mirror: !onLeft,
            ),
          ),
        ),
      );
}

/// The word count, the mistakes and the hint button.
class _Hud extends StatelessWidget {
  const _Hud({
    required this.word,
    required this.total,
    required this.mistakes,
    required this.onHint,
  });

  final int word;
  final int total;
  final int mistakes;
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget chip(Widget child) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMd,
        vertical: AppDimens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.cubeBorder, width: 2),
      ),
      child: child,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip(AppText.h3(l10n.letterPuzzleWord(word, total))),
        const SizedBox(width: AppDimens.spaceSm),
        chip(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(AppIcons.miss, size: 18, color: AppColors.wrong),
              const SizedBox(width: AppDimens.spaceXs),
              AppText.h3('$mistakes'),
              const SizedBox(width: AppDimens.spaceXs),
              AppText.body(l10n.letterPuzzleMistakes),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.spaceSm),
        FilledButton.icon(
          onPressed: onHint,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.hint,
            foregroundColor: AppColors.ink,
          ),
          icon: const FaIcon(AppIcons.hintBulb, size: 18),
          label: Text(l10n.letterPuzzleHint),
        ),
      ],
    );
  }
}

/// The icon, the name card with the word, the cubes, the tray and the
/// check button.
class _Board extends StatelessWidget {
  const _Board({
    super.key,
    required this.state,
    required this.width,
    required this.showHowTo,
    required this.cubeKeys,
    required this.waitingSlot,
    required this.onPlace,
    required this.onPlaceNext,
    required this.onRemove,
    required this.onCheck,
  });

  final LetterPuzzleState state;
  final double width;
  final bool showHowTo;

  /// One key per cube, so the page can find where each cube is.
  final List<GlobalKey> cubeKeys;

  /// A cube whose letter waits for the buddy to bring it.
  final int? waitingSlot;
  final void Function(int tile, int slot) onPlace;
  final void Function(int tile) onPlaceNext;
  final void Function(int slot) onRemove;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final board = state.board;
    final n = board.length;
    final cube = min(84.0, (width - AppDimens.spaceSm * 2) / (n + 0.8)) - 8;
    final canPlay = state.canPlay;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SaintIcon(width: 120),
        const SizedBox(height: AppDimens.spaceSm),
        _NamePlate(text: state.item.word.text, solved: board.solved),
        const SizedBox(height: AppDimens.spaceSm),
        // A cream panel, so the cubes and texts read on any background.
        Container(
          padding: const EdgeInsets.all(AppDimens.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.boardPanel,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.cubeBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.body(l10n.letterPuzzleWrite, color: AppColors.ink),
              const SizedBox(height: AppDimens.spaceSm),
              // Coptic reads left to right, also in the Arabic app.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < n; i++)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: _Cube(
                          key: i < cubeKeys.length ? cubeKeys[i] : null,
                          board: board,
                          slot: i,
                          waiting: i == waitingSlot,
                          size: cube,
                          enabled: canPlay,
                          onPlace: onPlace,
                          onRemove: onRemove,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              Directionality(
                textDirection: TextDirection.ltr,
                child: _Tray(
                  board: board,
                  size: cube,
                  enabled: canPlay,
                  onPlaceNext: onPlaceNext,
                  onRemove: onRemove,
                ),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: canPlay && board.full ? onCheck : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceXl,
                    ),
                  ),
                  icon: const FaIcon(AppIcons.checkWord, size: 20),
                  label: AppText.h3(
                    l10n.letterPuzzleCheck,
                    color: AppColors.white,
                  ),
                ),
              ),
              if (showHowTo) ...[
                const SizedBox(height: AppDimens.spaceSm),
                AppText(
                  l10n.letterPuzzleHowTo,
                  variant: AppTextVariant.caption,
                  color: AppColors.cocoa,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The wooden name card under the icon, with the word to spell.
class _NamePlate extends StatelessWidget {
  const _NamePlate({required this.text, required this.solved});

  final String text;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDimens.normal,
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceLg,
        vertical: AppDimens.spaceSm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.namePlateLight, AppColors.namePlate],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: solved ? AppColors.correct : AppColors.iconGold,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AppText.h1(
        text,
        color: AppColors.iconGoldLight,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// One cube: empty, or holding a tile. Takes dropped tiles; its own tile
/// can be dragged out or tapped back to the tray.
class _Cube extends StatelessWidget {
  const _Cube({
    super.key,
    required this.board,
    required this.waiting,
    required this.slot,
    required this.size,
    required this.enabled,
    required this.onPlace,
    required this.onRemove,
  });

  final PuzzleBoard board;
  final int slot;

  /// Its new letter is on the way (shown empty until the buddy arrives).
  final bool waiting;
  final double size;
  final bool enabled;
  final void Function(int tile, int slot) onPlace;
  final void Function(int slot) onRemove;

  @override
  Widget build(BuildContext context) {
    final tile = waiting ? null : board.slots[slot];
    final locked = board.locked[slot];
    final mark = board.marks[slot];
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => enabled && !locked,
      onAcceptWithDetails: (d) => onPlace(d.data, slot),
      builder: (context, candidates, _) {
        final hover = candidates.isNotEmpty;
        if (tile == null) {
          return AnimatedContainer(
            duration: AppDimens.fast,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: hover ? AppColors.iconGoldLight : AppColors.cubeEmpty,
              borderRadius: BorderRadius.circular(size * 0.18),
              border: Border.all(
                color: hover ? AppColors.iconGold : AppColors.namePlate,
                width: 3,
              ),
            ),
          );
        }
        final face = _TileFace(
          letter: board.tiles[tile],
          size: size,
          mark: mark,
          highlight: hover,
          popIn: true,
        );
        if (locked || !enabled) return face;
        return _DraggableTile(
          tile: tile,
          letter: board.tiles[tile],
          size: size,
          onTap: () => onRemove(slot),
          child: face,
        );
      },
    );
  }
}

/// The loose tiles, each in its own spot (a placed tile leaves a faint
/// gap). Tiles dragged here from a cube go back.
class _Tray extends StatelessWidget {
  const _Tray({
    required this.board,
    required this.size,
    required this.enabled,
    required this.onPlaceNext,
    required this.onRemove,
  });

  final PuzzleBoard board;
  final double size;
  final bool enabled;
  final void Function(int tile) onPlaceNext;
  final void Function(int slot) onRemove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) =>
          enabled &&
          !board.inTray(d.data) &&
          !board.locked[board.slotOf(d.data)!],
      onAcceptWithDetails: (d) => onRemove(board.slotOf(d.data)!),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: AppDimens.fast,
        padding: const EdgeInsets.all(AppDimens.spaceSm),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? AppColors.namePlate.withValues(alpha: 0.85)
              : AppColors.namePlateLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var t = 0; t < board.tiles.length; t++)
              Padding(
                padding: const EdgeInsets.all(4),
                child: board.inTray(t)
                    ? enabled
                          ? _DraggableTile(
                              tile: t,
                              letter: board.tiles[t],
                              size: size,
                              onTap: () => onPlaceNext(t),
                              child: _TileFace(
                                letter: board.tiles[t],
                                size: size,
                              ),
                            )
                          : _TileFace(letter: board.tiles[t], size: size)
                    : SizedBox.square(
                        dimension: size,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.trayGap,
                            borderRadius: BorderRadius.circular(size * 0.18),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tile that can be dragged (or tapped).
class _DraggableTile extends StatelessWidget {
  const _DraggableTile({
    required this.tile,
    required this.letter,
    required this.size,
    required this.onTap,
    required this.child,
  });

  final int tile;
  final CopticLetter letter;
  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Draggable<int>(
      data: tile,
      feedback: Material(
        color: AppColors.transparent,
        child: Transform.scale(
          scale: 1.12,
          child: _TileFace(letter: letter, size: size, lifted: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(onTap: onTap, child: child),
      ),
    );
  }
}

/// A cream letter tile; its border turns green or red after a check.
class _TileFace extends StatelessWidget {
  const _TileFace({
    required this.letter,
    required this.size,
    this.mark = SlotMark.none,
    this.highlight = false,
    this.lifted = false,
    this.popIn = false,
  });

  final CopticLetter letter;
  final double size;
  final SlotMark mark;
  final bool highlight;
  final bool lifted;

  /// Pops in when it first shows (a letter landing in its cube).
  final bool popIn;

  @override
  Widget build(BuildContext context) {
    final border = switch (mark) {
      SlotMark.right => AppColors.correct,
      SlotMark.wrong => AppColors.wrong,
      SlotMark.none => highlight ? AppColors.iconGold : AppColors.cubeBorder,
    };
    final face = AnimatedContainer(
      duration: AppDimens.fast,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: switch (mark) {
          SlotMark.right => AppColors.cubeRight,
          SlotMark.wrong => AppColors.cubeWrong,
          SlotMark.none => AppColors.cube,
        },
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: border, width: mark == SlotMark.none ? 3 : 5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: lifted ? 12 : 3,
            offset: Offset(0, lifted ? 6 : 2),
          ),
        ],
      ),
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: CopticText.h1(letter.small, color: AppColors.coptic),
        ),
      ),
    );
    if (mark == SlotMark.wrong) {
      return face.animate().shake(hz: 5, offset: const Offset(4, 0));
    }
    if (mark == SlotMark.right) {
      return face.animate().scale(
        begin: const Offset(1.15, 1.15),
        duration: AppDimens.normal,
        curve: Curves.easeOutBack,
      );
    }
    if (popIn) {
      return face.animate().scale(
        begin: const Offset(0.6, 0.6),
        duration: AppDimens.fast,
        curve: Curves.easeOutBack,
      );
    }
    return face;
  }
}
