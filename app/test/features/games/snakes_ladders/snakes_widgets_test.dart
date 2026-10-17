import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/core/domain/character_id.dart';
import 'package:nonofofo/core/l10n/l10n.dart';
import 'package:nonofofo/core/theme/app_colors.dart';
import 'package:nonofofo/engines/characters/domain/character_pose.dart';
import 'package:nonofofo/engines/sound/application/sound_service.dart';
import 'package:nonofofo/engines/sound/domain/sound_event.dart';
import 'package:nonofofo/features/games/snakes_ladders/presentation/question_card.dart';
import 'package:nonofofo/features/games/snakes_ladders/presentation/snakes_cubit.dart';
import 'package:nonofofo/features/games/snakes_ladders/presentation/snakes_result.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';
import 'package:nonofofo/features/questions/domain/letter_question.dart';

class _Sound extends Mock implements SoundService {}

CopticLetter _letter(String id, String en, String ar) => CopticLetter(
  id: id,
  small: id,
  capital: id.toUpperCase(),
  names: {'en': en, 'ar': ar},
);

SoundService _sound() {
  final s = _Sound();
  when(() => s.play(any(), by: any(named: 'by'))).thenAnswer((_) async {});
  return s;
}

Widget _app(Widget child, Locale locale) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<SoundService>.value(value: _sound()),
    RepositoryProvider<CharacterRoster>.value(value: CharacterRoster.empty),
  ],
  child: MaterialApp(
    locale: locale,
    supportedLocales: AppLocales.supported,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  ),
);

const _sizes = [Size(1280, 800), Size(375, 812), Size(812, 375)];

void main() {
  setUpAll(() => registerFallbackValue(SoundEvent.tap));
  final letters = [
    _letter('a', 'Alpha', 'الفا'),
    _letter('b', 'Epsilon', 'ابسيلون'),
    _letter('o', 'Omega', 'اوميجا'),
  ];

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final size in _sizes) {
      testWidgets('question card fits at $size (${locale.languageCode})', (
        tester,
      ) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final show in LetterSide.values) {
          await tester.pumpWidget(
            _app(
              QuestionCard(
                question: LetterQuestion(
                  show: show,
                  answer: letters[1],
                  choices: letters,
                  capital: true,
                ),
                playerName: 'Mina',
                character: CharacterId.nono,
                color: AppColors.nonoAccent,
                picked: 0,
                onPick: (_) {},
              ),
              locale,
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('result fits at $size (${locale.languageCode})', (
        tester,
      ) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            SnakesResult(
              state: const SnakesState(
                players: [
                  SnakesPlayer(character: CharacterId.nono, name: 'Mina'),
                  SnakesPlayer(
                    character: CharacterId.fofo,
                    name: 'Fofo',
                    computer: true,
                  ),
                ],
                positions: [64, 40],
                phase: SnakesPhase.done,
                asked: [12, 0],
                correct: [10, 0],
                turns: [10, 14],
                winner: 0,
                firstWin: true,
              ),
              colors: const [AppColors.nonoAccent, AppColors.fofoAccent],
              squares: 64,
              onPlayAgain: () {},
              onChangePlayers: () {},
              onBackToGames: () {},
              onShare: (_) {},
            ),
            locale,
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.byType(SnakesResult), findsOneWidget);
        // Let the confetti and timers finish.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }
}
