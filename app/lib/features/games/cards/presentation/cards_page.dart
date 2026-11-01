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
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/domain/character_reaction.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/characters/presentation/speech_bubble.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../../../letters/domain/letter_repository.dart';
import '../../../levels/domain/game_level.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../progress/domain/timed_record.dart';
import '../../shell/domain/game_timers.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../data/cards_config_repository.dart';
import '../domain/card_grid.dart';
import '../domain/cards_config.dart';
import '../domain/cards_mode.dart';
import '../domain/memory_card.dart';
import 'cards_cubit.dart';
import 'cards_hud.dart';
import 'cards_result.dart';
import 'cards_share_card.dart';
import 'flip_card.dart';
import 'seaside_background.dart';

/// Who plays Grandpa's Cards, with how many cards and which pairs.
class CardsArgs {
  const CardsArgs({
    required this.setup,
    required this.count,
    this.mode = CardsMode.letters,
  });

  final PlayerSetup setup;
  final int count;
  final CardsMode mode;
}

/// Grandpa's Cards' picker page for [mode].
String cardsPickerRoute(CardsMode mode) => switch (mode) {
  CardsMode.letters => AppRoutes.cards,
  CardsMode.sounds => AppRoutes.soundCards,
};

/// Grandpa's Cards, by the sea in Alexandria: find each letter's capital
/// and small card (Level 2: each letter card and its sounds card). On big screens the brothers stand on either side; the
/// child's buddy runs to every card tapped (it turns when he gets there)
/// and the other brother says the letter's name and cheers the pairs. On
/// small screens the buddy only pops in from the edge to turn the card and
/// the name shows in a bubble on the other side.
class CardsPage extends StatefulWidget {
  const CardsPage({super.key, required this.args});

  final CardsArgs args;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
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
  late final Future<(CardsConfig, List<CopticLetter>)> _content = (
    sl<CardsConfigRepository>().load(),
    sl<LetterRepository>().allLetters(),
  ).wait;

  CardsConfig? _config;
  List<CopticLetter> _alphabet = const [];
  CardsCubit? _cubit;

  /// The card the buddy is going to or standing at (null: at home).
  int? _heroAt;

  /// The buddy is on his way to a card: taps wait.
  bool _busy = false;

  /// Bumped on every move, so an old "go home" doesn't cut in.
  int _moveToken = 0;

  /// The buddy faces left (he's drawn facing right).
  bool _heroFacesLeft = false;

  /// Small screens: the side the buddy came in from (and goes back to),
  /// the card whose row he runs along, and a key bumped each time he comes
  /// in again (so he starts off-screen instead of gliding across).
  bool _heroFromLeft = true;
  int _heroRow = 0;
  int _entry = 0;

  /// Small screens: the letter name bubble and the card it belongs to.
  (String, int)? _nameBubble;
  Timer? _nameTimer;

  bool _showResult = false;
  TimedRecord? _bestBefore;

  /// The picture to share, drawn as soon as the board is solved.
  Future<Uint8List>? _card;
  final GameTimers _timers = GameTimers();
  final Random _random = Random();

