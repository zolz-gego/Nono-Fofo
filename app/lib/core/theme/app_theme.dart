import 'package:flutter/material.dart';

import '../typography/app_text_styles.dart';
import 'app_colors.dart';
import 'app_dimens.dart';

/// Builds Material's ThemeData from [AppColors] and [AppTextStyles], so
/// stock widgets (buttons, dialogs, app bars) follow the app palette too.
abstract final class AppTheme {
  static ThemeData light(Locale locale) {
    final script =
        locale.languageCode == 'ar' ? AppScript.arabic : AppScript.english;
    TextStyle t(AppTextVariant v) => AppTextStyles.of(script, v);

    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.textBody,
      error: AppColors.wrong,
      onError: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textBody,
      outline: AppColors.outline,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: script == AppScript.arabic ? AppFonts.arabic : AppFonts.english,
      textTheme: TextTheme(
        displayLarge: t(AppTextVariant.h1),
        headlineLarge: t(AppTextVariant.h1),
        headlineMedium: t(AppTextVariant.h2),
        headlineSmall: t(AppTextVariant.h3),
        titleLarge: t(AppTextVariant.h3),
        bodyLarge: t(AppTextVariant.body),
        bodyMedium: t(AppTextVariant.bodySmall),
        labelLarge: t(AppTextVariant.body),
        bodySmall: t(AppTextVariant.caption),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        centerTitle: true,
        titleTextStyle:
            t(AppTextVariant.h3).copyWith(color: AppColors.textOnDark),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(AppDimens.minTapTarget, AppDimens.minTapTarget),
          shape: buttonShape,
          textStyle: t(AppTextVariant.body),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.outline, width: 2),
          minimumSize: const Size(AppDimens.minTapTarget, AppDimens.minTapTarget),
          shape: buttonShape,
          textStyle: t(AppTextVariant.bodySmall),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.secondary,
        inactiveTrackColor: AppColors.tertiary,
      ),
    );
  }
}
