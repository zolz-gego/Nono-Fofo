/// One word to spell: shown as [ar] (Arabic UI) or [en] (English UI); the
/// answer is [letters], letter ids from letters.json in reading order.
class PuzzleWord {
  const PuzzleWord({required this.ar, required this.en, required this.letters});

  factory PuzzleWord.fromJson(Map<String, dynamic> json) => PuzzleWord(
    ar: json['ar'] as String,
    en: json['en'] as String,
    letters: [for (final id in json['letters'] as List) id as String],
  );

  final String ar;
  final String en;
  final List<String> letters;

  String textIn(String languageCode) => languageCode == 'ar' ? ar : en;
}

/// Settings and words from `assets/content/games/letter_puzzle.json`.
/// Defaults here are only used for keys missing from the file.
class LetterPuzzleConfig {
  const LetterPuzzleConfig({
    this.wordsPerRound = 10,
    this.lengths = const [3, 4, 5, 6, 7],
    this.threeStarsMaxMistakes = 2,
    this.twoStarsMaxMistakes = 5,
    this.words = const {},
  });

  factory LetterPuzzleConfig.fromJson(Map<String, dynamic> json) {
    const d = LetterPuzzleConfig();
    final stars = json['stars'] as Map<String, dynamic>? ?? const {};
    final words = json['words'] as Map<String, dynamic>? ?? const {};
    return LetterPuzzleConfig(
      wordsPerRound:
          (json['wordsPerRound'] as num?)?.toInt() ?? d.wordsPerRound,
      lengths:
          (json['lengths'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          d.lengths,
      threeStarsMaxMistakes:
          (stars['threeStarsMaxMistakes'] as num?)?.toInt() ??
          d.threeStarsMaxMistakes,
      twoStarsMaxMistakes:
          (stars['twoStarsMaxMistakes'] as num?)?.toInt() ??
          d.twoStarsMaxMistakes,
      words: {
        for (final MapEntry(:key, :value) in words.entries)
          int.parse(key): [
            for (final w in value as List)
              PuzzleWord.fromJson(w as Map<String, dynamic>),
          ],
      },
    );
  }

  final int wordsPerRound;

  /// Word lengths (in Coptic letters) offered in the picker.
  final List<int> lengths;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;

  /// Words by length.
  final Map<int, List<PuzzleWord>> words;

  /// Lengths that have words, in the picker's order.
  List<int> get playableLengths => [
    for (final n in lengths)
      if (words[n]?.isNotEmpty ?? false) n,
  ];

  /// Stars for a round with [mistakes] (failed checks + hints).
  int starsFor(int mistakes) => mistakes <= threeStarsMaxMistakes
      ? 3
      : mistakes <= twoStarsMaxMistakes
      ? 2
      : 1;
}
