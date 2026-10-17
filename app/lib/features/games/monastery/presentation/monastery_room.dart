import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The empty room: [image] if there is one, otherwise plaster walls with
/// arched windows, wooden beams and a stone floor, drawn in code.
class MonasteryBackground extends StatelessWidget {
  const MonasteryBackground({super.key, this.image});

  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    const painted = CustomPaint(painter: _RoomPainter(), size: Size.infinite);
    final image = this.image;
    if (image == null) return painted;
    return Image(
      image: image,
      fit: BoxFit.fill,
      errorBuilder: (_, _, _) => painted,
    );
  }
}

/// One thing standing in front of the letters: its [image] cut-out, or
/// [shape] drawn in code.
class MonasteryObject extends StatelessWidget {
  const MonasteryObject({super.key, required this.shape, this.image});

  final String shape;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      painter: _ObjectPainter(shape),
      size: Size.infinite,
    );
    final image = this.image;
    if (image == null) return painted;
    return Image(
      image: image,
      fit: BoxFit.fill,
      errorBuilder: (_, _, _) => painted,
    );
  }
}

/// Outside the room's picture, on wide or tall screens: desert sand.
class DesertSurround extends StatelessWidget {
  const DesertSurround({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.monasteryDesert, AppColors.monasteryDesertDark],
      ),
    ),
  );
}

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Size s, [double k = 1]) => Paint()
  ..color = AppColors.cocoa
  ..style = PaintingStyle.stroke
  ..strokeWidth = max(1.2, min(s.width, s.height) * 0.025) * k
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// Fills [path] with [color] and outlines it.
void _shape(Canvas c, Size s, Path path, Color color, [double k = 1]) => c
  ..drawPath(path, _fill(color))
  ..drawPath(path, _line(s, k));

void _box(Canvas c, Size s, Rect r, Color color, {double radius = 0}) => _shape(
  c,
  s,
  Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius))),
  color,
);

