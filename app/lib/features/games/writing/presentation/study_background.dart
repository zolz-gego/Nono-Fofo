import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Grandpa's study, drawn in code until the ElevenLabs picture is added:
/// bookshelves on both sides, a mashrabiya window with afternoon light, a
/// rug and an armchair. The middle of the wall stays empty for the board.
class StudyBackground extends StatelessWidget {
  const StudyBackground({super.key, this.image});

  /// The painted study (`art.background` in writing.json), if there is one.
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image(
        image: image!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const CustomPaint(painter: _StudyPainter()),
      );
    }
    return const CustomPaint(painter: _StudyPainter());
  }
}

class _StudyPainter extends CustomPainter {
  const _StudyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floorTop = h * 0.78;

    // Wall.
    final wall = Rect.fromLTWH(0, 0, w, floorTop);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.studyWall, AppColors.studyWallShade],
        ).createShader(wall),
    );

    // Window high on the right, with a soft beam of light.
    final win = Rect.fromLTWH(w * 0.86, h * 0.08, w * 0.1, h * 0.26);
    canvas.drawPath(
      Path()
        ..moveTo(win.left, win.top)
        ..lineTo(win.right, win.top)
        ..lineTo(w * 0.7, floorTop)
        ..lineTo(w * 0.52, floorTop)
        ..close(),
      Paint()..color = AppColors.studyLight,
    );
    _window(canvas, win);

    // Floor.
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, w, h - floorTop),
      Paint()..color = AppColors.studyFloor,
    );
    final line = Paint()
      ..color = AppColors.studyFloorLine
      ..strokeWidth = 2;
    for (var x = -h; x < w; x += 70) {
      canvas.drawLine(Offset(x, h), Offset(x + h * 0.3, floorTop), line);
    }
    canvas.drawLine(Offset(0, floorTop), Offset(w, floorTop), line);

    // Rug.
    final rug = Rect.fromCenter(
      center: Offset(w / 2, h * 0.9),
      width: w * 0.7,
      height: h * 0.12,
    );
    canvas
      ..drawOval(rug, Paint()..color = AppColors.studyRugBorder)
      ..drawOval(rug.deflate(8), Paint()..color = AppColors.studyRug)
      ..drawOval(
        rug.deflate(22),
        Paint()
          ..color = AppColors.sunYellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

    // Shelves on both sides.
    _shelf(
      canvas,
      Rect.fromLTWH(w * 0.01, h * 0.06, w * 0.15, floorTop - h * 0.06),
      1,
    );
    _shelf(
      canvas,
      Rect.fromLTWH(w * 0.84, h * 0.4, w * 0.15, floorTop - h * 0.4),
      2,
    );

    // Armchair in the lower left corner.
    _armchair(canvas, Rect.fromLTWH(-w * 0.03, h * 0.62, w * 0.13, h * 0.3));
  }

  void _window(Canvas canvas, Rect r) {
    final frame = Paint()..color = AppColors.studyMashrabiya;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(r.inflate(8), const Radius.circular(8)),
        frame,
      )
      ..drawRect(r, Paint()..color = AppColors.studyWindow);
    final lattice = Paint()
      ..color = AppColors.studyMashrabiya
      ..strokeWidth = 3;
    const n = 6;
    for (var i = 1; i < n; i++) {
      final x = r.left + r.width * i / n;
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), lattice);
    }
    for (var i = 1; i < n * 2; i++) {
      final y = r.top + r.height * i / (n * 2);
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), lattice);
    }
    // Pointed arch on top.
    canvas.drawPath(
      Path()
        ..moveTo(r.left - 8, r.top - 6)
        ..quadraticBezierTo(
          r.center.dx,
          r.top - r.width * 0.9,
          r.right + 8,
          r.top - 6,
        )
        ..close(),
      frame,
    );
  }

  void _shelf(Canvas canvas, Rect r, int seed) {
    final wood = Paint()..color = AppColors.studyShelf;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      wood,
    );
    final inner = r.deflate(10);
    canvas.drawRect(inner, Paint()..color = AppColors.boardFrameDark);
    final rand = math.Random(seed);
    const shelves = 4;
    final rowH = inner.height / shelves;
    for (var i = 0; i < shelves; i++) {
      final bottom = inner.top + rowH * (i + 1);
      var x = inner.left + 4;
      while (x < inner.right - 10) {
        final bw = 8 + rand.nextDouble() * 12;
        if (x + bw > inner.right - 2) break;
        final bh = rowH * (0.55 + rand.nextDouble() * 0.35);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, bottom - 6 - bh, bw, bh),
            const Radius.circular(2),
          ),
          Paint()
            ..color = AppColors.books[rand.nextInt(AppColors.books.length)],
        );
        x += bw + 2;
      }
      canvas.drawRect(Rect.fromLTWH(r.left, bottom - 6, r.width, 8), wood);
    }
  }

  void _armchair(Canvas canvas, Rect r) {
    final cloth = Paint()..color = AppColors.studyArmchair;
    final dark = Paint()..color = AppColors.boardFrameDark;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left + r.width * 0.15,
            r.top,
            r.width * 0.7,
            r.height * 0.7,
          ),
          const Radius.circular(24),
        ),
        cloth,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left,
            r.top + r.height * 0.45,
            r.width,
            r.height * 0.35,
          ),
          const Radius.circular(18),
        ),
        cloth,
      )
      ..drawRect(
        Rect.fromLTWH(
          r.left + r.width * 0.1,
          r.top + r.height * 0.8,
          8,
          r.height * 0.2,
        ),
        dark,
      )
      ..drawRect(
        Rect.fromLTWH(
          r.right - r.width * 0.1 - 8,
          r.top + r.height * 0.8,
          8,
          r.height * 0.2,
        ),
        dark,
      );
  }

  @override
  bool shouldRepaint(_StudyPainter old) => false;
}
