import 'snakes_board.dart';

/// Settings from `assets/content/games/snakes_ladders.json`. Defaults here
/// are only used for keys missing from the file.
class SnakesConfig {
  const SnakesConfig({
    required this.board,
    this.diceRoll = const Duration(milliseconds: 1000),
    this.hop = const Duration(milliseconds: 260),
    this.jump = const Duration(milliseconds: 900),
    this.reveal = const Duration(milliseconds: 1600),
    this.computerWait = const Duration(milliseconds: 900),
    this.turnPause = const Duration(milliseconds: 700),
  });

  factory SnakesConfig.fromJson(Map<String, dynamic> json) {
    Duration ms(String key, int fallback) =>
        Duration(milliseconds: (json[key] as num?)?.toInt() ?? fallback);
    Map<int, int> jumps(String key) => {
      for (final e in ((json[key] as Map?) ?? const {}).entries)
        int.parse(e.key as String): (e.value as num).toInt(),
    };

    return SnakesConfig(
      board: SnakesBoard(
        squares: (json['squares'] as num?)?.toInt() ?? 64,
        columns: (json['columns'] as num?)?.toInt() ?? 8,
        ladders: jumps('ladders'),
        snakes: jumps('snakes'),
      ),
      diceRoll: ms('diceRollMs', 1000),
      hop: ms('hopMs', 260),
      jump: ms('jumpMs', 900),
      reveal: ms('revealMs', 1600),
      computerWait: ms('computerWaitMs', 900),
      turnPause: ms('turnPauseMs', 700),
    );
  }

  final SnakesBoard board;

  /// How long the dice tumbles.
  final Duration diceRoll;

  /// Time per square while a token hops.
  final Duration hop;

  /// Time to climb a ladder or slide down a snake.
  final Duration jump;

  /// After a wrong answer, how long the right one glows.
  final Duration reveal;

  /// The computer brother's pause before rolling.
  final Duration computerWait;

  /// The pause between two turns.
  final Duration turnPause;
}
