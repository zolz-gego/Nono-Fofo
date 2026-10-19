import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../shell/presentation/game_scaffold.dart';
import 'adventure_cubit.dart';

/// The counters over the level: letters found (in their slots), coins
/// (filling toward an extra life) and lives, with room for the
/// settings button at the end.
class AdventureHud extends StatelessWidget {
  const AdventureHud({
    super.key,
    required this.state,
    required this.coinsPerLife,
    required this.maxLives,
  });

  final AdventureState state;
  final int coinsPerLife;
  final int maxLives;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, c) {
        final small = c.maxHeight < 420 || c.maxWidth < 700;
        final slot = small ? 30.0 : 40.0;
        return Padding(
          padding: const EdgeInsets.all(AppDimens.spaceSm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Panel(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, letter) in state.letters.indexed) ...[
                      if (i > 0) const SizedBox(width: 4),
                      _LetterSlot(
                        key: ValueKey('slot-$i-${state.found.contains(i)}'),
                        glyph: state.found.contains(i) ? letter.capital : null,
                        size: slot,
                      ),
                    ],
                    if (state.bonus) ...[
                      const SizedBox(width: AppDimens.spaceXs),
                      Tooltip(
                        message: l10n.adventureBonusStars,
                        child:
                            FaIcon(
                              AppIcons.star,
                              size: slot * 0.7,
                              color: AppColors.coral,
                            ).animate().scale(
                              begin: const Offset(2, 2),
                              curve: Curves.easeOutBack,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              _Panel(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: l10n.adventureCoins,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.square(
                            dimension: slot,
                            child: CircularProgressIndicator(
                              value: state.lifeCoins / coinsPerLife,
                              strokeWidth: 3,
                              backgroundColor: AppColors.sand,
                              color: AppColors.coral,
                            ),
                          ),
                          FaIcon(
                            AppIcons.coin,
                            size: slot * 0.5,
                            color: AppColors.sunYellow,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.spaceXs),
                    AppText.h3('${state.coins}'),
                    const SizedBox(width: AppDimens.spaceMd),
                    for (var i = 0; i < maxLives; i++)
                      if (i < state.lives || i < 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FaIcon(
                            i < state.lives ? AppIcons.life : AppIcons.lifeLost,
                            size: slot * 0.55,
                            color: AppColors.coral,
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(
                width: AppDimens.spaceSm + GameScaffold.buttonSize,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceSm,
        vertical: AppDimens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.cocoa.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

class _LetterSlot extends StatelessWidget {
  const _LetterSlot({super.key, required this.glyph, required this.size});

  final String? glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final found = glyph != null;
    Widget slot = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: found ? AppColors.sunYellow : AppColors.sand,
        border: Border.all(
          color: found
              ? AppColors.cocoa
              : AppColors.cocoa.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: found
          ? Text(
              glyph!,
              style: TextStyle(
                fontFamily: AppFonts.coptic,
                fontSize: size * 0.62,
                height: 1.1,
                color: AppColors.coptic,
              ),
            )
          : AppText.body('?', color: AppColors.cocoa.withValues(alpha: 0.4)),
    );
    if (found) {
      slot = slot.animate().scale(
        begin: const Offset(1.6, 1.6),
        curve: Curves.easeOutBack,
        duration: 450.ms,
      );
    }
    return slot;
  }
}

/// A short line from the hero (a checkpoint, the gate is locked...), with
/// an arrow pointing back when letters are missing.
class AdventureMessage extends StatelessWidget {
  const AdventureMessage({
    super.key,
    required this.text,
    required this.hero,
    this.pointBack = false,
  });

  final String text;

  /// `fofo` or `nono`, whose face shows.
  final String hero;
  final bool pointBack;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pointBack)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppDimens.spaceSm),
            child:
                Transform.flip(
                      flipX: rtl,
                      child: const FaIcon(
                        AppIcons.goBack,
                        size: 36,
                        color: AppColors.coral,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: rtl ? 10 : -10, duration: 400.ms),
          ),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.spaceXs,
              AppDimens.spaceXs,
              AppDimens.spaceMd,
              AppDimens.spaceXs,
            ),
            decoration: BoxDecoration(
              color: AppColors.speechBubble,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              border: Border.all(color: AppColors.speechBubbleBorder, width: 2),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AssetPaths.characterPose(hero, 'cheer'),
                  height: 44,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: AppDimens.spaceSm),
                Flexible(
                  child: AppText(text, variant: AppTextVariant.h3, maxLines: 2),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.3);
  }
}

/// A see-through ◀ or ▶ button for phones and tablets (hold to walk).
class AdventureHoldButton extends StatefulWidget {
  const AdventureHoldButton({
    super.key,
    required this.icon,
    required this.onHold,
    this.size = 84,
  });

  final FaIconData icon;

  /// Button diameter (smaller on phones held sideways).
  final double size;
  final ValueChanged<bool> onHold;

  @override
  State<AdventureHoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<AdventureHoldButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    widget.onHold(down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedContainer(
        duration: AppDimens.fast,
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: _down ? 0.55 : 0.28),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.7),
            width: 3,
          ),
        ),
        child: FaIcon(
          widget.icon,
          size: widget.size * 0.52,
          color: AppColors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
