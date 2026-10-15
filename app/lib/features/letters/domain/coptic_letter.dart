import 'package:equatable/equatable.dart';

/// One Coptic letter. [small] and [capital] are Avva Shenouda keyboard keys
/// (render them with `CopticText`).
class CopticLetter extends Equatable {
  const CopticLetter({
    required this.id,
    required this.small,
    required this.capital,
    required this.names,
  });

  final String id;
  final String small;
  final String capital;

  /// Letter name per UI language code, e.g. `{'ar': 'الفا', 'en': 'Alpha'}`.
  final Map<String, String> names;

  String nameIn(String languageCode) =>
      names[languageCode] ?? names.values.firstOrNull ?? id;

  @override
  List<Object?> get props => [id];
}
