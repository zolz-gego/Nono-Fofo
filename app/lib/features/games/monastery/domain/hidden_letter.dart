import 'dart:math';
import 'dart:ui' show Color, Offset;

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';
import 'monastery_config.dart';

/// One letter hiding in the room: which letter and form, where, at what
/// lean and colour, and whether it has been found.
class HiddenLetter extends Equatable {
  const HiddenLetter({
    required this.letter,
    required this.capital,
    required this.spot,
    required this.color,
    this.rotation = 0,
    this.found = false,
  });

  final CopticLetter letter;

  /// Capital or small form.
  final bool capital;
  final HidingSpot spot;
  final Color color;

  /// Lean, in radians.
  final double rotation;
  final bool found;

  /// The Avva Shenouda key to draw.
  String get glyph => capital ? letter.capital : letter.small;

  /// Where it is, in scene fractions.
  Offset get center => Offset(spot.x, spot.y);

  HiddenLetter copyWith({bool? found}) => HiddenLetter(
    letter: letter,
    capital: capital,
    spot: spot,
    color: color,
    rotation: rotation,
    found: found ?? this.found,
  );

  @override
  List<Object?> get props => [letter, capital, spot, found];
}

/// Distance between two scene points, in scene heights (x is stretched by
/// the scene's [aspect] so a circle stays a circle).
double sceneDistance(Offset a, Offset b, double aspect) {
  final dx = (a.dx - b.dx) * aspect, dy = a.dy - b.dy;
  return sqrt(dx * dx + dy * dy);
}

/// Hides [count] different letters from [alphabet] at random spots of
/// [config]'s scene, each randomly capital or small, never two closer than
/// `minSpotGap`. Fewer come back if the spots run out.
List<HiddenLetter> hideLetters({
  required List<CopticLetter> alphabet,
  required MonasteryConfig config,
  required int count,
  Random? random,
}) {
  final rnd = random ?? Random();
  final scene = config.scene;
  final spots = [...scene.spots]..shuffle(rnd);
  final picked = <HidingSpot>[];
  for (final s in spots) {
    if (picked.length == count) break;
    final c = Offset(s.x, s.y);
    final tooClose = picked.any(
      (p) =>
          sceneDistance(c, Offset(p.x, p.y), scene.aspect) < config.minSpotGap,
    );
    if (!tooClose) picked.add(s);
  }
  final letters = [...alphabet]..shuffle(rnd);
  final maxTurn = config.maxRotation * pi / 180;
  return [
    for (final (i, spot) in picked.indexed)
      if (i < letters.length)
        HiddenLetter(
          letter: letters[i],
          capital: rnd.nextBool(),
          spot: spot,
          color: config.letterColors.isEmpty
              ? const Color(0xFF8C7562)
              : config.letterColors[rnd.nextInt(config.letterColors.length)],
          rotation: (rnd.nextDouble() * 2 - 1) * maxTurn,
        ),
  ];
}
