import 'dart:math';

import 'package:flutter/gestures.dart';
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
import '../../letter_hunt/presentation/letter_hunt_result.dart';
import '../../letter_puzzle/data/letter_puzzle_config_repository.dart';
import '../../letter_puzzle/domain/letter_puzzle_config.dart';
import '../../letter_puzzle/presentation/letter_puzzle_cubit.dart';
import '../../letter_puzzle/presentation/letter_puzzle_page.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../shell/domain/game_timers.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../../snakes_ladders/presentation/pyramids_background.dart';
import '../data/match_letters_config_repository.dart';
import '../domain/match_board.dart';
import '../domain/match_letters_config.dart';
import 'match_letters_cubit.dart';
import 'sound_face.dart';

/// Match the letters, by the Pyramids. The word shows on a name plate
/// (Arabic, or English in English); under it the word's Coptic letters go
/// down one column and what each sounds like in the word goes down the
/// other, shuffled. The child draws a line from each letter to its sound
/// (or taps one, then the other); the buddy runs over and draws it. Once
/// every letter has a line the lines are checked: right ones turn green and
/// stay, wrong ones turn red and go. On big screens the other brother
/// stands in the far corner and reacts; on phones the buddy only comes in
/// to draw a line.
class MatchLettersPage extends StatefulWidget {
  const MatchLettersPage({super.key, required this.args});

  /// Same as the Letter puzzle: who plays, and the word length.
  final LetterPuzzleArgs args;

  @override
  State<MatchLettersPage> createState() => _MatchLettersPageState();
}

class _MatchLettersPageState extends State<MatchLettersPage> {
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
  late final Future<
    (MatchLettersConfig, LetterPuzzleConfig, List<CopticLetter>)
  >
  _content = (
    sl<MatchLettersConfigRepository>().load(),
    sl<LetterPuzzleConfigRepository>().load(),
    sl<LetterRepository>().allLetters(),
  ).wait;

  MatchLettersConfig? _config;
  LetterPuzzleConfig? _words;
  Map<String, CopticLetter> _alphabet = const {};
  MatchLettersCubit? _cubit;
  bool _showResult = false;
  final GameTimers _timers = GameTimers();
  final Random _random = Random();

  /// Phones: no brothers standing, the board gets the whole screen.
  static const double _smallScreen = 600;

  /// How long the buddy takes to run to a row (or back).
  static const Duration _heroRun = Duration(milliseconds: 450);

  /// How long the buddy waits by a row before going back.
  static const Duration _heroStay = Duration(milliseconds: 800);

  /// The row the buddy ran to (null: in his corner, or off screen).
  int? _heroAt;

  /// The row he was last level with (where he comes in on a phone).
  int _heroRow = 0;

  /// Bumped to put him somewhere without running (a phone's edge).
  int _heroEntry = 0;

  /// Bumped on every run, so an old "arrived" or "go home" doesn't cut in.
  int _moveToken = 0;

  /// A row whose new line shows once the buddy gets there.
  int? _waitingRow;

  /// The lines as of the last event, to see which row just got one.
  List<int?> _lastLinks = const [];
  int _lastIndex = -1;

