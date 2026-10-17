import 'dart:math';
import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';

/// Which side of a pair a card shows.
enum CardFace { capital, small }

/// One card on the table. Its partner has the same [letter] and the other
/// [face]; both share the letter's [color].
class MemoryCard extends Equatable {
  const MemoryCard({
    required this.letter,
    required this.face,
    required this.color,
    this.faceUp = false,
    this.matched = false,
  });

  final CopticLetter letter;
  final CardFace face;
  final Color color;
  final bool faceUp;

  /// Found with its partner: stays face up for good.
  final bool matched;

  /// The Avva Shenouda key to draw.
  String get glyph => face == CardFace.capital ? letter.capital : letter.small;

  bool pairsWith(MemoryCard other) =>
      other.letter == letter && other.face != face;

  MemoryCard copyWith({bool? faceUp, bool? matched}) => MemoryCard(
    letter: letter,
    face: face,
    color: color,
    faceUp: faceUp ?? this.faceUp,
    matched: matched ?? this.matched,
  );

  @override
  List<Object?> get props => [letter, face, faceUp, matched];
}

/// Deals [count] cards (count / 2 random letters from [alphabet], each as a
/// capital card and a small card), shuffled. [colors] go with the alphabet
/// order; missing ones repeat.
List<MemoryCard> dealCards({
  required List<CopticLetter> alphabet,
  required List<Color> colors,
  required int count,
  Random? random,
}) {
  final rnd = random ?? Random();
  final pairs = min(count ~/ 2, alphabet.length);
  final picked = [...alphabet.indexed]..shuffle(rnd);
  final cards = <MemoryCard>[
    for (final (i, letter) in picked.take(pairs))
      for (final face in CardFace.values)
        MemoryCard(
          letter: letter,
          face: face,
          color: colors.isEmpty
              ? const Color(0xFF5B4B3A)
              : colors[i % colors.length],
        ),
  ];
  return cards..shuffle(rnd);
}
