import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/letter_strokes.dart';

/// The child's own chalk drawings of each passed letter (small PNG
/// thumbnails), saved on this device. The latest pass replaces the old one.
class WritingDrawingsRepository {
  const WritingDrawingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String letterId, LetterForm form) =>
      'writing.drawing.$letterId.${form.name}';

  Uint8List? drawing(String letterId, LetterForm form) {
    final raw = _prefs.getString(_key(letterId, form));
    if (raw == null) return null;
    try {
      return base64Decode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> save(String letterId, LetterForm form, Uint8List png) =>
      _prefs.setString(_key(letterId, form), base64Encode(png));
}
