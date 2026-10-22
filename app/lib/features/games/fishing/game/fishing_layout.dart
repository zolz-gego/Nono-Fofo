import 'dart:math';
import 'dart:ui';

import '../../shell/presentation/question_bar_layout.dart';
import '../domain/fishing_config.dart';

/// The Nile background picture and where its banks and water are.
class NileArt {
  const NileArt(this.imageSize, this.marks);

  final Size imageSize;
  final BackgroundMarks marks;
}

/// Where everything sits in the fishing scene, from the scene size (and the
/// background picture, when there is one). Both the Flame game and the
/// Flutter overlay (question bar, basket, referee) use it, so they always
/// line up.
class FishingLayout with QuestionBarLayout {
  FishingLayout(this.size, {required this.goal, this.rtl = false, this.art}) {
    _fitArt();
  }

  final Size size;

  /// Number of fish to catch.
  final int goal;

  /// Right-to-left UI: caught fish fly to the bar's icon on the right.
  final bool rtl;

  final NileArt? art;

  @override
  double get width => size.width;
  @override
  double get height => size.height;
  bool get isPortrait => height > width;

  /// Where a caught fish flies: the fish on the question bar.
  Offset get basket => progressIconCenter(rtl: rtl);

  // ---------------------------------------------------------------------------
  // Brothers and the river
  // ---------------------------------------------------------------------------

  /// Nono's standing height (the `size` given to the character widgets).
  double get characterSize => (height * 0.30).clamp(110.0, 250.0);

  /// Where the background picture is drawn (it covers the whole scene).
  Rect? imageRect;

  late double waterTop;

  /// Top of the banks the brothers stand on.
  late double bankTop;

  /// Feet of the fishing brother (left bank) and the referee (right bank).
  late Offset heroFeet;
  late Offset refereeFeet;

  /// True where the picture's banks are cut off (or there is no picture):
  /// the banks are then drawn in code under the brothers.
  bool drawLeftBank = true;
  bool drawRightBank = true;

  /// Right edge of the left bank: the line hangs into the water past it.
  late double leftBankEdge;

  late double _bed;

  void _fitArt() {
    final art = this.art;
    if (art == null) {
      waterTop = height * 0.44;
      bankTop = waterTop - height * 0.03;
      _bed = height;
      heroFeet = Offset(max(width * 0.15, 64), bankTop);
      refereeFeet = Offset(width - max(width * 0.13, 56), bankTop);
      leftBankEdge = heroFeet.dx + 96;
      return;
    }
    final m = art.marks;
    final iw = art.imageSize.width;
    final ih = art.imageSize.height;
    // Cover the scene. On tall screens the brothers' rods reach up under the
    // card, so the picture is scaled up until the banks sit low enough.
    var s = max(width / iw, height / ih);
    final wantBank = cardBottom + characterSize * 0.95;
    if (isPortrait) s = max(s, wantBank / (m.bankTop * ih));
    final w = iw * s;
    final h = ih * s;
    final dx = (width - w) / 2;
    // Keep the waterline near 44% of the height (and, on tall screens, the
    // banks under the card), without uncovering any edge.
    var dy = height * 0.44 - m.waterTop * h;
    if (isPortrait) dy = max(dy, wantBank - m.bankTop * h);
    dy = dy.clamp(height - h, 0.0);
    imageRect = Rect.fromLTWH(dx, dy, w, h);
    waterTop = dy + m.waterTop * h;
    bankTop = dy + m.bankTop * h + h * 0.004;
    _bed = dy + m.bedTop * h;

    final leftX = dx + m.leftBankX * w;
    final rightX = dx + m.rightBankX * w;
    const margin = 36.0;
    drawLeftBank = leftX < margin;
    drawRightBank = rightX > width - margin;
    heroFeet = Offset(drawLeftBank ? max(width * 0.15, 64) : leftX, bankTop);
    refereeFeet = Offset(
      drawRightBank ? width - max(width * 0.13, 56) : rightX,
      bankTop,
    );
    leftBankEdge = drawLeftBank ? heroFeet.dx + 96 : dx + m.leftBankEdge * w;
  }

  double get fishWidth => (min(width, height) * 0.2).clamp(76.0, 150.0);
  double get fishHeight => fishWidth * 0.71;

  /// Fish swim in horizontal lanes under the surface.
  int get laneCount {
    final room = laneBottom - laneTop;
    return (room / (fishHeight * 1.1)).floor().clamp(2, 5);
  }

  double get laneTop => waterTop + fishHeight * 0.85;
  double get laneBottom =>
      min(_bed - fishHeight * 0.45, height - fishHeight * 0.75);

  double laneY(int lane) {
    final n = laneCount;
    if (n <= 1) return (laneTop + laneBottom) / 2;
    return laneTop + (laneBottom - laneTop) * lane / (n - 1);
  }
}
