import 'package:equatable/equatable.dart';

/// One finished run of a timed game: how long it took and in how many moves.
class TimedRecord extends Equatable {
  const TimedRecord({required this.time, required this.moves});

  final Duration time;
  final int moves;

  /// Faster wins; on the same second, fewer moves wins.
  bool beats(TimedRecord other) {
    final a = time.inSeconds, b = other.time.inSeconds;
    return a < b || (a == b && moves < other.moves);
  }

  /// "1:05" (or "1:02:05" past an hour).
  String get clock => formatClock(time);

  @override
  List<Object?> get props => [time, moves];
}

/// "m:ss" (or "h:mm:ss") for a stopwatch.
String formatClock(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}
