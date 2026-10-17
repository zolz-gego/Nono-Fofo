import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../../engines/sound/application/sound_service.dart';
import '../../../../engines/sound/domain/sound_event.dart';
import '../../progress/domain/timed_record.dart';

/// Every letter is found: time, wrong taps and hints, the best time (or
/// "New record!"), sharing, and what to play next.
class MonasteryResult extends StatefulWidget {
  const MonasteryResult({
    super.key,
    required this.count,
    required this.time,
    required this.wrongTaps,
    required this.hints,
    required this.newRecord,
    required this.onPlayAgain,
    required this.onBackToGames,
    required this.onShare,
    this.onOtherLevel,
    this.best,
  });

  final int count;
  final Duration time;
  final int wrongTaps;
  final int hints;
  final bool newRecord;

  /// The record to beat (not shown on a new record).
  final TimedRecord? best;
  final VoidCallback onPlayAgain;

  /// Null on phones, which always hide the same number of letters.
  final VoidCallback? onOtherLevel;
  final VoidCallback onBackToGames;

  /// Gets where the button is, for the share sheet's arrow on tablets.
  final void Function(Rect origin) onShare;

  @override
  State<MonasteryResult> createState() => _MonasteryResultState();
}

class _MonasteryResultState extends State<MonasteryResult> {
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
      sound.play(SoundEvent.confetti);
      if (widget.newRecord) sound.play(SoundEvent.star3);
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final best = widget.best;
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
                        constraints: const BoxConstraints(maxWidth: 520),
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
                            const FaIcon(
                              AppIcons.passed,
                              size: 56,
                              color: AppColors.correct,
                            ),
                            const SizedBox(height: AppDimens.spaceSm),
                            AppText.h2(
                              l10n.monasterySolved,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimens.spaceXs),
                            AppText.body(
                              l10n.monasterySolvedBody(widget.count),
                              color: AppColors.textMuted,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimens.spaceMd),
                            Row(
                              children: [
                                Expanded(
                                  child: _Stat(
                                    icon: AppIcons.timer,
                                    label: l10n.cardsTime,
                                    value: formatClock(widget.time),
                                  ),
                                ),
                                const SizedBox(width: AppDimens.spaceSm),
                                Expanded(
                                  child: _Stat(
                                    icon: AppIcons.miss,
                                    label: l10n.monasteryMisses,
                                    value: '${widget.wrongTaps}',
                                  ),
                                ),
                                const SizedBox(width: AppDimens.spaceSm),
                                Expanded(
                                  child: _Stat(
                                    icon: AppIcons.hintBulb,
                                    label: l10n.monasteryHints,
                                    value: '${widget.hints}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.spaceSm),
                            if (widget.newRecord)
                              _RecordBadge(text: l10n.cardsNewRecord)
                            else if (best != null)
                              AppText.body(
                                l10n.monasteryBest(best.clock, best.moves),
                                color: AppColors.textMuted,
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: AppDimens.spaceMd),
                            Builder(
                              builder: (context) => FilledButton.tonalIcon(
                                onPressed: () {
                                  final box =
                                      context.findRenderObject() as RenderBox?;
                                  widget.onShare(
                                    box == null
                                        ? Rect.zero
                                        : box.localToGlobal(Offset.zero) &
                                              box.size,
                                  );
                                },
                                icon: const FaIcon(AppIcons.share, size: 18),
                                label: Text(l10n.cardsShare),
                              ),
                            ),
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
                                if (widget.onOtherLevel != null) ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: widget.onOtherLevel,
                                      icon: const FaIcon(
                                        AppIcons.found,
                                        size: 18,
                                      ),
                                      label: Text(l10n.monasteryOtherLevel),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.spaceSm),
                                ],
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

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final FaIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: AppDimens.spaceXs),
          AppText.h2(value),
          AppText(
            label,
            variant: AppTextVariant.caption,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  const _RecordBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const FaIcon(AppIcons.record, size: 16, color: AppColors.cocoa),
              const SizedBox(width: AppDimens.spaceSm),
              AppText.h3(text, color: AppColors.cocoa),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
          duration: 600.ms,
        );
  }
}
