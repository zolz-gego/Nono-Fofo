import 'dart:ui' show Offset;

/// Small or capital: the two boards of a writing level, in play order.
enum LetterForm { small, capital }

/// How one letter form is written: strokes in order, each a list of points
/// given as fractions (0..1) of the glyph's ink box.
class LetterStrokes {
  const LetterStrokes(this.strokes);

  static const LetterStrokes none = LetterStrokes([]);

  final List<List<Offset>> strokes;

  bool get isEmpty => strokes.isEmpty;
}

/// Everything in `assets/content/games/writing_strokes.json`.
class StrokeBook {
  const StrokeBook(this._letters);

  factory StrokeBook.fromJson(Map<String, dynamic> json) {
    final letters = json['letters'] as Map<String, dynamic>? ?? const {};
    return StrokeBook({
      for (final MapEntry(:key, :value) in letters.entries)
        key: {
          for (final form in LetterForm.values)
            if ((value as Map<String, dynamic>)[form.name] case final List s)
              form: LetterStrokes([
                for (final stroke in s)
                  [
                    for (final p in stroke as List)
                      Offset(
                        ((p as List)[0] as num).toDouble(),
                        (p[1] as num).toDouble(),
                      ),
                  ],
              ]),
        },
    });
  }

  final Map<String, Map<LetterForm, LetterStrokes>> _letters;

  LetterStrokes of(String letterId, LetterForm form) =>
      _letters[letterId]?[form] ?? LetterStrokes.none;
}
