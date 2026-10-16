import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';

/// What goes on the picture a child can share after writing a letter.
class WritingShareCard {
  const WritingShareCard({
    required this.drawings,
    required this.title,
    required this.subtitle,
    required this.appTitle,
    required this.script,
    required this.direction,
    this.heroAsset,
  });

  /// The child's boards (small, capital) as PNGs.
  final List<Uint8List> drawings;

  /// e.g. "Bravo Mina! You wrote the letter Alpha".
  final String title;

  /// e.g. "With Nono at Grandpa's chalkboard".
  final String subtitle;
  final String appTitle;
  final AppScript script;
  final TextDirection direction;

  /// The hero's celebrate pose.
  final String? heroAsset;

  static const double size = 1080;

  /// Draws the card as a square PNG.
  Future<Uint8List> render() async {
    final boards = [for (final png in drawings) await _decode(png)];
    final logo = await _asset(AssetPaths.logo);
    final hero = heroAsset == null ? null : await _asset(heroAsset!);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const s = size;
    final rtl = direction == TextDirection.rtl;

    // Card.
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, s, s),
      Paint()..color = AppColors.sand,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 30, s - 60, s - 60),
        const Radius.circular(48),
      ),
      Paint()..color = AppColors.cream,
    );

    // Header: logo + app name.
    const header = Rect.fromLTWH(30, 30, s - 60, 150);
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndCorners(
          header,
          topLeft: const Radius.circular(48),
          topRight: const Radius.circular(48),
        ),
      )
      ..drawRect(header, Paint()..color = AppColors.deepTeal)
      ..restore();
    final name = _text(appTitle, 54, AppColors.white);
    const logoSize = 110.0;
    final rowW = logoSize + 24 + name.width;
    final rowLeft = (s - rowW) / 2;
    final logoLeft = rtl ? rowLeft + name.width + 24 : rowLeft;
    final nameLeft = rtl ? rowLeft : rowLeft + logoSize + 24;
    if (logo != null) {
      _drawImage(
        canvas,
        logo,
        Rect.fromLTWH(
          logoLeft,
          header.center.dy - logoSize / 2,
          logoSize,
          logoSize,
        ),
      );
    }
    name.paint(canvas, Offset(nameLeft, header.center.dy - name.height / 2));

    // Title.
    final title = _text(this.title, 58, AppColors.deepTeal, maxWidth: s - 160);
    title.paint(canvas, Offset((s - title.width) / 2, 215));
    final boardsTop = 215 + title.height + 40;

    // The two boards, in little wooden frames.
    const footerH = 250.0;
    final boardsH = s - 30 - footerH - boardsTop;
    final n = math.max(1, boards.length);
    const gap = 40.0;
    final slotW = (s - 160 - gap * (n - 1)) / n;
    for (final (i, img) in boards.indexed) {
      // Small board first, on the reading-start side.
      final slot = rtl ? n - 1 - i : i;
      final box = Rect.fromLTWH(
        80 + slot * (slotW + gap),
        boardsTop,
        slotW,
        boardsH,
      );
      final k = math.min(
        (box.width - 28) / img.width,
        (box.height - 28) / img.height,
      );
      final w = img.width * k, h = img.height * k;
      final inner = Rect.fromCenter(center: box.center, width: w, height: h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner.inflate(14), const Radius.circular(18)),
        Paint()..color = AppColors.boardFrame,
      );
      _drawImage(canvas, img, inner);
    }

    // Footer: the hero, cheering, and who helped.
    const footerTop = s - 30 - footerH;
    double textLeft = 80, textRight = s - 80;
    if (hero != null) {
      const heroH = 230.0;
      final heroW = hero.width * heroH / hero.height;
      final heroLeft = rtl ? 80.0 : s - 80 - heroW;
      _drawImage(
        canvas,
        hero,
        Rect.fromLTWH(heroLeft, footerTop + 4, heroW, heroH),
      );
      if (rtl) {
        textLeft = heroLeft + heroW + 20;
      } else {
        textRight = heroLeft - 20;
      }
    }
    final sub = _text(
      subtitle,
      42,
      AppColors.cocoa,
      maxWidth: textRight - textLeft,
    );
    sub.paint(
      canvas,
      Offset(
        rtl ? textRight - sub.width : textLeft,
        footerTop + (footerH - sub.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(s.toInt(), s.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    for (final img in [...boards, ?logo, ?hero]) {
      img.dispose();
    }
    return data!.buffer.asUint8List();
  }

  TextPainter _text(
    String text,
    double fontSize,
    Color color, {
    double maxWidth = size,
  }) {
    final style = AppTextStyles.of(
      script,
      AppTextVariant.h1,
    ).copyWith(fontSize: fontSize, color: color, height: 1.3);
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textAlign: TextAlign.center,
      maxLines: 3,
    )..layout(maxWidth: maxWidth);
  }

  static void _drawImage(Canvas canvas, ui.Image img, Rect dst) =>
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static Future<ui.Image?> _asset(String path) async {
    try {
      final data = await rootBundle.load(path);
      return await _decode(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
