import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/share/web_files.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../../../../engines/characters/domain/character_reaction.dart';
import '../../../../engines/characters/presentation/animated_character.dart';
import '../../../../engines/characters/presentation/character_controller.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../letter_hunt/presentation/letter_pick_page.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../data/letter_mask_builder.dart';
import '../data/writing_config_repository.dart';
import '../domain/letter_mask.dart';
import '../domain/letter_strokes.dart';
import '../domain/writing_board.dart';
import '../domain/writing_config.dart';
import 'chalk_tray.dart';
import 'chalkboard.dart';
import 'study_background.dart';
import 'writing_cubit.dart';
import 'writing_hud.dart';
import 'writing_result.dart';
import 'writing_share_card.dart';

/// "Write the letter" in Grandpa's study: the chosen hero stands by the
/// green chalkboard, the child colours the big hollow letter (small, then
/// capital), and the other brother cheers, warns and wipes the board when
/// it gets too messy.
class WritingPage extends StatefulWidget {
  const WritingPage({super.key, required this.args});

  final LetterHuntArgs args;

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterId _heroId = widget.args.setup.buddy;
  late final CharacterId _otherId = _heroId.other;
  late final CharacterController _hero = CharacterController(
    _heroId,
    sound: _sound,
    initial: CharacterAction.chalk,
  )..rest = CharacterAction.chalk;
  late final CharacterController _other = CharacterController(
    _otherId,
    sound: _sound,
  );
  final ChalkboardController _board = ChalkboardController();
  final WritingConfigRepository _repo = sl<WritingConfigRepository>();
  late final Future<(WritingConfig, StrokeBook)> _content = (
    _repo.load(),
    _repo.strokes(),
  ).wait;

  WritingConfig? _config;
  StrokeBook? _book;
  WritingCubit? _cubit;
  LetterMask? _mask;
  int _colorIndex = 0;
  int _sizeIndex = 1;

  /// The eraser is in hand instead of chalk.
  bool _erasing = false;

  /// The top bar and the other brother are hidden, so the board can grow;
  /// the hero stays, small, in a corner and says his brother's lines too.
  bool _fullScreen = false;

  /// The board shape this screen wants (worked out while laying out) and
  /// the one the current letter was built for. A tall screen gets a tall
  /// board, so the letter can be bigger.
  WritingBoard _wantedShape = WritingBoard.standard;
  WritingBoard _shape = WritingBoard.standard;
  bool _reshaping = false;

  /// Says the other brother's lines (the hero, in full screen).
  CharacterController get _voice => _fullScreen ? _hero : _other;

  /// The eraser is this much wider than the chalk of the same size.
  static const double _eraserScale = 1.6;
  bool _drawing = false;
  DateTime _lastChalkSound = DateTime(0);
  final Map<LetterForm, Uint8List> _shots = {};
  bool? _resultPassed;

  /// The picture to share after a pass (drawings, names, the hero).
  Future<Uint8List>? _card;
  final List<Timer> _timers = [];
  final Random _random = Random();

  CopticLetter get _letter => widget.args.target;

  @override
  void initState() {
    super.initState();
    _sound.playMusic(MusicTrack.grandpaHouse);
    _content.then((c) async {
      if (!mounted) return;
      final (config, book) = c;
      // Load the study and board pictures first, so the board never shows
      // up without its frame.
      await Future.wait([
        for (final path in [config.background, config.board])
          if (path != null)
            precacheImage(AssetImage(path), context, onError: (_, _) {}),
      ]);
      if (!mounted) return;
      _config = config;
      _book = book;
      _sizeIndex = config.startSize.clamp(0, config.chalkSizes.length - 1);
      _start();
    });
  }

