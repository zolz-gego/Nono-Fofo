import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

/// The snakes & ladders board: [squares] numbered squares, [columns] to a
/// row. Square 1 is bottom-left; numbers run along the bottom row, then
/// back along the next one up, and so on (like a real board). 0 is the
/// start, beside the board.
class SnakesBoard extends Equatable {
  SnakesBoard({
    required this.squares,
    required this.columns,
    required this.ladders,
    required this.snakes,
  }) {
    if (squares % columns != 0) {
      throw Failure(
        'snakes board: $squares squares don\'t fill rows of '
        '$columns',
      );
    }
    final ends = <int>{};
    void check(int from, int to, String what, bool up) {
      if (from <= 1 || from >= squares || to < 1 || to > squares) {
        throw Failure('snakes board: $what $from→$to is off the board');
      }
      if (up != (to > from)) {
        throw Failure('snakes board: $what $from→$to goes the wrong way');
      }
      if (!ends.add(from)) {
        throw Failure('snakes board: square $from has two snakes/ladders');
      }
    }

    ladders.forEach((from, to) => check(from, to, 'ladder', true));
    snakes.forEach((from, to) => check(from, to, 'snake', false));
    for (final to in [...ladders.values, ...snakes.values]) {
      if (ends.contains(to)) {
        throw Failure(
          'snakes board: something ends on square $to, where '
          'another snake or ladder starts',
        );
      }
    }
  }

  final int squares;
  final int columns;

  /// Bottom square → top square.
  final Map<int, int> ladders;

  /// Head square → tail square.
  final Map<int, int> snakes;

  int get rows => squares ~/ columns;

  /// Row (0 = bottom) and column (0 = left) of [square] (1-based).
  (int row, int column) cellOf(int square) {
    final i = square - 1;
    final row = i ~/ columns;
    final c = i % columns;
    return (row, row.isEven ? c : columns - 1 - c);
  }

  /// Where a token at [from] ends up after rolling [roll].
  MovePlan move(int from, int roll) {
    final target = from + roll;
    // Must land exactly on the last square: too far = stay put.
    if (target > squares) return MovePlan(from: from, steps: const []);
    final steps = [for (var s = from + 1; s <= target; s++) s];
    return MovePlan(
      from: from,
      steps: steps,
      jumpTo: ladders[target] ?? snakes[target],
    );
  }

  @override
  List<Object?> get props => [squares, columns, ladders, snakes];
}

/// One move: the squares hopped through one by one, then maybe a ladder up
/// or a snake down.
class MovePlan extends Equatable {
  const MovePlan({required this.from, required this.steps, this.jumpTo});

  final int from;

  /// Each square passed, the last one being where the dice took it. Empty
  /// when the roll went past the end (the token stays put).
  final List<int> steps;

  /// The end of the ladder or snake on the landing square, if any.
  final int? jumpTo;

  bool get overshoot => steps.isEmpty;
  int get landed => steps.isEmpty ? from : steps.last;
  int get end => jumpTo ?? landed;
  bool get climbed => jumpTo != null && jumpTo! > landed;
  bool get slid => jumpTo != null && jumpTo! < landed;

  @override
  List<Object?> get props => [from, steps, jumpTo];
}
