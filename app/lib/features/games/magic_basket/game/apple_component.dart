import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';

enum AppleState {
  /// Flying in an arc from the thrower's hand to its column.
  thrown,
  falling,

  /// Sitting in the basket.
  basket,

  /// Bouncing out of the basket (wrong sound).
  bouncing,

  /// Squashed on the path, fading away.
  splat,
}

/// One apple with a sound (an Arabic or English letter) on a cream label.
/// The game moves it; it only draws itself and fades when told to. It is
/// drawn over the buddy but under the basket's front, so apples drop in.
class AppleComponent extends PositionComponent {
  AppleComponent({
    required this.sound,
    required this.arabic,
    required double size,
  }) : _spin = (Random().nextDouble() - 0.5) * 0.6,
       super(size: Vector2.all(size), anchor: Anchor.center, priority: 16);

  final String sound;

  /// The sound is written in Arabic (else Latin letters).
  final bool arabic;
  final double _spin;

  AppleState state = AppleState.thrown;

  /// Fall speed (pixels per second) and, while bouncing, sideways speed.
  Vector2 velocity = Vector2.zero();

  /// 1 = fully visible.
  double opacity = 1;

  /// Tilt while falling, in radians.
  double get tilt => _spin * sin(_age * 3);
  double _age = 0;

  late final TextPainter _text = TextPainter(
    textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
    text: TextSpan(
      text: sound,
      style:
          (arabic
                  ? AppTextStyles.arabic(AppTextVariant.h1)
                  : AppTextStyles.english(AppTextVariant.h1))
              .copyWith(
                fontSize: size.x * (sound.length > 1 ? 0.3 : 0.38),
                height: 1.1,
                color: AppColors.ink,
              ),
    ),
  )..layout();

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    angle = state == AppleState.basket ? 0 : tilt;
  }

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0) return;
    final w = size.x;
    final h = size.y;
    final c = ui.Offset(w / 2, h * 0.55);
    final r = w * 0.46;
    final squash = state == AppleState.splat ? 0.78 : 1.0;
    canvas.save();
    if (opacity < 1) {
      canvas.saveLayer(
        null,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: opacity),
      );
    }
    canvas
      ..translate(c.dx, c.dy + r * (1 - squash))
      ..scale(2 - squash, squash)
      ..translate(-c.dx, -c.dy);

    // Stem and leaf.
    canvas.drawLine(
      ui.Offset(w * 0.5, h * 0.2),
      ui.Offset(w * 0.53, h * 0.04),
      ui.Paint()
        ..color = AppColors.appleStem
        ..strokeWidth = w * 0.05
        ..strokeCap = ui.StrokeCap.round,
    );
    final leaf = ui.Path()
      ..moveTo(w * 0.54, h * 0.1)
      ..quadraticBezierTo(w * 0.68, h * -0.02, w * 0.82, h * 0.06)
      ..quadraticBezierTo(w * 0.68, h * 0.17, w * 0.54, h * 0.1)
      ..close();
    canvas.drawPath(leaf, ui.Paint()..color = AppColors.appleLeaf);

    // Body: two lobes at the top, round at the bottom.
    final body = ui.Path()
      ..moveTo(c.dx, c.dy - r * 0.72)
      ..cubicTo(
        c.dx + r * 0.5,
        c.dy - r * 1.12,
        c.dx + r * 1.12,
        c.dy - r * 0.62,
        c.dx + r * 0.98,
        c.dy + r * 0.12,
      )
      ..cubicTo(
        c.dx + r * 0.86,
        c.dy + r * 0.82,
        c.dx + r * 0.38,
        c.dy + r * 1.02,
        c.dx,
        c.dy + r * 0.9,
      )
      ..cubicTo(
        c.dx - r * 0.38,
        c.dy + r * 1.02,
        c.dx - r * 0.86,
        c.dy + r * 0.82,
        c.dx - r * 0.98,
        c.dy + r * 0.12,
      )
      ..cubicTo(
        c.dx - r * 1.12,
        c.dy - r * 0.62,
        c.dx - r * 0.5,
        c.dy - r * 1.12,
        c.dx,
        c.dy - r * 0.72,
      )
      ..close();
    canvas
      ..drawPath(
        body,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            c - ui.Offset(r * 0.35, r * 0.4),
            r * 1.5,
            [AppColors.apple, AppColors.appleDark],
          ),
      )
      ..drawPath(
        body,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = max(1.5, w * 0.03)
          ..color = AppColors.appleDark,
      )
      // Shine.
      ..drawOval(
        ui.Rect.fromCenter(
          center: c + ui.Offset(-r * 0.55, -r * 0.4),
          width: r * 0.3,
          height: r * 0.5,
        ),
        ui.Paint()..color = AppColors.appleShine,
      );

    // The label with the sound.
    canvas.drawCircle(
      c + ui.Offset(0, r * 0.08),
      r * 0.56,
      ui.Paint()..color = AppColors.cream,
    );
    _text.paint(
      canvas,
      c + ui.Offset(-_text.width / 2, r * 0.08 - _text.height / 2),
    );
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }
}
