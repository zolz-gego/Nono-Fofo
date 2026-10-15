import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../../../core/theme/app_colors.dart';
import 'fishing_game.dart';

/// The Nile: sky, far bank with palms and a sailing felucca, the two grassy
/// banks the brothers stand on, and the water with bubbles and reeds.
/// With a background picture, the picture is drawn where the layout says
/// (plus moving bubbles), and a code bank is only added where the picture's
/// bank is cut off on narrow screens.
class NileBackground extends Component with HasGameReference<FishingGame> {
  NileBackground({this.picture}) : super(priority: 0);

  final ui.Image? picture;

  double _time = 0;
  final _random = Random(7);
  late final List<_Bubble> _bubbles = [
    for (var i = 0; i < 14; i++)
      _Bubble(
        _random.nextDouble(),
        _random.nextDouble(),
        0.5 + _random.nextDouble(),
        0.04 + _random.nextDouble() * 0.05,
      ),
  ];

  @override
  void update(double dt) {
    _time += dt;
    for (final b in _bubbles) {
      b.y -= dt * b.speed;
      if (b.y < 0) {
        b
          ..y = 1
          ..x = _random.nextDouble();
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final l = game.layout;
    final w = l.width;
    final h = l.height;

    final picture = this.picture;
    final rect = l.imageRect;
    if (picture != null && rect != null) {
      canvas.drawImageRect(
        picture,
        ui.Rect.fromLTWH(
          0,
          0,
          picture.width.toDouble(),
          picture.height.toDouble(),
        ),
        rect,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      _drawBubbles(canvas, w, h, l.waterTop);
    } else {
      _drawSky(canvas, w, l.waterTop);
      _drawFarBank(
        canvas,
        w,
        l.waterTop,
        from: l.heroFeet.dx + 90,
        to: l.refereeFeet.dx - 90,
      );
      _drawWater(canvas, w, h, l.waterTop);
    }
    if (l.drawLeftBank) {
      _drawBank(canvas, l.heroFeet.dx, l.bankTop, l.waterTop, left: true, w: w);
    }
    if (l.drawRightBank) {
      _drawBank(
        canvas,
        l.refereeFeet.dx,
        l.bankTop,
        l.waterTop,
        left: false,
        w: w,
      );
    }
  }

  void _drawSky(ui.Canvas canvas, double w, double bottom) {
    final rect = ui.Rect.fromLTWH(0, 0, w, bottom);
    canvas.drawRect(
      rect,
      ui.Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          AppColors.skyTop,
          AppColors.skyBottom,
        ]),
    );
    final sun = ui.Offset(w * 0.7, bottom * 0.3);
    canvas.drawCircle(sun, bottom * 0.2, ui.Paint()..color = AppColors.sunGlow);
    canvas.drawCircle(
      sun,
      bottom * 0.13,
      ui.Paint()..color = AppColors.sunYellow,
    );
    // Two slow clouds.
    for (var i = 0; i < 2; i++) {
      final cx = (w * (0.15 + 0.5 * i) + _time * (8 + i * 5)) % (w + 160) - 80;
      _cloud(canvas, ui.Offset(cx, bottom * (0.18 + i * 0.24)), bottom * 0.07);
    }
  }

  void _cloud(ui.Canvas canvas, ui.Offset c, double r) {
    final p = ui.Paint()..color = AppColors.cream;
    canvas
      ..drawCircle(c, r, p)
      ..drawCircle(c + ui.Offset(r * 0.9, r * 0.2), r * 0.8, p)
      ..drawCircle(c + ui.Offset(-r * 0.9, r * 0.25), r * 0.7, p)
      ..drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTRB(
            c.dx - r * 1.5,
            c.dy,
            c.dx + r * 1.6,
            c.dy + r * 0.9,
          ),
          ui.Radius.circular(r * 0.45),
        ),
        p,
      );
  }

  void _drawFarBank(
    ui.Canvas canvas,
    double w,
    double waterTop, {
    required double from,
    required double to,
  }) {
    final top = waterTop - waterTop * 0.12;
    final land = ui.Path()..moveTo(0, waterTop);
    for (var x = 0.0; x <= w; x += w / 8) {
      land.lineTo(x, top + sin(x / w * pi * 3) * waterTop * 0.02);
    }
    land
      ..lineTo(w, waterTop)
      ..close();
    canvas.drawPath(land, ui.Paint()..color = AppColors.farBank);
    for (final px in [0.08, 0.31, 0.38, 0.62, 0.9]) {
      _palm(canvas, ui.Offset(w * px, top + 2), waterTop * 0.22);
    }
    // A felucca sailing slowly between the two banks.
    final fx = from + (_time * 14) % max(1, to - from);
    _felucca(canvas, ui.Offset(fx, waterTop - 2), waterTop * 0.16);
  }

  void _palm(ui.Canvas canvas, ui.Offset base, double height) {
    final trunk = ui.Paint()
      ..color = AppColors.palmTrunk
      ..strokeWidth = max(2, height * 0.07)
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;
    final top = base + ui.Offset(height * 0.12, -height);
    canvas.drawPath(
      ui.Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx - height * 0.05,
          base.dy - height * 0.5,
          top.dx,
          top.dy,
        ),
      trunk,
    );
    final leaf = ui.Paint()..color = AppColors.palmLeaf;
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + (i - 2) * 0.62;
      final tip =
          top +
          ui.Offset(
            cos(a) * height * 0.42,
            sin(a) * height * 0.3 + height * 0.12,
          );
      canvas.drawPath(
        ui.Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            (top.dx + tip.dx) / 2,
            top.dy - height * 0.12,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            (top.dx + tip.dx) / 2,
            top.dy - height * 0.02,
            top.dx,
            top.dy,
          ),
        leaf,
      );
    }
  }

  void _felucca(ui.Canvas canvas, ui.Offset at, double s) {
    final hull = ui.Path()
      ..moveTo(at.dx - s * 0.7, at.dy - s * 0.18)
      ..lineTo(at.dx + s * 0.7, at.dy - s * 0.18)
      ..quadraticBezierTo(at.dx + s * 0.5, at.dy, at.dx, at.dy)
      ..quadraticBezierTo(
        at.dx - s * 0.5,
        at.dy,
        at.dx - s * 0.7,
        at.dy - s * 0.18,
      );
    canvas.drawPath(hull, ui.Paint()..color = AppColors.cocoa);
    final sail = ui.Path()
      ..moveTo(at.dx - s * 0.05, at.dy - s * 0.2)
      ..lineTo(at.dx + s * 0.05, at.dy - s * 1.3)
      ..quadraticBezierTo(
        at.dx + s * 0.75,
        at.dy - s * 0.6,
        at.dx + s * 0.55,
        at.dy - s * 0.24,
      )
      ..close();
    canvas.drawPath(sail, ui.Paint()..color = AppColors.cream);
  }

  void _drawWater(ui.Canvas canvas, double w, double h, double top) {
    final surface = ui.Path()..moveTo(0, h);
    final waveH = (h - top) * 0.012 + 2;
    for (var x = 0.0; x <= w + 8; x += 8) {
      surface.lineTo(x, top + sin(x / 38 + _time * 1.6) * waveH);
    }
    surface
      ..lineTo(w, h)
      ..close();
    final rect = ui.Rect.fromLTWH(0, top, w, h - top);
    canvas.drawPath(
      surface,
      ui.Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          AppColors.waterTop,
          AppColors.waterDeep,
        ]),
    );
    // Shine lines on the surface.
    final shine = ui.Paint()
      ..color = AppColors.waterShine
      ..strokeWidth = 2.5
      ..strokeCap = ui.StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final x = (w * (i / 6) + _time * 12) % w;
      final y = top + (h - top) * 0.05 + (i % 2) * 7;
      canvas.drawLine(ui.Offset(x, y), ui.Offset(x + 26, y), shine);
    }
    // River bed, pebbles and reeds.
    final bed = ui.Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += w / 10) {
      bed.lineTo(x, h - h * 0.035 - sin(x / w * pi * 4) * h * 0.012);
    }
    bed
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bed, ui.Paint()..color = AppColors.riverBed);
    final pebble = ui.Paint()..color = AppColors.pebble;
    for (final px in [0.12, 0.27, 0.45, 0.58, 0.77, 0.93]) {
      canvas.drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(w * px, h - h * 0.018),
          width: 16,
          height: 9,
        ),
        pebble,
      );
    }
    for (final rx in [0.03, 0.06, 0.5, 0.95, 0.98]) {
      _reed(
        canvas,
        ui.Offset(w * rx, h - h * 0.02),
        (h - top) * 0.32,
        sin(_time * 1.3 + rx * 9) * 0.08,
      );
    }
    _drawBubbles(canvas, w, h, top);
  }

  void _drawBubbles(ui.Canvas canvas, double w, double h, double top) {
    final bubble = ui.Paint()
      ..color = AppColors.waterShine
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final b in _bubbles) {
      canvas.drawCircle(
        ui.Offset(
          b.x * w + sin(_time * 2 + b.x * 10) * 4,
          top + 12 + b.y * (h - top - 24),
        ),
        3 * b.size,
        bubble,
      );
    }
  }

  void _reed(ui.Canvas canvas, ui.Offset base, double height, double sway) {
    final p = ui.Paint()
      ..color = AppColors.reed
      ..strokeWidth = 4
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;
    for (var i = -1; i <= 1; i++) {
      final hgt = height * (1 - i.abs() * 0.25);
      canvas.drawPath(
        ui.Path()
          ..moveTo(base.dx + i * 6, base.dy)
          ..quadraticBezierTo(
            base.dx + i * 10,
            base.dy - hgt * 0.5,
            base.dx + i * 12 + sway * hgt,
            base.dy - hgt,
          ),
        p,
      );
    }
  }

  /// A small grassy bank sticking out of the water for a brother to stand on.
  void _drawBank(
    ui.Canvas canvas,
    double cx,
    double top,
    double waterTop, {
    required bool left,
    required double w,
  }) {
    // A ledge: never deeper than a small block, even when the water is far
    // below (big picture on tall screens).
    final depth = min((waterTop - top).abs() * 2.2 + 10, 46.0);
    final reach = cx + (left ? 1 : -1) * 70;
    final edge = left ? 0.0 : w;
    final ground = ui.Path()
      ..moveTo(edge, top - 4)
      ..lineTo(reach - (left ? 20 : -20), top)
      ..quadraticBezierTo(
        reach + (left ? 18 : -18),
        top + 2,
        reach + (left ? 26 : -26),
        top + depth * 0.45,
      )
      ..quadraticBezierTo(reach, top + depth, edge, top + depth)
      ..close();
    canvas.drawPath(ground, ui.Paint()..color = AppColors.bankEarth);
    final grass = ui.Path()
      ..moveTo(edge, top - 8)
      ..lineTo(reach - (left ? 14 : -14), top - 3)
      ..quadraticBezierTo(
        reach + (left ? 14 : -14),
        top - 2,
        reach + (left ? 18 : -18),
        top + 7,
      )
      ..lineTo(edge, top + 7)
      ..close();
    canvas.drawPath(grass, ui.Paint()..color = AppColors.leafGreen);
  }
}

class _Bubble {
  _Bubble(this.x, this.y, this.size, this.speed);
  double x;
  double y;
  final double size;
  final double speed;
}
