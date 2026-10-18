import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../domain/adventure_level.dart';

enum FxKind { coin, debris, puff, sparkle }

/// What the art needs to draw an effect.
abstract interface class AdventureFx {
  FxKind get kind;
  double get x;
  double get y;

  /// 0 → 1 over the effect's life.
  double get progress;
}

/// Colors of one place.
class _Palette {
  const _Palette({
    required this.skyTop,
    required this.skyBottom,
    required this.earth,
    required this.earthDark,
    required this.top,
    required this.topDark,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color earth;
  final Color earthDark;

  /// The grass / sand / pavement on top of the ground.
  final Color top;
  final Color topDark;
}

/// Placeholder art for the Adventure, drawn in code until the Gemini art
/// arrives (see design/game-prompts.md). Positions are in tiles; [t] is the
/// size of one tile in world units.
class AdventureArt {
  AdventureArt(this.place) : _p = _palettes[place]!;

  final AdventurePlace place;
  final _Palette _p;

  static const Map<AdventurePlace, _Palette> _palettes = {
    AdventurePlace.nile: _Palette(
      skyTop: Color(0xFF8FD0E0),
      skyBottom: Color(0xFFE8F4EE),
      earth: Color(0xFFB08A5E),
      earthDark: Color(0xFF8E6C47),
      top: Color(0xFF6CC24A),
      topDark: Color(0xFF4E9A3A),
    ),
    AdventurePlace.desert: _Palette(
      skyTop: Color(0xFFF7B267),
      skyBottom: Color(0xFFFFEBC6),
      earth: Color(0xFFD9A55B),
      earthDark: Color(0xFFB9853F),
      top: Color(0xFFF2CF8A),
      topDark: Color(0xFFE0B66C),
    ),
    AdventurePlace.alexandria: _Palette(
      skyTop: Color(0xFF14213D),
      skyBottom: Color(0xFF3C4F82),
      earth: Color(0xFF5F6B7A),
      earthDark: Color(0xFF47515E),
      top: Color(0xFFA9B6C4),
      topDark: Color(0xFF8593A3),
    ),
  };

  Color get skyBottom => _p.skyBottom;

  /// Pictures from `assets/games/adventure/`, by name (see [artNames]);
  /// anything missing is drawn in code.
  final Map<String, Image> images = {};

  /// The pictures this place uses.
  static List<String> artNames(AdventurePlace place) => [
    'bg_${place.name}',
    'ground_${place.name}',
    'block_stone',
    'block_brick',
    'block_question',
    'block_used',
    for (final e in EnemyKind.values) e.name,
  ];

  static final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  void _image(Canvas canvas, Image image, Rect src, Rect dst) =>
      canvas.drawImageRect(image, src, dst, _imagePaint);

  static Rect _all(Image image) =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  static const Color _outline = Color(0xFF3E3227);
  static const Color _gold = Color(0xFFFFC845);
  static const Color _goldDark = Color(0xFFD99A1E);

  final Paint _paint = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _outline;

  Paint _fill(Color c) => _paint..color = c;

  Paint _line(double width, [Color color = _outline]) => _stroke
    ..strokeWidth = width
    ..color = color;

  // ---------------------------------------------------------------------------
  // Backdrop (screen space)
  // ---------------------------------------------------------------------------

  /// Sky and far scenery for a [w]×[h] screen; [scroll] is how far the
  /// camera has moved, in screen pixels.
  void backdrop(
    Canvas canvas,
    double w,
    double h,
    double scroll,
    double clock,
  ) {
    final sky = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, h), [
          _p.skyTop,
          _p.skyBottom,
        ]),
    );
    final bg = images['bg_${place.name}'];
    if (bg != null) {
      // The picture's own ground line (74% down) sits on the level's
      // ground (12 of 14 rows down); it repeats sideways, slowly.
      final ih = h * (12 / 14) / 0.74;
      final iw = ih * bg.width / bg.height;
      _repeat(w, scroll, 0.3, iw, (x, _) {
        _image(canvas, bg, _all(bg), Rect.fromLTWH(x, 0, iw + 1, ih));
      });
      return;
    }
    switch (place) {
      case AdventurePlace.nile:
        _nileBackdrop(canvas, w, h, scroll, clock);
      case AdventurePlace.desert:
        _desertBackdrop(canvas, w, h, scroll);
      case AdventurePlace.alexandria:
        _alexBackdrop(canvas, w, h, scroll, clock);
    }
  }

  /// Calls [draw] with the screen x of every copy of a pattern that repeats
  /// each [spacing] pixels and scrolls at [factor] of the camera.
  void _repeat(
    double w,
    double scroll,
    double factor,
    double spacing,
    void Function(double x, int i) draw,
  ) {
    final offset = scroll * factor;
    final first = (offset / spacing).floor() - 1;
    for (var i = first; i * spacing - offset < w + spacing; i++) {
      draw(i * spacing - offset, i);
    }
  }

  void _nileBackdrop(
    Canvas canvas,
    double w,
    double h,
    double s,
    double clock,
  ) {
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.16),
      h * 0.07,
      _fill(AppColors.sunGlow),
    );
    canvas.drawCircle(Offset(w * 0.82, h * 0.16), h * 0.045, _fill(_gold));
    // Far bank hills.
    _repeat(w, s, 0.12, h * 1.1, (x, i) {
      final path = Path()
        ..moveTo(x - h * 0.2, h * 0.62)
        ..quadraticBezierTo(
          x + h * 0.35,
          h * (0.40 + (i % 3) * 0.03),
          x + h * 0.9,
          h * 0.62,
        )
        ..close();
      canvas.drawPath(path, _fill(AppColors.farBank));
    });
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.6, w, h * 0.12),
      _fill(AppColors.farBank),
    );
    // The Nile.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.66, w, h * 0.1),
      _fill(AppColors.waterTop),
    );
    _repeat(w, s, 0.3, h * 0.35, (x, i) {
      final y = h * (0.69 + (i % 2) * 0.03) + sin(clock * 2 + i) * 2;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + h * 0.08, y),
        _line(2, AppColors.waterShine),
      );
    });
    // Palms.
    _repeat(w, s, 0.45, h * 0.55, (x, i) {
      if (i % 3 == 1) return;
      _palm(canvas, x, h * 0.78, h * (0.22 + (i % 2) * 0.05));
    });
  }

  void _palm(Canvas canvas, double x, double base, double height) {
    final top = Offset(x + height * 0.12, base - height);
    final trunk = Path()
      ..moveTo(x - height * 0.03, base)
      ..quadraticBezierTo(
        x + height * 0.02,
        base - height * 0.5,
        top.dx,
        top.dy,
      )
      ..lineTo(top.dx + height * 0.05, top.dy)
      ..quadraticBezierTo(
        x + height * 0.08,
        base - height * 0.5,
        x + height * 0.04,
        base,
      )
      ..close();
    canvas.drawPath(trunk, _fill(AppColors.palmTrunk));
    for (var k = 0; k < 6; k++) {
      final a = -pi / 2 + (k - 2.5) * 0.55;
      final end =
          top +
          Offset(cos(a) * height * 0.38, sin(a) * height * 0.22 + height * 0.1);
      final ctrl =
          top +
          Offset(cos(a) * height * 0.2, sin(a) * height * 0.3 - height * 0.08);
      final leaf = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(leaf, _line(height * 0.06, AppColors.palmLeaf));
    }
  }

  void _desertBackdrop(Canvas canvas, double w, double h, double s) {
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.2),
      h * 0.08,
      _fill(const Color(0x66FFF3C4)),
    );
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.2),
      h * 0.055,
      _fill(const Color(0xFFFFF0B0)),
    );
    // Pyramids far away.
    _repeat(w, s, 0.1, h * 1.6, (x, i) {
      void pyramid(double cx, double size) {
        final base = h * 0.7;
        final left = Path()
          ..moveTo(cx - size, base)
          ..lineTo(cx, base - size * 0.95)
          ..lineTo(cx, base)
          ..close();
        final right = Path()
          ..moveTo(cx, base - size * 0.95)
          ..lineTo(cx + size, base)
          ..lineTo(cx, base)
          ..close();
        canvas.drawPath(left, _fill(const Color(0xFFE9B872)));
        canvas.drawPath(right, _fill(const Color(0xFFC98F48)));
      }

      pyramid(x + h * 0.3, h * 0.32);
      pyramid(x + h * 0.78, h * 0.22);
      pyramid(x + h * 1.08, h * 0.14);
    });
    // Dunes.
    _repeat(w, s, 0.3, h * 0.9, (x, i) {
      final path = Path()
        ..moveTo(x - h * 0.3, h * 0.82)
        ..quadraticBezierTo(x + h * 0.25, h * 0.6, x + h * 0.95, h * 0.82)
        ..close();
      canvas.drawPath(path, _fill(const Color(0xFFEBC27E)));
    });
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.8, w, h * 0.2),
      _fill(const Color(0xFFEBC27E)),
    );
  }

  void _alexBackdrop(
    Canvas canvas,
    double w,
    double h,
    double s,
    double clock,
  ) {
    // Stars.
    _repeat(w, s, 0.03, h * 0.23, (x, i) {
      for (var k = 0; k < 3; k++) {
        final sx = x + ((i * 37 + k * 53) % 100) / 100 * h * 0.23;
        final sy = h * (0.04 + ((i * 17 + k * 29) % 100) / 100 * 0.4);
        final twinkle = 0.5 + 0.5 * sin(clock * 2 + i + k * 2.1);
        canvas.drawCircle(
          Offset(sx, sy),
          1.2 + twinkle,
          _fill(Color.fromRGBO(255, 251, 230, 0.4 + 0.6 * twinkle)),
        );
      }
    });
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.14),
      h * 0.06,
      _fill(const Color(0xFFFFF6D6)),
    );
    canvas.drawCircle(
      Offset(w * 0.78 + h * 0.025, h * 0.13),
      h * 0.05,
      _fill(_p.skyTop),
    );
    // The sea and Qaitbay-like lighthouse fort.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.62, w, h * 0.2),
      _fill(const Color(0xFF22406A)),
    );
    _repeat(w, s, 0.2, h * 2.2, (x, i) {
      final base = h * 0.64;
      canvas.drawRect(
        Rect.fromLTWH(x, base - h * 0.08, h * 0.4, h * 0.08),
        _fill(const Color(0xFF2B3A5C)),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + h * 0.15, base - h * 0.3, h * 0.1, h * 0.22),
        _fill(const Color(0xFF2B3A5C)),
      );
      final beam = Path()
        ..moveTo(x + h * 0.2, base - h * 0.28)
        ..lineTo(x + h * 0.2 + cos(clock) * h * 0.7, base - h * 0.36)
        ..lineTo(x + h * 0.2 + cos(clock) * h * 0.7, base - h * 0.2)
        ..close();
      canvas.drawPath(beam, _fill(const Color(0x22FFF3B0)));
      canvas.drawCircle(
        Offset(x + h * 0.2, base - h * 0.28),
        h * 0.02,
        _fill(_gold),
      );
    });
    _repeat(w, s, 0.25, h * 0.3, (x, i) {
      final y = h * (0.67 + (i % 3) * 0.04) + sin(clock * 1.5 + i) * 2;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + h * 0.06, y),
        _line(1.5, const Color(0x66FFF6D6)),
      );
    });
    // City buildings with lit windows.
    _repeat(w, s, 0.42, h * 0.16, (x, i) {
      final bh = h * (0.14 + ((i * 7) % 5) * 0.035);
      final top = h * 0.8 - bh;
      canvas.drawRect(
        Rect.fromLTWH(x, top, h * 0.14, bh),
        _fill(const Color(0xFF1E2A47)),
      );
      for (var r = 0; r < (bh / (h * 0.04)).floor() - 1; r++) {
        for (var c = 0; c < 3; c++) {
          if ((i + r * 3 + c) % 4 == 0) continue;
          canvas.drawRect(
            Rect.fromLTWH(
              x + h * (0.02 + c * 0.04),
              top + h * (0.02 + r * 0.04),
              h * 0.02,
              h * 0.02,
            ),
            _fill(const Color(0xFFFFD27A)),
          );
        }
      }
    });
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.8, w, h * 0.2),
      _fill(const Color(0xFF1E2A47)),
    );
  }

  // ---------------------------------------------------------------------------
  // Tiles
  // ---------------------------------------------------------------------------

  void tile(
    Canvas canvas,
    Tile tile,
    double col,
    double row,
    double t, {
    required bool topOpen,
    required double clock,
  }) {
    final r = Rect.fromLTWH(col * t, row * t, t, t);
    final picture = switch (tile) {
      Tile.air => null,
      Tile.ground => images['ground_${place.name}'],
      Tile.stone => images['block_stone'],
      Tile.brick => images['block_brick'],
      Tile.coinBlock ||
      Tile.letterBlock ||
      Tile.pageBlock => images['block_question'],
      Tile.usedBlock => images['block_used'],
    };
    if (picture != null) {
      if (tile == Tile.ground) {
        // The ground picture is 4 tiles wide and 2 tall: the top row has
        // the grass / sand edge, the row under it is plain earth.
        final size = picture.height / 2;
        final src = Rect.fromLTWH(
          (col.round() % 4) * size,
          topOpen ? 0 : size,
          size,
          size,
        );
        _image(canvas, picture, src, r.inflate(0.5));
      } else {
        final rr = RRect.fromRectAndRadius(
          r.deflate(t * 0.02),
          Radius.circular(t * 0.1),
        );
        canvas.save();
        canvas.clipRRect(rr);
        _image(canvas, picture, _all(picture), r);
        canvas.restore();
        canvas.drawRRect(rr, _line(t * 0.05));
      }
      return;
    }
    switch (tile) {
      case Tile.air:
        return;
      case Tile.ground:
        canvas.drawRect(r.inflate(0.5), _fill(_p.earth));
        final dots = (col * 7 + row * 3).round() % 3;
        canvas.drawCircle(
          r.topLeft + Offset(t * (0.25 + dots * 0.2), t * 0.62),
          t * 0.06,
          _fill(_p.earthDark),
        );
        canvas.drawCircle(
          r.topLeft + Offset(t * (0.7 - dots * 0.15), t * 0.85),
          t * 0.05,
          _fill(_p.earthDark),
        );
        if (topOpen) {
          canvas.drawRect(
            Rect.fromLTWH(r.left - 0.5, r.top, t + 1, t * 0.3),
            _fill(_p.top),
          );
          canvas.drawRect(
            Rect.fromLTWH(r.left - 0.5, r.top + t * 0.24, t + 1, t * 0.08),
            _fill(_p.topDark),
          );
          if (place == AdventurePlace.nile) {
            for (var k = 0; k < 3; k++) {
              final gx = r.left + t * (0.15 + k * 0.33);
              canvas.drawLine(
                Offset(gx, r.top),
                Offset(gx + t * 0.05, r.top - t * 0.12),
                _line(t * 0.05, _p.topDark),
              );
            }
          }
        }
      case Tile.stone:
        _block(
          canvas,
          r,
          place == AdventurePlace.alexandria
              ? const Color(0xFF8C98A6)
              : const Color(0xFFC9A46A),
          place == AdventurePlace.alexandria
              ? const Color(0xFF6B7684)
              : const Color(0xFFA9844C),
        );
      case Tile.brick:
        canvas.drawRect(r, _fill(const Color(0xFFC8643B)));
        final mortar = _line(t * 0.05, const Color(0xFF8E3F22));
        canvas.drawLine(
          Offset(r.left, r.top + t / 2),
          Offset(r.right, r.top + t / 2),
          mortar,
        );
        canvas.drawLine(
          Offset(r.left + t / 2, r.top),
          Offset(r.left + t / 2, r.top + t / 2),
          mortar,
        );
        canvas.drawLine(
          Offset(r.left + t / 4, r.top + t / 2),
          Offset(r.left + t / 4, r.bottom),
          mortar,
        );
        canvas.drawLine(
          Offset(r.left + t * 3 / 4, r.top + t / 2),
          Offset(r.left + t * 3 / 4, r.bottom),
          mortar,
        );
        canvas.drawRect(
          r.deflate(t * 0.02),
          _line(t * 0.06, const Color(0xFF8E3F22)),
        );
      case Tile.coinBlock || Tile.letterBlock || Tile.pageBlock:
        final shine = 0.5 + 0.5 * sin(clock * 3);
        _block(
          canvas,
          r,
          Color.lerp(_gold, const Color(0xFFFFE08A), shine * 0.4)!,
          _goldDark,
        );
        _text(
          canvas,
          '?',
          r.center,
          t * 0.7,
          const Color(0xFF8A5A1E),
          latin: true,
        );
      case Tile.usedBlock:
        _block(canvas, r, const Color(0xFFA27B55), const Color(0xFF7A5A3C));
    }
  }

  void _block(Canvas canvas, Rect r, Color face, Color edge) {
    final rr = RRect.fromRectAndRadius(
      r.deflate(r.width * 0.02),
      Radius.circular(r.width * 0.12),
    );
    canvas.drawRRect(rr, _fill(edge));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          r.left + r.width * 0.08,
          r.top + r.width * 0.06,
          r.right - r.width * 0.08,
          r.bottom - r.width * 0.14,
        ),
        Radius.circular(r.width * 0.1),
      ),
      _fill(face),
    );
    canvas.drawRRect(rr, _line(r.width * 0.05));
  }

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------

  void coin(Canvas canvas, double x, double y, double t, double clock) {
    final squeeze = cos(clock * 4).abs() * 0.8 + 0.2;
    final rect = Rect.fromCenter(
      center: Offset(x * t, y * t),
      width: t * 0.6 * squeeze,
      height: t * 0.7,
    );
    canvas.drawOval(rect, _fill(_goldDark));
    canvas.drawOval(rect.deflate(t * 0.07), _fill(_gold));
    canvas.drawOval(rect, _line(t * 0.04));
  }

  void flag(
    Canvas canvas,
    double x,
    double groundY,
    double t,
    bool reached,
    double clock,
  ) {
    final px = x * t, base = groundY * t, top = base - t * 4;
    canvas.drawLine(
      Offset(px, base),
      Offset(px, top),
      _line(t * 0.12, const Color(0xFF8A6B4E)),
    );
    canvas.drawCircle(Offset(px, top), t * 0.14, _fill(_gold));
    final y = reached ? top + t * 0.2 : base - t * 1.2;
    final wave = sin(clock * 5) * t * 0.08;
    final flag = Path()
      ..moveTo(px, y)
      ..quadraticBezierTo(px + t * 0.5, y + wave, px + t * 1.0, y + t * 0.3)
      ..quadraticBezierTo(px + t * 0.5, y + t * 0.6 - wave, px, y + t * 0.7)
      ..close();
    canvas.drawPath(
      flag,
      _fill(reached ? AppColors.leafGreen : const Color(0xFFB9B2A8)),
    );
    canvas.drawPath(flag, _line(t * 0.04));
    canvas.drawRect(
      Rect.fromLTWH(px - t * 0.3, base - t * 0.2, t * 0.6, t * 0.2),
      _fill(const Color(0xFF8A6B4E)),
    );
  }

  /// The letters gate: a tall wall with a door and one slot per letter
  /// (won letters glow in their slots).
  void gate(
    Canvas canvas,
    int col,
    double groundY,
    double t, {
    required double open,
    required int slots,
    required List<String?> found,
  }) {
    final cx = (col + 0.5) * t, base = groundY * t;
    final wall = Rect.fromLTRB(cx - t * 1.3, -t * 2, cx + t * 1.3, base);
    canvas.drawRect(wall, _fill(const Color(0xFFD8B47A)));
    for (var y = base - t * 0.5; y > -t * 2; y -= t * 0.5) {
      canvas.drawLine(
        Offset(wall.left, y),
        Offset(wall.right, y),
        _line(t * 0.03, const Color(0xFFB08A50)),
      );
    }
    canvas.drawRect(wall, _line(t * 0.08));
    // Door.
    final door = Rect.fromLTRB(
      cx - t * 0.7,
      base - t * 2.6,
      cx + t * 0.7,
      base,
    );
    final arch = Path()
      ..moveTo(door.left, door.bottom)
      ..lineTo(door.left, door.top + t * 0.7)
      ..arcToPoint(
        Offset(door.right, door.top + t * 0.7),
        radius: Radius.circular(t * 0.7),
      )
      ..lineTo(door.right, door.bottom)
      ..close();
    canvas.drawPath(arch, _fill(const Color(0xFF2B2420)));
    canvas.save();
    canvas.clipPath(arch);
    final shift = open * door.height;
    final wood = door.shift(Offset(0, -shift));
    canvas.drawRect(wood, _fill(const Color(0xFF8A5A3B)));
    for (var k = 1; k < 4; k++) {
      final x = wood.left + wood.width * k / 4;
      canvas.drawLine(
        Offset(x, wood.top),
        Offset(x, wood.bottom),
        _line(t * 0.04, const Color(0xFF6B4430)),
      );
    }
    canvas.drawCircle(
      Offset(wood.right - t * 0.25, wood.center.dy + t * 0.3),
      t * 0.08,
      _fill(_gold),
    );
    canvas.restore();
    canvas.drawPath(arch, _line(t * 0.08));
    // Letter slots above the door.
    for (var i = 0; i < slots; i++) {
      final center = Offset(cx, base - t * (3.3 + i * 0.95));
      final glyph = i < found.length ? found[i] : null;
      canvas.drawCircle(
        center,
        t * 0.42,
        _fill(glyph == null ? const Color(0xFF8E6C47) : _gold),
      );
      canvas.drawCircle(center, t * 0.42, _line(t * 0.05));
      if (glyph != null) {
        _text(canvas, glyph, center, t * 0.55, AppColors.cocoa);
      }
    }
  }

  void book(
    Canvas canvas,
    double x,
    double groundY,
    double t,
    double clock, {
    required bool glowing,
  }) {
    final c = Offset(x * t, groundY * t - t * 0.9);
    // Stand.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(c.dx, groundY * t - t * 0.3),
        width: t * 0.4,
        height: t * 0.6,
      ),
      _fill(const Color(0xFF6B4430)),
    );
    final glow = glowing
        ? 0.6 + 0.4 * sin(clock * 6)
        : 0.25 + 0.1 * sin(clock * 2);
    canvas.drawCircle(
      c,
      t * 1.2,
      _fill(Color.fromRGBO(255, 200, 69, glow * 0.5)),
    );
    final left = Path()
      ..moveTo(c.dx, c.dy + t * 0.15)
      ..lineTo(c.dx - t * 0.8, c.dy)
      ..lineTo(c.dx - t * 0.8, c.dy - t * 0.55)
      ..lineTo(c.dx, c.dy - t * 0.4)
      ..close();
    final right = Path()
      ..moveTo(c.dx, c.dy + t * 0.15)
      ..lineTo(c.dx + t * 0.8, c.dy)
      ..lineTo(c.dx + t * 0.8, c.dy - t * 0.55)
      ..lineTo(c.dx, c.dy - t * 0.4)
      ..close();
    canvas.drawPath(left, _fill(const Color(0xFFFFF6E0)));
    canvas.drawPath(right, _fill(const Color(0xFFFFEFCC)));
    canvas.drawPath(left, _line(t * 0.05, const Color(0xFF6B4430)));
    canvas.drawPath(right, _line(t * 0.05, const Color(0xFF6B4430)));
    for (var k = 0; k < 3; k++) {
      final y = c.dy - t * (0.3 - k * 0.12);
      canvas.drawLine(
        Offset(c.dx - t * 0.65, y - t * 0.06),
        Offset(c.dx - t * 0.15, y + t * 0.02),
        _line(t * 0.03, _goldDark),
      );
      canvas.drawLine(
        Offset(c.dx + t * 0.15, y + t * 0.02),
        Offset(c.dx + t * 0.65, y - t * 0.06),
        _line(t * 0.03, _goldDark),
      );
    }
  }

  void platform(
    Canvas canvas,
    double x,
    double y,
    double w,
    double t, {
    required bool falling,
  }) {
    final r = Rect.fromLTWH(x * t, y * t, w * t, t * 0.45);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(t * 0.1));
    canvas.drawRRect(
      rr,
      _fill(falling ? const Color(0xFFC9A46A) : const Color(0xFF9C6B43)),
    );
    for (var k = 1; k < (w * 2).round(); k++) {
      final px = r.left + k * t / 2;
      canvas.drawLine(
        Offset(px, r.top),
        Offset(px, r.bottom),
        _line(t * 0.03, const Color(0xFF6B4430)),
      );
    }
    canvas.drawRRect(rr, _line(t * 0.05));
  }

  /// Grandpa's glowing page; [y] is its bottom.
  void page(Canvas canvas, double x, double y, double t, double clock) {
    final c = Offset(x * t, (y - 0.45) * t);
    canvas.drawCircle(
      c,
      t * 0.65,
      _fill(Color.fromRGBO(255, 200, 69, 0.3 + 0.15 * sin(clock * 6))),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(sin(clock * 3) * 0.12);
    final r = Rect.fromCenter(
      center: Offset.zero,
      width: t * 0.62,
      height: t * 0.8,
    );
    canvas.drawRect(r, _fill(const Color(0xFFFFF3D6)));
    for (var k = 0; k < 4; k++) {
      final ly = r.top + t * (0.18 + k * 0.15);
      canvas.drawLine(
        Offset(r.left + t * 0.1, ly),
        Offset(r.right - t * 0.1, ly),
        _line(t * 0.04, _goldDark),
      );
    }
    canvas.drawRect(r, _line(t * 0.05, const Color(0xFF8A5A3B)));
    canvas.restore();
  }

  /// A lost letter popping from its block; [y] is its center.
  void letter(
    Canvas canvas,
    double x,
    double y,
    double t,
    String glyph,
    double scale,
    double clock,
  ) {
    if (scale <= 0.01) return;
    // Drawn at one size and scaled, so the text cache stays small.
    canvas.save();
    canvas.translate(x * t, y * t);
    canvas.scale(scale);
    final r = t * 0.6;
    canvas.drawCircle(
      Offset.zero,
      r * 1.5,
      _fill(Color.fromRGBO(255, 200, 69, 0.35 + 0.15 * sin(clock * 8))),
    );
    canvas.drawCircle(Offset.zero, r, _fill(const Color(0xFFFFF6E0)));
    canvas.drawCircle(Offset.zero, r, _line(t * 0.06, _goldDark));
    _text(canvas, glyph, Offset.zero, r * 1.25, AppColors.cocoa);
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Enemies
  // ---------------------------------------------------------------------------

  /// One enemy; ([x], [y]) is the middle of its feet.
  void enemy(
    Canvas canvas,
    EnemyKind kind,
    double x,
    double y,
    double t, {
    required bool facingLeft,
    required double clock,
    required bool squashed,
    required bool upsideDown,
  }) {
    canvas.save();
    canvas.translate(x * t, y * t);
    if (squashed) canvas.scale(1.1, 0.35);
    if (upsideDown) canvas.scale(1, -1);
    if (!facingLeft) canvas.scale(-1, 1);
    final picture = images[kind.name];
    if (picture != null) {
      // Pictures face left with their feet at the bottom; a little waddle.
      final h = t * enemyHeight(kind);
      final w = h * picture.width / picture.height;
      final step = sin(clock * 10);
      canvas.translate(0, -step.abs() * t * 0.05);
      canvas.rotate(step * 0.06);
      _image(canvas, picture, _all(picture), Rect.fromLTWH(-w / 2, -h, w, h));
      canvas.restore();
      return;
    }
    switch (kind) {
      case EnemyKind.duck:
        _duck(canvas, t, clock);
      case EnemyKind.scorpion:
        _scorpion(canvas, t, clock);
      case EnemyKind.crab:
        _crab(canvas, t, clock);
      case EnemyKind.seagull:
        _seagull(canvas, t, clock);
    }
    canvas.restore();
  }

  /// How tall each enemy's picture is drawn, in tiles.
  static double enemyHeight(EnemyKind kind) => switch (kind) {
    EnemyKind.duck => 1.25,
    EnemyKind.scorpion => 0.95,
    EnemyKind.crab => 0.9,
    EnemyKind.seagull => 1.35,
  };

  // Drawn facing left, feet at (0, 0).
  void _duck(Canvas canvas, double t, double clock) {
    final step = sin(clock * 10);
    final legs = _line(t * 0.07, const Color(0xFFF08A24));
    canvas.drawLine(
      Offset(-t * 0.12, -t * 0.25),
      Offset(-t * 0.12 + step * t * 0.08, 0),
      legs,
    );
    canvas.drawLine(
      Offset(t * 0.12, -t * 0.25),
      Offset(t * 0.12 - step * t * 0.08, 0),
      legs,
    );
    final body = Rect.fromCenter(
      center: Offset(t * 0.05, -t * 0.42),
      width: t * 0.8,
      height: t * 0.42,
    );
    canvas.drawOval(body, _fill(AppColors.white));
    canvas.drawOval(body, _line(t * 0.04));
    canvas.drawCircle(
      Offset(-t * 0.25, -t * 0.72),
      t * 0.18,
      _fill(AppColors.white),
    );
    canvas.drawCircle(Offset(-t * 0.25, -t * 0.72), t * 0.18, _line(t * 0.04));
    final beak = Path()
      ..moveTo(-t * 0.4, -t * 0.76)
      ..lineTo(-t * 0.6, -t * 0.7)
      ..lineTo(-t * 0.4, -t * 0.64)
      ..close();
    canvas.drawPath(beak, _fill(const Color(0xFFF08A24)));
    canvas.drawCircle(Offset(-t * 0.3, -t * 0.76), t * 0.04, _fill(_outline));
    // Angry brow.
    canvas.drawLine(
      Offset(-t * 0.38, -t * 0.86),
      Offset(-t * 0.22, -t * 0.82),
      _line(t * 0.04),
    );
    final wing = Path()
      ..moveTo(t * 0.0, -t * 0.48)
      ..quadraticBezierTo(
        t * 0.25,
        -t * (0.62 + step.abs() * 0.08),
        t * 0.35,
        -t * 0.42,
      )
      ..close();
    canvas.drawPath(wing, _fill(const Color(0xFFE6E1D6)));
  }

  void _scorpion(Canvas canvas, double t, double clock) {
    final step = sin(clock * 14);
    final legs = _line(t * 0.05, const Color(0xFF5B3A1E));
    for (var k = 0; k < 3; k++) {
      final lx = -t * 0.2 + k * t * 0.2;
      canvas.drawLine(
        Offset(lx, -t * 0.15),
        Offset(lx - t * 0.08 + (k.isEven ? step : -step) * t * 0.05, 0),
        legs,
      );
    }
    final body = Rect.fromCenter(
      center: Offset(0, -t * 0.2),
      width: t * 0.7,
      height: t * 0.26,
    );
    canvas.drawOval(body, _fill(const Color(0xFF9C6230)));
    canvas.drawOval(body, _line(t * 0.04));
    // Claws.
    for (final dy in [-0.28, -0.12]) {
      canvas.drawLine(
        Offset(-t * 0.3, -t * 0.2),
        Offset(-t * 0.5, -t * (0.2 - dy * 0.3)),
        _line(t * 0.06, const Color(0xFF9C6230)),
      );
      canvas.drawCircle(
        Offset(-t * 0.52, -t * (0.2 - dy * 0.3)),
        t * 0.07,
        _fill(const Color(0xFF9C6230)),
      );
    }
    // Tail curling up over the back.
    final tail = Path()
      ..moveTo(t * 0.3, -t * 0.22)
      ..quadraticBezierTo(
        t * 0.55,
        -t * 0.55,
        t * 0.25,
        -t * (0.62 + step.abs() * 0.04),
      );
    canvas.drawPath(tail, _line(t * 0.1, const Color(0xFF9C6230)));
    canvas.drawCircle(Offset(t * 0.22, -t * 0.62), t * 0.06, _fill(_outline));
    canvas.drawCircle(Offset(-t * 0.2, -t * 0.26), t * 0.035, _fill(_outline));
  }

  void _crab(Canvas canvas, double t, double clock) {
    final step = sin(clock * 12);
    final legs = _line(t * 0.05, const Color(0xFFB23A2A));
    for (var k = 0; k < 3; k++) {
      final dx = t * (0.15 + k * 0.1);
      canvas.drawLine(
        Offset(-dx, -t * 0.2),
        Offset(-dx - t * 0.12, step * t * 0.04),
        legs,
      );
      canvas.drawLine(
        Offset(dx, -t * 0.2),
        Offset(dx + t * 0.12, -step * t * 0.04),
        legs,
      );
    }
    final body = Rect.fromCenter(
      center: Offset(0, -t * 0.3),
      width: t * 0.8,
      height: t * 0.4,
    );
    canvas.drawOval(body, _fill(const Color(0xFFE5533D)));
    canvas.drawOval(body, _line(t * 0.04));
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(s * t * 0.12, -t * 0.45),
        Offset(s * t * 0.14, -t * 0.62),
        _line(t * 0.04),
      );
      canvas.drawCircle(
        Offset(s * t * 0.14, -t * 0.64),
        t * 0.07,
        _fill(AppColors.white),
      );
      canvas.drawCircle(
        Offset(s * t * 0.14, -t * 0.64),
        t * 0.035,
        _fill(_outline),
      );
      final claw = Offset(s * t * 0.5, -t * (0.55 + step.abs() * 0.05));
      canvas.drawLine(
        Offset(s * t * 0.35, -t * 0.35),
        claw,
        _line(t * 0.06, const Color(0xFFE5533D)),
      );
      canvas.drawCircle(claw, t * 0.1, _fill(const Color(0xFFE5533D)));
      canvas.drawCircle(claw, t * 0.1, _line(t * 0.03));
    }
  }

  void _seagull(Canvas canvas, double t, double clock) {
    final flap = sin(clock * 9);
    final body = Rect.fromCenter(
      center: Offset(0, -t * 0.3),
      width: t * 0.75,
      height: t * 0.3,
    );
    final wing = Path()
      ..moveTo(-t * 0.05, -t * 0.35)
      ..quadraticBezierTo(
        t * 0.15,
        -t * (0.35 + flap * 0.45),
        t * 0.45,
        -t * (0.3 + flap * 0.5),
      )
      ..lineTo(t * 0.2, -t * 0.3)
      ..close();
    canvas.drawPath(wing, _fill(const Color(0xFF9AA5B1)));
    canvas.drawOval(body, _fill(AppColors.white));
    canvas.drawOval(body, _line(t * 0.04));
    canvas.drawPath(wing, _line(t * 0.03));
    canvas.drawCircle(
      Offset(-t * 0.32, -t * 0.4),
      t * 0.14,
      _fill(AppColors.white),
    );
    canvas.drawCircle(Offset(-t * 0.32, -t * 0.4), t * 0.14, _line(t * 0.04));
    canvas.drawCircle(Offset(-t * 0.36, -t * 0.43), t * 0.03, _fill(_outline));
    final beak = Path()
      ..moveTo(-t * 0.44, -t * 0.42)
      ..lineTo(-t * 0.62, -t * 0.37)
      ..lineTo(-t * 0.44, -t * 0.34)
      ..close();
    canvas.drawPath(beak, _fill(_gold));
  }

  // ---------------------------------------------------------------------------
  // Effects
  // ---------------------------------------------------------------------------

  void fx(Canvas canvas, AdventureFx f, double t) {
    final p = f.progress;
    final c = Offset(f.x * t, f.y * t);
    switch (f.kind) {
      case FxKind.coin:
        coin(canvas, f.x, f.y, t, p * 6);
      case FxKind.debris:
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(p * 8);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: t * 0.35,
            height: t * 0.3,
          ),
          _fill(const Color(0xFFC8643B)),
        );
        canvas.restore();
      case FxKind.puff:
        canvas.drawCircle(
          c,
          t * (0.3 + p * 0.6),
          _fill(Color.fromRGBO(255, 255, 255, 0.8 * (1 - p))),
        );
      case FxKind.sparkle:
        final paint = _line(t * 0.06, Color.fromRGBO(255, 200, 69, 1 - p));
        for (var k = 0; k < 4; k++) {
          final a = k * pi / 2 + pi / 4;
          final d = t * (0.2 + p * 0.5);
          canvas.drawLine(
            c + Offset(cos(a), sin(a)) * d * 0.5,
            c + Offset(cos(a), sin(a)) * d,
            paint,
          );
        }
    }
  }

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  final Map<String, TextPainter> _texts = {};

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color, {
    bool latin = false,
  }) {
    final key = '$text|${size.toStringAsFixed(1)}|${color.toARGB32()}|$latin';
    final painter = _texts[key] ??= (TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: latin ? AppFonts.english : AppFonts.coptic,
          fontSize: size,
          height: 1,
          color: color,
          fontWeight: latin ? FontWeight.w800 : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout());
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }
}
