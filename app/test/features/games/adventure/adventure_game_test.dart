import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/core/assets/json_asset_loader.dart';
import 'package:nonofofo/engines/characters/data/character_repository_impl.dart';
import 'package:nonofofo/engines/characters/domain/character_pose.dart';
import 'package:nonofofo/engines/sound/application/sound_service.dart';
import 'package:nonofofo/engines/sound/domain/audio_engine.dart';
import 'package:nonofofo/engines/sound/domain/sound_repository.dart';
import 'package:nonofofo/features/games/adventure/domain/adventure_config.dart';
import 'package:nonofofo/features/games/adventure/domain/adventure_level.dart';
import 'package:nonofofo/features/games/adventure/game/adventure_game.dart';
import 'package:nonofofo/features/games/adventure/presentation/adventure_cubit.dart';
import 'package:nonofofo/features/games/progress/domain/game_progress_repository.dart';
import 'package:nonofofo/features/letters/domain/coptic_letter.dart';
import 'package:nonofofo/features/levels/domain/game_level.dart';
import 'package:nonofofo/features/questions/domain/letter_question.dart';

class _Progress extends Mock implements GameProgressRepository {}

class _SoundRepo extends Mock implements SoundRepository {}

class _Engine extends Mock implements AudioEngine {}

final _pool = [
  for (final id in 'abcdefg'.split(''))
    CopticLetter(id: id, small: id, capital: id, names: {'en': id}),
];

AdventureConfig _config() => AdventureConfig.fromJson(
  jsonDecode(File('assets/content/games/adventure.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// Runs the real game loop at 60 fps for [seconds].
void _run(AdventureGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CharacterRoster roster;
  final config = _config();

  setUpAll(() async {
    roster = await CharacterRepositoryImpl(JsonAssetLoader(rootBundle))
        .loadRoster();
  });

  Future<(AdventureGame, AdventureCubit)> start(
    WidgetTester tester,
    int level,
  ) async {
    final progress = _Progress();
    when(() => progress.bestStars(any(), any())).thenReturn(0);
    final cubit = AdventureCubit(
      progress,
      config: config,
      gameLevel: GameLevel.one,
      templates: const [
        LetterQuestionTemplate(id: 'q', level: 1, show: LetterSide.letter),
      ],
      pool: _pool,
    )..startLevel(level);
    final game = AdventureGame(
      cubit: cubit,
      level: config.levels[level],
      config: config,
      roster: roster,
      sound: SoundService(_SoundRepo(), _Engine()),
    );
    game.onGameResize(Vector2(1280, 736));
    await tester.runAsync(game.onLoad);
    return (game, cubit);
  }

  testWidgets('Fofo walks right and stands on the ground', (tester) async {
    final (game, _) = await start(tester, 0);
    final x0 = game.debugHero.x;
    game.input.right = true;
    _run(game, 0.5);
    game.input.right = false;
    expect(game.debugHero.x, greaterThan(x0 + 2));
    expect(game.debugHero.y, 12);
    expect(game.debugHero.onGround, isTrue);
  });

  testWidgets('Grandpa\'s page lands on the ground where Fofo can walk', (
    tester,
  ) async {
    for (final (i, level) in config.levels.indexed) {
      final (game, _) = await start(tester, i);
      // Find the page block and jump into it from below.
      late Cell block;
      for (var r = 0; r < level.height; r++) {
        for (var c = 0; c < level.width; c++) {
          if (level.tiles[r][c] == Tile.pageBlock) block = Cell(c, r);
        }
      }
      game
        ..debugRemoveEnemies()
        ..debugPlaceHero(Cell(block.col, 11));
      game.input.pressJump();
      _run(game, 0.6);
      game.input.releaseJump();
      _run(game, 2);
      final page = game.debugPage;
      expect(page, isNotNull, reason: level.id);
      expect(
        page!.settled,
        isTrue,
        reason: '${level.id} $page ${game.debugHero}',
      );
      // On the ground row, beside the block (not on top of the blocks).
      expect(page.y, 12, reason: level.id);
      expect((page.x - block.col - 0.5).abs(), lessThanOrEqualTo(4));
    }
  });

  testWidgets(
    'A sideways platform starts at its hole\'s edge and stays in it',
    (tester) async {
      final (game, _) = await start(tester, 1);
      // The desert's first pit: columns 42–47, stone steps on both sides.
      final first = game.debugSidewaysPlatforms.first;
      expect(first.startCol, 42);
      expect(first.range, 3);
    },
  );

  testWidgets('A replaced (retired) game no longer touches the lives', (
    tester,
  ) async {
    final (game, cubit) = await start(tester, 0);
    // Fall into the first hole...
    game.debugPlaceHero(const Cell(28, 11));
    game.retire();
    _run(game, 3);
    expect(cubit.state.lives, config.lives);
  });

  /// Cells of [level] whose map character is [ch].
  List<Cell> cellsOf(int level, String ch) {
    final json = jsonDecode(
      File('assets/content/games/adventure.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final rows = [
      for (final r in (json['levels'] as List)[level]['rows'] as List)
        r as String,
    ];
    return [
      for (var r = 0; r < rows.length; r++)
        for (var c = 0; c < rows[r].length; c++)
          if (rows[r][c] == ch) Cell(c, r),
    ];
  }

  /// Puts Fofo under [cell] and jumps into it.
  void bump(AdventureGame game, Cell cell) {
    game.debugPlaceHero(Cell(cell.col, 11));
    game.input.pressJump();
    _run(game, 0.5);
    game.input.releaseJump();
    _run(game, 0.8);
  }

  testWidgets('A hidden block in the desert gives a shower of coins', (
    tester,
  ) async {
    final (game, cubit) = await start(tester, 1);
    game.debugRemoveEnemies();
    final hidden = cellsOf(1, 'h');
    expect(hidden, hasLength(4));
    bump(game, hidden.first);
    expect(cubit.state.coins, 6);
  });

  testWidgets('Exactly one bonus spot hides the bonus letter', (tester) async {
    final (game, cubit) = await start(tester, 0);
    game.debugRemoveEnemies();
    final spots = cellsOf(0, 'X');
    expect(spots, hasLength(3));
    var found = 0;
    for (final spot in spots) {
      final before = cubit.state.bonus;
      bump(game, spot);
      if (!before && cubit.state.bonus) found++;
    }
    expect(found, 1);
    expect(cubit.state.bonusStars, 2);
  });

  testWidgets('Alexandria seagulls drop shells that hurt Fofo', (tester) async {
    final (game, cubit) = await start(tester, 2);
    // A seagull with open sky and ground under it (no blocks in the way).
    final level = config.levels[2];
    final gull = cellsOf(2, 'g').firstWhere(
      (g) =>
          level.tiles[12][g.col] == Tile.ground &&
          [for (var r = g.row + 1; r < 12; r++) level.tiles[r][g.col]]
              .every((t) => t == Tile.air),
    );
    game.debugPlaceHero(Cell(gull.col, 11));
    var lost = false;
    for (var t = 0.0; t < 8 && !lost; t += 1 / 60) {
      game.debugPlaceHero(Cell(gull.col, 11));
      game.update(1 / 60);
      lost = cubit.state.lives < config.lives;
    }
    expect(lost, isTrue);
  });
}
