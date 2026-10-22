import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/characters/domain/character_action.dart';
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
import '../data/letter_puzzle_config_repository.dart';
import '../domain/letter_puzzle_config.dart';
import 'letter_puzzle_cubit.dart';
import 'letter_puzzle_page.dart';

/// Before the Letter puzzle: the child picks how many letters the words
/// have. Each length is a wooden name plate (like the one under the icon in
/// the game) with a real word of that length on letter blocks, and its best
/// stars. Mix shows mixed-up blocks.
class LetterPuzzleLevelPage extends StatefulWidget {
  const LetterPuzzleLevelPage({super.key, required this.setup});

  final PlayerSetup setup;

  @override
  State<LetterPuzzleLevelPage> createState() => _LetterPuzzleLevelPageState();
}

class _LetterPuzzleLevelPageState extends State<LetterPuzzleLevelPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final CharacterController _buddy = CharacterController(
    widget.setup.buddy,
    sound: _sound,
    initial: CharacterAction.hint,
  );
  final Future<(LetterPuzzleConfig, List<CopticLetter>)> _content = (
    sl<LetterPuzzleConfigRepository>().load(),
    sl<LetterRepository>().allLetters(),
  ).wait;
  final GameProgressRepository _progress = sl<GameProgressRepository>();

  static const double _maxWidth = 960;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buddy.say(context.l10n.letterPuzzlePickLevel);
    });
  }

  @override
  void dispose() {
    _buddy.dispose();
    super.dispose();
  }

  Future<void> _play(int length) async {
    _sound.play(SoundEvent.select);
    _buddy.play(CharacterAction.cheer, hold: const Duration(seconds: 1));
    await context.push(
      AppRoutes.letterPuzzlePlay,
      extra: LetterPuzzleArgs(setup: widget.setup, length: length),
    );
    if (mounted) setState(() {}); // Show new best stars.
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.level, extra: widget.setup);
    }
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppTopBar(
        title: l10n.gameLetterPuzzle,
        onLogoTap: () => context.go(AppRoutes.home),
        actions: [
          IconButton(
            tooltip: l10n.backToGames,
            onPressed: _backToGames,
            icon: const FaIcon(AppIcons.road),
          ),
          const LanguageButton(),
          const MuteButton(),
          const SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: FutureBuilder<(LetterPuzzleConfig, List<CopticLetter>)>(
        future: _content,
        builder: (context, snap) {
          final content = snap.data;
          if (content == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final (config, letters) = content;
          final alphabet = {for (final l in letters) l.id: l};
          final lengths = config.playableLengths(_lang);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.spaceMd,
                  0,
                  AppDimens.spaceMd,
                  AppDimens.spaceXl,
                ),
                children: [
                  _header(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppDimens.spaceMd,
                    runSpacing: AppDimens.spaceMd,
                    children: [
                      for (final (i, n) in [
                        ...lengths,
                        LetterPuzzleConfig.mix,
                      ].indexed)
                        _NamePlateTile(
                              length: n,
                              blocks: n == LetterPuzzleConfig.mix
                                  ? _mixBlocks(config, lengths, alphabet)
                                  : _sampleWord(config, n, alphabet),
                              stars: _progress.bestStars(
                                LetterPuzzleCubit.id,
                                LetterPuzzleCubit.levelKey(n),
                              ),
                              onTap: () => _play(n),
                            )
                            .animate(delay: (60 * i).ms)
                            .fadeIn(duration: AppDimens.normal)
                            .scale(begin: const Offset(0.85, 0.85)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// A real word of [length] letters to show on its plate (the first one
  /// listed whose letters are all known).
  List<CopticLetter> _sampleWord(
    LetterPuzzleConfig config,
    int length,
    Map<String, CopticLetter> alphabet,
  ) {
    for (final w in config.wordsFor(_lang, length)) {
      if (w.letters.every(alphabet.containsKey)) {
        return [for (final id in w.letters) alphabet[id]!];
      }
    }
    return const [];
  }

  /// Mix: the first letter of each length's word, mixed up.
  List<CopticLetter> _mixBlocks(
    LetterPuzzleConfig config,
    List<int> lengths,
    Map<String, CopticLetter> alphabet,
  ) =>
      [for (final n in lengths) ..._sampleWord(config, n, alphabet).take(1)]
          .reversed
          .toList();

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            // Room above the buddy for the speech bubble.
            padding: const EdgeInsets.only(top: 90),
            child: AnimatedCharacter(controller: _buddy, size: 130),
          ),
          const SizedBox(width: AppDimens.spaceLg),
          Expanded(child: AppText.h2(context.l10n.letterPuzzlePickLevel)),
        ],
      ),
    );
  }
}

/// One level as a wooden name plate with a gold edge: the word on cream
/// letter blocks, how many letters, and the best stars. Mix tilts its blocks
/// every which way and shows a dice.
class _NamePlateTile extends StatelessWidget {
  const _NamePlateTile({
    required this.length,
    required this.blocks,
    required this.stars,
    required this.onTap,
  });

  final int length;

  /// The letters on the blocks.
  final List<CopticLetter> blocks;

  /// Best stars so far (0: never finished).
  final int stars;
  final VoidCallback onTap;

  static const double _width = 250;
  static const double _block = 36;

  bool get _mix => length == LetterPuzzleConfig.mix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = BorderRadius.circular(AppDimens.radiusMd);
    return SizedBox(
      width: _width,
      child: Material(
        color: AppColors.transparent,
        borderRadius: radius,
        elevation: 4,
        shadowColor: AppColors.shadow,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.namePlateLight, AppColors.namePlate],
            ),
            border: Border.all(color: AppColors.iconGold, width: 3),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Stack(
              children: [
                // Two gold pins holding the plate up.
                for (final x in [-0.88, 0.88])
                  Align(
                    alignment: Alignment(x, -0.82),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.iconGoldLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.spaceMd,
                    AppDimens.spaceMd,
                    AppDimens.spaceMd,
                    AppDimens.spaceSm,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: _block + 8, child: _blocks()),
                      const SizedBox(height: AppDimens.spaceSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_mix) ...[
                            const FaIcon(
                              AppIcons.random,
                              size: 18,
                              color: AppColors.iconGoldLight,
                            ),
                            const SizedBox(width: AppDimens.spaceSm),
                          ],
                          AppText.h3(
                            _mix
                                ? l10n.letterPuzzleMix
                                : l10n.letterPuzzleLength(length),
                            color: AppColors.iconGoldLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.spaceXs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: FaIcon(
                                i < stars ? AppIcons.star : AppIcons.starEmpty,
                                size: 18,
                                color: i < stars
                                    ? AppColors.star
                                    : AppColors.cubeBorder,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The word on cream blocks, left to right like all Coptic.
  Widget _blocks() => LayoutBuilder(
    builder: (context, c) => _row(
      blocks.isEmpty ? _block : min(_block, c.maxWidth / blocks.length - 4),
    ),
  );

  Widget _row(double size) => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, letter) in blocks.indexed)
          Transform.rotate(
            angle: _mix ? (i.isEven ? -0.22 : 0.18) : 0,
            child: Container(
              width: size,
              height: size,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cube,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.cubeBorder, width: 1.5),
              ),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CopticText.h3(letter.small, color: AppColors.coptic),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
