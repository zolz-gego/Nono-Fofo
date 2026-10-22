import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../../../core/theme/app_colors.dart';
import 'magic_basket_game.dart';

/// The big apple tree over the village, with the branch the other brother
/// sits on: the tree picture (mirrored in Arabic, so the branch is on the
/// start side), or a code-drawn tree when there is none.
class AppleTree extends Component with HasGameReference<MagicBasketGame> {
  AppleTree() : super(priority: 2);

  /// Leaf clumps as fractions of the canopy (fixed so the crown doesn't
  /// change between frames): x, y, radius, shade.
  static final List<(double, double, double, int)> _clumps = () {
    final r = Random(7);
    return [
      for (var i = 0; i < 26; i++)
        (
          0.04 + 0.92 * (i / 25) + (r.nextDouble() - 0.5) * 0.05,
          0.25 + r.nextDouble() * 0.5,
          0.09 + r.nextDouble() * 0.06,
          r.nextInt(3),
        ),
    ];
  }();

  static final List<ui.Offset> _hanging = () {
    final r = Random(11);
    return [
      for (var i = 0; i < 9; i++)
        ui.Offset(0.08 + 0.84 * i / 8, 0.45 + r.nextDouble() * 0.35),
    ];
  }();

  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    final picture = game.treePicture;
    final rect = game.layout.treeRect;
    if (picture != null && rect != null) {
      canvas.save();
      if (game.layout.rtl) {
        canvas
          ..translate(rect.center.dx, 0)
          ..scale(-1, 1)
          ..translate(-rect.center.dx, 0);
      }
      canvas
        ..drawImageRect(
          picture,
          ui.Rect.fromLTWH(
            0,
            0,
            picture.width.toDouble(),
            picture.height.toDouble(),
          ),
          rect,
          ui.Paint()..filterQuality = ui.FilterQuality.medium,
        )
        ..restore();
      return;
    }
    _renderDrawn(canvas);
  }

  void _renderDrawn(ui.Canvas canvas) {
    final l = game.layout;
    final crown = l.canopy;

    // Trunk, wider at the roots, behind the path line.
    final tw = l.trunkWidth;
    final x = l.trunkX;
    final trunk = ui.Path()
      ..moveTo(x - tw * 0.38, crown.bottom - tw * 0.4)
      ..lineTo(x + tw * 0.38, crown.bottom - tw * 0.4)
      ..quadraticBezierTo(
        x + tw * 0.42,
        l.groundY - tw * 0.8,
        x + tw,
        l.groundY - tw * 0.12,
      )
      ..lineTo(x - tw, l.groundY - tw * 0.12)
      ..quadraticBezierTo(
        x - tw * 0.42,
        l.groundY - tw * 0.8,
        x - tw * 0.38,
        crown.bottom - tw * 0.4,
      )
      ..close();
    canvas
      ..drawPath(trunk, ui.Paint()..color = AppColors.treeTrunk)
      ..drawPath(
        trunk,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.treeTrunkDark,
      );
    // Two big limbs into the crown.
    final limb = ui.Paint()
      ..color = AppColors.treeTrunk
      ..strokeWidth = tw * 0.32
      ..strokeCap = ui.StrokeCap.round;
    canvas
      ..drawLine(
        ui.Offset(x, crown.bottom),
        ui.Offset(x - crown.width * 0.22, crown.center.dy),
        limb,
      )
      ..drawLine(
        ui.Offset(x, crown.bottom),
        ui.Offset(x + crown.width * 0.22, crown.center.dy),
        limb,
      );

    // The crown: overlapping leaf clumps, dark ones first.
    final shades = [
      AppColors.treeLeafDark,
      AppColors.treeLeaf,
      AppColors.treeLeafLight,
    ];
    final unit = min(crown.width, crown.height * 2.6);
    for (final shade in [0, 1, 2]) {
      final paint = ui.Paint()..color = shades[shade];
      for (final (cx, cy, r, s) in _clumps) {
        if (s != shade) continue;
        final sway = sin(_time * 0.8 + cx * 9) * unit * 0.003;
        canvas.drawCircle(
          ui.Offset(
            crown.left + crown.width * cx + sway,
            crown.top + crown.height * cy,
          ),
          unit * r,
          paint,
        );
      }
    }

    // Plain apples still on the tree.
    final ar = l.appleSize * 0.2;
    for (final p in _hanging) {
      final c = ui.Offset(
        crown.left + crown.width * p.dx,
        crown.top + crown.height * p.dy,
      );
      canvas
        ..drawCircle(c, ar, ui.Paint()..color = AppColors.apple)
        ..drawCircle(
          c - ui.Offset(ar * 0.35, ar * 0.35),
          ar * 0.3,
          ui.Paint()..color = AppColors.appleShine,
        );
    }

    // The branch the thrower sits on.
    final (from, to) = l.branch;
    canvas.drawLine(
      from,
      to,
      ui.Paint()
        ..color = AppColors.treeTrunk
        ..strokeWidth = max(8, l.throwerSize * 0.08)
        ..strokeCap = ui.StrokeCap.round,
    );
  }
}

/// The woven basket the buddy carries, drawn in front of him, placed by the
/// middle of its opening. Apples in it sit on that line: a second
/// [frontOnly] basket draws the part below it again over them, so they
/// look inside.
class BasketComponent extends PositionComponent {
  BasketComponent({this.picture, this.opening = 0, this.frontOnly = false})
    : super(
        anchor: Anchor(0.5, picture == null ? 0 : opening),
        priority: frontOnly ? 18 : 16,
      );

  /// The basket picture, or null to draw one in code.
  final ui.Image? picture;

  /// The middle of the opening, as a fraction of the picture's height.
  final double opening;
  final bool frontOnly;

  @override
  void render(ui.Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final picture = this.picture;
    if (picture != null) {
      final src = ui.Rect.fromLTWH(
        0,
        0,
        picture.width.toDouble(),
        picture.height.toDouble(),
      );
      final dst = ui.Rect.fromLTWH(0, 0, w, h);
      canvas.save();
      if (frontOnly) canvas.clipRect(ui.Rect.fromLTRB(0, h * opening, w, h));
      canvas
        ..drawImageRect(
          picture,
          src,
          dst,
          ui.Paint()..filterQuality = ui.FilterQuality.medium,
        )
        ..restore();
      return;
    }
    // The code-drawn basket has its rim at the top: all of it is the front.
    if (!frontOnly) return;
    final body = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w * 0.86, h)
      ..lineTo(w * 0.14, h)
      ..close();
    canvas.drawPath(body, ui.Paint()..color = AppColors.basket);
    // Weave.
    final weave = ui.Paint()
      ..color = AppColors.basketDark
      ..strokeWidth = max(1.5, w * 0.02);
    for (var i = 1; i < 3; i++) {
      final y = h * i / 3;
      final inset = w * 0.14 * y / h;
      canvas.drawLine(ui.Offset(inset, y), ui.Offset(w - inset, y), weave);
    }
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      canvas.drawLine(
        ui.Offset(w * t, 0),
        ui.Offset(w * 0.14 + w * 0.72 * t, h),
        weave,
      );
    }
    canvas
      ..drawPath(
        body,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = max(2, w * 0.025)
          ..color = AppColors.basketDark,
      )
      // Rim.
      ..drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(-w * 0.03, -h * 0.1, w * 1.06, h * 0.2),
          ui.Radius.circular(h * 0.1),
        ),
        ui.Paint()..color = AppColors.basketRim,
      );
  }
}
