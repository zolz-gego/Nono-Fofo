import 'dart:math';
import 'dart:ui' show Offset;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../progress/domain/game_progress_repository.dart';
import '../../progress/domain/timed_record.dart';
import '../domain/hidden_letter.dart';

/// Something the page reacts to (sounds, the brothers, the popup).
enum MonasteryEvent {
  none,

  /// A letter was found ([MonasteryState.last]).
  found,

  /// A tap missed every letter.
  wrong,

  /// A hint points near letter [MonasteryState.last].
  hint,

  /// Every letter is found.
  solved,
}

class MonasteryState extends Equatable {
  const MonasteryState({
    required this.letters,
    this.wrongTaps = 0,
    this.hints = 0,
    this.solvedIn,
    this.newRecord = false,
    this.last,
    this.event = MonasteryEvent.none,
    this.eventId = 0,
  });

  final List<HiddenLetter> letters;
  final int wrongTaps;
  final int hints;

  /// The finished time (null while playing).
  final Duration? solvedIn;

  /// The finished run beat the best time for this many letters.
  final bool newRecord;

  /// The letter the last event is about.
  final int? last;
  final MonasteryEvent event;
  final int eventId;

  bool get solved => solvedIn != null;
  int get foundCount => letters.where((l) => l.found).length;

  MonasteryState copyWith({
    List<HiddenLetter>? letters,
    int? wrongTaps,
    int? hints,
    Duration? solvedIn,
    bool? newRecord,
    int? last,
    MonasteryEvent? event,
  }) => MonasteryState(
    letters: letters ?? this.letters,
    wrongTaps: wrongTaps ?? this.wrongTaps,
    hints: hints ?? this.hints,
    solvedIn: solvedIn ?? this.solvedIn,
    newRecord: newRecord ?? this.newRecord,
    last: last ?? this.last,
    event: event ?? this.event,
    eventId: event == null ? eventId : eventId + 1,
  );

  @override
  List<Object?> get props => [
    letters,
    wrongTaps,
    hints,
    solvedIn,
    newRecord,
    last,
    event,
    eventId,
  ];
}

/// Rules of Search the Monastery: tap where a letter hides to find it; a
/// tap on nothing is a wrong tap. The clock runs from [start] until the
/// last letter is found; the best time (with its wrong taps) is kept per
/// number of letters.
class MonasteryCubit extends Cubit<MonasteryState> {
  MonasteryCubit(
    this._progress, {
    required List<HiddenLetter> letters,
    required this.aspect,
    this.tapRadius = 1,
    Stopwatch? stopwatch,
    Random? random,
  }) : _clock = stopwatch ?? Stopwatch(),
       _random = random ?? Random(),
       super(MonasteryState(letters: letters));

  /// Key the best times are saved under (per number of letters).
  static const String id = 'monastery';

  final GameProgressRepository _progress;
  final Stopwatch _clock;
  final Random _random;

  /// The scene's width / height, for measuring taps.
  final double aspect;

  /// How forgiving a tap is (1 = about the letter's size).
  final double tapRadius;

  /// Time on the clock now.
  Duration get elapsed => state.solvedIn ?? _clock.elapsed;

  void start() {
    if (!state.solved) _clock.start();
  }

  /// The hidden letter (not found yet) under scene point [p], if any; the
  /// nearest one when two are in reach.
  int? letterAt(Offset p) {
    int? best;
    var bestD = double.infinity;
    for (final (i, l) in state.letters.indexed) {
      if (l.found) continue;
      final d = sceneDistance(p, l.center, aspect);
      if (d <= l.spot.size * 0.75 * tapRadius && d < bestD) {
        best = i;
        bestD = d;
      }
    }
    return best;
  }

  /// Letter [i] is found.
  Future<void> reveal(int i) async {
    if (state.solved || state.letters[i].found) return;
    final letters = [...state.letters];
    letters[i] = letters[i].copyWith(found: true);
    if (letters.any((l) => !l.found)) {
      emit(
        state.copyWith(letters: letters, last: i, event: MonasteryEvent.found),
      );
      return;
    }
    _clock.stop();
    final run = TimedRecord(time: _clock.elapsed, moves: state.wrongTaps);
    final level = '${letters.length}';
    final best = _progress.bestTime(id, level);
    emit(
      state.copyWith(
        letters: letters,
        solvedIn: run.time,
        newRecord: best == null || run.beats(best),
        last: i,
        event: MonasteryEvent.solved,
      ),
    );
    await _progress.saveTime(id, level, run);
  }

  /// A tap found nothing.
  void miss() {
    if (state.solved) return;
    emit(
      state.copyWith(
        wrongTaps: state.wrongTaps + 1,
        event: MonasteryEvent.wrong,
      ),
    );
  }

  /// Points near a random letter not found yet.
  void hint() {
    if (state.solved) return;
    final left = [
      for (final (i, l) in state.letters.indexed)
        if (!l.found) i,
    ];
    if (left.isEmpty) return;
    emit(
      state.copyWith(
        hints: state.hints + 1,
        last: left[_random.nextInt(left.length)],
        event: MonasteryEvent.hint,
      ),
    );
  }

  @override
  Future<void> close() {
    _clock.stop();
    return super.close();
  }
}
