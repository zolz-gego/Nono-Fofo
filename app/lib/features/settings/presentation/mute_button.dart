import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../domain/app_settings.dart';
import 'settings_cubit.dart';

/// Top-bar button that mutes / unmutes all sound (music, effects, voices).
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<SettingsCubit, AppSettings>(
      buildWhen: (a, b) => a.muted != b.muted,
      builder: (context, s) => IconButton(
        tooltip: s.muted ? l10n.unmute : l10n.mute,
        color: AppColors.textOnDark,
        onPressed: () => context.read<SettingsCubit>().setMuted(!s.muted),
        icon: FaIcon(s.muted ? AppIcons.soundOff : AppIcons.soundOn),
      ),
    );
  }
}
