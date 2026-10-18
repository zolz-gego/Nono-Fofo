import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../../letters/domain/coptic_letter.dart';
import 'adventure_cubit.dart';

/// A cream card in the middle of a dimmed level.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.maxWidth = 520, this.border});

  final Widget child;
  final double maxWidth;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scrim,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spaceMd),
          child:
              Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    padding: const EdgeInsets.all(AppDimens.spaceLg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(
                        color: border ?? AppColors.speechBubbleBorder,
                        width: border == null ? 2 : 4,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.shadow, blurRadius: 24),
                      ],
                    ),
                    child: child,
                  )
                  .animate()
                  .fadeIn(duration: AppDimens.normal)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    curve: Curves.easeOutBack,
                  ),
        ),
      ),
    );
  }
}

/// A right answer: the won letter big (capital and small) with its name.
class AdventureLetterShow extends StatelessWidget {
  const AdventureLetterShow({
    super.key,
    required this.letter,
    required this.hero,
  });

  final CopticLetter letter;

  /// `fofo` or `nono`.
  final String hero;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return LayoutBuilder(
      builder: (context, c) {
        final size = (c.maxHeight * 0.22).clamp(60.0, 130.0);
        return _Card(
          border: AppColors.sunYellow,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AssetPaths.characterPose(hero, 'celebrate'),
                height: size * 1.4,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: AppDimens.spaceMd),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${letter.capital} ${letter.small}',
                      style: TextStyle(
                        fontFamily: AppFonts.coptic,
                        fontSize: size,
                        height: 1.1,
                        color: AppColors.coptic,
                      ),
                    ),
                    AppText.h2(
                      context.l10n.adventureLetterWon(letter.nameIn(lang)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The game is paused: resume, restart the level, or pick another level.
class AdventurePauseCard extends StatelessWidget {
  const AdventurePauseCard({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onLevels,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Card(
      maxWidth: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.h1(l10n.adventurePaused, textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.spaceLg),
          FilledButton.icon(
            onPressed: onResume,
            icon: const FaIcon(AppIcons.play),
            label: Text(l10n.adventureResume),
          ),
          const SizedBox(height: AppDimens.spaceSm),
          OutlinedButton.icon(
            onPressed: onRestart,
            icon: const FaIcon(AppIcons.replay),
            label: Text(l10n.adventureRestart),
          ),
          const SizedBox(height: AppDimens.spaceSm),
          OutlinedButton.icon(
            onPressed: onLevels,
            icon: const FaIcon(AppIcons.levels),
            label: Text(l10n.adventureLevels),
          ),
        ],
      ),
    );
  }
}

/// All lives lost: try the level again or go back to the road.
class AdventureGameOver extends StatefulWidget {
  const AdventureGameOver({
    super.key,
    required this.onTryAgain,
    required this.onBackToRoad,
  });

  final VoidCallback onTryAgain;
  final VoidCallback onBackToRoad;

  @override
  State<AdventureGameOver> createState() => _AdventureGameOverState();
}

class _AdventureGameOverState extends State<AdventureGameOver> {
  @override
  void initState() {
    super.initState();
    context.read<SoundService>().play(SoundEvent.gameLose);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset(
                AssetPaths.characterPose('fofo', 'encourage'),
                height: 120,
                fit: BoxFit.contain,
              ),
              Image.asset(
                AssetPaths.characterPose('nono', 'encourage'),
                height: 140,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceSm),
          AppText.h1(l10n.adventureGameOver, textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.spaceXs),
          AppText.body(
            l10n.adventureGameOverBody,
            color: AppColors.textMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.spaceLg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppDimens.spaceSm,
            runSpacing: AppDimens.spaceSm,
            children: [
              FilledButton.icon(
                onPressed: widget.onTryAgain,
                icon: const FaIcon(AppIcons.replay),
                label: Text(l10n.adventureTryAgain),
              ),
              OutlinedButton.icon(
                onPressed: widget.onBackToRoad,
                icon: const FaIcon(AppIcons.road),
                label: Text(l10n.backToGames),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The letters reached Grandpa's book: stars, coins, time and what next.
class AdventureComplete extends StatefulWidget {
  const AdventureComplete({
    super.key,
    required this.state,
    required this.totalCoins,
    required this.hasNext,
    required this.onNext,
    required this.onPlayAgain,
    required this.onLevels,
  });

  final AdventureState state;
  final int totalCoins;
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onPlayAgain;
  final VoidCallback onLevels;

  @override
  State<AdventureComplete> createState() => _AdventureCompleteState();
}

class _AdventureCompleteState extends State<AdventureComplete> {
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    final sound = context.read<SoundService>();
    Future.delayed(AppDimens.slow, () {
      if (!mounted) return;
      _confetti.play();
      sound
        ..play(SoundEvent.confetti)
        ..play(switch (widget.state.stars) {
          3 => SoundEvent.star3,
          2 => SoundEvent.star2,
          _ => SoundEvent.star1,
        });
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = widget.state;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        _Card(
          border: AppColors.leafGreen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child:
                          FaIcon(
                                i < s.stars
                                    ? AppIcons.star
                                    : AppIcons.starEmpty,
                                size: i == 1 ? 52 : 40,
                                color: AppColors.star,
                              )
                              .animate(delay: (300 + i * 200).ms)
                              .scale(
                                begin: const Offset(0.2, 0.2),
                                curve: Curves.easeOutBack,
                              ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceSm),
              AppText.h1(l10n.adventureComplete, textAlign: TextAlign.center),
              AppText.body(
                l10n.adventureCompleteBody,
                color: AppColors.textMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.spaceMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final l in s.letters)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        l.capital,
                        style: const TextStyle(
                          fontFamily: AppFonts.coptic,
                          fontSize: 40,
                          height: 1.1,
                          color: AppColors.coptic,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stat(
                    icon: AppIcons.coin,
                    value: '${s.coins}/${widget.totalCoins}',
                    label: l10n.adventureCoins,
                  ),
                  const SizedBox(width: AppDimens.spaceLg),
                  _Stat(
                    icon: AppIcons.timer,
                    value: _clock(s.time),
                    label: l10n.adventureTime,
                  ),
                ],
              ),
              if (s.allDone) ...[
                const SizedBox(height: AppDimens.spaceMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceMd,
                    vertical: AppDimens.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sunYellow,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(AppIcons.record, size: 18),
                      const SizedBox(width: AppDimens.spaceSm),
                      Flexible(child: AppText.h3(l10n.adventureAllDone)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppDimens.spaceLg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppDimens.spaceSm,
                runSpacing: AppDimens.spaceSm,
                children: [
                  if (widget.hasNext)
                    FilledButton.icon(
                      onPressed: widget.onNext,
                      icon: const FaIcon(AppIcons.next),
                      label: Text(l10n.adventureNextLevel),
                    ),
                  OutlinedButton.icon(
                    onPressed: widget.onPlayAgain,
                    icon: const FaIcon(AppIcons.replay),
                    label: Text(l10n.playAgain),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onLevels,
                    icon: const FaIcon(AppIcons.levels),
                    label: Text(l10n.adventureLevels),
                  ),
                ],
              ),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          colors: const [
            AppColors.sunYellow,
            AppColors.coral,
            AppColors.leafGreen,
            AppColors.mistBlue,
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final FaIconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 20, color: AppColors.cocoa),
            const SizedBox(width: AppDimens.spaceXs),
            AppText.h2(value),
          ],
        ),
        AppText.body(label, color: AppColors.textMuted),
      ],
    );
  }
}
