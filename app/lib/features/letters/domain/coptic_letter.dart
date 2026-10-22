import 'package:equatable/equatable.dart';

/// One Coptic letter. [small] and [capital] are Avva Shenouda keyboard keys
/// (render them with `CopticText`).
class CopticLetter extends Equatable {
  const CopticLetter({
    required this.id,
    required this.small,
    required this.capital,
    required this.names,
    this.sounds = const {},
    this.neverDrop = const {},
  });

  final String id;
  final String small;
  final String capital;

  /// Letter name per UI language code, e.g. `{'ar': 'الفا', 'en': 'Alpha'}`.
  final Map<String, String> names;

  /// How the letter is said (Level 2), per UI language code, e.g.
  /// `{'ar': ['ب', 'ڤ'], 'en': ['b', 'v']}`.
  final Map<String, List<String>> sounds;

  /// Debatable sounds that never fall as wrong answers when this letter is
  /// asked, per UI language code.
  final Map<String, List<String>> neverDrop;

  List<String> soundsIn(String languageCode) =>
      sounds[languageCode] ?? const [];

  List<String> neverDropIn(String languageCode) =>
      neverDrop[languageCode] ?? const [];

  String nameIn(String languageCode) =>
      names[languageCode] ?? names.values.firstOrNull ?? id;

  @override
  List<Object?> get props => [id];
}