  /// The game area and the match area, for working out where he runs.
  final GlobalKey _stageKey = GlobalKey();
  final GlobalKey _areaKey = GlobalKey();
  _AreaGeometry? _geometry;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.pyramids);
    _content.then((c) {
      if (!mounted) return;
      final (config, words, letters) = c;
      _config = config;
      _words = words;
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
      // Only words that have a sound for every letter.
      pool: [
        for (final w in _words!.poolFor(_lang!, widget.args.length))
          if (w.sounds.length == w.letters.length) w,
      ],
      alphabet: _alphabet,
      count: config.wordsPerRound,
      random: _random,
    );
    if (items.isEmpty) return;
    setState(() {
      _cubit = MatchLettersCubit(
        sl<GameProgressRepository>(),
        config: config,
        length: widget.args.length,
        items: items,
        random: _random,
      );
      _showResult = false;
      _heroAt = null;
      _waitingRow = null;
      _lastLinks = const [];
      _lastIndex = -1;
    });
    _moveToken++;
    _hero.idle();
    _other.idle();
    _sound.play(SoundEvent.levelStart);
    _later(const Duration(milliseconds: 500), () {
      if (!_small) {
        _hero.say(context.l10n.matchLettersStart(widget.args.setup.name));
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

  void _onEvent(BuildContext context, MatchLettersState state) {
    final l10n = context.l10n;
    final config = _config!;
    _followLines(state);
    switch (state.event) {
      case MatchLettersEvent.none:
        break;
      case MatchLettersEvent.linked || MatchLettersEvent.hint:
        if (state.event == MatchLettersEvent.hint) {
          _sound.play(SoundEvent.hintRevealed);
          if (!_small) {
            _hero.say(
              l10n.matchLettersHintSay,
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          _sound.play(SoundEvent.select);
        }
        // The last line: check once the buddy has drawn it.
        if (state.board.full && !state.board.solved) {
          final index = state.index;
          _later(_heroRun + config.checkDelay, () {
            if (_cubit?.state.index == index) _cubit?.check();
          });
        }
      case MatchLettersEvent.wrong:
        if (_small) {
          _sound.play(SoundEvent.wrongAnswer);
        } else {
          _hero.hideSpeech();
          _other.react(CharacterReaction.wrong, say: l10n.matchLettersWrong);
        }
        _later(config.redFor, () => _cubit?.clearWrong());
      case MatchLettersEvent.wordDone:
        if (_small) {
          _sound.play(SoundEvent.correctAnswer);
        } else {
          _hero.hideSpeech();
          _hero.play(CharacterAction.cheer, hold: config.wordDoneFor);
          _other.react(CharacterReaction.correct, say: l10n.letterPuzzleRight);
        }
        _later(config.wordDoneFor, () => _cubit?.next());
      case MatchLettersEvent.finished:
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

  /// A row just got a line (drawn, or a hint): the buddy runs there and the
  /// line shows when he arrives. A new word sends him back.
  void _followLines(MatchLettersState state) {
    final links = state.board.links;
    // A new word starts with no lines.
    final sameWord = state.index == _lastIndex;
    final before = sameWord
        ? _lastLinks
        : List<int?>.filled(links.length, null);
    int? drawn;
    for (var i = 0; i < links.length; i++) {
      if (links[i] != null && links[i] != before[i]) {
        drawn = i;
        break;
      }
    }
    _lastLinks = links;
    _lastIndex = state.index;
    if (drawn != null) {
      _comeTo(drawn);
    } else if (!sameWord) {
      _goHome();
    }
  }

  /// Runs to [row]; on a phone he first pops just off his edge, level with
  /// the row, so he runs straight in.
  void _comeTo(int row) {
    if (_small && _heroAt == null) {
      final token = ++_moveToken;
      setState(() {
        _heroRow = row;
        _heroEntry++;
        _waitingRow = row;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && token == _moveToken) _runTo(row);
      });
      return;
    }
    _runTo(row);
  }

  void _runTo(int row) {
    final token = ++_moveToken;
    _hero
      ..hideSpeech()
      ..play(CharacterAction.run);
    _sound.play(SoundEvent.charRun, by: _heroId);
    setState(() {
      _heroAt = row;
      _heroRow = row;
      _waitingRow = row;
    });
    _later(_heroRun, () {
      if (token != _moveToken) return;
      setState(() => _waitingRow = null);
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
      _waitingRow = null;
    });
    _later(_heroRun, () {
      if (token == _moveToken) _hero.idle();
    });
  }

  /// Layout of the last build, for the buddy's spots.
  ({Size size, double charSize, bool rtl, bool small})? _layout;

  /// The buddy's box: in his corner (on a phone: just off his edge, level
  /// with row [_heroRow]), or beside row [row]'s line on his side of the
  /// board.
  /// Null before the first layout.
  Rect? _heroRect(int? row) {
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
    // On the left he stands by the letter; on the right, by the sound its
    // line goes to.
    final at = row ?? _heroRow;
    final tile = _tileRect(
      onLeft ? at : _cubit?.state.board.links.elementAtOrNull(at) ?? at,
      left: onLeft,
    );
    if (tile == null) return layout.small ? null : home;
    final h = (tile.height * 2.1).clamp(80.0, max(80.0, homeH)).toDouble();
    final w = h * aspect;
    final y = (tile.center.dy - h * 0.45)
        .clamp(0.0, max(0.0, layout.size.height - h))
        .toDouble();
    if (row == null) {
      if (!layout.small) return home;
      // Just off his edge.
      return Rect.fromLTWH(onLeft ? -w - 20 : layout.size.width + 20, y, w, h);
    }
    final x = onLeft ? tile.left - w * 0.9 : tile.right - w * 0.1;
    return Rect.fromLTWH(
      x.clamp(-w * 0.3, layout.size.width - w * 0.7),
      y,
      w,
      h,
    );
  }

  /// Where row [row]'s letter (left) or sound tile is on the game area.
  Rect? _tileRect(int row, {required bool left}) {
    final g = _geometry;
    final area = _areaKey.currentContext?.findRenderObject();
    final stage = _stageKey.currentContext?.findRenderObject();
    if (g == null ||
        row >= g.rows ||
        area is! RenderBox ||
        stage is! RenderBox ||
        !area.attached) {
      return null;
    }
    final local = left ? g.letterRect(row) : g.soundRect(row);
    return Rect.fromPoints(
      area.localToGlobal(local.topLeft, ancestor: stage),
      area.localToGlobal(local.bottomRight, ancestor: stage),
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
      context.go(AppRoutes.matchLetters);
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
      title: context.l10n.gameMatchLetters,
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
          const Positioned.fill(child: PyramidsBackground()),
          if (cubit == null)
            const Center(child: CircularProgressIndicator())
          else
            Positioned.fill(
              child: BlocConsumer<MatchLettersCubit, MatchLettersState>(
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

  Widget _screen(Size size, MatchLettersState state) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final small = _small;
    const hudH = 60.0;
    final charSize = small ? 0.0 : min(size.height * 0.32, 230.0);
    // Room for a brother at each side, wide enough for his speech bubble.
    final side = small ? AppDimens.spaceSm : _cornerWidth + AppDimens.spaceSm;
    final boardW = min(size.width - side * 2, 760.0);
    _layout = (size: size, charSize: charSize, rtl: rtl, small: small);
    final geometry = _AreaGeometry.fit(
      rows: state.board.length,
      width: boardW - AppDimens.spaceMd * 2,
      // The name plate, the Coptic word, the panel's texts and padding.
      height: size.height - hudH - AppDimens.spaceSm - 250,
    );
    _geometry = geometry;

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
                  geometry: geometry,
                  areaKey: _areaKey,
                  showHowTo: state.index == 0,
                  waitingRow: _waitingRow,
                  onLink: (row, sound) => _cubit?.link(row, sound),
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

  /// The buddy: in his corner (off screen on a phone), or beside the row
  /// he's drawing a line for. He always stands on his own side, facing the
  /// board.
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

/// Where everything sits in the match area: letter tiles down the left,
/// sound tiles down the right (a little wider, for a haraka and its name),
/// a dot beside each on the inner side, and room for lines between.
class _AreaGeometry {
  const _AreaGeometry({
    required this.rows,
    required this.tile,
    required this.width,
  });

  /// Tiles as big as fit [height] (between [_minTile] and [_maxTile]), in
  /// an area at most [width] wide.
  factory _AreaGeometry.fit({
    required int rows,
    required double width,
    required double height,
  }) {
    final byHeight = height / max(rows, 1) / _rowFactor;
    final tile = byHeight.clamp(_minTile, _maxTile).toDouble();
    return _AreaGeometry(
      rows: rows,
      tile: tile,
      width: min(width, tile * 2.4 + _dotGap * 4 + _maxLines),
    );
  }

  static const double _minTile = 44;
  static const double _maxTile = 74;

  /// Row height as a share of the tile.
  static const double _rowFactor = 1.22;

  /// Space between a tile and its dot's center.
  static const double _dotGap = 18;
  static const double dotRadius = 9;

  /// Widest the lines' gap gets.
  static const double _maxLines = 300;

  final int rows;
  final double tile;
  final double width;

  double get rowHeight => tile * _rowFactor;
  double get height => rowHeight * rows;
  double get soundWidth => tile * 1.4;

  double _top(int row) => row * rowHeight + (rowHeight - tile) / 2;

  Rect letterRect(int row) => Rect.fromLTWH(0, _top(row), tile, tile);

  Rect soundRect(int row) =>
      Rect.fromLTWH(width - soundWidth, _top(row), soundWidth, tile);

  Offset letterDot(int row) => Offset(tile + _dotGap, _top(row) + tile / 2);

  Offset soundDot(int row) =>
      Offset(width - soundWidth - _dotGap, _top(row) + tile / 2);

  /// Where a touch at [p] lands: a letter row (left) or a sound, counting
  /// the tile, its dot and the space around them.
  ({bool left, int index})? hit(Offset p) {
    if (p.dy < 0 || p.dy >= height) return null;
    final row = (p.dy / rowHeight).floor();
    final reach = _dotGap + dotRadius * 2;
    if (p.dx <= tile + reach) return (left: true, index: row);
    if (p.dx >= width - soundWidth - reach) return (left: false, index: row);
    return null;
  }
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

/// The name plate with the word (and its Coptic spelling once matched),
/// and the panel with the two columns.
class _Board extends StatelessWidget {
  const _Board({
    super.key,
    required this.state,
    required this.geometry,
    required this.areaKey,
    required this.showHowTo,
    required this.waitingRow,
    required this.onLink,
  });

  final MatchLettersState state;
  final _AreaGeometry geometry;
  final GlobalKey areaKey;
  final bool showHowTo;

  /// A row whose line waits for the buddy to draw it.
  final int? waitingRow;
  final void Function(int row, int sound) onLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final board = state.board;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NamePlate(text: state.item.word.text, solved: board.solved),
        // The Coptic spelling shows here once every line is right.
        SizedBox(
          height: 52,
          child: board.solved
              ? Center(
                  child:
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.spaceMd,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cubeRight,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.correct,
                                width: 2,
                              ),
                            ),
                            child: CopticText.h2(
                              board.letters.map((l) => l.small).join(),
                              color: AppColors.coptic,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: AppDimens.normal)
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            curve: Curves.easeOutBack,
                          ),
                )
              : null,
        ),
        // A cream panel, so the tiles and texts read on any background.
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
              AppText.body(l10n.matchLettersDo, color: AppColors.ink),
              const SizedBox(height: AppDimens.spaceSm),
              // Coptic on the left, also in the Arabic app.
              Directionality(
                textDirection: TextDirection.ltr,
                child: _MatchArea(
                  key: areaKey,
                  board: board,
                  geometry: geometry,
                  enabled: state.canPlay,
                  waitingRow: waitingRow,
                  onLink: onLink,
                ),
              ),
              if (showHowTo) ...[
                const SizedBox(height: AppDimens.spaceSm),
                AppText(
                  l10n.matchLettersHowTo,
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

/// The wooden name plate with the word.
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

/// The two columns and the lines between them. Draw a line from a tile
/// (or its dot) to one in the other column, or tap one then the other.
class _MatchArea extends StatefulWidget {
  const _MatchArea({
    super.key,
    required this.board,
    required this.geometry,
    required this.enabled,
    required this.waitingRow,
    required this.onLink,
  });

  final MatchBoard board;
  final _AreaGeometry geometry;
  final bool enabled;
  final int? waitingRow;
  final void Function(int row, int sound) onLink;

  @override
  State<_MatchArea> createState() => _MatchAreaState();
}

class _MatchAreaState extends State<_MatchArea> {
  /// The tile a line is being drawn from (or that was tapped first).
  ({bool left, int index})? _from;

  /// Where the finger is while drawing.
  Offset? _pointer;

  MatchBoard get _board => widget.board;

  @override
  void didUpdateWidget(_MatchArea old) {
    super.didUpdateWidget(old);
    if (!widget.enabled && (_from != null || _pointer != null)) {
      _from = null;
      _pointer = null;
    }
  }

  /// Tiles on a green line can't be picked.
  bool _free(({bool left, int index}) at) =>
      at.left ? !_board.locked[at.index] : !_board.soundLocked(at.index);

  ({bool left, int index})? _hitFree(Offset p) {
    final at = widget.geometry.hit(p);
    return at != null && _free(at) ? at : null;
  }

  /// A line between [a] and [b] (one in each column).
  void _link(({bool left, int index}) a, ({bool left, int index}) b) {
    final row = a.left ? a.index : b.index;
    final sound = a.left ? b.index : a.index;
    widget.onLink(row, sound);
  }

  void _onPanStart(DragStartDetails d) {
    if (!widget.enabled) return;
    final at = _hitFree(d.localPosition);
    setState(() {
      _from = at;
      _pointer = at == null ? null : d.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_from == null) return;
    setState(() => _pointer = d.localPosition);
  }

  void _onPanEnd(DragEndDetails _) {
    final from = _from, to = _pointer == null ? null : _hitFree(_pointer!);
    setState(() {
      _pointer = null;
      // Dropped on its own column: keep it picked, like a tap.
      _from = to != null && to.left == from?.left ? to : null;
    });
    if (from != null && to != null && to.left != from.left) _link(from, to);
  }

  void _onTapUp(TapUpDetails d) {
    if (!widget.enabled) return;
    final at = _hitFree(d.localPosition);
    final from = _from;
    if (at == null) {
      setState(() => _from = null);
    } else if (from == null || from.left == at.left) {
      setState(() => _from = from == at ? null : at);
    } else {
      setState(() => _from = null);
      _link(from, at);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.geometry;
    final board = _board;
    final lang = Localizations.localeOf(context).languageCode;
    return SizedBox(
      width: g.width,
      height: g.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Taps need their position (which tile), so they must come as real
        // pointer events, not as a screen reader's "tap" on the whole area.
        excludeFromSemantics: true,
        // A line starts at the tile the finger went down on.
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapUp: _onTapUp,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < board.length; i++) ...[
                Positioned.fromRect(
                  rect: g.letterRect(i),
                  child: _Tile(
                    mark: board.marks[i],
                    picked: _from == (left: true, index: i),
                    child: CopticText.h1(
                      board.letters[i].small,
                      color: AppColors.coptic,
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: g.soundRect(i),
                  child: _Tile(
                    mark: switch (board.rowOf(i)) {
                      final row? => board.marks[row],
                      null => LineMark.none,
                    },
                    picked: _from == (left: false, index: i),
                    child: SoundFace(sound: board.sounds[i], lang: lang),
                  ),
                ),
              ],
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LinesPainter(
                      board: board,
                      geometry: g,
                      waitingRow: widget.waitingRow,
                      from: _from,
                      pointer: _pointer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A cream tile; its border turns gold when picked, green or red with its
/// line after a check.
class _Tile extends StatelessWidget {
  const _Tile({required this.mark, required this.picked, required this.child});

  final LineMark mark;
  final bool picked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final face = LayoutBuilder(
      builder: (context, c) => AnimatedContainer(
        duration: AppDimens.fast,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: switch (mark) {
            LineMark.right => AppColors.cubeRight,
            LineMark.wrong => AppColors.cubeWrong,
            LineMark.none => picked ? AppColors.iconGoldLight : AppColors.cube,
          },
          borderRadius: BorderRadius.circular(c.maxHeight * 0.18),
          border: Border.all(
            color: switch (mark) {
              LineMark.right => AppColors.correct,
              LineMark.wrong => AppColors.wrong,
              LineMark.none =>
                picked ? AppColors.iconGold : AppColors.cubeBorder,
            },
            width: mark == LineMark.none && !picked ? 3 : 5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: picked ? 10 : 3,
              offset: Offset(0, picked ? 4 : 2),
            ),
          ],
        ),
        child: FittedBox(
          child: Padding(
            padding: EdgeInsets.all(c.maxHeight * 0.1),
            child: child,
          ),
        ),
      ),
    );
    if (mark == LineMark.wrong) {
      return face.animate().shake(hz: 5, offset: const Offset(4, 0));
    }
    if (mark == LineMark.right) {
      return face.animate().scale(
        begin: const Offset(1.12, 1.12),
        duration: AppDimens.normal,
        curve: Curves.easeOutBack,
      );
    }
    return face;
  }
}

/// The dots beside the tiles, the lines between them, and the line being
/// drawn.
class _LinesPainter extends CustomPainter {
  _LinesPainter({
    required this.board,
    required this.geometry,
    required this.waitingRow,
    required this.from,
    required this.pointer,
  });

  final MatchBoard board;
  final _AreaGeometry geometry;
  final int? waitingRow;
  final ({bool left, int index})? from;
  final Offset? pointer;

  static Color _color(LineMark mark) => switch (mark) {
    LineMark.right => AppColors.correct,
    LineMark.wrong => AppColors.wrong,
    LineMark.none => AppColors.deepTeal,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final linked = <int, Color>{}; // sound -> its line's colour
    final rowColor = <int, Color>{};
    for (var row = 0; row < board.length; row++) {
      final sound = board.links[row];
      if (sound == null || row == waitingRow) continue;
      final color = _color(board.marks[row]);
      rowColor[row] = color;
      linked[sound] = color;
      canvas.drawLine(g.letterDot(row), g.soundDot(sound), line..color = color);
    }
    final start = from, end = pointer;
    if (start != null && end != null) {
      canvas.drawLine(
        start.left ? g.letterDot(start.index) : g.soundDot(start.index),
        end,
        line..color = AppColors.iconGold,
      );
    }
    final fill = Paint();
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.cocoa;
    void dot(Offset c, Color? color) {
      canvas
        ..drawCircle(
          c,
          _AreaGeometry.dotRadius,
          fill..color = color ?? AppColors.cube,
        )
        ..drawCircle(c, _AreaGeometry.dotRadius, ring);
    }

    for (var i = 0; i < board.length; i++) {
      dot(g.letterDot(i), rowColor[i]);
      dot(g.soundDot(i), linked[i]);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) =>
      old.board != board ||
      old.waitingRow != waitingRow ||
      old.from != from ||
      old.pointer != pointer ||
      old.geometry.tile != geometry.tile ||
      old.geometry.width != geometry.width;
}
