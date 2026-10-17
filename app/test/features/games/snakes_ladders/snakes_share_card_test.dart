import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/core/typography/app_text_styles.dart';
import 'package:nonofofo/features/games/snakes_ladders/presentation/snakes_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a square PNG in both directions', () async {
    for (final direction in TextDirection.values) {
      final png = await SnakesShareCard(
        title: 'Mina won Snakes & Ladders!',
        line: 'Mina beat Fofo',
        stats: const [('9/11', 'Right answers'), ('12', 'Rolls')],
        badge: 'Challenge complete!',
        subtitle: 'With Nono by the Pyramids',
        appTitle: 'Nono & Fofo',
        script: AppScript.english,
        direction: direction,
        heroAssets: const [
          'assets/characters/nono/celebrate.png',
          'assets/characters/fofo/encourage.png',
        ],
      ).render();
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, SnakesShareCard.size);
      expect(frame.image.height, SnakesShareCard.size);
    }
  });
}
