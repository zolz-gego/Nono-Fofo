import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../balloons/domain/balloons_config.dart';

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
    this.picture,
    this.letterSpot = const BalloonLetterSpot(ui.Offset(0.5, 0.59), 0.58),
  }) : _spin = (Random().nextDouble() - 0.5) * 0.6,
       super(size: Vector2.all(size), anchor: Anchor.center, priority: 17);

  final String sound;

  /// The sound is written in Arabic (else Latin letters).
  final bool arabic;

  /// The apple picture (with an empty cream circle), or null to draw one in
  /// code.
  final ui.Image? picture;

  /// Where the sound goes on [picture].
  final BalloonLetterSpot letterSpot;
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
                fontSize: switch (picture) {
                  // The picture fills the height; the spot is sized from
                  // its width.
                  final p? =>
                    size.y *
                        p.width /
                        p.height *
                        letterSpot.size *
                        (sound.length > 1 ? 0.5 : 0.62),
                  null => size.x * (sound.length > 1 ? 0.3 : 0.38),
                },
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
    final picture = this.picture;
    if (picture != null) {
      _renderPicture(canvas, picture, w, h);
    } else {
      _renderDrawn(canvas, c, r, w, h);
    }
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  /// The picture fills the height; the sound sits on its cream circle.
  void _renderPicture(ui.Canvas canvas, ui.Image picture, double w, double h) {
    final pw = h * picture.width / picture.height;
    final dst = ui.Rect.fromLTWH((w - pw) / 2, 0, pw, h);
    canvas.drawImageRect(
      picture,
      ui.Rect.fromLTWH(
        0,
        0,
        picture.width.toDouble(),
        picture.height.toDouble(),
      ),
      dst,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final spot = ui.Offset(
      dst.left + letterSpot.center.dx * dst.width,
      dst.top + letterSpot.center.dy * dst.height,
    );
    _text.paint(canvas, spot - ui.Offset(_text.width / 2, _text.height / 2));
  }

  void _renderDrawn(
    ui.Canvas canvas,
    ui.Offset c,
    double r,
    double w,
    double h,
  ) {
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
  }
}