  int get _count => widget.args.count;
  CardsMode get _mode => widget.args.mode;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.alexandria);
    _content.then((c) async {
      if (!mounted) return;
      final (config, alphabet) = c;
      await Future.wait([
        for (final path in [config.background, config.cardBack])
          if (path != null)
            precacheImage(AssetImage(path), context, onError: (_, _) {}),
      ]);
      if (!mounted) return;
      _config = config;
      _alphabet = alphabet;
      _start();
    });
  }

  void _start() {
    _timers.cancelAll();
    _nameTimer?.cancel();
    _cubit?.close();
    final config = _config!;
    final progress = sl<GameProgressRepository>();
    _bestBefore = progress.bestTime(_mode.id, '$_count');
    final cubit = CardsCubit(
      progress,
      mode: _mode,
      languageCode: () => Localizations.localeOf(context).languageCode,
      cards: dealCards(
        alphabet: _alphabet,
        count: _count,
        mode: _mode,
        soundless: config.soundless,
        random: _random,
      ),
    );
    setState(() {
      _cubit = cubit;
      _heroAt = null;
      _heroRow = 0;
      _entry++;
      _busy = false;
      _nameBubble = null;
      _showResult = false;
      _card = null;
    });
    _hero.idle();
    _other.idle();
    _sound.play(SoundEvent.levelStart);
    _later(const Duration(milliseconds: 500), () {
      if (_small) return;
      final name = widget.args.setup.name;
      _hero.say(switch (_mode) {
        CardsMode.letters => context.l10n.cardsStart(name),
        CardsMode.sounds => context.l10n.soundCardsStart(name),
      });
    });
  }

  @override
  void dispose() {
    _timers.cancelAll();
    _nameTimer?.cancel();
    _hero.dispose();
    _other.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.later(d, () {
    if (mounted) f();
  });

  bool get _small =>
      _config?.isSmallScreen(MediaQuery.sizeOf(context).shortestSide) ?? false;

  // ---------------------------------------------------------------------------
  // The buddy and the cards
  // ---------------------------------------------------------------------------

  /// Layout of the last build, for working out where the buddy runs.
  _Layout? _layout;

  void _onCardTap(int i) {
    final cubit = _cubit, layout = _layout;
    if (cubit == null || layout == null) return;
    if (_busy || !cubit.state.canFlip(i)) return;
    _busy = true;
    final token = ++_moveToken;
    if (layout.small && _heroAt == null) {
      // Pop in from the nearest edge, level with the card: put him just off
      // that edge first (no animation), then run in on the next frame.
      setState(() {
        _heroFromLeft = layout.cards[i].center.dx < layout.size.width / 2;
        _heroRow = i;
        _entry++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && token == _moveToken) _runTo(i, token);
      });
      return;
    }
    _runTo(i, token);
  }

  void _runTo(int i, int token) {
    final layout = _layout!;
    final from = layout.heroRect(
      _heroAt,
      fromLeft: _heroFromLeft,
      row: _heroRow,
    );
    final to = layout.heroRect(i, fromLeft: _heroFromLeft);
    _hero
      ..hideSpeech()
      ..play(CharacterAction.run);
    _sound.play(SoundEvent.charRun, by: _heroId);
    setState(() {
      _heroAt = i;
      _heroRow = i;
      if ((to.center.dx - from.center.dx).abs() > 1) {
        _heroFacesLeft = to.center.dx < from.center.dx;
      }
    });
    _later(_config!.heroRun, () {
      if (token != _moveToken) return;
      _busy = false;
      _hero.play(CharacterAction.hint);
      _cubit?.flip(i);
      // Back home after a moment, unless another card is tapped first.
      _later(const Duration(milliseconds: 700), () {
        if (token != _moveToken || _cubit?.state.solved == true) return;
        _goHome();
      });
    });
  }

  void _goHome() {
    final layout = _layout;
    if (layout == null || _heroAt == null) return;
    final token = ++_moveToken;
    final from = layout.heroRect(_heroAt, fromLeft: _heroFromLeft);
    final to = layout.heroRect(null, fromLeft: _heroFromLeft, row: _heroRow);
    _hero.play(CharacterAction.run);
    setState(() {
      _heroAt = null;
      _heroFacesLeft = to.center.dx < from.center.dx;
    });
    _later(_config!.heroRun, () {
      if (token != _moveToken) return;
      // At home, face the table again.
      setState(() => _heroFacesLeft = layout.heroHomeOnRight);
      _hero.idle();
    });
  }

  void _showName(int cardIndex) {
    final config = _config!;
    final lang = Localizations.localeOf(context).languageCode;
    final card = _cubit!.state.cards[cardIndex];
    // A sound card says nothing: the child works out whose sound it is.
    if (card.face == CardFace.sound) return;
    final name = card.letter.nameIn(lang);
    if (!_small) {
      _other.say(name, duration: config.nameBubble);
      return;
    }
    _nameTimer?.cancel();
    setState(() => _nameBubble = (name, cardIndex));
    _nameTimer = Timer(config.nameBubble, () {
      if (mounted) setState(() => _nameBubble = null);
    });
  }

  void _onEvent(BuildContext context, CardsState state) {
    final config = _config!;
    final at = state.lastFlipped;
    if (state.event != CardsEvent.none) {
      _sound.playKey('memory.card_flip');
      if (at != null) _showName(at);
    }
    switch (state.event) {
      case CardsEvent.none || CardsEvent.flipped:
        break;
      case CardsEvent.match:
        _sound.playKey('memory.card_match');
        if (_small) {
          _sound.play(SoundEvent.correctAnswer);
        } else {
          _other.react(CharacterReaction.correct);
        }
      case CardsEvent.mismatch:
        _sound.playKey('memory.card_mismatch');
        if (!_small) {
          _other.play(
            CharacterAction.encourage,
            hold: const Duration(milliseconds: 1200),
          );
        }
        _later(config.mismatchShow, () => _cubit?.hideMismatch());
      case CardsEvent.solved:
        _sound.playKey('memory.card_match');
        _later(const Duration(milliseconds: 600), () {
          _goHome();
          if (_small) {
            _sound.play(SoundEvent.levelComplete);
          } else {
            _hero.react(CharacterReaction.celebrate);
            _other.react(CharacterReaction.celebrate);
          }
        });
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

  void _otherLevel() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(cardsPickerRoute(_mode));
    }
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level(widget.args.setup.level));
  }

  Future<Uint8List> _buildShareCard() {
    final l10n = context.l10n;
    final state = _cubit!.state;
    final lang = Localizations.localeOf(context).languageCode;
    final heroName = _heroId == CharacterId.nono ? l10n.nono : l10n.fofo;
    final roster = context.read<CharacterRoster>();
    return CardsShareCard(
      title: l10n.cardsShareTitle(widget.args.setup.name, _count),
      time: formatClock(state.solvedIn!),
      timeLabel: l10n.cardsTime,
      moves: '${state.moves}',
      movesLabel: l10n.cardsMoves,
      badge: state.newRecord ? l10n.cardsNewRecord : null,
      subtitle: l10n.cardsShareWith(heroName),
      appTitle: l10n.appTitle,
      script: lang == 'ar' ? AppScript.arabic : AppScript.english,
      direction: Directionality.of(context),
      heroAssets: [
        for (final id in [_heroId, _heroId.other])
          ?roster.pose(id, CharacterAction.celebrate)?.asset,
      ],
    ).render();
  }

  Future<void> _share(Rect origin) async {
    _sound.play(SoundEvent.tap);
    final l10n = context.l10n;
    final state = _cubit!.state;
    final text = l10n.cardsShareText(
      widget.args.setup.name,
      _count,
      formatClock(state.solvedIn!),
      state.moves,
    );
    final fileName = 'nono-fofo-${_mode.id}-$_count.png';
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
    final config = _config;
    return GameScaffold(
      title: l10n.gameCards,
      onPause: () {
        _timers.pause();
        cubit?.pauseClock();
      },
      onResume: () {
        _timers.resume();
        cubit?.resumeClock();
      },
      actions: [
        GameAction(
          icon: AppIcons.cards,
          label: (l) => l.cardsOtherLevel,
          onPressed: _otherLevel,
        ),
      ],
      body: cubit == null || config == null
          ? const Center(child: CircularProgressIndicator())
          : BlocConsumer<CardsCubit, CardsState>(
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

  Widget _scene(Size size, CardsState state, CardsConfig config) {
    final roster = context.read<CharacterRoster>();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layout = _Layout.of(
      size: size,
      count: state.cards.length,
      small: _small,
      rtl: rtl,
      roster: roster,
      hero: _heroId,
    );
    _layout = layout;
    final heroRect = layout.heroRect(
      _heroAt,
      fromLeft: _heroFromLeft,
      row: _heroRow,
    );
    final back = config.cardBack == null ? null : AssetImage(config.cardBack!);
    final bubble = _nameBubble;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: SeasideBackground(
            image: config.background == null
                ? null
                : AssetImage(config.background!),
          ),
        ),
        Positioned(
          top: AppDimens.spaceSm,
          left: 0,
          right: 0,
          height: _Layout.hudH - AppDimens.spaceSm * 2,
          child: Center(
            child: FittedBox(
              child: CardsHud(
                elapsed: () => _cubit?.elapsed ?? Duration.zero,
                running: state.started && !state.solved,
                moves: state.moves,
                pairsFound: state.pairsFound,
                pairs: state.cards.length ~/ 2,
              ),
            ),
          ),
        ),
        for (final (i, card) in state.cards.indexed)
          Positioned.fromRect(
            rect: layout.cards[i],
            child: FlipCard(
              key: ValueKey(i),
              card: card,
              back: back,
              onTap: state.canFlip(i) ? () => _onCardTap(i) : null,
            ),
          ),
        if (!layout.small) layout.place(_other, layout.otherHome, !rtl),
        AnimatedPositioned.fromRect(
          key: ValueKey(_entry),
          rect: heroRect,
          duration: config.heroRun,
          curve: Curves.easeInOut,
          child: IgnorePointer(
            child: FittedBox(
              alignment: Alignment.bottomCenter,
              child: AnimatedCharacter(
                controller: _hero,
                size: layout.heroDrawSize,
                mirror: _heroAt == null && !layout.small
                    ? layout.heroHomeOnRight
                    : _heroFacesLeft,
              ),
            ),
          ),
        ),
        if (layout.small && bubble != null)
          _smallBubble(layout, bubble.$1, bubble.$2),
        if (_showResult && state.solved)
          Positioned.fill(
            child: CardsResult(
              count: _count,
              time: state.solvedIn!,
              moves: state.moves,
              best: state.newRecord ? null : _bestBefore,
              newRecord: state.newRecord,
              onPlayAgain: _playAgain,
              onOtherLevel: _otherLevel,
              onBackToGames: _backToGames,
              onShare: _share,
            ),
          ),
      ],
    );
  }

  /// The letter name, on the side away from the card so it hides nothing
  /// the child needs.
  Widget _smallBubble(_Layout layout, String name, int cardIndex) {
    final card = layout.cards[cardIndex];
    final onLeft = card.center.dx > layout.size.width / 2;
    const gap = AppDimens.spaceSm;
    final top = (card.center.dy - 24)
        .clamp(_Layout.hudH, max(_Layout.hudH, layout.size.height - 64))
        .toDouble();
    return Positioned(
      top: top,
      left: onLeft ? gap : null,
      right: onLeft ? null : gap,
      child: IgnorePointer(
        child: SpeechBubble(key: ValueKey(name), text: name, showTail: false),
      ),
    );
  }
}

