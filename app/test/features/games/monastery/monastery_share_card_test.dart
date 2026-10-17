import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/core/typography/app_text_styles.dart';
import 'package:nonofofo/features/games/monastery/presentation/monastery_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a square PNG in both directions', () async {
    for (final direction in TextDirection.values) {
      final png = await MonasteryShareCard(
        title: 'Bravo Mina! You found 10 letters',
        glyphs: 'abgdezyqik'.split(''),
        stats: const [('1:05', 'Time'), ('3', 'Misses'), ('1', 'Hints')],
        badge: 'New record!',
        subtitle: 'With Nono at the desert monastery',
        appTitle: 'Nono & Fofo',
        script: AppScript.english,
        direction: direction,
        heroAssets: const [
          'assets/characters/nono/celebrate.png',
          'assets/characters/fofo/celebrate.png',
        ],
      ).render();
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, MonasteryShareCard.size);
      expect(frame.image.height, MonasteryShareCard.size);
    }
  });
}
