import 'memory_card.dart';

/// What makes a pair in Grandpa's Cards. Each mode keeps its own best
/// times ([id]).
enum CardsMode {
  /// Level 1: a letter's capital card and its small card.
  letters('cards', (CardFace.capital, CardFace.small)),

  /// Level 2: a letter card (capital and small) and a card with the
  /// letter's sounds.
  sounds('soundCards', (CardFace.letter, CardFace.sound));

  const CardsMode(this.id, this.faces);

  /// Key the best times are saved under (per number of cards).
  final String id;

  /// The two faces of a pair.
  final (CardFace, CardFace) faces;
}
