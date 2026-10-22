/// One word to spell: [text] shows on the name card; the answer is
/// [letters], letter ids from letters.json in reading order.
class PuzzleWord {
  const PuzzleWord({required this.text, required this.letters});

  factory PuzzleWord.fromJson(Map<String, dynamic> json) => PuzzleWord(
    text: json['text'] as String,
    letters: [for (final id in json['letters'] as List) id as String],
  );

  final String text;
  final List<String> letters;
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
    List<PuzzleWord> parse(Object? list) => [
      for (final w in list as List)
        PuzzleWord.fromJson(w as Map<String, dynamic>),
    ];
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
        for (final MapEntry(key: lang, value: byLength) in words.entries)
          lang: {
            for (final MapEntry(:key, :value)
                in (byLength as Map<String, dynamic>).entries)
              int.parse(key): parse(value),
          },
      },
    );
  }

  final int wordsPerRound;

  /// Word lengths (in Coptic letters) offered in the picker.
  final List<int> lengths;
  final int threeStarsMaxMistakes;
  final int twoStarsMaxMistakes;

  /// Words by UI language code, then by length in Coptic letters. Each
  /// language has its own words (English ones are "Franco English").
  final Map<String, Map<int, List<PuzzleWord>>> words;

  /// The words of [length] letters for the [languageCode] app.
  List<PuzzleWord> wordsFor(String languageCode, int length) =>
      words[languageCode]?[length] ?? const [];

  /// Lengths that have words in [languageCode], in the picker's order.
  List<int> playableLengths(String languageCode) => [
    for (final n in lengths)
      if (wordsFor(languageCode, n).isNotEmpty) n,
  ];

  /// Stars for a round with [mistakes] (failed checks + hints).
  int starsFor(int mistakes) => mistakes <= threeStarsMaxMistakes
      ? 3
      : mistakes <= twoStarsMaxMistakes
      ? 2
      : 1;
}
