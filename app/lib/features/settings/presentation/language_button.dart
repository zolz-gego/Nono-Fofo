import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/text/app_texts.dart';
import 'settings_cubit.dart';

/// Top-bar button that switches between Arabic and English. Its label is
/// the language you would switch TO ("English" while in Arabic).
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final toArabic = cubit.state.languageCode != AppLocales.arabic.languageCode;
    final label = context.l10n.switchLanguage;
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: AppColors.textOnDark),
      onPressed: () => cubit.setLanguage(
        toArabic
            ? AppLocales.arabic.languageCode
            : AppLocales.english.languageCode,
      ),
      icon: const Icon(Icons.translate_rounded),
      // The label is written in the target language, so use its font.
      label: toArabic
          ? ArabicText(label, color: AppColors.textOnDark)
          : EnglishText(label, color: AppColors.textOnDark),
    );
  }
}
