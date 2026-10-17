import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import '../../../../core/widgets/app_top_bar.dart';
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
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../../progress/domain/timed_record.dart';
import '../data/monastery_config_repository.dart';
import '../domain/hidden_letter.dart';
import '../domain/monastery_config.dart';
import 'letters_bar.dart';
import 'monastery_cubit.dart';
import 'monastery_hud.dart';
import 'monastery_result.dart';
import 'monastery_room.dart';
import 'monastery_scene_view.dart';
import 'monastery_share_card.dart';

/// Who plays Search the Monastery, and how many letters hide.
class MonasteryArgs {
  const MonasteryArgs({required this.setup, required this.count});

  final PlayerSetup setup;
  final int count;
}

/// Search the Monastery: letters hide behind things in a monastery room
/// with only a bit of each showing; the ones to find are listed along the
/// bottom. On big screens both brothers stand small in the bottom corners:
/// the child's buddy runs to every letter found and the other brother says
/// its name (or "Not here!" on a miss). Phones show no brothers; bubbles
/// pop up in the room instead. The room never scrolls: each screen shape
/// gets the room drawn for it (wide or tall).
class MonasteryPage extends StatefulWidget {
  const MonasteryPage({super.key, required this.args});

  final MonasteryArgs args;

  @override
  State<MonasteryPage> createState() => _MonasteryPageState();
}

class _MonasteryPageState extends State<MonasteryPage> {
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
  late final Future<(MonasteryConfig, List<CopticLetter>)> _content = (
    sl<MonasteryConfigRepository>().load(),
    sl<LetterRepository>().allLetters(),
  ).wait;

  MonasteryConfig? _config;
  List<CopticLetter> _alphabet = const [];

  /// The room being played: the one whose shape fits the screen best.
  MonasteryScene? _scene;

  /// A start (in a new room) is waiting for the next frame.
  bool _starting = false;
  MonasteryCubit? _cubit;

  /// The letter the buddy is going to or standing at (null: at home).
  int? _heroAt;

  /// The buddy is on his way to a letter: taps wait.
  bool _busy = false;

  /// Bumped on every move, so an old "go home" doesn't cut in.
  int _moveToken = 0;

  /// The buddy faces left (he's drawn facing right).
  bool _heroFacesLeft = false;

  HintGlow? _hint;
  final List<MissMark> _misses = [];
  int _markId = 0;

  /// Phones: a bubble in the room (letter name or "Not here!").
  SceneBubble? _bubble;
  Timer? _bubbleTimer;

  bool _showResult = false;
  TimedRecord? _bestBefore;

  /// The picture to share, drawn as soon as every letter is found.
  Future<Uint8List>? _card;
  final List<Timer> _timers = [];
  final Random _random = Random();

