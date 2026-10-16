import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../domain/balloons_config.dart';
import 'balloons_game.dart';

enum BalloonState { rising, held, bunch, popping }

/// One helium balloon with a letter on it and a string hanging down. Rises
/// with a gentle sway; the game moves it directly once it is caught.
class BalloonComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BalloonsGame> {
  BalloonComponent({
    required this.letter,
    required this.color,
    required this.speed,
    required this.stringLength,
    required double width,
    required double height,
    this.sprite,
    this.letterSpot = BalloonLetterSpot.fallback,
  }) : _phase = Random().nextDouble() * pi * 2,
       super(
         size: Vector2(
           width,
           sprite == null ? height : width * sprite.height / sprite.width,
         ),
         anchor: Anchor.center,
         priority: 10,
       );

  final CopticLetter letter;
  final Color color;

  /// Pixels per second while rising.
  double speed;
  double stringLength;

  /// A painted balloon (string not included), or null to draw one in code.
  final ui.Image? sprite;
  final BalloonLetterSpot letterSpot;

  final double _phase;
  double _time = 0;
  BalloonState state = BalloonState.rising;

  /// Column x the balloon sways around while rising.
  double baseX = 0;

  /// Where the string ends, in scene coordinates (a hand), or null to let
  /// it hang free.
  ui.Offset? stringEnd;

  /// Extra sway while held in a bunch (bigger when celebrating).
  double bob = 0.04;

  double _pop = 0;
  static const double _popTime = 0.28;

