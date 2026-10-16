import 'package:flutter/widgets.dart';

import '../../typography/app_text_styles.dart';

/// Base for the script-specific text components. Each script fixes its font
/// family and text direction; the variant picks header vs normal text.
abstract class _ScriptText extends StatelessWidget {
  const _ScriptText(
    this.text, {
    super.key,
    required this.variant,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  AppScript get script;
  TextDirection get direction;

  @override
  Widget build(BuildContext context) {
    var style = AppTextStyles.of(script, variant);
    if (color != null) style = style.copyWith(color: color);
    return Text(
      text,
      style: style,
      textDirection: direction,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Coptic text, rendered with the Avva Shenouda font.
/// Pass the text exactly as typed with the Avva Shenouda keyboard.
class CopticText extends _ScriptText {
  const CopticText(
    super.text, {
    super.key,
    super.variant = AppTextVariant.body,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
  });
  const CopticText.h1(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h1);
  const CopticText.h2(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h2);
  const CopticText.h3(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h3);
  const CopticText.body(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.body);

  @override
  AppScript get script => AppScript.coptic;
  @override
  TextDirection get direction => TextDirection.ltr;
}

/// Arabic text (always right-to-left).
class ArabicText extends _ScriptText {
  const ArabicText(
    super.text, {
    super.key,
    super.variant = AppTextVariant.body,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
  });
  const ArabicText.h1(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h1);
  const ArabicText.h2(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h2);
  const ArabicText.h3(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h3);
  const ArabicText.body(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.body);

  @override
  AppScript get script => AppScript.arabic;
  @override
  TextDirection get direction => TextDirection.rtl;
}

/// English text (always left-to-right).
class EnglishText extends _ScriptText {
  const EnglishText(
    super.text, {
    super.key,
    super.variant = AppTextVariant.body,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
  });
  const EnglishText.h1(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h1);
  const EnglishText.h2(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h2);
  const EnglishText.h3(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.h3);
  const EnglishText.body(super.text, {super.key, super.color, super.textAlign})
    : super(variant: AppTextVariant.body);

  @override
  AppScript get script => AppScript.english;
  @override
  TextDirection get direction => TextDirection.ltr;
}

/// UI text in the app's current language (Arabic or English), e.g. strings
/// from `context.l10n`. Picks the right font and direction automatically.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.body,
    this.color,
    this.textAlign,
    this.maxLines,
  });
  const AppText.h1(this.text, {super.key, this.color, this.textAlign})
    : variant = AppTextVariant.h1,
      maxLines = null;
  const AppText.h2(this.text, {super.key, this.color, this.textAlign})
    : variant = AppTextVariant.h2,
      maxLines = null;
  const AppText.h3(this.text, {super.key, this.color, this.textAlign})
    : variant = AppTextVariant.h3,
      maxLines = null;
  const AppText.body(this.text, {super.key, this.color, this.textAlign})
    : variant = AppTextVariant.body,
      maxLines = null;

  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic
        ? ArabicText(
            text,
            variant: variant,
            color: color,
            textAlign: textAlign,
            maxLines: maxLines,
          )
        : EnglishText(
            text,
            variant: variant,
            color: color,
            textAlign: textAlign,
            maxLines: maxLines,
          );
  }
}