  int get _count => widget.args.count;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.monastery);
    _content.then((c) async {
      if (!mounted) return;
      final (config, alphabet) = c;
      await Future.wait([
        for (final path in {
          for (final scene in config.scenes) ...[
            scene.background,
            for (final o in scene.objects) o.image,
          ],
        })
          if (path != null)
            precacheImage(AssetImage(path), context, onError: (_, _) {}),
      ]);
      if (!mounted) return;
      // The room is picked (and the game started) once the space for it
      // is known, in build.
      setState(() {
        _config = config;
        _alphabet = alphabet;
      });
    });
  }

  /// Starts a game in [scene] after this frame (first build, or the screen
  /// turned and another room fits better).
  void _startIn(MonasteryScene scene) {
    if (_starting) return;
    _starting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting = false;
      if (!mounted) return;
      _scene = scene;
      _start();
    });
  }

  void _start() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _bubbleTimer?.cancel();
    _cubit?.close();
    final config = _config!;
    final scene = _scene!;
    final progress = sl<GameProgressRepository>();
    final letters = hideLetters(
      alphabet: _alphabet,
      config: config,
      scene: scene,
      count: _count,
      random: _random,
    );
    _bestBefore = progress.bestTime(MonasteryCubit.id, '${letters.length}');
    final cubit = MonasteryCubit(
      progress,
      letters: letters,
      aspect: scene.aspect,
      tapRadius: config.tapRadius,
    );
    setState(() {
      _cubit = cubit;
      _heroAt = null;
      _busy = false;
      _hint = null;
      _misses.clear();
      _bubble = null;
      _showResult = false;
      _card = null;
    });
    _hero.idle();
    _other.idle();
    _sound.play(SoundEvent.levelStart);
    cubit.start();
    _later(const Duration(milliseconds: 500), () {
      if (!_small) {
        _hero.say(context.l10n.monasteryStart(widget.args.setup.name));
      }
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _bubbleTimer?.cancel();
    _hero.dispose();
    _other.dispose();
    _cubit?.close();
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.add(
    Timer(d, () {
      if (mounted) f();
    }),
  );

  bool get _small =>
      _config?.isSmallScreen(MediaQuery.sizeOf(context).shortestSide) ?? false;

  String get _lang => Localizations.localeOf(context).languageCode;

  // ---------------------------------------------------------------------------
  // Taps, the buddy and the letters
  // ---------------------------------------------------------------------------

  /// Layout of the last build, for working out where the buddy runs.
  _Layout? _layout;

  void _onSceneTap(Offset p) {
    final cubit = _cubit;
    if (cubit == null || cubit.state.solved || _busy) return;
    final i = cubit.letterAt(p);
    if (i == null) {
      _miss(p);
      return;
    }
    if (_small || _layout == null) {
      cubit.reveal(i);
      return;
    }
    _runTo(i);
  }

  void _miss(Offset p) {
    final id = ++_markId;
    setState(() => _misses.add(MissMark(at: p, id: id)));
    _later(const Duration(milliseconds: 900), () {
      setState(() => _misses.removeWhere((m) => m.id == id));
    });
    _lastMiss = p;
    _cubit?.miss();
  }

  Offset? _lastMiss;

  void _runTo(int i) {
    final layout = _layout!;
    final token = ++_moveToken;
    _busy = true;
    final from = layout.heroRect(_heroAt);
    final to = layout.heroRect(i);
    _hero
      ..hideSpeech()
      ..play(CharacterAction.run);
    _sound.play(SoundEvent.charRun, by: _heroId);
    setState(() {
      _heroAt = i;
      if ((to.center.dx - from.center.dx).abs() > 1) {
        _heroFacesLeft = to.center.dx < from.center.dx;
      }
    });
    _later(_config!.heroRun, () {
      if (token != _moveToken) return;
      _busy = false;
      _hero.play(CharacterAction.hint);
      _cubit?.reveal(i);
      // Back home after a moment, unless another letter is found first.
      _later(const Duration(milliseconds: 900), () {
        if (token != _moveToken || _cubit?.state.solved == true) return;
        _goHome();
      });
    });
  }

  void _goHome() {
    final layout = _layout;
    if (layout == null || _heroAt == null) return;
    final token = ++_moveToken;
    final from = layout.heroRect(_heroAt);
    final to = layout.heroRect(null);
    _hero.play(CharacterAction.run);
    setState(() {
      _heroAt = null;
      _heroFacesLeft = to.center.dx < from.center.dx;
    });
    _later(_config!.heroRun, () {
      if (token != _moveToken) return;
      setState(() => _heroFacesLeft = layout.heroHomeOnRight);
      _hero.idle();
    });
  }

  void _showBubble(String text, Offset at, Duration duration) {
    _bubbleTimer?.cancel();
    setState(() => _bubble = SceneBubble(text: text, at: at));
    _bubbleTimer = Timer(duration, () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  void _onHint() {
    _sound.play(SoundEvent.hint);
    _cubit?.hint();
  }

  void _onEvent(BuildContext context, MonasteryState state) {
    final config = _config!;
    final l10n = context.l10n;
    final last = state.last;
    switch (state.event) {
      case MonasteryEvent.none:
        break;
      case MonasteryEvent.found || MonasteryEvent.solved:
        final letter = state.letters[last!];
        final name = letter.letter.nameIn(_lang);
        _sound.play(SoundEvent.letterFound);
        if (_hint?.index == last) setState(() => _hint = null);
        if (_small) {
          _showBubble(name, letter.center, config.nameBubble);
        } else {
          _other.say(name, duration: config.nameBubble);
          _other.play(CharacterAction.cheer, hold: config.nameBubble);
        }
        if (state.event == MonasteryEvent.solved) _onSolved();
      case MonasteryEvent.wrong:
        final at = _lastMiss ?? const Offset(0.5, 0.5);
        if (_small) {
          _sound.play(SoundEvent.wrongAnswer);
          _showBubble(
            l10n.monasteryWrong,
            at,
            const Duration(milliseconds: 1100),
          );
        } else {
          _other.react(CharacterReaction.wrong, say: l10n.monasteryWrong);
        }
      case MonasteryEvent.hint:
        final glow = HintGlow(
          index: last!,
          // A little off the letter, so it shows the area, not the spot.
          offset: Offset(
            (_random.nextDouble() - 0.5) * 0.06,
            (_random.nextDouble() - 0.5) * 0.08,
          ),
          id: state.hints,
        );
        setState(() => _hint = glow);
        if (!_small) {
          _other.play(CharacterAction.hint, hold: config.hintGlow);
          _other.say(l10n.monasteryHintSay, duration: config.hintGlow);
        }
        _later(config.hintGlow, () {
          if (_hint?.id == glow.id) setState(() => _hint = null);
        });
    }
  }

  void _onSolved() {
    _later(const Duration(milliseconds: 700), () {
      _goHome();
      if (_small) {
        _sound.play(SoundEvent.levelComplete);
      } else {
        _hero.react(CharacterReaction.celebrate);
        _other.react(CharacterReaction.celebrate);
      }
    });
    _later(const Duration(milliseconds: 2000), () {
      setState(() => _showResult = true);
      // Draw the share picture now: browsers only allow sharing right
      // after the tap, so it can't be drawn then.
      _card = _buildShareCard();
    });
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
      context.go(AppRoutes.monastery, extra: widget.args.setup);
    }
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    context.go(AppRoutes.level, extra: widget.args.setup);
  }

  Future<Uint8List> _buildShareCard() {
    final l10n = context.l10n;
    final state = _cubit!.state;
    final heroName = _heroId == CharacterId.nono ? l10n.nono : l10n.fofo;
    final roster = context.read<CharacterRoster>();
    return MonasteryShareCard(
      title: l10n.monasteryShareTitle(
        widget.args.setup.name,
        state.letters.length,
      ),
      glyphs: [for (final l in state.letters) l.glyph],
      stats: [
        (formatClock(state.solvedIn!), l10n.cardsTime),
        ('${state.wrongTaps}', l10n.monasteryMisses),
        ('${state.hints}', l10n.monasteryHints),
      ],
      badge: state.newRecord ? l10n.cardsNewRecord : null,
      subtitle: l10n.monasteryShareWith(heroName),
      appTitle: l10n.appTitle,
      script: _lang == 'ar' ? AppScript.arabic : AppScript.english,
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
    final count = state.letters.length;
    final text = l10n.monasteryShareText(
      widget.args.setup.name,
      count,
      formatClock(state.solvedIn!),
    );
    final fileName = 'nono-fofo-monastery-$count.png';
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
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.gameMonastery,
        onLogoTap: () => context.go(AppRoutes.home),
        actions: [
          IconButton(
            tooltip: l10n.monasteryOtherLevel,
            onPressed: _otherLevel,
            icon: const FaIcon(AppIcons.found),
          ),
          const LanguageButton(),
          const MuteButton(),
          const SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: config == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final best = config.sceneFor(
                  _Layout.areaFor(size, small: _small).size,
                );
                if (cubit == null || best.id != _scene?.id) {
                  _startIn(best);
                  return const Center(child: CircularProgressIndicator());
                }
                return BlocConsumer<MonasteryCubit, MonasteryState>(
                  bloc: cubit,
                  listenWhen: (a, b) => a.eventId != b.eventId,
                  listener: _onEvent,
                  builder: (context, state) => _screen(size, state, config),
                );
              },
            ),
    );
  }

  Widget _screen(Size size, MonasteryState state, MonasteryConfig config) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final scene = _scene!;
    final layout = _Layout.of(
      size: size,
      aspect: scene.aspect,
      small: _small,
      rtl: rtl,
      roster: context.read<CharacterRoster>(),
      hero: _heroId,
      letters: state.letters,
    );
    _layout = layout;
    final view = MonasterySceneView(
      config: config,
      scene: scene,
      letters: state.letters,
      onTap: _onSceneTap,
      hint: _hint,
      misses: _misses,
      bubble: _bubble,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: DesertSurround()),
        Positioned.fromRect(rect: layout.scene, child: view),
        Positioned(
          top: AppDimens.spaceSm,
          left: 0,
          right: 0,
          height: layout.hudH - AppDimens.spaceSm * 2,
          child: Center(
            child: FittedBox(
              child: MonasteryHud(
                elapsed: () => _cubit?.elapsed ?? Duration.zero,
                running: !state.solved,
                found: state.foundCount,
                total: state.letters.length,
                onHint: state.solved || _hint != null ? null : _onHint,
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: layout.bar,
          child: LettersBar(letters: state.letters, height: layout.bar.height),
        ),
        if (!layout.small) ...[
          layout.place(_other, layout.otherHome, !rtl),
          AnimatedPositioned.fromRect(
            rect: layout.heroRect(_heroAt),
            duration: config.heroRun,
            curve: Curves.easeInOut,
            child: IgnorePointer(
              child: FittedBox(
                alignment: Alignment.bottomCenter,
                child: AnimatedCharacter(
                  controller: _hero,
                  size: layout.charSize,
                  mirror: _heroAt == null
                      ? layout.heroHomeOnRight
                      : _heroFacesLeft,
                ),
              ),
            ),
          ),
        ],
        if (_showResult && state.solved)
          Positioned.fill(
            child: MonasteryResult(
              count: state.letters.length,
              time: state.solvedIn!,
              wrongTaps: state.wrongTaps,
              hints: state.hints,
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
}

/// Where everything goes: the HUD, the room, the letters bar, the
/// brothers' corners, and the spot beside a letter where the buddy stands.
class _Layout {
  _Layout._({
    required this.size,
    required this.small,
    required this.rtl,
    required this.hudH,
    required this.sceneArea,
    required this.scene,
    required this.bar,
    required this.heroHome,
    required this.otherHome,
    required this.charSize,
    required this.roster,
    required this.hero,
    required this.letters,
  });

  factory _Layout.of({
    required Size size,
    required double aspect,
    required bool small,
    required bool rtl,
    required CharacterRoster roster,
    required CharacterId hero,
    required List<HiddenLetter> letters,
  }) {
    const gap = AppDimens.spaceSm;
    final hudH = _hudH(small);
    final barH = _barH(small);
    final ref = roster.referenceHeight;
    double idleW(CharacterId id) =>
        roster.pose(id, CharacterAction.idle)?.width ?? ref * 0.4;
    double idleH(CharacterId id) =>
        roster.pose(id, CharacterAction.idle)?.height ?? ref;

    final sceneArea = areaFor(size, small: small);
    // As big as fits, never scrolled: the room is picked to match this
    // space's shape.
    var w = sceneArea.width, h = w / aspect;
    if (h > sceneArea.height) {
      h = sceneArea.height;
      w = h * aspect;
    }
    final scene = Rect.fromCenter(
      center: sceneArea.center,
      width: w,
      height: h,
    );

    // Brothers small in the bottom corners, the bar between them.
    final charSize = small ? 0.0 : min(size.height * 0.3, 220.0);
    Rect corner(CharacterId id, bool startSide) {
      final k = charSize / ref;
      final w = idleW(id) * k, h = idleH(id) * k;
      final onLeft = startSide != rtl;
      return Rect.fromLTWH(
        onLeft ? gap : size.width - gap - w,
        size.height - h,
        w,
        h,
      );
    }

    final heroHome = small ? Rect.zero : corner(hero, true);
    final otherHome = small ? Rect.zero : corner(hero.other, false);
    final side = small ? gap : max(heroHome.width, otherHome.width) + gap * 2;
    final bar = Rect.fromLTRB(
      side,
      size.height - barH - gap / 2,
      size.width - side,
      size.height - gap / 2,
    );

    return _Layout._(
      size: size,
      small: small,
      rtl: rtl,
      hudH: hudH,
      sceneArea: sceneArea,
      scene: scene,
      bar: bar,
      heroHome: heroHome,
      otherHome: otherHome,
      charSize: charSize,
      roster: roster,
      hero: hero,
      letters: letters,
    );
  }

  static double _hudH(bool small) => small ? 52 : 60;
  static double _barH(bool small) => small ? 64 : 84;

  /// The space for the room on a [size] screen: between the HUD and the
  /// letters bar.
  static Rect areaFor(Size size, {required bool small}) {
    const gap = AppDimens.spaceSm;
    return Rect.fromLTRB(
      gap,
      _hudH(small),
      size.width - gap,
      size.height - _barH(small) - gap,
    );
  }

  final Size size;
  final bool small;
  final bool rtl;
  final double hudH;

  /// The space for the room.
  final Rect sceneArea;

  /// The room itself.
  final Rect scene;
  final Rect bar;
  final Rect heroHome;
  final Rect otherHome;

  /// The size the brothers are drawn at (then scaled to fit their spot).
  final double charSize;
  final CharacterRoster roster;
  final CharacterId hero;
  final List<HiddenLetter> letters;

  /// The buddy's corner is on the right (Arabic).
  bool get heroHomeOnRight => rtl;

  /// The buddy's box when at letter [at] (null: in his corner): beside it,
  /// on the side he comes from, the letter at about his hands.
  Rect heroRect(int? at) {
    if (at == null || at >= letters.length) return heroHome;
    final idle = roster.pose(hero, CharacterAction.idle);
    final aspect = idle == null ? 0.4 : idle.width / idle.height;
    final h = (scene.height * 0.36)
        .clamp(70.0, max(70.0, heroHome.height))
        .toDouble();
    final w = h * aspect;
    final l = letters[at];
    final c = Offset(
      scene.left + l.spot.x * scene.width,
      scene.top + l.spot.y * scene.height,
    );
    final fromLeft = heroHome.center.dx < c.dx;
    final x = fromLeft ? c.dx - w * 0.95 : c.dx - w * 0.05;
    final bottom = (c.dy + h * 0.4)
        .clamp(scene.top + h, max(scene.top + h, scene.bottom))
        .toDouble();
    return Rect.fromLTWH(
      x.clamp(0.0, max(0.0, size.width - w)),
      bottom - h,
      w,
      h,
    );
  }

  /// A standing brother at [rect], facing left when [facesLeft].
  Widget place(CharacterController c, Rect rect, bool facesLeft) =>
      Positioned.fromRect(
        rect: rect,
        child: IgnorePointer(
          child: FittedBox(
            alignment: Alignment.bottomCenter,
            child: AnimatedCharacter(
              controller: c,
              size: charSize,
              mirror: facesLeft,
            ),
          ),
        ),
      );
}