  late final TextPainter _text = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: letter.small,
      style: AppTextStyles.coptic(AppTextVariant.h1).copyWith(
        fontSize: size.x * (sprite == null ? 0.42 : letterSpot.size * 0.85),
        height: 1,
        color: AppColors.coptic,
      ),
    ),
  )..layout();

  bool get isRising => state == BalloonState.rising;

  /// Body tilt from the sway, so it leans the way it drifts.
  double get _tilt => switch (state) {
    BalloonState.rising => cos(_time * 1.4 + _phase) * 0.07,
    BalloonState.bunch => sin(_time * 2 + _phase) * bob,
    _ => sin(_time * 3 + _phase) * 0.05,
  };

  void pop() {
    state = BalloonState.popping;
    stringEnd = null;
    _pop = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    switch (state) {
      case BalloonState.rising:
        y -= speed * dt;
        x = baseX + sin(_time * 1.4 + _phase) * size.x * 0.16;
        if (y < -size.y - stringLength) game.balloonLeft(this);
      case BalloonState.popping:
        _pop += dt;
        if (_pop >= _popTime) removeFromParent();
      case BalloonState.held || BalloonState.bunch:
        break;
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // A bit bigger than the balloon, for small fingers.
    final pad = size.x * 0.18;
    return point.x >= -pad &&
        point.y >= -pad &&
        point.x <= size.x + pad &&
        point.y <= size.y + pad;
  }

  @override
  void onTapDown(TapDownEvent event) => game.balloonTapped(this);

  @override
  void render(ui.Canvas canvas) {
    final w = size.x;
    final h = size.y;
    if (state == BalloonState.popping) return _renderPop(canvas, w, h);

    // The string, in scene space divided by the scale (the body may be
    // smaller in the bunch).
    final k = scale.x == 0 ? 1.0 : scale.x;
    final knot = ui.Offset(w / 2, h + w * 0.05);
    final end = stringEnd == null
        ? knot +
              ui.Offset(-cos(_time * 1.4 + _phase) * w * 0.12, stringLength / k)
        : ui.Offset(
                (stringEnd!.dx - position.x) / k,
                (stringEnd!.dy - position.y) / k,
              ) +
              ui.Offset(w / 2, h / 2);
    final mid = ui.Offset.lerp(knot, end, 0.5)!;
    final wiggle = sin(_time * 3.2 + _phase) * w * 0.07;
    canvas.drawPath(
      ui.Path()
        ..moveTo(knot.dx, knot.dy)
        ..quadraticBezierTo(mid.dx + wiggle, mid.dy, end.dx, end.dy),
      ui.Paint()
        ..color = AppColors.balloonString
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = max(1.2, w * 0.022) / k
        ..strokeCap = ui.StrokeCap.round,
    );

    canvas.save();
    // Tilt around the knot, like a real balloon on a string.
    canvas.translate(knot.dx, knot.dy);
    canvas.rotate(_tilt);
    canvas.translate(-knot.dx, -knot.dy);
    if (sprite != null) {
      final img = sprite!;
      canvas.drawImageRect(
        img,
        ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      _paintLetter(canvas, letterSpot.center.dx * w, letterSpot.center.dy * h);
    } else {
      _paintBody(canvas, w, h);
      _paintLetter(canvas, w / 2, h * 0.44);
    }
    canvas.restore();
  }

  void _paintLetter(ui.Canvas canvas, double cx, double cy) {
    canvas.save();
    canvas.translate(cx, cy);
    // The letter stays upright whatever the balloon does.
    canvas.rotate(-_tilt);
    _text.paint(canvas, ui.Offset(-_text.width / 2, -_text.height / 2));
    canvas.restore();
  }

  ui.Path _bodyPath(double w, double h) => ui.Path()
    ..moveTo(w / 2, h)
    ..cubicTo(w * 0.2, h * 0.88, 0, h * 0.64, 0, h * 0.42)
    ..cubicTo(0, h * 0.17, w * 0.22, 0, w / 2, 0)
    ..cubicTo(w * 0.78, 0, w, h * 0.17, w, h * 0.42)
    ..cubicTo(w, h * 0.64, w * 0.8, h * 0.88, w / 2, h)
    ..close();

  void _paintBody(ui.Canvas canvas, double w, double h) {
    final outline = ui.Paint()
      ..color = AppColors.outline
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.03)
      ..strokeJoin = ui.StrokeJoin.round;
    final body = _bodyPath(w, h);
    final light = Color.lerp(color, AppColors.white, 0.35)!;
    final dark = Color.lerp(color, AppColors.ink, 0.22)!;
    canvas.drawPath(
      body,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          ui.Offset(w * 0.34, h * 0.28),
          w * 0.85,
          [light, color, dark],
          [0, 0.55, 1],
        ),
    );
    canvas.drawPath(body, outline);

    // Knot.
    final knot = ui.Path()
      ..moveTo(w / 2 - w * 0.08, h + w * 0.06)
      ..lineTo(w / 2 + w * 0.08, h + w * 0.06)
      ..lineTo(w / 2, h - w * 0.02)
      ..close();
    canvas.drawPath(knot, ui.Paint()..color = dark);
    canvas.drawPath(knot, outline..strokeWidth = max(1.2, w * 0.022));

    // Shine.
    canvas.save();
    canvas.translate(w * 0.26, h * 0.2);
    canvas.rotate(-0.5);
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset.zero,
        width: w * 0.13,
        height: h * 0.22,
      ),
      ui.Paint()..color = AppColors.white.withValues(alpha: 0.65),
    );
    canvas.restore();

    // Cream circle the letter sits in.
    final r = w * 0.29;
    final c = ui.Offset(w / 2, h * 0.44);
    canvas.drawCircle(c, r, ui.Paint()..color = AppColors.cream);
    canvas.drawCircle(c, r, outline..strokeWidth = max(1.2, w * 0.022));
  }

  void _renderPop(ui.Canvas canvas, double w, double h) {
    final t = (_pop / _popTime).clamp(0.0, 1.0);
    final c = ui.Offset(w / 2, h * 0.45);
    final fade = 1 - t;
    // A quick puff: the body swells and fades, spikes and bits fly out.
    canvas.drawCircle(
      c,
      w * (0.45 + 0.35 * t),
      ui.Paint()..color = color.withValues(alpha: 0.5 * fade),
    );
    final spike = ui.Paint()
      ..color = AppColors.outline.withValues(alpha: fade)
      ..strokeWidth = max(2, w * 0.04)
      ..strokeCap = ui.StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 + _phase;
      final dir = ui.Offset(cos(a), sin(a));
      canvas.drawLine(
        c + dir * w * (0.35 + 0.3 * t),
        c + dir * w * (0.5 + 0.45 * t),
        spike,
      );
      canvas.drawCircle(
        c + ui.Offset(cos(a + 0.4), sin(a + 0.4)) * w * (0.3 + 0.6 * t),
        w * 0.05,
        ui.Paint()
          ..color = AppColors.celebration[i % AppColors.celebration.length]
              .withValues(alpha: fade),
      );
    }
  }
}
