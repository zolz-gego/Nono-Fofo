import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../../../core/theme/app_colors.dart';
import 'magic_basket_game.dart';

/// The big apple tree over the village: trunk, a wide leafy crown with a
/// few plain apples in it, and the branch the other brother sits on. Drawn
/// in code until the tree picture is added.
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

/// The woven basket the buddy carries, drawn in front of him. Apples in it
/// sit just behind the front so their tops show over the rim.
class BasketComponent extends PositionComponent {
  BasketComponent() : super(anchor: Anchor.topCenter, priority: 18);

  @override
  void render(ui.Canvas canvas) {
    final w = size.x;
    final h = size.y;
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