/// Where everything goes on this screen: the cards, the brothers' homes
/// and the spot beside a card where the buddy stands to turn it.
class _Layout {
  _Layout._({
    required this.size,
    required this.small,
    required this.rtl,
    required this.cards,
    required this.cardSize,
    required this.heroHome,
    required this.otherHome,
    required this.heroDrawSize,
    required this.roster,
    required this.hero,
  });

  factory _Layout.of({
    required Size size,
    required int count,
    required bool small,
    required bool rtl,
    required CharacterRoster roster,
    required CharacterId hero,
  }) {
    const gap = AppDimens.spaceSm;
    final ref = roster.referenceHeight;
    double idleW(CharacterId id) =>
        roster.pose(id, CharacterAction.idle)?.width ?? ref * 0.4;
    double idleH(CharacterId id) =>
        roster.pose(id, CharacterAction.idle)?.height ?? ref;

    // Big screens keep a strip on each side for a brother.
    final sideW = small ? 0.0 : (size.width * 0.17).clamp(110.0, 260.0);
    final area = Rect.fromLTRB(
      sideW + gap,
      hudH,
      size.width - sideW - gap,
      size.height - gap,
    );
    final grid = CardGrid.fit(count, area.size, maxCardWidth: 170);
    final cards = [
      for (var i = 0; i < count; i++)
        grid.cardRect(i, count, rtl: rtl).shift(area.topLeft),
    ];

    // Standing brothers: as tall as fits their strip.
    final widest = max(idleW(hero), idleW(hero.other));
    final charSize = small
        ? 0.0
        : min(size.height * 0.6, (sideW - gap) * ref / widest);
    Rect standing(CharacterId id, bool startSide) {
      final k = charSize / ref;
      final w = idleW(id) * k, h = idleH(id) * k;
      final cx = startSide ? sideW / 2 : size.width - sideW / 2;
      final x = rtl ? size.width - cx : cx;
      return Rect.fromLTWH(x - w / 2, size.height - gap - h, w, h);
    }

    return _Layout._(
      size: size,
      small: small,
      rtl: rtl,
      cards: cards,
      cardSize: grid.cardSize,
      heroHome: small ? Rect.zero : standing(hero, true),
      otherHome: small ? Rect.zero : standing(hero.other, false),
      heroDrawSize: small
          ? (grid.cardSize.height * 1.6).clamp(80.0, 180.0)
          : charSize,
      roster: roster,
      hero: hero,
    );
  }

