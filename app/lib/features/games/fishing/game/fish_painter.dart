import 'dart:math';
import 'dart:ui';

import '../../../../core/theme/app_colors.dart';

/// Draws a cute flat cartoon fish facing right, centered on (0, 0), with a
/// cream patch in the middle for the letter. Used until painted fish images
/// are added (see design/game-prompts.md).
class FishPainter {
  FishPainter(this.color);

  final Color color;

  /// Where the letter patch sits, as a fraction of the fish width.
  static const double patchX = -0.03;

  late final Paint _body = Paint()..color = color;
  late final Paint _fin = Paint()
    ..color = Color.lerp(color, AppColors.cocoa, 0.22)!;
  late final Paint _belly = Paint()
    ..color = Color.lerp(color, AppColors.cream, 0.45)!;
  final Paint _patch = Paint()..color = AppColors.cream;
  final Paint _white = Paint()..color = AppColors.white;
  final Paint _ink = Paint()..color = AppColors.ink;
  late final Paint _blush = Paint()
    ..color = AppColors.coral.withValues(alpha: 0.35);
  final Paint _outline = Paint()
    ..color = AppColors.cocoa
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// [tail] is the wiggle (-1..1). Returns the letter patch radius.
  double paint(Canvas canvas, double w, double h, {double tail = 0}) {
    _outline.strokeWidth = max(1.6, w * 0.022);

    // Tail, swinging around where it meets the body.
    canvas.save();
    canvas.translate(-w * 0.3, 0);
    canvas.rotate(tail * 0.35);
    final tailPath = Path()
      ..moveTo(w * 0.04, 0)
      ..quadraticBezierTo(-w * 0.12, -h * 0.5, -w * 0.2, -h * 0.42)
      ..quadraticBezierTo(-w * 0.12, 0, -w * 0.2, h * 0.42)
      ..quadraticBezierTo(-w * 0.12, h * 0.5, w * 0.04, 0)
      ..close();
    canvas.drawPath(tailPath, _fin);
    canvas.drawPath(tailPath, _outline);
    canvas.restore();

    // Top fin.
    final topFin = Path()
      ..moveTo(-w * 0.16, -h * 0.34)
      ..quadraticBezierTo(-w * 0.02, -h * 0.72, w * 0.16, -h * 0.36)
      ..close();
    canvas.drawPath(topFin, _fin);
    canvas.drawPath(topFin, _outline);

    // Body: a plump teardrop with a round nose.
    final body = Path()
      ..moveTo(-w * 0.3, 0)
      ..cubicTo(-w * 0.22, -h * 0.5, w * 0.3, -h * 0.52, w * 0.44, -h * 0.04)
      ..cubicTo(w * 0.46, h * 0.04, w * 0.42, h * 0.1, w * 0.36, h * 0.18)
      ..cubicTo(w * 0.22, h * 0.5, -w * 0.22, h * 0.5, -w * 0.3, 0)
      ..close();
    canvas.drawPath(body, _body);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.02, h * 0.36),
        width: w * 0.8,
        height: h * 0.5,
      ),
      _belly,
    );
    canvas.restore();
    canvas.drawPath(body, _outline);

    // Side fin.
    final sideFin = Path()
      ..moveTo(-w * 0.02, h * 0.16)
      ..quadraticBezierTo(-w * 0.12, h * 0.36, -w * 0.18, h * 0.3)
      ..quadraticBezierTo(-w * 0.1, h * 0.18, -w * 0.02, h * 0.16)
      ..close();
    canvas.drawPath(sideFin, _fin);
    canvas.drawPath(sideFin, _outline);

    // Letter patch.
    final r = h * 0.3;
    final patchCenter = Offset(w * patchX, 0);
    canvas.drawCircle(patchCenter, r, _patch);
    canvas.drawCircle(patchCenter, r, _outline);

    // Eye, blush and smile.
    final eye = Offset(w * 0.27, -h * 0.13);
    canvas.drawCircle(eye, h * 0.12, _white);
    canvas.drawCircle(eye, h * 0.12, _outline);
    canvas.drawCircle(eye + Offset(w * 0.012, h * 0.01), h * 0.065, _ink);
    canvas.drawCircle(eye + Offset(w * 0.028, -h * 0.025), h * 0.025, _white);
    canvas.drawCircle(Offset(w * 0.3, h * 0.08), h * 0.055, _blush);
    final smile = Path()
      ..moveTo(w * 0.36, h * 0.07)
      ..quadraticBezierTo(w * 0.4, h * 0.13, w * 0.43, h * 0.05);
    canvas.drawPath(smile, _outline);

    return r;
  }
}
