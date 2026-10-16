import 'package:flutter/painting.dart';

import '../theme/app_colors.dart';

/// Font families bundled in `assets/fonts/` (see pubspec.yaml).
abstract final class AppFonts {
  static const String arabic = 'BalooBhaijaan2';
  static const String english = 'Baloo2';

  /// Legacy font: Coptic glyphs live on Latin keys, so Coptic content is
  /// stored exactly as typed with the Avva Shenouda keyboard.
  static const String coptic = 'AvvaShenouda';
}

/// The scripts the app renders text in.
enum AppScript { arabic, english, coptic }

/// Text levels: headers and normal texts.
enum AppTextVariant { h1, h2, h3, body, bodySmall, caption }

/// One place to tune every text style in the app.
abstract final class AppTextStyles {
  static const Map<AppTextVariant, _Spec> _specs = {
    AppTextVariant.h1: _Spec(size: 34, weight: FontWeight.w800, height: 1.25),
    AppTextVariant.h2: _Spec(size: 28, weight: FontWeight.w700, height: 1.25),
    AppTextVariant.h3: _Spec(size: 22, weight: FontWeight.w700, height: 1.3),
    AppTextVariant.body: _Spec(size: 18, weight: FontWeight.w500, height: 1.5),
    AppTextVariant.bodySmall: _Spec(
      size: 15,
      weight: FontWeight.w500,
      height: 1.45,
    ),
    AppTextVariant.caption: _Spec(
      size: 13,
      weight: FontWeight.w600,
      height: 1.4,
    ),
  };

  /// Avva Shenouda glyphs look small next to Baloo at the same size.
  static const double _copticScale = 1.25;

  static bool isHeader(AppTextVariant v) =>
      v == AppTextVariant.h1 ||
      v == AppTextVariant.h2 ||
      v == AppTextVariant.h3;

  static TextStyle of(AppScript script, AppTextVariant variant) {
    final spec = _specs[variant]!;
    final family = switch (script) {
      AppScript.arabic => AppFonts.arabic,
      AppScript.english => AppFonts.english,
      AppScript.coptic => AppFonts.coptic,
    };
    final color = switch (script) {
      AppScript.coptic => AppColors.coptic,
      _ => isHeader(variant) ? AppColors.textHeading : AppColors.textBody,
    };
    final isCoptic = script == AppScript.coptic;
    return TextStyle(
      fontFamily: family,
      fontSize: isCoptic ? spec.size * _copticScale : spec.size,
      // Baloo fonts are variable fonts; set the axis too so every renderer
      // (web/CanvasKit included) picks up the weight.
      fontWeight: isCoptic ? FontWeight.normal : spec.weight,
      fontVariations: isCoptic
          ? null
          : [FontVariation.weight(spec.weight.value.toDouble())],
      height: spec.height,
      color: color,
    );
  }

  static TextStyle arabic(AppTextVariant v) => of(AppScript.arabic, v);
  static TextStyle english(AppTextVariant v) => of(AppScript.english, v);
  static TextStyle coptic(AppTextVariant v) => of(AppScript.coptic, v);
}

class _Spec {
  const _Spec({required this.size, required this.weight, required this.height});

  final double size;
  final FontWeight weight;
  final double height;
}
