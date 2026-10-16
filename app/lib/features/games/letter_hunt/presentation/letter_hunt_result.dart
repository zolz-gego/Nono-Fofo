import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';

/// End of a "find the letter" game: the stars won (one by one, each with its sound),
/// confetti, and what to do next.
class LetterHuntResult extends StatefulWidget {
  const LetterHuntResult({
    super.key,
    required this.stars,
    required this.isNewBest,
    required this.onPlayAgain,
    required this.onOtherLetter,
    required this.onBackToGames,
  });

  final int stars;
  final bool isNewBest;
  final VoidCallback onPlayAgain;
  final VoidCallback onOtherLetter;
  final VoidCallback onBackToGames;

  @override
  State<LetterHuntResult> createState() => _LetterHuntResultState();
}

class _LetterHuntResultState extends State<LetterHuntResult> {
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  final List<Timer> _timers = [];

  static const Duration _starGap = Duration(milliseconds: 450);
  static const List<SoundEvent> _starSounds = [
    SoundEvent.star1,
    SoundEvent.star2,
    SoundEvent.star3,
  ];

  @override
  void initState() {
    super.initState();
    final sound = context.read<SoundService>();
    for (var i = 0; i < widget.stars; i++) {
      _timers.add(Timer(_starGap * (i + 1), () => sound.play(_starSounds[i])));
    }
    _timers.add(
      Timer(_starGap * (widget.stars + 1), () {
        _confetti.play();
        sound.play(SoundEvent.confetti);
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = switch (widget.stars) {
      3 => l10n.fishingStars3,
      2 => l10n.fishingStars2,
      _ => l10n.fishingStars1,
    };
    return ColoredBox(
      color: AppColors.scrim,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child:
                SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.spaceMd),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(AppDimens.spaceLg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusLg,
                          ),
                          border: Border.all(
                            color: AppColors.speechBubbleBorder,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [for (var i = 0; i < 3; i++) _star(i)],
                            ),
                            const SizedBox(height: AppDimens.spaceMd),
                            AppText.h3(message, textAlign: TextAlign.center),
                            if (widget.isNewBest) ...[
                              const SizedBox(height: AppDimens.spaceSm),
                              Chip(
                                backgroundColor: AppColors.sunYellow,
                                label: AppText.body(l10n.newBest),
                              ),
                            ],
                            const SizedBox(height: AppDimens.spaceLg),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: widget.onPlayAgain,
                                icon: const FaIcon(AppIcons.replay),
                                label: Text(l10n.playAgain),
                              ),
                            ),
                            const SizedBox(height: AppDimens.spaceSm),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onOtherLetter,
                                    icon: const FaIcon(
                                      AppIcons.letters,
                                      size: 18,
                                    ),
                                    label: Text(l10n.otherLetter),
                                  ),
                                ),
                                const SizedBox(width: AppDimens.spaceSm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onBackToGames,
                                    icon: const FaIcon(AppIcons.road, size: 18),
                                    label: Text(l10n.backToGames),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: AppDimens.normal)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: AppColors.celebration,
            numberOfParticles: 30,
          ),
        ],
      ),
    );
  }

  Widget _star(int i) {
    final won = i < widget.stars;
    final star = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceXs),
      child: FaIcon(
        won ? AppIcons.star : AppIcons.starEmpty,
        size: i == 1 ? 64 : 50,
        color: won ? AppColors.star : AppColors.outline,
      ),
    );
    if (!won) return star;
    return star
        .animate(delay: _starGap * (i + 1))
        .scale(
          begin: const Offset(0, 0),
          curve: Curves.elasticOut,
          duration: AppDimens.slow,
        )
        .rotate(begin: -0.3);
  }
}
