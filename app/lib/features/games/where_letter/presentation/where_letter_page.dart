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
import '../../letter_hunt/presentation/letter_hunt_result.dart';
import '../../letter_puzzle/data/letter_puzzle_config_repository.dart';
import '../../letter_puzzle/domain/letter_puzzle_config.dart';
import '../../letter_puzzle/presentation/church_background.dart';
import '../../letter_puzzle/presentation/letter_puzzle_cubit.dart';
import '../../letter_puzzle/presentation/letter_puzzle_page.dart';
import '../../match_letters/presentation/sound_face.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../shell/domain/game_timers.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../data/where_letter_config_repository.dart';
import '../domain/gap_question.dart';
import '../domain/where_letter_config.dart';
import 'where_letter_cubit.dart';

/// Where the buddy puts something: the missing letter into the gap, or its
/// sound into the box under it.
enum _Spot { gap, sound }

/// Where's the letter, in the church. A word's Coptic letters show with one
/// missing; the child picks the missing letter from the options, and the
/// buddy runs over and puts it in the gap. Then the child picks what that
/// letter sounds like in the word (Arabic, or Latin in English), and the
/// buddy puts it in a box under the letter. Then the word itself shows and
/// the other brother cheers. On big screens the brothers stand in the
/// bottom corners; on phones the buddy only comes in to put a letter.
class WhereLetterPage extends StatefulWidget {
  const WhereLetterPage({super.key, required this.args});

  /// Same as the Letter puzzle: who plays, and the word length.
  final LetterPuzzleArgs args;

  @override
  State<WhereLetterPage> createState() => _WhereLetterPageState();
}

class _WhereLetterPageState extends State<WhereLetterPage> {
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
  late final Future<(WhereLetterConfig, LetterPuzzleConfig, List<CopticLetter>)>
  _content = (
    sl<WhereLetterConfigRepository>().load(),
    sl<LetterPuzzleConfigRepository>().load(),
    sl<LetterRepository>().allLetters(),
  ).wait;

  WhereLetterConfig? _config;
  LetterPuzzleConfig? _words;
  List<CopticLetter> _letters = const [];
  WhereLetterCubit? _cubit;
  bool _showResult = false;
  final GameTimers _timers = GameTimers();
  final Random _random = Random();

  /// Phones: no brothers standing, the board gets the whole screen.
  static const double _smallScreen = 600;

  /// How long the buddy takes to run to a spot (or back).
  static const Duration _heroRun = Duration(milliseconds: 450);

  /// How long the buddy waits by a spot before going back.
  static const Duration _heroStay = Duration(milliseconds: 800);

  /// The spot the buddy ran to (null: in his corner, or off screen).
  _Spot? _heroAt;

  /// The spot he was last by (where he comes in on a phone).
  _Spot _heroSpot = _Spot.gap;

  /// Bumped to put him somewhere without running (a phone's edge).
  int _heroEntry = 0;

  /// Bumped on every run, so an old "arrived" or "go home" doesn't cut in.
  int _moveToken = 0;

  /// A spot whose letter or sound shows once the buddy gets there.
  _Spot? _waiting;

