import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/core/typography/app_text_styles.dart';
import 'package:nonofofo/features/games/adventure/presentation/adventure_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a square PNG in both directions', () async {
    for (final direction in TextDirection.values) {
      final png = await AdventureShareCard(
        title: 'Mina finished level 2!',
        place: 'The desert & the Pyramids',
        background: 'assets/games/adventure/bg_desert.webp',
        stars: 2,
        bonusStars: 2,
        letters: const ['A', 'B', 'J', 'D', 'E'],
        stats: const [('41/60', 'Coins'), ('3:12', 'Time')],
        badge: 'You finished the whole adventure!',
        appTitle: 'Nono & Fofo',
        script: AppScript.english,
        direction: direction,
        heroAssets: const [
          'assets/characters/fofo/celebrate.png',
          'assets/characters/nono/celebrate.png',
        ],
      ).render();
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, AdventureShareCard.size);
      expect(frame.image.height, AdventureShareCard.size);
    }
  });
}
