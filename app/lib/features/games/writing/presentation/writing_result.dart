import 'dart:typed_data';

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

/// End of a writing level: passed (the child's two boards + confetti) or
/// not passed (a friendly "try again").
class WritingResult extends StatefulWidget {
  const WritingResult({
    super.key,
    required this.passed,
    required this.drawings,
    required this.onPlayAgain,
    required this.onOtherLetter,
    required this.onBackToGames,
    this.wipesToFail = 3,
  });

  final bool passed;

  /// For the "wiped N times" line.
  final int wipesToFail;

  /// The small and capital boards as PNGs (passed only).
  final List<Uint8List> drawings;
  final VoidCallback onPlayAgain;
  final VoidCallback onOtherLetter;
  final VoidCallback onBackToGames;

  @override
  State<WritingResult> createState() => _WritingResultState();
}

class _WritingResultState extends State<WritingResult> {
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    final sound = context.read<SoundService>();
    if (widget.passed) {
      Future.delayed(AppDimens.slow, () {
        if (!mounted) return;
        _confetti.play();
        sound.play(SoundEvent.confetti);
      });
    } else {
      sound.play(SoundEvent.tryAgain);
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final passed = widget.passed;
    final primary = passed
        ? (l10n.otherLetter, AppIcons.letters, widget.onOtherLetter)
        : (l10n.playAgain, AppIcons.replay, widget.onPlayAgain);
    final secondary = passed
        ? (l10n.writingAgain, AppIcons.replay, widget.onPlayAgain)
        : (l10n.otherLetter, AppIcons.letters, widget.onOtherLetter);
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
                        constraints: const BoxConstraints(maxWidth: 560),
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
                            FaIcon(
                              passed ? AppIcons.passed : AppIcons.sponge,
                              size: 56,
                              color: passed
                                  ? AppColors.correct
                                  : AppColors.coral,
                            ),
                            const SizedBox(height: AppDimens.spaceSm),
                            AppText.h2(
                              passed ? l10n.writingPassed : l10n.writingFailed,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimens.spaceXs),
                            AppText.body(
                              passed
                                  ? l10n.writingPassedBody
                                  : l10n.writingFailedBody(widget.wipesToFail),
                              color: AppColors.textMuted,
                              textAlign: TextAlign.center,
                            ),
                            if (widget.drawings.isNotEmpty) ...[
                              const SizedBox(height: AppDimens.spaceMd),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final (i, png)
                                      in widget.drawings.indexed)
                                    Flexible(
                                      child:
                                          Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppDimens.spaceXs,
                                                    ),
                                                child: _Drawing(png: png),
                                              )
                                              .animate(delay: (200 * i).ms)
                                              .fadeIn(
                                                duration: AppDimens.normal,
                                              )
                                              .scale(
                                                begin: const Offset(0.7, 0.7),
                                                curve: Curves.easeOutBack,
                                              ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppDimens.spaceLg),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: primary.$3,
                                icon: FaIcon(primary.$2),
                                label: Text(primary.$1),
                              ),
                            ),
                            const SizedBox(height: AppDimens.spaceSm),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: secondary.$3,
                                    icon: FaIcon(secondary.$2, size: 18),
                                    label: Text(secondary.$1),
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
}

/// One saved board, in a little wooden frame.
class _Drawing extends StatelessWidget {
  const _Drawing({required this.png});

  final Uint8List png;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.boardFrame,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(png, fit: BoxFit.contain, gaplessPlayback: true),
      ),
    );
  }
}
