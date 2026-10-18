import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/domain/character_id.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../questions/domain/letter_question.dart';
import 'snakes_board_view.dart';

/// The letter question asked before a roll: whose turn, the letter (or
/// its name), and three big answers. Once [picked], the tapped answer
/// turns green or red, and the right one glows green.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.playerName,
    required this.character,
    required this.color,
    required this.picked,
    required this.onPick,
    this.title,
  });

  final LetterQuestion question;

  /// The line at the top; whose turn it is when null.
  final String? title;
  final String playerName;
  final CharacterId character;
  final Color color;
  final int? picked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final q = question;
    final showLetter = q.show == LetterSide.letter;
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 520 || c.maxWidth < 420;
        final promptSize = compact ? 84.0 : 120.0;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spaceMd),
            child:
                Container(
                      constraints: const BoxConstraints(maxWidth: 560),
                      padding: EdgeInsets.all(
                        compact ? AppDimens.spaceMd : AppDimens.spaceLg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        border: Border.all(color: color, width: 4),
                        boxShadow: [
                          BoxShadow(color: AppColors.shadow, blurRadius: 24),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox.square(
                                dimension: compact ? 40 : 52,
                                child: CharacterToken(
                                  character: character,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: AppDimens.spaceSm),
                              Flexible(
                                child: AppText.h3(
                                  title ?? l10n.snakesTurn(playerName),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: compact
                                ? AppDimens.spaceSm
                                : AppDimens.spaceMd,
                          ),
                          AppText.h2(
                            showLetter
                                ? l10n.snakesWhatName
                                : l10n.snakesWhichLetter(q.answer.nameIn(lang)),
                            textAlign: TextAlign.center,
                          ),
                          if (showLetter)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppDimens.spaceSm,
                              ),
                              child: Text(
                                q.glyph(q.answer),
                                style: TextStyle(
                                  fontFamily: AppFonts.coptic,
                                  fontSize: promptSize,
                                  height: 1.1,
                                  color: AppColors.coptic,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: compact
                                  ? AppDimens.spaceSm
                                  : AppDimens.spaceMd,
                            ),
                          Row(
                            children: [
                              for (final (i, letter) in q.choices.indexed) ...[
                                if (i > 0)
                                  const SizedBox(width: AppDimens.spaceSm),
                                Expanded(
                                  child: _Choice(
                                    index: i,
                                    glyph: showLetter ? null : q.glyph(letter),
                                    text: showLetter
                                        ? letter.nameIn(lang)
                                        : null,
                                    compact: compact,
                                    state: _stateOf(i),
                                    onTap: picked == null
                                        ? () => onPick(i)
                                        : null,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: AppDimens.normal)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      curve: Curves.easeOutBack,
                    ),
          ),
        );
      },
    );
  }

  _ChoiceState _stateOf(int i) {
    final p = picked;
    if (p == null) return _ChoiceState.open;
    if (i == question.answerIndex) return _ChoiceState.right;
    if (i == p) return _ChoiceState.wrong;
    return _ChoiceState.faded;
  }
}

enum _ChoiceState { open, right, wrong, faded }

class _Choice extends StatefulWidget {
  const _Choice({
    required this.index,
    required this.compact,
    required this.state,
    required this.onTap,
    this.glyph,
    this.text,
  });

  final int index;
  final String? glyph;
  final String? text;
  final bool compact;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  State<_Choice> createState() => _ChoiceStateWidget();
}

class _ChoiceStateWidget extends State<_Choice> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (widget.state) {
      _ChoiceState.open => (
        _hovered ? AppColors.mistBlue.withValues(alpha: 0.5) : AppColors.white,
        AppColors.tertiary,
      ),
      _ChoiceState.right => (
        AppColors.correct.withValues(alpha: 0.3),
        AppColors.correct,
      ),
      _ChoiceState.wrong => (
        AppColors.wrong.withValues(alpha: 0.3),
        AppColors.wrong,
      ),
      _ChoiceState.faded => (AppColors.white, AppColors.tertiary),
    };
    final h = widget.compact ? 84.0 : 112.0;
    final Widget label = widget.glyph != null
        ? Text(
            widget.glyph!,
            style: TextStyle(
              fontFamily: AppFonts.coptic,
              fontSize: h * 0.62,
              height: 1.1,
              color: AppColors.coptic,
            ),
          )
        : FittedBox(fit: BoxFit.scaleDown, child: AppText.h2(widget.text!));
    Widget box = AnimatedContainer(
      duration: AppDimens.fast,
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: border,
          width: widget.state == _ChoiceState.open ? 3 : 4,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: label),
          if (widget.state == _ChoiceState.right ||
              widget.state == _ChoiceState.wrong)
            PositionedDirectional(
              top: AppDimens.spaceSm,
              end: 0,
              child: FaIcon(
                widget.state == _ChoiceState.right
                    ? AppIcons.rightAnswer
                    : AppIcons.miss,
                size: 20,
                color: border,
              ),
            ),
        ],
      ),
    );
    box = AnimatedOpacity(
      opacity: widget.state == _ChoiceState.faded ? 0.45 : 1,
      duration: AppDimens.fast,
      child: box,
    );
    if (widget.state == _ChoiceState.right) {
      box = box
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 350.ms,
          );
    } else if (widget.state == _ChoiceState.wrong) {
      box = box.animate().shake(hz: 5, duration: 450.ms);
    }
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(button: true, child: box),
      ),
    );
  }
}
