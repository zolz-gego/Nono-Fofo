import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';

/// The square picture to share after an Adventure level: logo, who finished
/// which level, the stars (bonus stars too), the letters brought back,
/// coins and time, and both brothers, over the level's own background.
class AdventureShareCard {
  const AdventureShareCard({
    required this.title,
    required this.place,
    required this.background,
    required this.stars,
    required this.bonusStars,
    required this.letters,
    required this.stats,
    required this.appTitle,
    required this.script,
    required this.direction,
    this.badge,
    this.heroAssets = const [],
  });

  /// e.g. "Mina finished level 2!".
  final String title;

  /// e.g. "The desert & the Pyramids".
  final String place;

  /// The level's background picture (asset path).
  final String background;

  /// 1–3 stars from coins, plus 0 or 2 bonus stars.
  final int stars;
  final int bonusStars;

  /// The letters brought back (Avva Shenouda keys).
  final List<String> letters;

  /// (value, label) boxes: coins, time.
  final List<(String, String)> stats;

  /// "You finished the whole adventure!", or null.
  final String? badge;
  final String appTitle;
  final AppScript script;
  final TextDirection direction;
  final List<String> heroAssets;

  static const double size = 1080;

  Future<Uint8List> render() async {
    final logo = await _asset(AssetPaths.logo);
    final bg = await _asset(background);
    final heroes = [for (final path in heroAssets) ?await _asset(path)];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const s = size;
    final rtl = direction == TextDirection.rtl;

    // The level's background, covering the square.
    if (bg != null) {
      final scale = math.max(s / bg.width, s / bg.height);
      final w = bg.width * scale, h = bg.height * scale;
      _drawImage(canvas, bg, Rect.fromLTWH((s - w) / 2, (s - h) / 2, w, h));
    } else {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, s, s),
        Paint()..color = AppColors.mistBlue,
      );
    }
    const card = Rect.fromLTWH(30, 30, s - 60, s - 60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(48)),
      Paint()..color = AppColors.cream.withValues(alpha: 0.9),
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

    // Title and place.
    var y = 200.0;
    final title = _text(this.title, 56, AppColors.deepTeal, maxWidth: s - 160);
    title.paint(canvas, Offset((s - title.width) / 2, y));
    y += title.height + 6;
    final place = _text(this.place, 40, AppColors.cocoa, maxWidth: s - 160);
    place.paint(canvas, Offset((s - place.width) / 2, y));
    y += place.height + 20;

    // Stars: the coin stars, then the bonus ones in coral.
    const starR = 46.0, starGap = 22.0;
    final total = 3 + bonusStars;
    final rowStars = total * starR * 2 + (total - 1) * starGap;
    for (var i = 0; i < total; i++) {
      final bonus = i >= 3;
      final cx = (s - rowStars) / 2 + starR + i * (starR * 2 + starGap);
      final filled = bonus || i < stars;
      _star(
        canvas,
        Offset(cx, y + starR),
        bonus ? starR * 0.85 : starR,
        filled ? (bonus ? AppColors.coral : AppColors.sunYellow) : null,
      );
    }
    y += starR * 2 + 24;

    // The letters brought back.
    if (letters.isNotEmpty) {
      final glyphs = TextPainter(
        text: TextSpan(
          text: letters.join('  '),
          style: const TextStyle(
            fontFamily: AppFonts.coptic,
            fontSize: 92,
            height: 1.1,
            color: AppColors.coptic,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: s - 160);
      glyphs.paint(canvas, Offset((s - glyphs.width) / 2, y));
      y += glyphs.height + 20;
    }

    // Coins and time, in boxes.
    const boxH = 150.0, gap = 30.0;
    final n = stats.length;
    final boxW = (s - 320 - gap * (n - 1)) / n;
    for (final (i, (value, label)) in stats.indexed) {
      final slot = rtl ? n - 1 - i : i;
      final box = Rect.fromLTWH(160 + slot * (boxW + gap), y, boxW, boxH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(32)),
        Paint()..color = AppColors.mistBlue.withValues(alpha: 0.6),
      );
      final v = _text(value, 70, AppColors.deepTeal, maxWidth: boxW - 20);
      final l = _text(label, 34, AppColors.slateTeal, maxWidth: boxW - 20);
      final top = box.top + (boxH - v.height - l.height) / 2;
      v.paint(canvas, Offset(box.center.dx - v.width / 2, top));
      l.paint(canvas, Offset(box.center.dx - l.width / 2, top + v.height));
    }
    y += boxH + 20;

    // Whole adventure done ribbon.
    final badge = this.badge;
    if (badge != null) {
      final b = _text(badge, 42, AppColors.cocoa, maxWidth: s - 520);
      final r = Rect.fromCenter(
        // Under the boxes, never over them.
        center: Offset(s / 2, math.max(y + 12 + (b.height + 24) / 2, s - 155)),
        width: b.width + 70,
        height: b.height + 24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
        Paint()..color = AppColors.sunYellow,
      );
      b.paint(canvas, Offset(r.center.dx - b.width / 2, r.top + 12));
    }

    // Both brothers at the bottom corners.
    const heroH = 230.0;
    for (final (i, img) in heroes.indexed) {
      final w = img.width * heroH / img.height;
      final onLeft = (i == 0) != rtl;
      final left = onLeft ? 60.0 : s - 60 - w;
      _drawImage(canvas, img, Rect.fromLTWH(left, s - 40 - heroH, w, heroH));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(s.toInt(), s.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    for (final img in [?logo, ?bg, ...heroes]) {
      img.dispose();
    }
    return data!.buffer.asUint8List();
  }

  /// A five-point star; outlined when [fill] is null.
  static void _star(Canvas canvas, Offset c, double r, Color? fill) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    if (fill != null) canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.cocoa,
    );
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
