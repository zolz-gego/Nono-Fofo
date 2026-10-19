import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/settings_cubit.dart';
import 'game_scaffold.dart';

/// Shows the paused game's pop-up. Returns the picked action to run once it
/// has closed, or null to resume (also when tapping outside or going back).
Future<VoidCallback?> showGameSettings(
  BuildContext context, {
  required List<GameAction> actions,
}) => showGeneralDialog<VoidCallback>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.gameResume,
  barrierColor: AppColors.scrim,
  transitionDuration: AppDimens.fast,
  pageBuilder: (context, _, _) => _GameSettingsDialog(actions: actions),
);

class _GameSettingsDialog extends StatelessWidget {
  const _GameSettingsDialog({required this.actions});

  final List<GameAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nav = Navigator.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        child:
            Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    side: const BorderSide(
                      color: AppColors.speechBubbleBorder,
                      width: 2,
                    ),
                  ),
                  elevation: 12,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.all(AppDimens.spaceLg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText.h1(
                          l10n.gamePaused,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.spaceMd),
                        FilledButton.icon(
                          onPressed: () => nav.pop(),
                          icon: const FaIcon(AppIcons.play),
                          label: Text(l10n.gameResume),
                        ),
                        const SizedBox(height: AppDimens.spaceMd),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppDimens.spaceSm,
                          runSpacing: AppDimens.spaceSm,
                          children: [
                            for (final a in actions)
                              OutlinedButton.icon(
                                onPressed: () => nav.pop(a.onPressed),
                                icon: FaIcon(a.icon),
                                label: Text(a.label(l10n)),
                              ),
                            const _LanguageToggle(),
                            const _SoundToggle(),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: AppDimens.fast)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  curve: Curves.easeOutBack,
                ),
      ),
    );
  }
}

/// Switches the language right away; the pop-up stays open. Its label is
/// the language you would switch TO, in that language's font.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final toArabic = cubit.state.languageCode != AppLocales.arabic.languageCode;
    final label = context.l10n.switchLanguage;
    return OutlinedButton.icon(
      onPressed: () => cubit.setLanguage(
        toArabic
            ? AppLocales.arabic.languageCode
            : AppLocales.english.languageCode,
      ),
      icon: const FaIcon(AppIcons.language),
      label: toArabic
          ? ArabicText(label, color: AppColors.primary)
          : EnglishText(label, color: AppColors.primary),
    );
  }
}

/// Mutes / unmutes all sound; the pop-up stays open.
class _SoundToggle extends StatelessWidget {
  const _SoundToggle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<SettingsCubit, AppSettings>(
      buildWhen: (a, b) => a.muted != b.muted,
      builder: (context, s) => OutlinedButton.icon(
        onPressed: () => context.read<SettingsCubit>().setMuted(!s.muted),
        icon: FaIcon(s.muted ? AppIcons.soundOff : AppIcons.soundOn),
        label: Text(s.muted ? l10n.unmute : l10n.mute),
      ),
    );
  }
}