  /// The game area, the gap and the sound box, for working out where he
  /// runs.
  final GlobalKey _stageKey = GlobalKey();
  final GlobalKey _gapKey = GlobalKey();
  final GlobalKey _soundKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.monastery);
    _content.then((c) {
      if (!mounted) return;
      final (config, words, letters) = c;
      _config = config;
      _words = words;
      _letters = letters;
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
    final words = _words!;
    final lang = _lang!;
    final items = LetterPuzzleCubit.pickItems(
      // Only words that have a sound for every letter.
      pool: [
        for (final w in words.poolFor(lang, widget.args.length))
          if (w.sounds.length == w.letters.length) w,
      ],
      alphabet: {for (final l in _letters) l.id: l},
      count: config.wordsPerRound,
      random: _random,
    );
    if (items.isEmpty) return;
    final maker = GapMaker(
      alphabet: _letters,
      words: [for (final byLength in words.words[lang]!.values) ...byLength],
      languageCode: lang,
      options: config.options,
    );
    setState(() {
      _cubit = WhereLetterCubit(
        sl<GameProgressRepository>(),
        config: config,
        length: widget.args.length,
        items: items,
        maker: maker,
        random: _random,
      );
      _showResult = false;
      _heroAt = null;
      _waiting = null;
    });
    _moveToken++;
    _hero.idle();
    _other.idle();
    _sound.play(SoundEvent.levelStart);
    _later(const Duration(milliseconds: 500), () {
      if (!_small) {
        _hero.say(context.l10n.whereLetterStart(widget.args.setup.name));
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

  void _onEvent(BuildContext context, WhereLetterState state) {
    final l10n = context.l10n;
    final config = _config!;
    switch (state.event) {
      case WhereLetterEvent.none:
        // A new word: the buddy goes back.
        _goHome();
      case WhereLetterEvent.letterRight:
        _sound.play(SoundEvent.select);
        _comeTo(_Spot.gap);
      case WhereLetterEvent.wrong:
        if (_small) {
          _sound.play(SoundEvent.wrongAnswer);
        } else {
          _hero.hideSpeech();
          _other.react(CharacterReaction.wrong, say: l10n.whereLetterWrong);
        }
      case WhereLetterEvent.hint:
        _sound.play(SoundEvent.hintRevealed);
        if (!_small) {
          _hero.say(
            l10n.whereLetterHintSay,
            duration: const Duration(seconds: 2),
          );
        }
      case WhereLetterEvent.wordDone:
        _sound.play(SoundEvent.select);
        _comeTo(_Spot.sound, stay: true);
        _later(_heroRun, () {
          if (_small) {
            _sound.play(SoundEvent.correctAnswer);
          } else {
            _hero.play(CharacterAction.cheer, hold: config.wordDoneFor);
            _other.react(
              CharacterReaction.correct,
              say: l10n.letterPuzzleRight,
            );
          }
        });
        _later(_heroRun + config.wordDoneFor, () => _cubit?.next());
      case WhereLetterEvent.finished:
        _goHome();
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

  /// Runs to [spot]; on a phone he first pops just off his edge, level with
  /// it, so he runs straight in. With [stay] he waits there (the word is
  /// done) until the next word sends him back.
  void _comeTo(_Spot spot, {bool stay = false}) {
    if (_small && _heroAt == null) {
      final token = ++_moveToken;
      setState(() {
        _heroSpot = spot;
        _heroEntry++;
        _waiting = spot;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && token == _moveToken) _runTo(spot, stay: stay);
      });
      return;
    }
    _runTo(spot, stay: stay);
  }

  void _runTo(_Spot spot, {required bool stay}) {
    final token = ++_moveToken;
    _hero
      ..hideSpeech()
      ..play(CharacterAction.run);
    _sound.play(SoundEvent.charRun, by: _heroId);
    setState(() {
      _heroAt = spot;
      _heroSpot = spot;
      _waiting = spot;
    });
    _later(_heroRun, () {
      if (token != _moveToken) return;
      setState(() => _waiting = null);
      if (stay) return;
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
      _waiting = null;
    });
    _later(_heroRun, () {
      if (token == _moveToken) _hero.idle();
    });
  }

  /// Layout of the last build, for the buddy's spots.
  ({Size size, double charSize, bool rtl, bool small})? _layout;

  /// The buddy's box: in his corner (on a phone: just off his edge, level
  /// with [_heroSpot]), or beside [spot] on his side of the board.
  /// Null before the first layout.
  Rect? _heroRect(_Spot? spot) {
    final layout = _layout;
    if (layout == null) return null;
    final roster = context.read<CharacterRoster>();
    final idle = roster.pose(_heroId, CharacterAction.idle);
    final ref = roster.referenceHeight;
    final aspect = idle == null ? 0.45 : idle.width / idle.height;
    final onLeft = !layout.rtl;
    final homeH = layout.small
        ? 150.0
        : layout.charSize * (idle?.height ?? ref) / ref;
    final homeW = homeH * aspect;
    final home = Rect.fromLTWH(
      (onLeft ? _cornerWidth / 2 : layout.size.width - _cornerWidth / 2) -
          homeW / 2,
      layout.size.height - homeH,
      homeW,
      homeH,
    );
    final target = _spotRect(spot ?? _heroSpot);
    if (target == null) return layout.small ? null : home;
    final h = (target.height * 2.1).clamp(80.0, max(80.0, homeH)).toDouble();
    final w = h * aspect;
    final y = (target.center.dy - h * 0.45)
        .clamp(0.0, max(0.0, layout.size.height - h))
        .toDouble();
    if (spot == null) {
      if (!layout.small) return home;
      // Just off his edge.
      return Rect.fromLTWH(onLeft ? -w - 20 : layout.size.width + 20, y, w, h);
    }
    final x = onLeft ? target.left - w * 0.9 : target.right - w * 0.1;
    return Rect.fromLTWH(
      x.clamp(-w * 0.3, layout.size.width - w * 0.7),
      y,
      w,
      h,
    );
  }

  /// Where the gap or the sound box is on the game area.
  Rect? _spotRect(_Spot spot) {
    final box = (spot == _Spot.gap ? _gapKey : _soundKey).currentContext
        ?.findRenderObject();
    final stage = _stageKey.currentContext?.findRenderObject();
    if (box is! RenderBox || stage is! RenderBox || !box.attached) return null;
    return Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: stage),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: stage),
    );
  }

  void _onHint() {
    _sound.play(SoundEvent.hint);
    _cubit?.hint();
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
      context.go(AppRoutes.whereLetter);
    }
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level(widget.args.setup.level));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    return GameScaffold(
      title: context.l10n.gameWhereLetter,
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
              child: BlocConsumer<WhereLetterCubit, WhereLetterState>(
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

  /// The Letter puzzle's church picture, or the church drawn in code until
  /// there is one.
  Widget _background() {
    final path = _words?.background;
    if (path == null) return const ChurchBackground();
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ChurchBackground(),
    );
  }

  Widget _screen(Size size, WhereLetterState state) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final small = _small;
    const hudH = 60.0;
    final charSize = small ? 0.0 : min(size.height * 0.32, 230.0);
    // Room for a brother at each side, wide enough for his speech bubble.
    final side = small ? AppDimens.spaceSm : _cornerWidth + AppDimens.spaceSm;
    final boardW = min(size.width - side * 2, 760.0);
    _layout = (size: size, charSize: charSize, rtl: rtl, small: small);
    final playing = state.canPlay && _waiting == null;

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
                onHint: playing && state.question.canHint ? _onHint : null,
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
                  gapKey: _gapKey,
                  soundKey: _soundKey,
                  waiting: _waiting,
                  enabled: playing,
                  onPick: (i) => _cubit?.pick(i),
                ),
              ),
            ),
          ),
        ),
        if (!small) _corner(_other, charSize, onLeft: rtl),
        _runningHero(charSize, rtl, small),
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
      ],
    );
  }

  /// The buddy: in his corner (off screen on a phone), or beside the spot
  /// he's putting something in. He always stands on his own side, facing
  /// the board.
  Widget _runningHero(double charSize, bool rtl, bool small) {
    final rect = _heroRect(_heroAt);
    if (rect == null) {
      return small
          ? const SizedBox.shrink()
          : _corner(_hero, charSize, onLeft: !rtl);
    }
    return AnimatedPositioned.fromRect(
      key: ValueKey(_heroEntry),
      rect: rect,
      duration: _heroRun,
      curve: Curves.easeInOut,
      child: IgnorePointer(
        child: FittedBox(
          alignment: Alignment.bottomCenter,
          child: AnimatedCharacter(
            controller: _hero,
            size: small ? rect.height : charSize,
            mirror: rtl,
          ),
        ),
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

/// The panel: what to do, the Coptic word with its gap (and the sound box
/// under it), the word itself once done, and the options.
class _Board extends StatelessWidget {
  const _Board({
    super.key,
    required this.state,
    required this.width,
    required this.gapKey,
    required this.soundKey,
    required this.waiting,
    required this.enabled,
    required this.onPick,
  });

  final WhereLetterState state;
  final double width;
  final GlobalKey gapKey;
  final GlobalKey soundKey;

  /// A spot whose letter or sound waits for the buddy to put it in.
  final _Spot? waiting;
  final bool enabled;
  final void Function(int option) onPick;

  static const double _gapBetween = AppDimens.spaceSm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final q = state.question;
    final n = q.letters.length;
    // Room for the panel's padding.
    final tile = ((width - AppDimens.spaceMd * 4 - _gapBetween * (n - 1)) / n)
        .clamp(40.0, 84.0)
        .toDouble();
    final letterIn = q.step != GapStep.letter && waiting != _Spot.gap;
    final soundIn = q.done && waiting != _Spot.sound;
    final done = q.done && waiting == null;

    return Container(
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
          AppText.h3(
            switch (q.step) {
              GapStep.letter => l10n.whereLetterPickLetter,
              GapStep.sound || GapStep.done => l10n.whereLetterPickSound,
            },
            color: AppColors.ink,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.spaceMd),
          // Coptic reads left to right, also in the Arabic app.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: _gapBetween),
                  SizedBox(
                    width: tile,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          key: i == q.gap ? gapKey : null,
                          dimension: tile,
                          child: i == q.gap && !letterIn
                              ? const _Gap()
                              : _LetterTile(
                                  letter: q.letters[i],
                                  placed: i == q.gap,
                                  glow: done,
                                ),
                        ),
                        if (i == q.gap && q.step != GapStep.letter)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppDimens.spaceXs,
                            ),
                            child: SizedBox(
                              key: soundKey,
                              width: tile,
                              height: tile * 0.8,
                              child: soundIn
                                  ? _SoundBox(sound: q.sound, lang: lang)
                                  : const _Gap(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // The word itself shows here once both choices are right; the
          // space is kept so nothing jumps.
          SizedBox(
            height: 64,
            child: done
                ? Center(
                    child: _NamePlate(text: state.item.word.text)
                        .animate()
                        .fadeIn(duration: AppDimens.normal)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          curve: Curves.easeOutBack,
                        ),
                  )
                : null,
          ),
          _Options(
            question: q,
            lang: lang,
            // As big as fit the panel, up to 96.
            size:
                ((width - AppDimens.spaceMd * 4) / q.letterOptions.length -
                        AppDimens.spaceSm * 2)
                    .clamp(48.0, 96.0)
                    .toDouble(),
            enabled: enabled,
            onPick: onPick,
          ),
        ],
      ),
    );
  }
}

