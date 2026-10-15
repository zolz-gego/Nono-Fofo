import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/text/app_texts.dart';

/// Comic speech bubble shown above a character. Animates in and out.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.maxWidth = 220});

  final String? text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDimens.fast,
      child: text == null
          ? const SizedBox.shrink()
          : Column(
              key: ValueKey(text),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceMd,
                      vertical: AppDimens.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.speechBubble,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                        color: AppColors.speechBubbleBorder, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 6,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: AppText.body(text!, textAlign: TextAlign.center),
                ),
                CustomPaint(
                  size: const Size(18, 10),
                  painter: _TailPainter(),
                ),
              ],
            )
              .animate()
              .scale(
                  begin: const Offset(0.6, 0.6),
                  alignment: Alignment.bottomCenter,
                  curve: Curves.easeOutBack,
                  duration: AppDimens.normal)
              .fadeIn(duration: AppDimens.fast),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, Paint()..color = AppColors.speechBubble);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.speechBubbleBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
