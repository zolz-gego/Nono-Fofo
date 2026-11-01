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
import '../../../../core/typography/app_text_styles.dart';
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
import '../../../profile/presentation/profile_button.dart';
import '../../../settings/presentation/language_button.dart';
import '../../../settings/presentation/mute_button.dart';
import '../../progress/domain/game_progress_repository.dart';

/// What a "find the letter" game needs: who plays, the letter to catch and
/// the letters the other items may carry.
class LetterHuntArgs {
  const LetterHuntArgs({
    required this.setup,
    required this.target,
    required this.pool,
  });

  final PlayerSetup setup;
  final CopticLetter target;
  final List<CopticLetter> pool;
}

/// Before a "find the letter" game: the child picks the letter to catch, or
/// lets the dice pick one. Each letter shows the best stars won with it in
/// that game, or for a pass / not-passed game ([passFail]) a green tick.
class LetterPickPage extends StatefulWidget {
  const LetterPickPage({
    super.key,
    required this.setup,
    required this.gameId,
    required this.title,
    required this.prompt,
    required this.playRoute,
    this.passFail = false,
    this.allLetters = false,
    this.bothForms = false,
  });

  final PlayerSetup setup;

  /// Key the best stars are saved under.
  final String gameId;
  final String title;

  /// What the buddy asks, e.g. "Pick the letter you'll catch!".
  final String prompt;

  /// Route of the game itself; gets [LetterHuntArgs] as `extra`.
  final String playRoute;

  /// The game has no stars, only passed / not passed (the writing game).
  final bool passFail;

  /// Offer the whole alphabet instead of the level's letters.
  final bool allLetters;

  /// The tiles show the capital and the small letter (the game asks for
  /// both).
  final bool bothForms;

  @override
  State<LetterPickPage> createState() => _LetterPickPageState();
}

class _LetterPickPageState extends State<LetterPickPage> {
  late final SoundService _sound = context.read<SoundService>();
  late final Future<List<CopticLetter>> _letters = widget.allLetters
      ? sl<LetterRepository>().allLetters()
      : sl<LetterRepository>().lettersOf(widget.setup.level);
  late final CharacterController _buddy = CharacterController(
    widget.setup.buddy,
    sound: _sound,
    initial: CharacterAction.hint,
  );
  final GameProgressRepository _progress = sl<GameProgressRepository>();

  static const double _maxWidth = 960;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buddy.say(widget.prompt);
    });
  }

  @override
  void dispose() {
    _buddy.dispose();
    super.dispose();
  }

  Future<void> _play(CopticLetter letter, List<CopticLetter> pool) async {
    _sound.play(SoundEvent.select);
    await context.push(
      widget.playRoute,
      extra: LetterHuntArgs(setup: widget.setup, target: letter, pool: pool),
    );
    if (mounted) setState(() {}); // Show any new stars.
  }

  void _playRandom(List<CopticLetter> pool) {
    _buddy.play(CharacterAction.cheer, hold: const Duration(seconds: 1));
    _play(pool[Random().nextInt(pool.length)], pool);
  }

  void _backToGames() {
    _sound.play(SoundEvent.back);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.level(widget.setup.level));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppTopBar(
        title: widget.title,
        onLogoTap: () => context.go(AppRoutes.home),
        actions: [
          IconButton(
            tooltip: l10n.backToGames,
            onPressed: _backToGames,
            icon: const FaIcon(AppIcons.road),
          ),
          const ProfileButton(),
          const LanguageButton(),
          const MuteButton(),
          const SizedBox(width: AppDimens.spaceSm),
        ],
      ),
      body: FutureBuilder<List<CopticLetter>>(
        future: _letters,
        builder: (context, snap) {
          final letters = snap.data;
          if (letters == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(letters)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.spaceMd,
                      0,
                      AppDimens.spaceMd,
                      AppDimens.spaceXl,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 130,
                            mainAxisSpacing: AppDimens.spaceMd,
                            crossAxisSpacing: AppDimens.spaceMd,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: letters.length,
                      itemBuilder: (context, i) =>
                          _LetterTile(
                                letter: letters[i],
                                stars: widget.passFail
                                    ? null
                                    : _progress.bestStars(
                                        widget.gameId,
                                        letters[i].id,
                                      ),
                                passed:
                                    widget.passFail &&
                                    _progress.hasPassed(
                                      widget.gameId,
                                      letters[i].id,
                                    ),
                                bothForms: widget.bothForms,
                                onTap: () => _play(letters[i], letters),
                              )
                              .animate(delay: (40 * i).ms)
                              .fadeIn(duration: AppDimens.normal)
                              .scale(begin: const Offset(0.85, 0.85)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(List<CopticLetter> letters) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            // Room above the buddy for the speech bubble.
            padding: const EdgeInsets.only(top: 90),
            child: AnimatedCharacter(controller: _buddy, size: 130),
          ),
          const SizedBox(width: AppDimens.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.h2(widget.prompt),
                const SizedBox(height: AppDimens.spaceMd),
                FilledButton.icon(
                  onPressed: () => _playRandom(letters),
                  icon: const FaIcon(AppIcons.random),
                  label: Text(context.l10n.randomLetter),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.stars,
    required this.onTap,
    this.passed = false,
    this.bothForms = false,
  });

  final CopticLetter letter;

  /// Best stars, or null for a pass / not-passed game.
  final int? stars;
  final bool passed;
  final bool bothForms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spaceSm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  child: Text(
                    // Pass / not-passed (writing) levels and [bothForms]
                    // games play both forms: show the capital and the
                    // small one.
                    stars == null || bothForms
                        ? '${letter.capital} ${letter.small}'
                        : letter.small,
                    // Coptic keys like ")" must not be mirrored in
                    // Arabic (right-to-left) layouts.
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.coptic(AppTextVariant.h1)
                        .copyWith(fontSize: 64, height: 1.1),
                  ),
                ),
              ),
              AppText(
                letter.nameIn(lang),
                variant: AppTextVariant.caption,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppDimens.spaceXs),
              if (stars == null)
                SizedBox(
                  height: 18,
                  child: passed
                      ? const FaIcon(
                          AppIcons.passed,
                          size: 18,
                          color: AppColors.correct,
                        )
                      : null,
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: FaIcon(
                          i < stars! ? AppIcons.star : AppIcons.starEmpty,
                          size: 14,
                          color: i < stars!
                              ? AppColors.star
                              : AppColors.outline,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
