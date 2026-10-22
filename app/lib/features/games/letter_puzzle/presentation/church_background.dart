import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Inside an old church (placeholder art until a picture is made): a warm
/// wall with arched windows, red curtains at the sides and a wooden floor.
class ChurchBackground extends StatelessWidget {
  const ChurchBackground({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _ChurchPainter(), size: Size.infinite);
}

class _ChurchPainter extends CustomPainter {
  const _ChurchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floorTop = h * 0.82;

    // Wall.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, floorTop),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.churchWallShade, AppColors.churchWall],
        ).createShader(Rect.fromLTWH(0, 0, w, floorTop)),
    );

    // Arched windows along the wall.
    final count = max(3, (w / 260).round());
    final gap = w / count;
    final winW = min(gap * 0.42, 120.0);
    final winH = floorTop * 0.42;
    final winTop = floorTop * 0.08;
    for (var i = 0; i < count; i++) {
      final cx = gap * (i + 0.5);
      final frame = _arch(
        Rect.fromLTWH(cx - winW / 2 - 8, winTop - 8, winW + 16, winH + 16),
      );
      canvas.drawPath(frame, Paint()..color = AppColors.churchArch);
      final glass = _arch(Rect.fromLTWH(cx - winW / 2, winTop, winW, winH));
      canvas.drawPath(glass, Paint()..color = AppColors.churchWindow);
      canvas.drawCircle(
        Offset(cx, winTop + winH * 0.45),
        winW * 0.9,
        Paint()..color = AppColors.churchWindowGlow,
      );
      // A small cross in the glass.
      final bar = Paint()
        ..color = AppColors.churchArchDark
        ..strokeWidth = 3;
      final cy = winTop + winH * 0.4;
      canvas
        ..drawLine(
          Offset(cx, cy - winW * 0.25),
          Offset(cx, cy + winW * 0.3),
          bar,
        )
        ..drawLine(
          Offset(cx - winW * 0.18, cy - winW * 0.06),
          Offset(cx + winW * 0.18, cy - winW * 0.06),
          bar,
        );
    }

    // Floor with planks.
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, w, h - floorTop),
      Paint()..color = AppColors.churchFloor,
    );
    final line = Paint()
      ..color = AppColors.churchFloorLine
      ..strokeWidth = 2;
    for (var y = floorTop + 18; y < h; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }

    // Curtains at both sides.
    for (final left in [true, false]) {
      final cw = min(w * 0.07, 70.0);
      final x0 = left ? 0.0 : w - cw;
      final curtain = Path()
        ..moveTo(x0, 0)
        ..lineTo(x0 + cw, 0)
        ..quadraticBezierTo(
          left ? x0 + cw * 0.4 : x0 + cw * 0.6,
          floorTop * 0.5,
          left ? x0 + cw * 0.25 : x0 + cw * 0.75,
          floorTop,
        )
        ..lineTo(left ? x0 : x0 + cw, floorTop)
        ..close();
      canvas.drawPath(curtain, Paint()..color = AppColors.churchCurtain);
      final fold = Paint()
        ..color = AppColors.churchCurtainDark
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x0 + cw * 0.5, 0),
        Offset(left ? x0 + cw * 0.15 : x0 + cw * 0.85, floorTop),
        fold,
      );
    }
  }

  /// A round-topped window shape in [r].
  Path _arch(Rect r) {
    final radius = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + radius)
      ..arcToPoint(
        Offset(r.right, r.top + radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A saint's icon in a gold frame (placeholder: a halo, a face and a red
/// robe on a deep blue back).
class SaintIcon extends StatelessWidget {
  const SaintIcon({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, width * 1.25),
    painter: const _IconPainter(),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(outer, Paint()..color = AppColors.iconGold);
    canvas.drawRRect(
      outer.deflate(w * 0.03),
      Paint()
        ..color = AppColors.iconGoldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final inner = Rect.fromLTWH(w * 0.09, w * 0.09, w * 0.82, h - w * 0.18);
    canvas.drawRect(inner, Paint()..color = AppColors.iconBack);

    final cx = w / 2;
    final faceY = inner.top + inner.height * 0.33;
    final faceR = w * 0.14;
    canvas.drawCircle(
      Offset(cx, faceY),
      faceR * 1.75,
      Paint()..color = AppColors.iconHalo,
    );
    final robe = Path()
      ..moveTo(cx - faceR * 0.6, faceY + faceR * 0.8)
      ..lineTo(cx + faceR * 0.6, faceY + faceR * 0.8)
      ..lineTo(inner.right - w * 0.06, inner.bottom)
      ..lineTo(inner.left + w * 0.06, inner.bottom)
      ..close();
    canvas.drawPath(robe, Paint()..color = AppColors.iconRobe);
    canvas.drawCircle(
      Offset(cx, faceY),
      faceR,
      Paint()..color = AppColors.iconFace,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