/// The empty spot: a gold-edged tile with a "?" that gently pulses.
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) =>
          Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.iconGoldLight,
                  borderRadius: BorderRadius.circular(c.maxHeight * 0.18),
                  border: Border.all(color: AppColors.iconGold, width: 4),
                ),
                child: FittedBox(
                  child: Padding(
                    padding: EdgeInsets.all(c.maxHeight * 0.12),
                    child: const AppText.h1('?', color: AppColors.cocoa),
                  ),
                ),
              )
              .animate(onPlay: (a) => a.repeat(reverse: true))
              .scaleXY(end: 1.06, duration: 700.ms, curve: Curves.easeInOut),
    );
  }
}

/// One Coptic letter of the word. The one put in the gap is green; the
/// whole word glows green once done.
class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.placed,
    required this.glow,
  });

  final CopticLetter letter;
  final bool placed;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final green = placed || glow;
    final face = LayoutBuilder(
      builder: (context, c) => AnimatedContainer(
        duration: AppDimens.normal,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: green ? AppColors.cubeRight : AppColors.cube,
          borderRadius: BorderRadius.circular(c.maxHeight * 0.18),
          border: Border.all(
            color: green ? AppColors.correct : AppColors.cubeBorder,
            width: green ? 5 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: glow ? AppColors.correct : AppColors.shadow,
              blurRadius: glow ? 12 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          child: Padding(
            padding: EdgeInsets.all(c.maxHeight * 0.1),
            child: CopticText.h1(letter.small, color: AppColors.coptic),
          ),
        ),
      ),
    );
    if (!placed) return face;
    // Pops in as the buddy puts it.
    return face.animate().scale(
      begin: const Offset(0.4, 0.4),
      duration: AppDimens.normal,
      curve: Curves.easeOutBack,
    );
  }
}

