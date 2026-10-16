import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../../core/typography/app_text_styles.dart';
import '../domain/letter_mask.dart';
import '../domain/writing_board.dart';

/// Turns one Coptic glyph (typed with the Avva Shenouda keyboard) into a
/// [LetterMask]: the glyph is drawn off screen, fitted into
/// [WritingBoard.letterArea], and its pixels become the letter's cells.
class LetterMaskBuilder {
  const LetterMaskBuilder();

  static const double _probeSize = 400;

  Future<LetterMask> build(String glyph, {double thicken = 0}) async {
    // 1. Draw the glyph once to find its ink box.
    final painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: const TextStyle(
          fontFamily: AppFonts.coptic,
          fontSize: _probeSize,
          color: Color(0xFFFFFFFF),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const pad = _probeSize * 0.3;
    final probeW = (painter.width + pad * 2).ceil();
    final probeH = (painter.height + pad * 2).ceil();
    final probe = await _render(probeW, probeH, (c) {
      painter.paint(c, const Offset(pad, pad));
    });
    final ink =
        _inkBox(probe, probeW, probeH) ??
        Rect.fromLTWH(pad, pad, painter.width, painter.height);

    // 2. Fit the ink box into the letter area.
    const area = WritingBoard.letterArea;
    final scale = math.min(area.width / ink.width, area.height / ink.height);
    final inkRect = Rect.fromCenter(
      center: area.center,
      width: ink.width * scale,
      height: ink.height * scale,
    );

    // 3. Draw it at grid resolution: one pixel per cell.
    const cell = WritingBoard.cell;
    final (cols, rows) = LetterMask.gridFor(
      WritingBoard.width,
      WritingBoard.height,
      cell,
    );
    final grid = await _render(cols, rows, (c) {
      c
        ..scale(1 / cell)
        ..translate(inkRect.left, inkRect.top)
        ..scale(scale)
        ..translate(-ink.left + pad, -ink.top + pad);
      painter.paint(c, Offset.zero);
    });
    final letter = Uint8List(cols * rows);
    for (var i = 0; i < letter.length; i++) {
      if (grid[i * 4 + 3] > 110) letter[i] = 1;
    }
    painter.dispose();

    final mask = LetterMask(
      cols: cols,
      rows: rows,
      cell: cell,
      letter: letter,
      inkRect: inkRect,
    );
    final cells = (thicken * WritingBoard.height / cell).round();
    return cells > 0 ? mask.thickened(cells) : mask;
  }

  static Future<Uint8List> _render(
    int w,
    int h,
    void Function(Canvas) draw,
  ) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List();
  }

  /// Bounding box of the painted pixels, or null if nothing was painted
  /// (e.g. the font has not loaded).
  static Rect? _inkBox(Uint8List rgba, int w, int h) {
    var minX = w, minY = h, maxX = -1, maxY = -1;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (rgba[(y * w + x) * 4 + 3] <= 110) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < 0) return null;
    return Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      maxX + 1.0,
      maxY + 1.0,
    );
  }
}
