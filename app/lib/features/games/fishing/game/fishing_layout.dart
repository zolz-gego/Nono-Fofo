import 'dart:math';
import 'dart:ui';

/// Where everything sits in the fishing scene, from the scene size alone.
/// Both the Flame game and the Flutter overlay (target card, basket,
/// referee) use it, so they always line up.
class FishingLayout {
  FishingLayout(this.size, {required this.goal, this.rtl = false});

  final Size size;

  /// Number of basket slots (fish to catch).
  final int goal;

  /// Right-to-left UI: the basket fills from the right.
  final bool rtl;

  double get width => size.width;
  double get height => size.height;

  /// Top of the water.
  double get waterTop => height * 0.44;

  /// The grassy banks the brothers stand on rise a little above the water.
  double get bankTop => waterTop - height * 0.03;

  /// Nono's standing height (the `size` given to the character widgets).
  double get characterSize => (height * 0.30).clamp(110.0, 250.0);

  /// Feet of the fishing brother (left bank) and the referee (right bank).
  Offset get heroFeet => Offset(max(width * 0.15, 64), bankTop);
  Offset get refereeFeet => Offset(width - max(width * 0.13, 56), bankTop);

  double get fishWidth => (min(width, height) * 0.2).clamp(76.0, 150.0);
  double get fishHeight => fishWidth * 0.68;

  /// Fish swim in horizontal lanes under the surface.
  int get laneCount {
    final room = laneBottom - laneTop;
    return (room / (fishHeight * 1.1)).floor().clamp(2, 5);
  }

  double get laneTop => waterTop + fishHeight * 0.85;
  double get laneBottom => height - fishHeight * 0.85;

  double laneY(int lane) {
    final n = laneCount;
    if (n <= 1) return (laneTop + laneBottom) / 2;
    return laneTop + (laneBottom - laneTop) * lane / (n - 1);
  }

  /// The card at the top with the letter to catch and the basket slots.
  double get cardTop => 8;
  double get cardLetterSize => (height * 0.1).clamp(44.0, 72.0);
  double get slotGap => 6;
  static const double cardPadding = 16;

  /// Slots shrink on narrow screens so the card stays between the brothers.
  double get slotSize {
    final room = width * 0.56 - cardPadding * 2 - (goal - 1) * slotGap;
    return min(fishWidth * 0.42, room / goal).clamp(18.0, 46.0);
  }

  double get slotsTop => cardTop + 10 + cardLetterSize * 1.25 + 26;
  double get slotsWidth => goal * slotSize + (goal - 1) * slotGap;
  double get cardWidth => min(width, max(170, slotsWidth + cardPadding * 2));
  double get cardBottom => slotsTop + slotSize + 10;

  /// Center of basket slot [index] (0 = the first to fill).
  Offset slotCenter(int index) {
    final left = width / 2 - slotsWidth / 2;
    final column = rtl ? goal - 1 - index : index;
    return Offset(
      left + column * (slotSize + slotGap) + slotSize / 2,
      slotsTop + slotSize / 2,
    );
  }
}
