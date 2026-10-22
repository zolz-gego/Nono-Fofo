import 'dart:math';
import 'dart:ui';

import '../../balloons/game/balloons_layout.dart';
import '../../balloons/game/village_background.dart';
import '../../shell/presentation/game_scaffold.dart';
import '../domain/magic_basket_config.dart';

/// The tree picture's size and its marked spots.
class TreeArt {
  const TreeArt(this.imageSize, this.marks);

  final Size imageSize;
  final TreeMarks marks;
}

/// Where everything sits in the Magic basket scene, from the scene size (and
/// the village picture, when there is one). Both the Flame game and the
/// Flutter overlay (the card, the brother in the tree) use it, so they
/// always line up.
///
/// A big apple tree fills the top of the village. The other brother sits on
/// a branch at the start side (away from the settings button) and throws
/// the apples; the child's buddy runs along the path with the basket.
class MagicBasketLayout implements VillageFrame {
  MagicBasketLayout(
    this.size, {
    required this.goal,
    required this.soundCount,
    this.rtl = false,
    this.art,
    this.tree,
    this.throwerSeat,
    this.throwerToss,
  }) {
    _fitArt();
  }

  final Size size;

  final int goal;

  /// How many sounds the letter has (one chip each on the card).
  final int soundCount;

  final bool rtl;

  final VillageArt? art;

  /// The tree picture, or null while the tree is drawn in code.
  final TreeArt? tree;

  /// The thrower's seat and his tossing hand, relative to his feet, in units
  /// of [throwerSize], facing right (null when his poses have none).
  final Offset? throwerSeat;
  final Offset? throwerToss;

  @override
  double get width => size.width;
  @override
  double get height => size.height;

  /// Short screens (phones in landscape) get a slimmer top.
  bool get compact => height < 520;

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
  // Top: the progress row beside the settings button (apples caught, the
  // sounds found), and the letter's name in one line under it
  // ---------------------------------------------------------------------------

  double get hudTop => GameScaffold.buttonInset;

  /// The progress row is as tall as the settings button, between the two
  /// top corners (the button is in one of them).
  double get progressHeight => GameScaffold.buttonSize;
  double get progressLeft => GameScaffold.cornerSize;
  double get progressWidth => width - GameScaffold.cornerSize * 2;

  double get nameTop => hudTop + progressHeight + (compact ? 4 : 6);
  double get nameHeight => compact ? 34 : 42;

  /// Bottom of everything at the top.
  double get cardBottom => nameTop + nameHeight;

  /// The whole top area (speech bubbles stay out of it).
  Rect get cardRect =>
      Rect.fromLTRB(progressLeft, hudTop, width - progressLeft, cardBottom);

  // ---------------------------------------------------------------------------
  // The tree
  // ---------------------------------------------------------------------------

  /// Where the tree picture is drawn: its roots on the path and the top of
  /// its crown past the top edge, so the leaves fill the whole top of the
  /// scene on any screen. Its sides may go past the screen edges too; it
  /// slides sideways (never uncovering an edge) so the brother's branch
  /// stays on screen.
  Rect? get treeRect {
    final tree = this.tree;
    if (tree == null) return null;
    final aspect = tree.imageSize.width / tree.imageSize.height;
    final tall = groundY / (tree.marks.rootY - _crownAbove);
    final w = max(width * 1.04, tall * aspect);
    final h = w / aspect;
    final seat = rtl ? 1 - tree.marks.seat.dx : tree.marks.seat.dx;
    var left = (width - w) / 2;
    final seatX = left + seat * w;
    if (seatX < width * 0.2) left += width * 0.2 - seatX;
    if (seatX > width * 0.8) left -= seatX - width * 0.8;
    left = left.clamp(width - w, 0.0);
    return Rect.fromLTWH(left, groundY - tree.marks.rootY * h, w, h);
  }

  /// How much of the tree picture's height sits above the top edge.
  static const double _crownAbove = 0.12;

  /// A point of the tree picture (fractions, as drawn in English) on
  /// screen; mirrored in Arabic.
  Offset _onTree(Offset f) {
    final r = treeRect!;
    return Offset(
      r.left + (rtl ? 1 - f.dx : f.dx) * r.width,
      r.top + f.dy * r.height,
    );
  }

  /// The canopy of the code-drawn tree: a wide crown over the play area.
  Rect get canopy {
    final top = max(hudTop, height * 0.02);
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

  /// The brother in the tree: as big as the buddy on the tree picture (he
  /// sits on a big branch), a little smaller on the code-drawn one.
  double get throwerSize => characterSize * (tree == null ? 0.82 : 1);

  /// Where the brother in the tree sits: on the picture's branch, or on
  /// the code-drawn branch at the start side, clear of the settings button
  /// and of the card.
  Offset get seatPoint {
    if (tree != null) return _onTree(tree!.marks.seat);
    final margin = max(width * 0.1, throwerSize * 0.45) + 8;
    final x = rtl ? width - margin : margin;
    final y = max(
      canopy.top + throwerSize + GameScaffold.cornerSize * 0.2,
      canopy.bottom - appleSize * 1.4,
    );
    return Offset(x, min(y, canopy.bottom));
  }

  /// His seat or tossing hand on screen, from his feet (he faces the middle:
  /// mirrored in Arabic).
  Offset _fromThrowerFeet(Offset units) =>
      Offset(rtl ? -units.dx : units.dx, units.dy) * throwerSize;

  /// Feet of the brother in the tree (his poses are anchored there).
  Offset get throwerFeet {
    final seat = throwerSeat;
    if (seat == null) return seatPoint;
    return seatPoint - _fromThrowerFeet(seat);
  }

  /// Where an apple leaves his hand.
  Offset get throwerHand {
    final toss = throwerToss;
    if (toss != null) return throwerFeet + _fromThrowerFeet(toss);
    return throwerFeet +
        Offset((rtl ? -1 : 1) * throwerSize * 0.25, -throwerSize * 0.55);
  }

  /// The code-drawn branch he sits on.
  (Offset, Offset) get branch {
    final feet = seatPoint;
    final y = feet.dy + throwerSize * 0.02;
    final reach = throwerSize * 0.9;
    return (Offset(feet.dx - reach, y), Offset(feet.dx + reach, y));
  }

  /// Pixels per second the buddy runs (it follows the pointer quickly).
  double get runSpeed => max(width * 0.9, 520);

  // ---------------------------------------------------------------------------
  // Basket
  // ---------------------------------------------------------------------------

  double get basketWidth => characterSize * 0.58;
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

  /// Where apples start falling: out of the leaves just under the top
  /// rows, so they fall through the whole scene.
  double get dropY => tree != null
      ? cardBottom + appleSize * 0.6
      : canopy.bottom - appleSize * 0.35;

  /// An apple that reaches this line has hit the ground.
  double get floorY => groundY - appleSize * 0.15;
}
