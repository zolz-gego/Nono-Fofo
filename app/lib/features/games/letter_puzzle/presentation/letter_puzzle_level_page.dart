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
import '../../../levels/domain/game_level.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../data/letter_puzzle_config_repository.dart';
import '../domain/letter_puzzle_config.dart';
import 'letter_puzzle_cubit.dart';
import 'letter_puzzle_page.dart';

/// Before the Letter puzzle: the child picks how many letters the words
/// have. Each length shows its best stars.
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
  final Future<LetterPuzzleConfig> _config = sl<LetterPuzzleConfigRepository>()
      .load();
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
      body: FutureBuilder<LetterPuzzleConfig>(
        future: _config,
        builder: (context, snap) {
          final config = snap.data;
          if (config == null) {
            return const Center(child: CircularProgressIndicator());
          }
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
                    spacing: AppDimens.spaceSm,
                    runSpacing: AppDimens.spaceSm,
                    children: [
                      for (final (i, n) in config.playableLengths.indexed)
                        _LengthTile(
                              length: n,
                              stars: _progress.bestStars(
                                LetterPuzzleCubit.id,
                                '$n',
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

/// One word length: a row of that many empty cubes, how many letters, and
/// the best stars.
class _LengthTile extends StatelessWidget {
  const _LengthTile({
    required this.length,
    required this.stars,
    required this.onTap,
  });

  final int length;

  /// Best stars so far (0: never finished).
  final int stars;
  final VoidCallback onTap;

  static const double _width = 160;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusMd);
    return SizedBox(
      width: _width,
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        elevation: 2,
        shadowColor: AppColors.shadow,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spaceMd),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < length; i++)
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: AppColors.iconGoldLight,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppColors.namePlate),
                          ),
                        ),
                    ],
                  ),
                ),
                AppText.h3(context.l10n.letterPuzzleLength(length)),
                const SizedBox(height: AppDimens.spaceXs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FaIcon(
                          i < stars ? AppIcons.star : AppIcons.starEmpty,
                          size: 18,
                          color: i < stars ? AppColors.star : AppColors.outline,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