  void _start() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _cubit?.close();
    _board.clear();
    _shots.clear();
    final cubit = WritingCubit(
      sl<GameProgressRepository>(),
      config: _config!,
      letterId: _letter.id,
    );
    setState(() {
      _cubit = cubit;
      _mask = null;
      _resultPassed = null;
      _erasing = false;
      _card = null;
    });
    _hero.play(CharacterAction.chalk);
    _other
      ..rest = CharacterAction.idle
      ..idle();
    _sound.play(SoundEvent.levelStart);
    _prepareBoard(LetterForm.small);
  }

  Future<void> _prepareBoard(
    LetterForm form, {
    bool announce = true,
    bool withDemo = true,
  }) async {
    final cubit = _cubit!;
    // Wait for a layout, so the board shape for this screen is known.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _cubit != cubit) return;
    final shape = _wantedShape;
    final glyph = form == LetterForm.small ? _letter.small : _letter.capital;
    Future<LetterMask> build() => const LetterMaskBuilder().build(
      glyph,
      thicken: _config!.letterThicken,
      board: shape,
    );
    var mask = await build();
    // The font may still be loading on the very first board: try again.
    for (var i = 0; i < 5 && mask.insideCount == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      mask = await build();
    }
    if (!mounted || _cubit != cubit) return;
    _board.clear();
    setState(() {
      _mask = mask;
      _shape = shape;
    });
    cubit.boardReady(mask, withDemo: withDemo, announce: announce);
  }

  /// The screen changed shape (turned, or full screen) before the child
  /// drew anything: build the same letter again for the new board shape.
  Future<void> _reshape() async {
    final cubit = _cubit;
    if (cubit != null && mounted) {
      await _prepareBoard(
        cubit.state.form,
        announce: false,
        withDemo: cubit.state.phase == WritingPhase.demo,
      );
    }
    _reshaping = false;
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _hero.dispose();
    _other.dispose();
    _board.dispose();
    _cubit?.close();
    if (_fullScreen) _setSystemBars(visible: true);
    _sound.playMusic(MusicTrack.map);
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) => _timers.add(
    Timer(d, () {
      if (mounted) f();
    }),
  );

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  String _cheer(AppLocalizations l10n) => switch (_random.nextInt(4)) {
    0 => l10n.fishingCheer1,
    1 => l10n.fishingCheer2(widget.args.setup.name),
    2 => l10n.fishingCheer3,
    _ => l10n.fishingCheer4,
  };

  void _onEvent(BuildContext context, WritingState state) {
    final l10n = context.l10n;
    switch (state.event) {
      case WritingEvent.none:
        break;
      case WritingEvent.boardStart:
        if (state.form == LetterForm.small) {
          _hero.say(l10n.writingStart(widget.args.setup.name));
          _later(
            const Duration(milliseconds: 1800),
            () => _voice.say(l10n.writingWatch),
          );
        } else {
          _voice.say(l10n.writingWatch);
        }
      case WritingEvent.halfway:
        _voice.react(CharacterReaction.correct, say: l10n.writingHalfway);
      case WritingEvent.warn:
        _sound.playKey('writing.stroke_off');
        _voice.react(CharacterReaction.think, say: l10n.writingWarn);
      case WritingEvent.wipe:
        _wipeReaction(l10n);
      case WritingEvent.levelFailed:
        _wipeReaction(l10n);
      case WritingEvent.boardPassed:
        _sound.playKey('writing.letter_traced');
        _hero.react(CharacterReaction.correct);
        _voice.react(CharacterReaction.celebrate, say: l10n.writingCapitalNext);
        _snapshot(state.form);
        _later(const Duration(milliseconds: 2200), () {
          _hero.play(CharacterAction.chalk);
          _cubit?.nextBoard();
          _prepareBoard(LetterForm.capital);
        });
      case WritingEvent.levelPassed:
        _sound.playKey('writing.letter_traced');
        _hero.react(CharacterReaction.celebrate);
        _voice.react(CharacterReaction.celebrate, say: _cheer(l10n));
        _snapshot(state.form).then((_) {
          _later(const Duration(milliseconds: 1400), () {
            _sound.play(SoundEvent.levelComplete);
            setState(() => _resultPassed = true);
            // Get the share picture ready now: browsers only allow sharing
            // right after the tap, so it can't be drawn then.
            _card = _buildShareCard();
          });
        });
    }
  }

  void _wipeReaction(AppLocalizations l10n) {
    _sound.playKey('writing.sponge_wipe');
    _voice
      ..play(CharacterAction.sponge, hold: const Duration(seconds: 2))
      ..say(l10n.writingWipe);
  }

  Future<void> _snapshot(LetterForm form) async {
    // Wait a frame so the green "passed" outline is in the picture.
    await WidgetsBinding.instance.endOfFrame;
    // Just the letter (with a little board around it), never too narrow.
    final ink = _mask?.inkRect.inflate(36);
    final crop = ink == null
        ? null
        : Rect.fromCenter(
            center: ink.center,
            width: max(ink.width, ink.height * 0.75),
            height: ink.height,
          );
    Uint8List? png;
    try {
      png = await _board.capturePng(crop: crop);
    } catch (_) {
      png = null; // No picture this time; the game goes on.
    }
    if (png != null) _shots[form] = png;
  }

  void _onWipeDone() {
    final cubit = _cubit;
    if (cubit == null) return;
    if (cubit.state.phase == WritingPhase.failed) {
      _sound.play(SoundEvent.levelFailed);
      _voice.react(CharacterReaction.encourage);
      setState(() => _resultPassed = false);
    } else {
      cubit.wipeDone();
    }
  }

  void _onChalk(Offset a, Offset b, double radius) {
    _cubit?.chalk(a, b, radius);
    final now = DateTime.now();
    if (now.difference(_lastChalkSound) > const Duration(milliseconds: 750)) {
      _lastChalkSound = now;
      _sound.playKey('writing.chalk_stroke');
    }
  }

  void _onErase(Offset a, Offset b, double radius) {
    _cubit?.erase(a, b, radius);
    final now = DateTime.now();
    if (now.difference(_lastChalkSound) > const Duration(milliseconds: 750)) {
      _lastChalkSound = now;
      _sound.playKey('writing.chalk_stroke');
    }
  }

  void _onDrawing(bool drawing) {
    if (drawing != _drawing) setState(() => _drawing = drawing);
  }

  void _toggleFullScreen() {
    _sound.play(SoundEvent.tap);
    setState(() => _fullScreen = !_fullScreen);
    _setSystemBars(visible: !_fullScreen);
  }

  /// Hides the phone's status and navigation bars too (no effect on the
  /// web).
  void _setSystemBars({required bool visible}) {
    SystemChrome.setEnabledSystemUIMode(
      visible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  // ---------------------------------------------------------------------------
  // Result actions
  // ---------------------------------------------------------------------------

  void _playAgain() {
    _sound.play(SoundEvent.tap);
    _start();
  }

  Future<Uint8List> _buildShareCard() {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final heroName = _heroId == CharacterId.nono ? l10n.nono : l10n.fofo;
    return WritingShareCard(
      drawings: [for (final form in LetterForm.values) ?_shots[form]],
      title: l10n.writingShareTitle(
        widget.args.setup.name,
        _letter.nameIn(lang),
      ),
      subtitle: l10n.writingShareWith(heroName),
      appTitle: l10n.appTitle,
      script: lang == 'ar' ? AppScript.arabic : AppScript.english,
      direction: Directionality.of(context),
      heroAsset: context
          .read<CharacterRoster>()
          .pose(_heroId, CharacterAction.celebrate)
          ?.asset,
    ).render();
  }

  Future<void> _share(Rect origin) async {
    _sound.play(SoundEvent.tap);
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final text = l10n.writingShareText(
      widget.args.setup.name,
      _letter.nameIn(lang),
    );
    final fileName = 'nono-fofo-${_letter.id}.png';
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
    // Browsers without a share sheet (e.g. Chrome on a Mac) save the
    // picture instead, and say so.
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
      // The share sheet failed (not cancelled): save it instead on the web.
      if (kIsWeb) await download(card);
    }
  }

  void _otherLetter() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.writing, extra: widget.args.setup);
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
    final config = _config;
    return Scaffold(
      appBar: _fullScreen
          ? null
          : AppTopBar(
              title: l10n.gameWriteLetter,
              onLogoTap: () => context.go(AppRoutes.home),
              actions: [
                IconButton(
                  tooltip: l10n.writingFullScreen,
                  onPressed: cubit == null ? null : _toggleFullScreen,
                  icon: const FaIcon(AppIcons.fullScreen),
                ),
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
      body: cubit == null || config == null
          ? const Center(child: CircularProgressIndicator())
          : BlocConsumer<WritingCubit, WritingState>(
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

  Widget _scene(Size size, WritingState state, WritingConfig config) {
    final roster = context.read<CharacterRoster>();
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // Wide screens: the board in the middle, a brother on each side, the
    // chalk tray under it. Upright screens: a tall board fills the width
    // and the height down to a strip at the bottom, where the brothers stand
    // in the corners with a square chalk tray between them. Short screens
    // (phones held sideways): the board takes the full height, the square
    // tray stands beside it and the brothers on the start side.
    // Full screen: the same, with only the hero, smaller, so the board grows
    // (upright, the tray stands right beside him).
    final full = _fullScreen;
    final portrait = size.width < size.height;
    final short = !portrait && size.height < 520;
    const hudH = 64.0, trayH = 92.0, gap = AppDimens.spaceSm, exitW = 64.0;
    const boardTop = hudH + gap;
    final feetY = size.height - gap;
    final surface = config.board == null ? null : config.boardSurface;

    double idleW(CharacterController c) =>
        roster.pose(c.character, CharacterAction.idle)?.width ?? 0;
    // In full screen the other brother is away: only the hero is measured.
    final heroW = idleW(_hero), otherW = full ? 0.0 : idleW(_other);
    final ref = roster.referenceHeight;

    // Where the board may go, measured from the start side (left in
    // English, right in Arabic).
    final Rect boardArea;
    final trayW = short ? min(size.width * 0.24, 200.0) : 0.0;
    final charZoneW = short ? size.width * (full ? 0.13 : 0.22) : 0.0;
    final stripH = portrait ? size.height * (full ? 0.19 : 0.25) : 0.0;
    if (portrait) {
      boardArea = Rect.fromLTRB(
        gap,
        boardTop,
        size.width - gap,
        feetY - stripH - gap,
      );
    } else if (short) {
      boardArea = Rect.fromLTRB(
        charZoneW + gap,
        boardTop,
        size.width - trayW - gap * 2,
        size.height - gap,
      );
    } else {
      final w = size.width * (full ? 0.74 : 0.6);
      boardArea = Rect.fromLTWH(
        (size.width - w) / 2,
        boardTop,
        w,
        size.height - hudH - trayH - gap * 4,
      );
    }

    // Upright, the board grows taller to fill its area. A new shape needs
    // the letter built again: only done while the board is still clean.
    final WritingBoard wanted;
    if (portrait) {
      final (std, _) = Chalkboard.layoutFor(surface);
      final s = boardArea.width / std.width;
      final frameH = std.height - WritingBoard.standardHeight;
      final h = ((boardArea.height / s - frameH) / 20).floor() * 20.0;
      wanted = WritingBoard(
        height: h.clamp(WritingBoard.standardHeight, WritingBoard.maxHeight),
      );
    } else {
      wanted = WritingBoard.standard;
    }
    _wantedShape = wanted;
    if (wanted != _shape &&
        !_reshaping &&
        _mask != null &&
        _board.isEmpty &&
        (state.phase == WritingPhase.demo ||
            state.phase == WritingPhase.drawing)) {
      _reshaping = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reshape());
    }

    final (design, _) = Chalkboard.layoutFor(surface, _shape);
    final scale = min(
      boardArea.width / design.width,
      boardArea.height / design.height,
    );
    final boardW = design.width * scale;
    final boardH = design.height * scale;
    final boardY = portrait
        ? boardArea.top + (boardArea.height - boardH) / 2
        : boardTop;
    final boardStart = short
        ? charZoneW +
              gap +
              (size.width - charZoneW - gap - boardW - gap - trayW) / 2
        : boardArea.left + (boardArea.width - boardW) / 2;
    double fromStart(double start, double width) =>
        rtl ? size.width - start - width : start;
    final boardLeft = fromStart(boardStart, boardW);

    // Characters stand on the floor, the hero on the start side.
    final double charSize;
    if (portrait) {
      charSize = stripH;
    } else if (short) {
      charSize = min(
        size.height * 0.75,
        heroW + otherW == 0
            ? double.infinity
            : (charZoneW - gap) * ref / (heroW + otherW),
      );
    } else {
      final sideW = (size.width - boardW) / 2;
      charSize = min(
        min(size.height * (full ? 0.4 : 0.6), 460.0),
        max(heroW, otherW) == 0
            ? double.infinity
            : (sideW - gap) * ref / max(heroW, otherW),
      );
    }
    final k = charSize / ref;
    // Each brother's centre, measured from the start side.
    final (heroX, otherX) = portrait
        ? (gap + heroW * k / 2, size.width - gap - otherW * k / 2)
        : short
        ? (gap + heroW * k / 2, gap + (heroW + otherW / 2) * k)
        : ((size.width - boardW) / 4, size.width - (size.width - boardW) / 4);

    // The chalk tray: square beside the board or between the brothers,
    // a long ledge under the board on wide screens.
    final squareTray = portrait || short;
    final Rect trayRect;
    if (portrait) {
      final start = gap * 2 + heroW * k;
      final end = full ? size.width - gap : size.width - gap * 2 - otherW * k;
      trayRect = Rect.fromLTRB(
        fromStart(start, end - start),
        feetY - stripH,
        fromStart(start, end - start) + end - start,
        feetY,
      );
    } else if (short) {
      trayRect = Rect.fromLTWH(
        fromStart(boardStart + boardW + gap, trayW),
        boardY,
        trayW,
        boardH,
      );
    } else {
      trayRect = Rect.fromLTWH(0, boardY + boardH + gap, size.width, trayH);
    }

    Positioned standing(CharacterController c, double startX, bool facesEnd) {
      final idle = roster.pose(c.character, CharacterAction.idle);
      final w = (idle?.width ?? 0) * k, h = (idle?.height ?? 0) * k;
      // Unmirrored characters face right; [facesEnd] turns them towards the
      // end side (right in English).
      return Positioned(
        left: fromStart(startX - w / 2, w),
        top: feetY - h,
        child: AnimatedCharacter(
          controller: c,
          size: charSize,
          mirror: facesEnd == rtl,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: StudyBackground(
            image: config.background == null
                ? null
                : AssetImage(config.background!),
          ),
        ),
        Positioned(
          left: boardLeft,
          top: boardY,
          width: boardW,
          height: boardH,
          child: FittedBox(
            child: Chalkboard(
              board: _shape,
              controller: _board,
              mask: _mask,
              strokes: _book?.of(_letter.id, state.form) ?? LetterStrokes.none,
              phase: state.phase,
              chalkColor: _chalkColor,
              chalkRadius:
                  config.chalkSizes[_sizeIndex] * (_erasing ? _eraserScale : 1),
              erasing: _erasing,
              onErase: _onErase,
              demoStrokeSeconds: config.demoStrokeSeconds,
              onChalk: _onChalk,
              onDrawing: _onDrawing,
              onDemoDone: () => _cubit?.demoDone(),
              onDemoStroke: () => _sound.playKey('writing.chalk_stroke'),
              onWipeDone: _onWipeDone,
              art: config.board == null ? null : AssetImage(config.board!),
              artSurface: config.boardSurface,
            ),
          ),
        ),
        if (_mask == null)
          Positioned(
            left: boardLeft,
            top: boardY,
            width: boardW,
            height: boardH,
            child: const Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          top: AppDimens.spaceSm,
          // Room for the exit button in full screen.
          left: full ? exitW : 0,
          right: full ? exitW : 0,
          height: hudH - AppDimens.spaceSm,
          child: Center(
            child: FittedBox(
              child: WritingHud(
                letter: _letter,
                state: state,
                passAt: config.passAt,
                warnAt: config.warnAt,
                wipesToFail: config.wipesToFail,
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: trayRect,
          child: Align(
            // In full screen (upright) the tray stands right by the hero.
            alignment: portrait && full
                ? AlignmentDirectional.centerStart
                : Alignment.center,
            child: FittedBox(
              child: ChalkTray(
                vertical: squareTray,
                colorIndex: _colorIndex,
                sizeIndex: _sizeIndex,
                sizes: config.chalkSizes,
                erasing: _erasing,
                onColor: (i) {
                  _sound.play(SoundEvent.select);
                  setState(() {
                    _colorIndex = i;
                    _erasing = false;
                  });
                },
                onEraser: () {
                  _sound.play(SoundEvent.select);
                  setState(() => _erasing = !_erasing);
                },
                onSize: (i) {
                  _sound.play(SoundEvent.select);
                  setState(() => _sizeIndex = i);
                },
              ),
            ),
          ),
        ),
        // The hero's arm "writes" while the child draws.
        _Scribbling(active: _drawing, child: standing(_hero, heroX, true)),
        if (!full) standing(_other, otherX, short),
        if (full)
          Positioned(
            top: AppDimens.spaceSm,
            left: fromStart(size.width - exitW, exitW - gap),
            width: exitW - gap,
            height: hudH - AppDimens.spaceSm,
            child: Center(
              child: IconButton.filled(
                tooltip: context.l10n.writingExitFullScreen,
                onPressed: _toggleFullScreen,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                icon: const FaIcon(AppIcons.exitFullScreen),
              ),
            ),
          ),
        if (_resultPassed != null)
          Positioned.fill(
            child: WritingResult(
              passed: _resultPassed!,
              wipesToFail: config.wipesToFail,
              drawings: [
                if (_resultPassed!)
                  for (final form in LetterForm.values) ?_shots[form],
              ],
              onPlayAgain: _playAgain,
              onOtherLetter: _otherLetter,
              onBackToGames: _backToGames,
              onShare: _resultPassed! ? _share : null,
            ),
          ),
      ],
    );
  }

  Color get _chalkColor => AppColors.chalk[_colorIndex];
}

/// Wiggles a positioned child a little, fast, while [active] (the hero
/// writing along with the child).
class _Scribbling extends StatefulWidget {
  const _Scribbling({required this.active, required this.child});

  final bool active;
  final Positioned child;

  @override
  State<_Scribbling> createState() => _ScribblingState();
}

class _ScribblingState extends State<_Scribbling>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(_Scribbling old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.child;
    return Positioned(
      left: p.left,
      top: p.top,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.rotate(
          angle: sin(_c.value * 2 * pi) * 0.025,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(sin(_c.value * 4 * pi) * 2, 0),
            child: child,
          ),
        ),
        child: p.child,
      ),
    );
  }
}
