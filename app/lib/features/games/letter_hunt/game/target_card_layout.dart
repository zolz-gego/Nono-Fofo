import 'dart:math';
import 'dart:ui';

/// Where the card at the top of a "find the letter" scene sits: the letter
/// to catch and one progress slot per item to win. Each game's layout mixes
/// this in, so the Flame scene and the Flutter HUD line up.
mixin TargetCardLayout {
  Size get size;

  /// Number of progress slots (items to catch).
  int get goal;

  /// Right-to-left UI: the slots fill from the right.
  bool get rtl;

  /// Largest slot size; slots shrink on narrow screens.
  double get slotMaxSize;

  double get width => size.width;
  double get height => size.height;
  bool get isPortrait => height > width;

  double get cardTop => 8;
  double get cardLetterSize => (height * 0.1).clamp(44.0, 72.0);
  double get slotGap => 6;
  static const double cardPadding = 16;

  /// Slots shrink on narrow screens so the card stays between the brothers.
  double get slotSize {
    final room = width * 0.56 - cardPadding * 2 - (goal - 1) * slotGap;
    return min(slotMaxSize, room / goal).clamp(18.0, 46.0);
  }

  double get slotsTop => cardTop + 10 + cardLetterSize * 1.25 + 26;
  double get slotsWidth => goal * slotSize + (goal - 1) * slotGap;
  double get cardWidth => min(width, max(170, slotsWidth + cardPadding * 2));
  double get cardBottom => slotsTop + slotSize + 10;

  Rect get cardRect => Rect.fromLTRB(
    (width - cardWidth) / 2,
    cardTop,
    (width + cardWidth) / 2,
    cardBottom,
  );

  /// Center of progress slot [index] (0 = the first to fill).
  Offset slotCenter(int index) {
    final left = width / 2 - slotsWidth / 2;
    final column = rtl ? goal - 1 - index : index;
    return Offset(
      left + column * (slotSize + slotGap) + slotSize / 2,
      slotsTop + slotSize / 2,
    );
  }
}
