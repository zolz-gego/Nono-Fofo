import 'dart:math';
import 'dart:ui';

import '../../letter_hunt/game/target_card_layout.dart';

/// The village background picture and where the brothers' feet go in it
/// (fraction of its height).
class VillageArt {
  const VillageArt(this.imageSize, this.feetY);

  final Size imageSize;
  final double feetY;
}

/// Where everything sits in the balloons scene, from the scene size (and the
/// background picture, when there is one). Both the Flame game and the
/// Flutter overlay (target card, the brother holding the balloons) use it,
/// so they always line up.
///
/// The child's buddy starts on the left and runs around the path; the other
/// brother stands on the right and keeps the bunch of correct balloons.
class BalloonsLayout with TargetCardLayout {
  BalloonsLayout(
    this.size, {
    required this.goal,
    this.rtl = false,
    this.art,
    this.receiverFist,
  }) {
    _fitArt();
  }

  @override
  final Size size;

  @override
  final int goal;

  @override
  final bool rtl;

  final VillageArt? art;

  /// The receiver's raised fist in his "hold" pose, relative to his feet,
  /// in units of [characterSize] (null when he has no such pose).
  final Offset? receiverFist;

  @override
  double get slotMaxSize => balloonWidth * 0.5;

  /// Where the background picture is drawn (it covers the whole scene).
  Rect? imageRect;

  /// The line the brothers stand on (middle of the dirt path).
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
  // Brothers
  // ---------------------------------------------------------------------------

  /// Nono's standing height (the `size` given to the character widgets).
  double get characterSize => (height * 0.27).clamp(105.0, 220.0);

  /// Feet of the brother who keeps the balloons.
  Offset get receiverFeet => Offset(width - max(width * 0.11, 64), groundY);

  /// Where the receiver holds the strings of his bunch: his raised fist,
  /// or at his side when he has no "hold" pose.
  Offset get receiverHand =>
      receiverFeet +
      (receiverFist ?? const Offset(-0.3, -0.52)) * characterSize;

  /// Where the buddy waits between catches.
  double get buddyHomeX => max(width * 0.18, 70);

  /// How far the buddy may run to catch a balloon.
  double get buddyMinX => max(width * 0.06, 44);
  double get buddyMaxX => receiverFeet.dx - characterSize * 0.85;

  /// Where the buddy stands to hand a balloon over.
  double get deliverX => receiverFeet.dx - characterSize * 0.62;

  /// Pixels per second the buddy runs.
  double get runSpeed => max(width * 0.75, 420);

  // ---------------------------------------------------------------------------
  // Balloons
  // ---------------------------------------------------------------------------

  double get balloonWidth => (min(width, height) * 0.13).clamp(56.0, 104.0);

  /// Body height of a code-drawn balloon (pictures keep their own shape).
  double get balloonHeight => balloonWidth * 1.2;

  double get stringLength => balloonWidth * 1.05;

  /// Balloons rise in columns between the left edge and the receiver.
  double get columnsLeft => balloonWidth * 0.75;
  double get columnsRight => receiverFeet.dx - characterSize * 0.55;

  int get columnCount =>
      max(2, ((columnsRight - columnsLeft) / (balloonWidth * 1.2)).floor() + 1);

  double columnX(int column) {
    final n = columnCount;
    return columnsLeft + (columnsRight - columnsLeft) * column / (n - 1);
  }

  /// Where a new balloon starts: just under the bottom edge.
  double get spawnY => height + balloonHeight * 0.6;

  /// Smaller balloons in the receiver's bunch.
  double get bunchScale => 0.72;

  /// Center of the [index]th balloon in the bunch (0 = the first caught).
  /// They fan out up and to the left of the receiver's hand.
  Offset bunchSlot(int index) {
    final n = max(goal, 2);
    final t = (index % n) / (n - 1);
    final angle = lerpDouble(-0.75, 0.3, t)!;
    final length =
        (stringLength + balloonHeight * 0.5) * bunchScale * 1.25 +
        (index.isOdd ? balloonWidth * 0.32 : 0);
    final hand = receiverHand;
    final c = Offset(
      hand.dx + sin(angle) * length,
      hand.dy - cos(angle) * length,
    );
    // Keep the whole bunch under the card and on screen.
    final r = balloonWidth * bunchScale * 0.6;
    return Offset(c.dx.clamp(r, width - r), max(c.dy, cardBottom + r * 1.2));
  }
}