/// The sound put under the missing letter.
class _SoundBox extends StatelessWidget {
  const _SoundBox({required this.sound, required this.lang});

  final String sound;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) =>
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cubeRight,
              borderRadius: BorderRadius.circular(c.maxHeight * 0.2),
              border: Border.all(color: AppColors.correct, width: 4),
            ),
            child: FittedBox(
              child: Padding(
                padding: EdgeInsets.all(c.maxHeight * 0.08),
                child: SoundFace(sound: sound, lang: lang),
              ),
            ),
          ).animate().scale(
            begin: const Offset(0.4, 0.4),
            duration: AppDimens.normal,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

/// The wooden name plate with the word.
class _NamePlate extends StatelessWidget {
  const _NamePlate({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceLg,
        vertical: AppDimens.spaceXs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.namePlateLight, AppColors.namePlate],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.correct, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AppText.h2(
        text,
        color: AppColors.iconGoldLight,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The current choice's options: Coptic letters, then sounds. A wrong pick
/// turns red, shakes and stays out; one a hint took away fades out.
class _Options extends StatelessWidget {
  const _Options({
    required this.question,
    required this.lang,
    required this.size,
    required this.enabled,
    required this.onPick,
  });

  final GapQuestion question;
  final String lang;
  final double size;
  final bool enabled;
  final void Function(int option) onPick;

  @override
  Widget build(BuildContext context) {
    final q = question;
    // Once the word is done the sounds stay, the right one green.
    final letters = q.step == GapStep.letter;
    final count = letters ? q.letterOptions.length : q.soundOptions.length;
    return Directionality(
      textDirection: letters ? TextDirection.ltr : Directionality.of(context),
      child: Row(
        key: ValueKey(q.step == GapStep.letter),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spaceSm,
              ),
              child: _Option(
                size: size,
                mark: q.markAt(i),
                right: q.done && q.soundOptions[i] == q.sound,
                onTap: enabled && q.markAt(i) == OptionMark.none
                    ? () => onPick(i)
                    : null,
                child: letters
                    ? CopticText.h1(
                        q.letterOptions[i].small,
                        color: AppColors.coptic,
                      )
                    : SoundFace(sound: q.soundOptions[i], lang: lang),
              ),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.size,
    required this.mark,
    required this.right,
    required this.onTap,
    required this.child,
  });

  final double size;
  final OptionMark mark;
  final bool right;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wrong = mark == OptionMark.wrong;
    Widget face = AnimatedContainer(
      duration: AppDimens.fast,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: right
            ? AppColors.cubeRight
            : wrong
            ? AppColors.cubeWrong
            : AppColors.cube,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(
          color: right
              ? AppColors.correct
              : wrong
              ? AppColors.wrong
              : AppColors.iconGold,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: onTap == null ? 2 : 6,
            offset: Offset(0, onTap == null ? 1 : 4),
          ),
        ],
      ),
      child: FittedBox(
        child: Padding(padding: EdgeInsets.all(size * 0.1), child: child),
      ),
    );
    if (wrong) {
      face = face.animate().shake(hz: 5, offset: const Offset(4, 0));
    }
    return AnimatedOpacity(
      duration: AppDimens.normal,
      opacity: mark == OptionMark.hidden ? 0.15 : 1,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: face),
      ),
    );
  }
}
