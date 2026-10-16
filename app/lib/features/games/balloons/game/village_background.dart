import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../../../core/theme/app_colors.dart';
import 'balloons_game.dart';

/// An Egyptian countryside village: big sky with drifting clouds, palms, a
/// row of pastel mud-brick houses and a pigeon tower, green fields, a small
/// canal, and the dirt path the brothers stand on. With a background
/// picture, the picture is drawn where the layout says instead.
class VillageBackground extends Component with HasGameReference<BalloonsGame> {
  VillageBackground({this.picture}) : super(priority: 0);

  final ui.Image? picture;

  double _time = 0;

  /// Houses along the horizon, as fractions of the width/height (fixed so
  /// the village doesn't change between frames).
  late final List<_House> _houses = _makeHouses();

  static List<_House> _makeHouses() {
    final r = Random(3);
    final houses = <_House>[];
    var x = -0.03;
    var i = 0;
    while (x < 1.02) {
      final w = 0.075 + r.nextDouble() * 0.05;
      houses.add(
        _House(
          x: x,
          width: w,
          height: 0.075 + r.nextDouble() * 0.06,
          color: AppColors.houses[i % AppColors.houses.length],
          straw: r.nextDouble() < 0.4,
          windows: 1 + r.nextInt(2),
          back: i.isOdd,
        ),
      );
      x += w * (0.78 + r.nextDouble() * 0.2);
      i++;
    }
    return houses;
  }

