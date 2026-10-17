import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/core/typography/app_text_styles.dart';
import 'package:nonofofo/features/games/cards/presentation/cards_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a square PNG in both directions', () async {
    for (final direction in TextDirection.values) {
      final png = await CardsShareCard(
        title: 'Bravo Mina! You matched 16 cards',
        time: '1:05',
        timeLabel: 'Time',
        moves: '12',
        movesLabel: 'Moves',
        badge: 'New record!',
        subtitle: 'With Nono by the sea in Alexandria',
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
      expect(frame.image.width, CardsShareCard.size);
      expect(frame.image.height, CardsShareCard.size);
    }
  });
}
