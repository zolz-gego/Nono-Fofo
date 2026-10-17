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
import 'snakes_board_view.dart';
import 'snakes_cubit.dart';

/// Someone reached the last square: who won, both players' right answers
/// and rolls, "Challenge complete!" the first time the child beats the
/// computer, sharing, and what to do next.
class SnakesResult extends StatefulWidget {
  const SnakesResult({
    super.key,
    required this.state,
    required this.colors,
    required this.squares,
    required this.onPlayAgain,
    required this.onChangePlayers,
    required this.onBackToGames,
    required this.onShare,
  });

  final SnakesState state;

  /// Each player's colour.
  final List<Color> colors;
  final int squares;
  final VoidCallback onPlayAgain;
  final VoidCallback onChangePlayers;
  final VoidCallback onBackToGames;

  /// Gets where the button is, for the share sheet's arrow on tablets.
  final void Function(Rect origin) onShare;

  @override
  State<SnakesResult> createState() => _SnakesResultState();
}

class _SnakesResultState extends State<SnakesResult> {
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  /// The child lost to the computer: no confetti.
  bool get _childLost =>
      widget.state.winner != 0 && widget.state.players[1].computer;

  @override
  void initState() {
    super.initState();
    final sound = context.read<SoundService>();
    Future.delayed(AppDimens.slow, () {
      if (!mounted) return;
      if (_childLost) {
        sound.play(SoundEvent.gameLose);
        return;
      }
      _confetti.play();
      sound.play(SoundEvent.confetti);
      if (widget.state.firstWin) sound.play(SoundEvent.star3);
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
    final s = widget.state;
    final winner = s.players[s.winner!];
    final vsComputer = s.players[1].computer;
    final (title, body) = switch ((vsComputer, s.winner)) {
      (true, 0) => (
        l10n.snakesYouWon,
        l10n.snakesYouWonBody(widget.squares, s.players[1].name),
      ),
      (true, _) => (l10n.snakesYouLost(winner.name), l10n.snakesYouLostBody),
      _ => (
        l10n.snakesWinner(winner.name),
        l10n.snakesFriendWonBody(winner.name, widget.squares),
      ),
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
                            SizedBox.square(
                              dimension: 72,
                              child: CharacterToken(
                                character: winner.character,
                                color: widget.colors[s.winner!],
                                active: true,
                              ),
                            ),
                            const SizedBox(height: AppDimens.spaceSm),
                            AppText.h2(title, textAlign: TextAlign.center),
                            const SizedBox(height: AppDimens.spaceXs),
                            AppText.body(
                              body,
                              color: AppColors.textMuted,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimens.spaceMd),
                            for (final i in [0, 1]) ...[
                              if (i == 1)
                                const SizedBox(height: AppDimens.spaceSm),
                              _PlayerLine(
                                state: s,
                                index: i,
                                color: widget.colors[i],
                              ),
                            ],
                            if (s.firstWin) ...[
                              const SizedBox(height: AppDimens.spaceMd),
                              _Badge(text: l10n.snakesChallengeDone),
                            ],
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
                                label: Text(l10n.snakesShare),
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
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onChangePlayers,
                                    icon: const FaIcon(
                                      AppIcons.changePlayers,
                                      size: 18,
                                    ),
                                    label: Text(l10n.snakesChangePlayers),
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

/// One player's token, name, right answers and rolls.
class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.state,
    required this.index,
    required this.color,
  });

  final SnakesState state;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = state.players[index];
    final won = state.winner == index;
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: won ? 0.3 : 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: CharacterToken(character: p.character, color: color),
          ),
          const SizedBox(width: AppDimens.spaceSm),
          Expanded(child: AppText.h3(p.name)),
          if (won) ...[
            const FaIcon(AppIcons.record, size: 18, color: AppColors.cocoa),
            const SizedBox(width: AppDimens.spaceSm),
          ],
          if (!p.computer)
            _Stat(
              icon: AppIcons.rightAnswer,
              label: l10n.snakesRight,
              value: '${state.correct[index]}/${state.asked[index]}',
            ),
          const SizedBox(width: AppDimens.spaceSm),
          _Stat(
            icon: AppIcons.dice,
            label: l10n.snakesRolls,
            value: '${state.turns[index]}',
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
    return Tooltip(
      message: label,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: AppDimens.spaceXs),
              AppText.h3(value),
            ],
          ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

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