  @override
  void update(double dt) => _time += dt;

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
      return;
    }

    final ground = l.groundY;
    // Everything in the village sits relative to the path the brothers
    // stand on, so it lines up on any screen.
    final unit = min(h, w * 0.8);
    final pathTop = ground - unit * 0.06;
    final canalTop = pathTop - unit * 0.035;
    final houseBase = canalTop - unit * 0.07;

    _drawSky(canvas, w, houseBase);
    _drawHills(canvas, w, houseBase, unit);
    for (final px in [0.04, 0.27, 0.49, 0.83, 0.97]) {
      _palm(canvas, ui.Offset(w * px, houseBase + unit * 0.01), unit * 0.24);
    }
    for (final back in [true, false]) {
      for (final house in _houses.where((e) => e.back == back)) {
        _drawHouse(
          canvas,
          house,
          w,
          houseBase + (back ? -unit * 0.012 : unit * 0.006),
          unit,
        );
      }
      // The pigeon tower stands between the back and the front row.
      if (back) {
        _drawPigeonTower(
          canvas,
          ui.Offset(w * 0.66, houseBase + unit * 0.004),
          unit,
        );
      }
    }
    _drawFields(canvas, w, houseBase + unit * 0.006, canalTop);
    _drawCanal(canvas, w, canalTop, pathTop);
    _drawPath(canvas, w, h, pathTop, unit);
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
    final sun = ui.Offset(w * 0.1, bottom * 0.16);
    final r = min(bottom, w) * 0.07;
    canvas.drawCircle(sun, r * 1.6, ui.Paint()..color = AppColors.sunGlow);
    canvas.drawCircle(sun, r, ui.Paint()..color = AppColors.sunYellow);
    // Slow clouds at different heights.
    for (var i = 0; i < 4; i++) {
      final speed = 6.0 + i * 3;
      final cx = (w * (0.12 + 0.27 * i) + _time * speed) % (w + 200) - 100;
      _cloud(
        canvas,
        ui.Offset(cx, bottom * (0.14 + 0.17 * ((i * 3) % 4))),
        bottom * (0.05 + 0.012 * (i % 2)),
      );
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

  /// Far green fields rolling behind the houses.
  void _drawHills(ui.Canvas canvas, double w, double base, double unit) {
    final top = base - unit * 0.07;
    final land = ui.Path()..moveTo(0, base);
    for (var x = 0.0; x <= w + 1; x += w / 12) {
      land.lineTo(x, top + sin(x / w * pi * 2.4 + 0.6) * unit * 0.018);
    }
    land
      ..lineTo(w, base)
      ..close();
    canvas.drawPath(land, ui.Paint()..color = AppColors.farBank);
  }

  void _palm(ui.Canvas canvas, ui.Offset base, double height) {
    final trunk = ui.Paint()
      ..color = AppColors.palmTrunk
      ..strokeWidth = max(2, height * 0.06)
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;
    final top = base + ui.Offset(height * 0.1, -height);
    canvas.drawPath(
      ui.Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx - height * 0.06,
          base.dy - height * 0.5,
          top.dx,
          top.dy,
        ),
      trunk,
    );
    final leaf = ui.Paint()..color = AppColors.palmLeaf;
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * 0.55;
      final tip =
          top +
          ui.Offset(
            cos(a) * height * 0.4,
            sin(a) * height * 0.26 + height * 0.13,
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

  /// A traditional round pigeon tower (برج حمام) with rows of little holes.
  void _drawPigeonTower(ui.Canvas canvas, ui.Offset base, double unit) {
    final h = unit * 0.36;
    final bw = unit * 0.1;
    final tw = unit * 0.055;
    final body = ui.Path()
      ..moveTo(base.dx - bw / 2, base.dy)
      ..lineTo(base.dx - tw / 2, base.dy - h * 0.82)
      ..quadraticBezierTo(
        base.dx,
        base.dy - h * 1.05,
        base.dx + tw / 2,
        base.dy - h * 0.82,
      )
      ..lineTo(base.dx + bw / 2, base.dy)
      ..close();
    canvas.drawPath(body, ui.Paint()..color = AppColors.pigeonTower);
    canvas.drawPath(
      body,
      ui.Paint()
        ..color = AppColors.cocoa.withValues(alpha: 0.55)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = max(1, unit * 0.003),
    );
    final hole = ui.Paint()..color = AppColors.cocoa.withValues(alpha: 0.75);
    for (var row = 0; row < 6; row++) {
      final y = base.dy - h * (0.12 + row * 0.12);
      final width = ui.lerpDouble(bw, tw, (row * 0.12 + 0.12) / 0.82)! * 0.8;
      final n = 4 - row ~/ 2;
      for (var i = 0; i < n; i++) {
        final x = base.dx - width / 2 + width * (i + 0.5) / n;
        canvas.drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(x, y),
            width: unit * 0.008,
            height: unit * 0.011,
          ),
          hole,
        );
      }
    }
  }

  void _drawHouse(
    ui.Canvas canvas,
    _House house,
    double w,
    double base,
    double unit,
  ) {
    final left = house.x * w;
    final width = house.width * w;
    final height = house.height * unit * 1.6;
    final wall = ui.Rect.fromLTWH(left, base - height, width, height);
    final line = ui.Paint()
      ..color = AppColors.cocoa.withValues(alpha: 0.6)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = max(1, unit * 0.0035);
    canvas.drawRect(wall, ui.Paint()..color = house.color);
    // Soft shade on the right side.
    canvas.drawRect(
      ui.Rect.fromLTRB(
        wall.right - width * 0.18,
        wall.top,
        wall.right,
        wall.bottom,
      ),
      ui.Paint()..color = AppColors.ink.withValues(alpha: 0.06),
    );
    canvas.drawRect(wall, line);
    // Flat roof lip, sometimes with a pile of straw / palm fronds on top.
    final lip = ui.Rect.fromLTWH(
      left - width * 0.03,
      wall.top - unit * 0.008,
      width * 1.06,
      unit * 0.01,
    );
    canvas.drawRect(
      lip,
      ui.Paint()..color = ui.Color.lerp(house.color, AppColors.cocoa, 0.25)!,
    );
    if (house.straw) {
      final straw = ui.Path()
        ..moveTo(left + width * 0.12, lip.top)
        ..quadraticBezierTo(
          left + width * 0.35,
          lip.top - unit * 0.035,
          left + width * 0.62,
          lip.top,
        )
        ..close();
      canvas.drawPath(straw, ui.Paint()..color = AppColors.roofStraw);
    }
    // Door.
    final doorW = width * 0.22;
    final doorH = height * 0.45;
    final door = ui.RRect.fromRectAndCorners(
      ui.Rect.fromLTWH(
        left + width * 0.38 - doorW / 2,
        base - doorH,
        doorW,
        doorH,
      ),
      topLeft: ui.Radius.circular(doorW / 2),
      topRight: ui.Radius.circular(doorW / 2),
    );
    canvas.drawRRect(door, ui.Paint()..color = AppColors.houseDoor);
    // Small windows.
    final win = ui.Paint()..color = AppColors.houseWindow;
    for (var i = 0; i < house.windows; i++) {
      final cx = left + width * (house.windows == 1 ? 0.72 : 0.62 + i * 0.2);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(
            center: ui.Offset(cx, base - height * 0.68),
            width: width * 0.13,
            height: height * 0.2,
          ),
          ui.Radius.circular(width * 0.03),
        ),
        win,
      );
    }
  }

  void _drawFields(ui.Canvas canvas, double w, double top, double bottom) {
    canvas.drawRect(
      ui.Rect.fromLTRB(0, top, w, bottom),
      ui.Paint()..color = AppColors.villageField,
    );
    final row = ui.Paint()
      ..color = AppColors.villageFieldRow
      ..strokeWidth = max(1.5, (bottom - top) * 0.08)
      ..strokeCap = ui.StrokeCap.round;
    final rows = 2;
    for (var r = 0; r < rows; r++) {
      final y = top + (bottom - top) * (0.35 + r * 0.35);
      for (var x = (r * 9.0) % 18; x < w; x += 18) {
        canvas.drawLine(ui.Offset(x, y), ui.Offset(x + 8, y), row);
      }
    }
  }

  void _drawCanal(ui.Canvas canvas, double w, double top, double bottom) {
    canvas.drawRect(
      ui.Rect.fromLTRB(0, top, w, bottom),
      ui.Paint()..color = AppColors.villageCanal,
    );
    final shine = ui.Paint()
      ..color = AppColors.waterShine
      ..strokeWidth = max(1.2, (bottom - top) * 0.12)
      ..strokeCap = ui.StrokeCap.round;
    final y = (top + bottom) / 2;
    final drift = (_time * 12) % 60;
    for (var x = drift - 60; x < w; x += 60) {
      canvas.drawLine(ui.Offset(x, y), ui.Offset(x + 16, y), shine);
    }
  }

  void _drawPath(
    ui.Canvas canvas,
    double w,
    double h,
    double top,
    double unit,
  ) {
    canvas.drawRect(
      ui.Rect.fromLTRB(0, top, w, h),
      ui.Paint()..color = AppColors.villagePath,
    );
    canvas.drawRect(
      ui.Rect.fromLTRB(0, top, w, top + max(2, unit * 0.008)),
      ui.Paint()..color = AppColors.villagePathEdge,
    );
    final r = Random(11);
    final pebble = ui.Paint()..color = AppColors.villagePathEdge;
    for (var i = 0; i < 26; i++) {
      canvas.drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(
            r.nextDouble() * w,
            top + unit * 0.02 + r.nextDouble() * (h - top),
          ),
          width: unit * (0.008 + r.nextDouble() * 0.01),
          height: unit * 0.006,
        ),
        pebble,
      );
    }
  }
}

class _House {
  const _House({
    required this.x,
    required this.width,
    required this.height,
    required this.color,
    required this.straw,
    required this.windows,
    required this.back,
  });

  final double x;
  final double width;
  final double height;
  final ui.Color color;
  final bool straw;
  final int windows;

  /// Drawn a little behind the others, so the row looks deeper.
  final bool back;
}
