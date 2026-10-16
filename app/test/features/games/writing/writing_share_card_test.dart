import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/core/typography/app_text_styles.dart';
import 'package:nonofofo/features/games/writing/presentation/writing_share_card.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF2F5D4E),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a square PNG in both directions', () async {
    final small = await _png(120, 200);
    final capital = await _png(140, 200);
    for (final direction in TextDirection.values) {
      final png = await WritingShareCard(
        drawings: [small, capital],
        title: 'Bravo Mina! You wrote the letter Alpha',
        subtitle: "With Nono at Grandpa's chalkboard",
        appTitle: 'Nono & Fofo',
        script: AppScript.english,
        direction: direction,
        heroAsset: 'assets/characters/nono/celebrate.png',
      ).render();
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, WritingShareCard.size);
      expect(frame.image.height, WritingShareCard.size);
    }
  });
}
