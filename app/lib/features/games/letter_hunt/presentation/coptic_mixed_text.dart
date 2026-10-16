import 'package:flutter/widgets.dart';

import '../../../../core/typography/app_text_styles.dart';

/// Text for a speech bubble: [key] identifies it (plain text), [span] draws
/// it with the Coptic letters in the Coptic font.
typedef MixedText = ({String key, InlineSpan span});

/// Placeholders put into translated text where a Coptic letter goes, e.g.
/// `l10n.fishingWrong(copticSlot1, copticSlot2)`.
const String copticSlot1 = '\u0001';
const String copticSlot2 = '\u0002';

/// Builds text in the UI language with Coptic letters swapped in for the
/// [coptic] placeholders ([copticSlot1], [copticSlot2]).
MixedText copticMixedText(
  BuildContext context,
  String text, [
  Map<String, String> coptic = const {},
]) {
  final ui = Localizations.localeOf(context).languageCode == 'ar'
      ? AppTextStyles.arabic(AppTextVariant.body)
      : AppTextStyles.english(AppTextVariant.body);
  final letter = AppTextStyles.coptic(AppTextVariant.h3);
  final spans = <InlineSpan>[];
  final buffer = StringBuffer();
  void flush() {
    if (buffer.isEmpty) return;
    spans.add(TextSpan(text: buffer.toString(), style: ui));
    buffer.clear();
  }

  for (final ch in text.split('')) {
    final key = coptic[ch];
    if (key == null) {
      buffer.write(ch);
    } else {
      flush();
      // Isolated, so the letter never pulls punctuation around it.
      spans.add(TextSpan(text: '\u2068 $key \u2069', style: letter));
    }
  }
  flush();
  final key = text.replaceAllMapped(
    RegExp('[$copticSlot1$copticSlot2]'),
    (m) => coptic[m[0]] ?? '',
  );
  return (key: key, span: TextSpan(children: spans));
}
