import 'dart:math';
import 'dart:ui';

import '../../balloons/game/balloons_layout.dart';
import '../../balloons/game/village_background.dart';
import '../../letter_hunt/game/target_card_layout.dart';
import '../../shell/presentation/game_scaffold.dart';

/// Where everything sits in the Magic basket scene, from the scene size (and
/// the village picture, when there is one). Both the Flame game and the
/// Flutter overlay (the card, the brother in the tree) use it, so they
/// always line up.
///
/// A big apple tree fills the top of the village. The other brother sits on
/// a branch at the start side (away from the settings button) and throws
/// the apples; the child's buddy runs along the path with the basket.
class MagicBasketLayout with TargetCardLayout implements VillageFrame {
  MagicBasketLayout(
    this.size, {
    required this.goal,
    required this.soundCount,
    this.rtl = false,
    this.art,
  }) {
    _fitArt();
  }

  @override
  final Size size;

  @override
  final int goal;

  /// How many sounds the letter has (one chip each on the card).
  final int soundCount;

  @override
  final bool rtl;

  final VillageArt? art;

  @override
  double get slotMaxSize => appleSize * 0.5;

  @override
  Rect? imageRect;

  @override
  late double groundY;

  void _fitArt() {
    final art = this.art;
    if (art == null) {
      groundY = height * 0.9;
      return;
    }
    final iw = art.imageSize.width;
    final ih = art.imageSize.height;
    final s = max(width / iw, height / ih);
    final w = iw * s;
    final h = ih * s;
    // Keep the feet near 90% of the height without uncovering an edge.
    final dy = (height * 0.9 - art.feetY * h).clamp(height - h, 0.0);
    imageRect = Rect.fromLTWH((width - w) / 2, dy, w, h);
    groundY = dy + art.feetY * h;
  }

  // ---------------------------------------------------------------------------
  // Card: "Ⲁⲁ (Alpha)", the sound chips, then the apple slots
  // ---------------------------------------------------------------------------

  /// Height of the row of sound chips under the letter.
  double get chipSize => compact ? 26 : 38;

  @override
  double get slotsTop =>
      cardTop +
      (compact ? cardLetterSize * 1.15 + 6 : 10 + cardLetterSize * 1.25 + 14) +
      chipSize +
      (compact ? 6 : 10);

  /// Top of the sound chips row.
  double get chipsTop => slotsTop - chipSize - (compact ? 6 : 10);

  // ---------------------------------------------------------------------------
  // The tree
  // ---------------------------------------------------------------------------

  /// The canopy: a wide crown over the whole play area.
  Rect get canopy {
    final top = max(cardTop, height * 0.02);
    final bottom = max(height * 0.42, cardBottom + appleSize * 0.6);
    return Rect.fromLTRB(width * 0.02, top, width * 0.98, bottom);
  }

  double get trunkX => width * 0.5;
  double get trunkWidth => (width * 0.07).clamp(40.0, 110.0);

  // ---------------------------------------------------------------------------
  // Brothers
  // ---------------------------------------------------------------------------

  /// Nono's standing height (the `size` given to the character widgets).
  double get characterSize => (height * 0.25).clamp(100.0, 200.0);

  /// The brother in the tree is a little smaller (he's further back).
  double get throwerSize => characterSize * 0.82;

  /// Feet of the brother sitting in the tree, on the start side, clear of
  /// the settings button and of the card.
  Offset get throwerFeet {
    final margin = max(width * 0.1, throwerSize * 0.45) + 8;
    final x = rtl ? width - margin : margin;
    final y = max(
      canopy.top + throwerSize + GameScaffold.cornerSize * 0.2,
      canopy.bottom - appleSize * 1.4,
    );
    return Offset(x, min(y, canopy.bottom));
  }

  /// Where an apple leaves his hand.
  Offset get throwerHand =>
      throwerFeet +
      Offset((rtl ? -1 : 1) * throwerSize * 0.25, -throwerSize * 0.55);

  /// The branch he sits on, from his side toward the trunk.
  (Offset, Offset) get branch {
    final feet = throwerFeet;
    final y = feet.dy + throwerSize * 0.02;
    final reach = throwerSize * 0.9;
    return (Offset(feet.dx - reach, y), Offset(feet.dx + reach, y));
  }

  /// Pixels per second the buddy runs (it follows the pointer quickly).
  double get runSpeed => max(width * 0.9, 520);

  // ---------------------------------------------------------------------------
  // Basket
  // ---------------------------------------------------------------------------

  double get basketWidth => characterSize * 0.66;
  double get basketHeight => basketWidth * 0.5;

  double get heroMinX => basketWidth / 2 + 8;
  double get heroMaxX => width - basketWidth / 2 - 8;

  // ---------------------------------------------------------------------------
  // Apples
  // ---------------------------------------------------------------------------

  double get appleSize => (min(width, height) * 0.11).clamp(48.0, 92.0);

  /// Apples land in columns across the tree.
  double get columnsLeft => max(width * 0.08, appleSize);
  double get columnsRight => width - columnsLeft;

  int get columnCount =>
      max(3, ((columnsRight - columnsLeft) / (appleSize * 1.3)).floor() + 1);

  double columnX(int column) {
    final n = columnCount;
    return columnsLeft + (columnsRight - columnsLeft) * column / (n - 1);
  }

  /// Where a thrown apple starts falling: just under the leaves.
  double get dropY => canopy.bottom - appleSize * 0.35;

  /// An apple that reaches this line has hit the ground.
  double get floorY => groundY - appleSize * 0.15;
}
