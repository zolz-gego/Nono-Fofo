import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Alexandria by the sea: [image] if there is one, otherwise a simple
/// sky, sea, the Qaitbay fort far away and the beach, drawn in code.
class SeasideBackground extends StatelessWidget {
  const SeasideBackground({super.key, this.image});

  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    if (image != null) {
      return Image(
        image: image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _SeasidePainting(),
      );
    }
    return const _SeasidePainting();
  }
}

class _SeasidePainting extends StatelessWidget {
  const _SeasidePainting();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SeasidePainter(), size: Size.infinite);
}

class _SeasidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.34, shore = h * 0.52;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.seaSkyTop, AppColors.seaSkyBottom],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon)),
    );
    // Sun.
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.1),
      min(w, h) * 0.06,
      Paint()..color = AppColors.sunYellow,
    );

    // Qaitbay fort, far away on the start side.
    final fort = Paint()..color = AppColors.fortWall;
    final fx = w * 0.06, fw = w * 0.2, fh = h * 0.07;
    canvas
      ..drawRect(Rect.fromLTWH(fx, horizon - fh, fw, fh), fort)
      ..drawRect(
        Rect.fromLTWH(fx + fw * 0.35, horizon - fh * 1.8, fw * 0.3, fh * 0.8),
        fort,
      )
      ..drawRect(
        Rect.fromLTWH(fx + fw * 0.46, horizon - fh * 2.4, fw * 0.08, fh * 0.6),
        Paint()..color = AppColors.fortShade,
      );

    // Sea.
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, shore - horizon),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.seaFar, AppColors.seaNear],
        ).createShader(Rect.fromLTWH(0, horizon, w, shore - horizon)),
    );
    final foam = Paint()
      ..color = AppColors.seaFoam
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, h * 0.004)
      ..strokeCap = StrokeCap.round;
    final rnd = Random(7);
    for (var i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * w;
      final y = horizon + 8 + rnd.nextDouble() * (shore - horizon - 20);
      final len = w * (0.02 + rnd.nextDouble() * 0.03);
      canvas.drawArc(
        Rect.fromLTWH(x, y, len, len * 0.5),
        pi * 1.1,
        pi * 0.8,
        false,
        foam,
      );
    }

    // Beach, with a wavy edge of foam.
    final edge = Path()..moveTo(0, shore);
    for (var x = 0.0; x <= w; x += w / 24) {
      edge.lineTo(x, shore + sin(x / w * pi * 6) * h * 0.008);
    }
    final beach = Path()
      ..addPath(edge, Offset.zero)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas
      ..drawPath(
        beach,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.beachSand, AppColors.beachSandDark],
          ).createShader(Rect.fromLTWH(0, shore, w, h - shore)),
      )
      ..drawPath(
        edge,
        Paint()
          ..color = AppColors.seaFoam
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(3.0, h * 0.006),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
