import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';

/// The square picture a child can share after solving Grandpa's Cards:
/// logo, who and how many cards, the time and moves, a "New record!"
/// ribbon, and both brothers cheering by the sea.
class CardsShareCard {
  const CardsShareCard({
    required this.title,
    required this.time,
    required this.timeLabel,
    required this.moves,
    required this.movesLabel,
    required this.subtitle,
    required this.appTitle,
    required this.script,
    required this.direction,
    this.badge,
    this.heroAssets = const [],
  });

  /// e.g. "Bravo Mina! You matched 16 cards".
  final String title;
  final String time;
  final String timeLabel;
  final String moves;
  final String movesLabel;

  /// "New record!", or null.
  final String? badge;

  /// e.g. "With Nono by the sea in Alexandria".
  final String subtitle;
  final String appTitle;
  final AppScript script;
  final TextDirection direction;

  /// The brothers' celebrate poses (the child's buddy first).
  final List<String> heroAssets;

  static const double size = 1080;

  Future<Uint8List> render() async {
    final logo = await _asset(AssetPaths.logo);
    final heroes = [for (final path in heroAssets) ?await _asset(path)];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const s = size;
    final rtl = direction == TextDirection.rtl;

    // Sky, sea and sand behind a cream card.
    canvas
      ..drawRect(
        const Rect.fromLTWH(0, 0, s, s * 0.45),
        Paint()..color = AppColors.seaSkyTop,
      )
      ..drawRect(
        const Rect.fromLTWH(0, s * 0.45, s, s * 0.2),
        Paint()..color = AppColors.seaNear,
      )
      ..drawRect(
        const Rect.fromLTWH(0, s * 0.65, s, s * 0.35),
        Paint()..color = AppColors.beachSand,
      );
    const card = Rect.fromLTWH(30, 30, s - 60, s - 60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(48)),
      Paint()..color = AppColors.cream.withValues(alpha: 0.94),
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
    if (logo != null) {
      _drawImage(
        canvas,
        logo,
        Rect.fromLTWH(
          rtl ? rowLeft + name.width + 24 : rowLeft,
          header.center.dy - logoSize / 2,
          logoSize,
          logoSize,
        ),
      );
    }
    name.paint(
      canvas,
      Offset(
        rtl ? rowLeft : rowLeft + logoSize + 24,
        header.center.dy - name.height / 2,
      ),
    );

    // Title.
    final title = _text(this.title, 58, AppColors.deepTeal, maxWidth: s - 160);
    title.paint(canvas, Offset((s - title.width) / 2, 210));
    var y = 210 + title.height + 30;

    // Time and moves, in two boxes.
    const boxH = 200.0, gap = 40.0;
    const boxW = (s - 160 - gap) / 2;
    final stats = [(time, timeLabel), (moves, movesLabel)];
    for (final (i, (value, label)) in stats.indexed) {
      final slot = rtl ? 1 - i : i;
      final box = Rect.fromLTWH(80 + slot * (boxW + gap), y, boxW, boxH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(32)),
        Paint()..color = AppColors.mistBlue.withValues(alpha: 0.6),
      );
      final v = _text(value, 96, AppColors.deepTeal, maxWidth: boxW - 20);
      final l = _text(label, 40, AppColors.slateTeal, maxWidth: boxW - 20);
      final top = box.top + (boxH - v.height - l.height) / 2;
      v.paint(canvas, Offset(box.center.dx - v.width / 2, top));
      l.paint(canvas, Offset(box.center.dx - l.width / 2, top + v.height));
    }
    y += boxH + 30;

    // New record ribbon.
    final badge = this.badge;
    if (badge != null) {
      final b = _text(badge, 48, AppColors.cocoa);
      final r = Rect.fromCenter(
        center: Offset(s / 2, y + b.height / 2 + 14),
        width: b.width + 80,
        height: b.height + 28,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
        Paint()..color = AppColors.sunYellow,
      );
      b.paint(canvas, Offset(r.center.dx - b.width / 2, r.top + 14));
    }

    // Footer: both brothers cheering, and where they played.
    const footerH = 270.0;
    const footerTop = s - 30 - footerH;
    const heroH = 250.0;
    final sub = _text(subtitle, 40, AppColors.cocoa, maxWidth: s - 520);
    sub.paint(
      canvas,
      Offset((s - sub.width) / 2, footerTop + (footerH - sub.height) / 2),
    );
    for (final (i, img) in heroes.indexed) {
      final w = img.width * heroH / img.height;
      final onLeft = (i == 0) != rtl;
      final left = onLeft ? 70.0 : s - 70 - w;
      _drawImage(
        canvas,
        img,
        Rect.fromLTWH(left, footerTop + footerH - heroH - 10, w, heroH),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(s.toInt(), s.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    for (final img in [?logo, ...heroes]) {
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
    )..layout(maxWidth: math.max(10, maxWidth));
  }

  static void _drawImage(Canvas canvas, ui.Image img, Rect dst) =>
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );

  static Future<ui.Image?> _asset(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}
