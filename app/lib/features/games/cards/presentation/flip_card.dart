import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../domain/memory_card.dart';

/// One card on the table. Turns over (in 3D) when [card] goes face up or
/// down; a found pair gets a little hop and a green tick.
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.card,
    required this.onTap,
    this.back,
  });

  final MemoryCard card;
  final VoidCallback? onTap;

  /// Picture for the back of the card (drawn in code without it).
  final ImageProvider? back;

  static const Duration flipTime = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final radius = BorderRadius.circular(box.maxWidth * 0.12);
        return GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: onTap == null
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: card.faceUp ? 1 : 0),
              duration: flipTime,
              curve: Curves.easeInOut,
              builder: (context, t, _) {
                final showFront = t >= 0.5;
                final angle = t * pi;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(showFront ? angle - pi : angle),
                  child: showFront
                      ? _Front(card: card, radius: radius, width: box.maxWidth)
                      : _Back(image: back, radius: radius, width: box.maxWidth),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.card, required this.radius, required this.width});

  final MemoryCard card;
  final BorderRadius radius;
  final double width;

  @override
  Widget build(BuildContext context) {
    final border = max(2.0, width * 0.05);
    return AnimatedScale(
      scale: card.matched ? 1.06 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardFace,
          borderRadius: radius,
          border: Border.all(
            color: card.matched ? AppColors.correct : card.color,
            width: border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(width * 0.1),
                child: FittedBox(
                  child: Text(
                    card.glyph,
                    // Coptic keys like ")" must not be mirrored in Arabic.
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.coptic(AppTextVariant.h1)
                        .copyWith(fontSize: 96, height: 1.1, color: card.color),
                  ),
                ),
              ),
            ),
            if (card.matched)
              PositionedDirectional(
                top: width * 0.06,
                end: width * 0.06,
                child: FaIcon(
                  AppIcons.passed,
                  size: max(10.0, width * 0.18),
                  color: AppColors.correct,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.image, required this.radius, required this.width});

  final ImageProvider? image;
  final BorderRadius radius;
  final double width;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    if (image != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image(image: image, fit: BoxFit.cover),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBack,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.cardBackBorder,
          width: max(2.0, width * 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: _DiamondsPainter(),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.55,
              child: Image.asset(AssetPaths.logo, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft diamond lattice, like an old card back.
class _DiamondsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardBackPattern
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, size.width * 0.02);
    final step = size.width / 4;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas
        ..drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint)
        ..drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
