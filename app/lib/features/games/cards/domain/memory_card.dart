import 'dart:math';
import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';
import 'cards_mode.dart';

/// Which side of a pair a card shows: the capital or small letter (Level
/// 1), or the letter in both forms or its sounds (Level 2).
enum CardFace { capital, small, letter, sound }

/// One card on the table. Its partner has the same [letter] and the other
/// [face]; both share the letter's [color].
class MemoryCard extends Equatable {
  const MemoryCard({
    required this.letter,
    required this.face,
    required this.color,
    this.soundless = '',
    this.faceUp = false,
    this.matched = false,
  });

  final CopticLetter letter;
  final CardFace face;
  final Color color;

  /// What a sound card shows for a letter with no sounds (So: "6").
  final String soundless;
  final bool faceUp;

  /// Found with its partner: stays face up for good.
  final bool matched;

  /// The Avva Shenouda keys to draw (not for a sound card).
  String get glyph => switch (face) {
    CardFace.capital => letter.capital,
    CardFace.small => letter.small,
    CardFace.letter => '${letter.capital} ${letter.small}',
    CardFace.sound => '',
  };

  /// The letter's sounds in [languageCode], e.g. "ب / ڤ".
  String sounds(String languageCode) {
    final sounds = letter.soundsIn(languageCode);
    return sounds.isEmpty ? soundless : sounds.join(' / ');
  }

  /// A letter card also pairs with another letter's sound card that looks
  /// the same in [languageCode] (Ei, Ita and Iota all say ي).
  bool pairsWith(MemoryCard other, {String languageCode = 'ar'}) {
    if (other.face == face) return false;
    if (other.letter == letter) return true;
    return {
          face,
          other.face,
        }.containsAll(const [CardFace.letter, CardFace.sound]) &&
        sounds(languageCode) == other.sounds(languageCode);
  }

  MemoryCard copyWith({bool? faceUp, bool? matched}) => MemoryCard(
    letter: letter,
    face: face,
    color: color,
    soundless: soundless,
    faceUp: faceUp ?? this.faceUp,
    matched: matched ?? this.matched,
  );

  @override
  List<Object?> get props => [letter, face, faceUp, matched];
}

/// Deals [count] cards (count / 2 random letters from [alphabet], each as
/// the two faces of [mode]), shuffled. [colors] go with the alphabet order;
/// missing ones repeat. [soundless] is what a sound card shows for a letter
/// with no sounds, by letter id.
List<MemoryCard> dealCards({
  required List<CopticLetter> alphabet,
  required List<Color> colors,
  required int count,
  CardsMode mode = CardsMode.letters,
  Map<String, String> soundless = const {},
  Random? random,
}) {
  final rnd = random ?? Random();
  final pairs = min(count ~/ 2, alphabet.length);
  final picked = [...alphabet.indexed]..shuffle(rnd);
  final cards = <MemoryCard>[
    for (final (i, letter) in picked.take(pairs))
      for (final face in [mode.faces.$1, mode.faces.$2])
        MemoryCard(
          letter: letter,
          face: face,
          soundless: soundless[letter.id] ?? '',
          color: colors.isEmpty
              ? const Color(0xFF5B4B3A)
              : colors[i % colors.length],
        ),
  ];
  return cards..shuffle(rnd);
}