  static const double hudH = 60;

  final Size size;
  final bool small;
  final bool rtl;
  final List<Rect> cards;
  final Size cardSize;
  final Rect heroHome;
  final Rect otherHome;

  /// The size the buddy is drawn at (then scaled to fit his spot).
  final double heroDrawSize;
  final CharacterRoster roster;
  final CharacterId hero;

  /// The buddy's home strip is on the right (Arabic).
  bool get heroHomeOnRight => rtl;

  /// The buddy's box when standing at card [at] (null: at home). On small
  /// screens home is just off the edge he came in from ([fromLeft]), level
  /// with card [row].
  Rect heroRect(int? at, {bool fromLeft = true, int row = 0}) {
    final ref = roster.referenceHeight;
    final idle = roster.pose(hero, CharacterAction.idle);
    final aspect = idle == null ? 0.4 : idle.width / idle.height;
    final heightAtCard = small
        ? heroDrawSize * (idle?.height ?? ref) / ref
        : min(
            (cardSize.height * 1.5).clamp(70.0, double.infinity),
            heroHome.height,
          );
    final w = heightAtCard * aspect;
    if (at == null) {
      if (!small) return heroHome;
      final card = cards.isEmpty
          ? Rect.zero
          : cards[row.clamp(0, cards.length - 1)];
      final top = card.bottom - heightAtCard;
      return Rect.fromLTWH(
        fromLeft ? -w - 20 : size.width + 20,
        top,
        w,
        heightAtCard,
      );
    }
    final card = cards[at];
    // Stand beside the card, on the side he comes from, feet on its
    // bottom edge, a little over it so he seems to reach for it.
    final left = small ? fromLeft : heroHome.center.dx < card.center.dx;
    final x = left ? card.left - w * 0.6 : card.right - w * 0.4;
    return Rect.fromLTWH(
      x.clamp(-w * 0.3, size.width - w * 0.7),
      (card.bottom - heightAtCard).clamp(0.0, size.height - heightAtCard),
      w,
      heightAtCard,
    );
  }

  /// A standing brother at [rect], facing left when [facesLeft].
  Widget place(CharacterController c, Rect rect, bool facesLeft) =>
      Positioned.fromRect(
        rect: rect,
        child: FittedBox(
          alignment: Alignment.bottomCenter,
          child: AnimatedCharacter(
            controller: c,
            size: heroDrawSize,
            mirror: facesLeft,
          ),
        ),
      );
}
