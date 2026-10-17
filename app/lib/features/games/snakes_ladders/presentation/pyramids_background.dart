import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Placeholder scene behind the board: sky, sun, the three Pyramids and
/// sand dunes.
class PyramidsBackground extends StatelessWidget {
  const PyramidsBackground({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _PyramidsPainter(), child: SizedBox.expand());
}

class _PyramidsPainter extends CustomPainter {
  const _PyramidsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.62;
    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.pyramidSkyTop, AppColors.pyramidSkyBottom],
          ).createShader(Rect.fromLTWH(0, 0, w, horizon)),
      )
      ..drawCircle(
        Offset(w * 0.86, h * 0.14),
        h * 0.07,
        Paint()..color = AppColors.sunYellow.withValues(alpha: 0.9),
      )
      ..drawCircle(
        Offset(w * 0.86, h * 0.14),
        h * 0.12,
        Paint()..color = AppColors.sunGlow,
      );

    // Big, middle and small pyramid, lit from the right.
    void pyramid(double cx, double base, double height) {
      final apex = Offset(cx, horizon - height);
      final left = Offset(cx - base / 2, horizon + 2);
      final right = Offset(cx + base / 2, horizon + 2);
      final foot = Offset(cx + base * 0.12, horizon + 2);
      canvas
        ..drawPath(
          Path()
            ..moveTo(apex.dx, apex.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(foot.dx, foot.dy)
            ..close(),
          Paint()..color = AppColors.pyramidShade,
        )
        ..drawPath(
          Path()
            ..moveTo(apex.dx, apex.dy)
            ..lineTo(foot.dx, foot.dy)
            ..lineTo(right.dx, right.dy)
            ..close(),
          Paint()..color = AppColors.pyramidLight,
        );
    }

    pyramid(w * 0.2, h * 0.5, h * 0.3);
    pyramid(w * 0.42, h * 0.38, h * 0.22);
    pyramid(w * 0.58, h * 0.22, h * 0.13);

    canvas
      ..drawPath(
        Path()
          ..moveTo(0, horizon)
          ..quadraticBezierTo(w * 0.35, horizon - h * 0.04, w * 0.7, horizon)
          ..quadraticBezierTo(w * 0.88, horizon + h * 0.03, w, horizon - 6)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = AppColors.pyramidDune,
      )
      ..drawPath(
        Path()
          ..moveTo(0, h * 0.82)
          ..quadraticBezierTo(w * 0.3, h * 0.76, w * 0.6, h * 0.84)
          ..quadraticBezierTo(w * 0.85, h * 0.9, w, h * 0.8)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = AppColors.pyramidDuneDark,
      );
  }

  @override
  bool shouldRepaint(_PyramidsPainter old) => false;
}
