import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../domain/fishing_config.dart';
import 'fish_painter.dart';
import 'fishing_game.dart';

enum FishState { swimming, hooked, caught, released }

/// One fish with a letter on its side. Swims along its lane; the game moves
/// it directly while it is on the hook.
class FishComponent extends PositionComponent
    with TapCallbacks, HasGameReference<FishingGame> {
  FishComponent({
    required this.letter,
    required this.lane,
    required this.direction,
    required this.speed,
    required Color color,
    this.sprite,
    this.letterSpot = LetterSpot.fallback,
    required Vector2 fishSize,
  }) : _painter = FishPainter(color),
       _phase = Random().nextDouble() * pi * 2,
       super(size: fishSize, anchor: Anchor.center, priority: 10);

  final CopticLetter letter;
  int lane;

  /// +1 swims right, -1 swims left.
  final int direction;

  /// Pixels per second.
  double speed;

  /// A painted fish image (facing right), or null to draw one in code.
  final ui.Image? sprite;

  /// Where the letter goes on [sprite].
  final LetterSpot letterSpot;

  final FishPainter _painter;
  final double _phase;
  double _time = 0;
  FishState state = FishState.swimming;

  /// Lane height the fish bobs around.
  double baseY = 0;

  /// 0 = swimming flat, 1 = hanging nose-up from the hook.
  double hang = 0;

  /// Released fish dive back to their lane before swimming on.
  double _diveFrom = 0;
  double _dive = 1;

  late final TextPainter _text = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: letter.small,
      style: AppTextStyles.coptic(AppTextVariant.h1).copyWith(
        fontSize: sprite == null
            ? size.y * 0.5
            : size.y * letterSpot.size * 0.8,
        height: 1,
        color: AppColors.coptic,
      ),
    ),
  )..layout();

  bool get isSwimming => state == FishState.swimming;

  void release() {
    state = FishState.released;
    _diveFrom = y;
    _dive = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    switch (state) {
      case FishState.swimming:
        x += direction * speed * dt;
        y = baseY + sin(_time * 2.2 + _phase) * size.y * 0.06;
      case FishState.released:
        _dive = min(1, _dive + dt * 1.6);
        hang = 1 - Curves.easeOut.transform(_dive);
        y = ui.lerpDouble(_diveFrom, baseY, Curves.easeIn.transform(_dive))!;
        x += direction * speed * dt * _dive;
        if (_dive >= 1) state = FishState.swimming;
      case FishState.hooked || FishState.caught:
        break;
    }
    final out = size.x;
    if ((direction > 0 && x > game.size.x + out) ||
        (direction < 0 && x < -out)) {
      game.fishLeft(this);
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // A bit bigger than the fish, for small fingers.
    final pad = size.y * 0.2;
    return point.x >= -pad &&
        point.y >= -pad &&
        point.x <= size.x + pad &&
        point.y <= size.y + pad;
  }

  @override
  void onTapDown(TapDownEvent event) => game.fishTapped(this);

  @override
  void render(ui.Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final wiggleSpeed = state == FishState.hooked ? 16.0 : 7.0;
    final tail = sin(_time * wiggleSpeed + _phase);

    canvas.save();
    canvas.translate(w / 2, h / 2);
    // Nose up while hanging from the hook.
    canvas.rotate(-direction * hang * pi / 2 + hang * tail * 0.12);
    if (direction < 0) canvas.scale(-1, 1);
    if (sprite != null) {
      final img = sprite!;
      canvas.drawImageRect(
        img,
        ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        ui.Rect.fromCenter(center: ui.Offset.zero, width: w, height: h),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    } else {
      _painter.paint(canvas, w, h, tail: tail);
    }
    // The letter stays upright and readable whatever the fish does.
    canvas.translate(
      sprite == null
          ? w * FishPainter.patchX
          : (letterSpot.center.dx - 0.5) * w,
      sprite == null ? 0 : (letterSpot.center.dy - 0.5) * h,
    );
    if (direction < 0) canvas.scale(-1, 1);
    canvas.rotate(direction * hang * pi / 2 - hang * tail * 0.12);
    _text.paint(canvas, ui.Offset(-_text.width / 2, -_text.height / 2));
    canvas.restore();
  }
}