/// An arch: a rectangle with a half-round top.
Path _arch(Rect r) {
  final rad = r.width / 2;
  return Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + rad)
    ..arcToPoint(Offset(r.right, r.top + rad), radius: Radius.circular(rad))
    ..lineTo(r.right, r.bottom)
    ..close();
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter();

  static const double floorY = 0.72;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floor = h * floorY;
    final outline = Paint()
      ..color = AppColors.cocoa.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, h * 0.004);

    // Plastered back wall.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, floor),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.monasteryWallShade, AppColors.monasteryWall],
        ).createShader(Rect.fromLTWH(0, 0, w, floor)),
    );

    // Arched windows with sky, and a dark niche.
    for (final r in [
      Rect.fromLTWH(w * 0.715, h * 0.1, w * 0.085, h * 0.24),
      Rect.fromLTWH(w * 0.2, h * 0.14, w * 0.05, h * 0.18),
    ]) {
      final p = _arch(r);
      canvas
        ..drawPath(p, _fill(AppColors.monasterySky))
        ..drawPath(p, outline);
    }
    final niche = _arch(Rect.fromLTWH(w * 0.885, h * 0.14, w * 0.07, h * 0.22));
    canvas
      ..drawPath(niche, _fill(AppColors.monasteryNiche))
      ..drawPath(niche, outline);

    // Ceiling beams.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.045),
      _fill(AppColors.monasteryBeam),
    );
    for (var x = w * 0.04; x < w; x += w * 0.12) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w * 0.025, h * 0.075),
        _fill(AppColors.monasteryWoodDark),
      );
    }

    // Stone floor, with tiles getting bigger toward the front.
    canvas.drawRect(
      Rect.fromLTWH(0, floor, w, h - floor),
      _fill(AppColors.monasteryFloor),
    );
    final tile = Paint()
      ..color = AppColors.monasteryFloorLine
      ..strokeWidth = max(1.0, h * 0.004);
    var y = floor;
    var step = h * 0.04;
    while (y < h) {
      canvas.drawLine(Offset(0, y), Offset(w, y), tile);
      y += step;
      step *= 1.35;
    }
    for (var i = -8; i <= 8; i++) {
      final top = w / 2 + i * w * 0.07;
      final bottom = w / 2 + i * w * 0.13;
      canvas.drawLine(Offset(top, floor), Offset(bottom, h), tile);
    }
    canvas.drawLine(Offset(0, floor), Offset(w, floor), outline);

    // A long rug down the middle of the floor.
    final rug = Path()
      ..moveTo(w * 0.36, floor + h * 0.02)
      ..lineTo(w * 0.62, floor + h * 0.02)
      ..lineTo(w * 0.68, h)
      ..lineTo(w * 0.3, h)
      ..close();
    canvas
      ..drawPath(rug, _fill(AppColors.monasteryRug))
      ..drawPath(
        rug,
        Paint()
          ..color = AppColors.monasteryRugBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.01,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ObjectPainter extends CustomPainter {
  _ObjectPainter(this.shape);

  final String shape;

  @override
  void paint(Canvas canvas, Size size) {
    switch (shape) {
      case 'bookshelf':
        _bookshelf(canvas, size);
      case 'lamp':
        _lamp(canvas, size);
      case 'chair':
        _chair(canvas, size);
      case 'door':
        _door(canvas, size);
      case 'candleStand':
        _candleStand(canvas, size);
      case 'lectern':
        _lectern(canvas, size);
      case 'curtain':
        _curtain(canvas, size);
      case 'plant':
        _plant(canvas, size);
      case 'jar':
        _jar(canvas, size);
      case 'basket':
        _basket(canvas, size);
      case 'bench':
        _bench(canvas, size);
      case 'books':
        _books(canvas, size);
      default:
        _box(canvas, size, Offset.zero & size, AppColors.monasteryWood);
    }
  }

  void _bookshelf(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _box(c, s, Offset.zero & s, AppColors.monasteryWood, radius: w * 0.04);
    const rows = 4;
    final inner = Rect.fromLTRB(w * 0.08, h * 0.04, w * 0.92, h * 0.96);
    final rowH = inner.height / rows;
    final rnd = Random(3);
    for (var r = 0; r < rows; r++) {
      final top = inner.top + r * rowH;
      final cell = Rect.fromLTWH(inner.left, top, inner.width, rowH * 0.86);
      c.drawRect(cell, _fill(AppColors.monasteryWoodDark));
      var x = cell.left + w * 0.02;
      while (x < cell.right - w * 0.06) {
        final bw = w * (0.07 + rnd.nextDouble() * 0.06);
        final bh = cell.height * (0.6 + rnd.nextDouble() * 0.38);
        if (x + bw > cell.right) break;
        _box(
          c,
          s,
          Rect.fromLTWH(x, cell.bottom - bh, bw, bh),
          AppColors.books[rnd.nextInt(AppColors.books.length)],
        );
        x += bw + w * 0.008;
      }
    }
  }

  void _lamp(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawLine(Offset(w / 2, 0), Offset(w / 2, h * 0.45), _line(s, 0.8));
    final bowl = Path()
      ..moveTo(w * 0.05, h * 0.5)
      ..lineTo(w * 0.95, h * 0.5)
      ..quadraticBezierTo(w * 0.9, h * 0.92, w / 2, h * 0.95)
      ..quadraticBezierTo(w * 0.1, h * 0.92, w * 0.05, h * 0.5)
      ..close();
    _shape(c, s, bowl, AppColors.monasteryBrass);
    _shape(
      c,
      s,
      Path()..addOval(Rect.fromLTWH(w * 0.35, h * 0.3, w * 0.3, h * 0.2)),
      AppColors.sunYellow,
      0.6,
    );
  }

  void _chair(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // Back, seat, then legs with gaps between them.
    _shape(
      c,
      s,
      Path()..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(w * 0.12, 0, w * 0.88, h * 0.52),
          topLeft: Radius.circular(w * 0.35),
          topRight: Radius.circular(w * 0.35),
        ),
      ),
      AppColors.monasteryWood,
    );
    _box(
      c,
      s,
      Rect.fromLTRB(w * 0.28, h * 0.12, w * 0.72, h * 0.42),
      AppColors.monasteryWoodDark,
      radius: w * 0.12,
    );
    _box(
      c,
      s,
      Rect.fromLTRB(0, h * 0.5, w, h * 0.62),
      AppColors.monasteryWood,
      radius: h * 0.02,
    );
    for (final x in [0.04, 0.82]) {
      _box(
        c,
        s,
        Rect.fromLTWH(w * x, h * 0.62, w * 0.14, h * 0.38),
        AppColors.monasteryWoodDark,
      );
    }
  }

  void _door(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _shape(c, s, _arch(Offset.zero & s), AppColors.monasteryNiche);
    final leaf = _arch(Rect.fromLTRB(w * 0.1, h * 0.04, w * 0.9, h));
    _shape(c, s, leaf, AppColors.monasteryWood);
    final plank = _line(s, 0.5);
    for (final x in [0.3, 0.5, 0.7]) {
      c.drawLine(Offset(w * x, h * 0.12), Offset(w * x, h), plank);
    }
    final stud = _fill(AppColors.monasteryWoodDark);
    for (final y in [0.35, 0.6, 0.85]) {
      for (final x in [0.2, 0.4, 0.6, 0.8]) {
        c.drawCircle(Offset(w * x, h * y), w * 0.025, stud);
      }
    }
    _shape(
      c,
      s,
      Path()..addOval(
        Rect.fromCircle(center: Offset(w * 0.78, h * 0.55), radius: w * 0.05),
      ),
      AppColors.monasteryBrass,
      0.6,
    );
  }

  void _candleStand(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // Candle and flame on a dish, a thin pole, a wide foot.
    _shape(
      c,
      s,
      Path()..addOval(Rect.fromLTWH(w * 0.3, 0, w * 0.4, h * 0.07)),
      AppColors.sunYellow,
      0.6,
    );
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.32, h * 0.06, w * 0.36, h * 0.12),
      AppColors.cream,
    );
    _box(
      c,
      s,
      Rect.fromLTWH(0, h * 0.17, w, h * 0.03),
      AppColors.monasteryBrass,
    );
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.4, h * 0.2, w * 0.2, h * 0.72),
      AppColors.monasteryBrass,
    );
    _shape(
      c,
      s,
      Path()
        ..moveTo(w * 0.4, h * 0.9)
        ..lineTo(w * 0.6, h * 0.9)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      AppColors.monasteryBrass,
    );
  }

  void _lectern(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.38, h * 0.3, w * 0.24, h * 0.62),
      AppColors.monasteryWood,
    );
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.1, h * 0.9, w * 0.8, h * 0.1),
      AppColors.monasteryWoodDark,
    );
    // Slanted top with an open book.
    _shape(
      c,
      s,
      Path()
        ..moveTo(0, h * 0.34)
        ..lineTo(w, h * 0.18)
        ..lineTo(w, h * 0.3)
        ..lineTo(0, h * 0.44)
        ..close(),
      AppColors.monasteryWoodDark,
    );
    _shape(
      c,
      s,
      Path()
        ..moveTo(w * 0.08, h * 0.28)
        ..quadraticBezierTo(w * 0.3, h * 0.16, w * 0.5, h * 0.22)
        ..quadraticBezierTo(w * 0.7, h * 0.1, w * 0.92, h * 0.14)
        ..lineTo(w * 0.92, h * 0.22)
        ..lineTo(w * 0.08, h * 0.36)
        ..close(),
      AppColors.cream,
      0.7,
    );
  }

  void _curtain(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // Hangs from a rod, tied back to the start side, open on the far side.
    final cloth = Path()
      ..moveTo(0, h * 0.05)
      ..lineTo(w * 0.62, h * 0.05)
      ..quadraticBezierTo(w * 0.42, h * 0.4, w * 0.28, h * 0.55)
      ..quadraticBezierTo(w * 0.42, h * 0.8, w * 0.46, h)
      ..lineTo(0, h)
      ..close();
    _shape(c, s, cloth, AppColors.monasteryCurtain);
    final fold = _line(s, 0.5);
    for (final x in [0.12, 0.26]) {
      c.drawLine(Offset(w * x, h * 0.08), Offset(w * x * 0.9, h * 0.97), fold);
    }
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.18, h * 0.52, w * 0.18, h * 0.06),
      AppColors.sunYellow,
    );
    _box(
      c,
      s,
      Rect.fromLTWH(0, 0, w, h * 0.06),
      AppColors.monasteryWoodDark,
      radius: h * 0.03,
    );
  }

  void _plant(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // Palm leaves fanning out (with gaps), over a clay pot.
    final leaf = _fill(AppColors.monasteryLeaf);
    final dark = _fill(AppColors.monasteryLeafDark);
    final base = Offset(w / 2, h * 0.66);
    for (var i = 0; i < 7; i++) {
      final a = -pi / 2 + (i - 3) * 0.42;
      final len = h * (i.isEven ? 0.6 : 0.5);
      final tip = base + Offset(cos(a), sin(a)) * len;
      final side = Offset(-sin(a), cos(a)) * w * 0.08;
      final mid = base + (tip - base) * 0.5;
      final p = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(mid.dx + side.dx, mid.dy + side.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(
          mid.dx - side.dx,
          mid.dy - side.dy,
          base.dx,
          base.dy,
        )
        ..close();
      c
        ..drawPath(p, i.isEven ? leaf : dark)
        ..drawPath(p, _line(s, 0.6));
    }
    _shape(
      c,
      s,
      Path()
        ..moveTo(w * 0.15, h * 0.64)
        ..lineTo(w * 0.85, h * 0.64)
        ..lineTo(w * 0.72, h)
        ..lineTo(w * 0.28, h)
        ..close(),
      AppColors.monasteryClay,
    );
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.1, h * 0.62, w * 0.8, h * 0.06),
      AppColors.monasteryClayDark,
    );
  }

  void _jar(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // A big clay water jar (zeer) on a little wooden stand.
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.12, h * 0.86, w * 0.76, h * 0.14),
      AppColors.monasteryWoodDark,
    );
    final body = Path()
      ..moveTo(w * 0.36, h * 0.08)
      ..lineTo(w * 0.64, h * 0.08)
      ..quadraticBezierTo(w * 0.62, h * 0.2, w * 0.82, h * 0.32)
      ..quadraticBezierTo(w * 1.02, h * 0.6, w * 0.6, h * 0.88)
      ..lineTo(w * 0.4, h * 0.88)
      ..quadraticBezierTo(-w * 0.02, h * 0.6, w * 0.18, h * 0.32)
      ..quadraticBezierTo(w * 0.38, h * 0.2, w * 0.36, h * 0.08)
      ..close();
    _shape(c, s, body, AppColors.monasteryClay);
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.3, 0, w * 0.4, h * 0.09),
      AppColors.monasteryClayDark,
      radius: h * 0.02,
    );
    c.drawLine(
      Offset(w * 0.2, h * 0.45),
      Offset(w * 0.8, h * 0.45),
      _line(s, 0.5),
    );
  }

  void _basket(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // Round loaves peeking over a woven basket.
    for (final (x, y) in [(0.3, 0.22), (0.55, 0.12), (0.72, 0.26)]) {
      _shape(
        c,
        s,
        Path()..addOval(
          Rect.fromCenter(
            center: Offset(w * x, h * y + h * 0.12),
            width: w * 0.34,
            height: h * 0.3,
          ),
        ),
        AppColors.monasteryBread,
        0.7,
      );
    }
    final body = Path()
      ..moveTo(0, h * 0.35)
      ..lineTo(w, h * 0.35)
      ..lineTo(w * 0.86, h)
      ..lineTo(w * 0.14, h)
      ..close();
    _shape(c, s, body, AppColors.monasteryWicker);
    final weave = _line(s, 0.4);
    for (var i = 1; i < 4; i++) {
      final y = h * (0.35 + i * 0.16);
      c.drawLine(Offset(w * 0.05, y), Offset(w * 0.95, y), weave);
    }
  }

  void _bench(Canvas c, Size s) {
    final w = s.width, h = s.height;
    for (final x in [0.06, 0.86]) {
      _box(
        c,
        s,
        Rect.fromLTWH(w * x, h * 0.3, w * 0.08, h * 0.7),
        AppColors.monasteryWoodDark,
      );
    }
    _box(
      c,
      s,
      Rect.fromLTWH(w * 0.1, h * 0.6, w * 0.8, h * 0.08),
      AppColors.monasteryWoodDark,
    );
    _box(
      c,
      s,
      Rect.fromLTWH(0, 0, w, h * 0.32),
      AppColors.monasteryWood,
      radius: h * 0.06,
    );
  }

  void _books(Canvas c, Size s) {
    final w = s.width, h = s.height;
    const colors = [AppColors.coral, AppColors.deepTeal, AppColors.sunYellow];
    final widths = [0.9, 1.0, 0.8];
    final offsets = [0.06, 0.0, 0.12];
    final bh = h / 3;
    for (var i = 0; i < 3; i++) {
      _box(
        c,
        s,
        Rect.fromLTWH(w * offsets[i], i * bh, w * widths[i], bh),
        colors[i],
        radius: bh * 0.15,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ObjectPainter oldDelegate) =>
      oldDelegate.shape != shape;
}
