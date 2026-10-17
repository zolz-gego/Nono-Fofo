import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/character_id.dart';
import '../../../letters/domain/coptic_letter.dart';
import '../../../levels/domain/game_level.dart';
import '../../../questions/domain/letter_question.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/snakes_config.dart';

/// Against the computer brother, or a friend on the same device.
enum SnakesMode { computer, friend }

/// One of the two players. The child is always player 0.
class SnakesPlayer extends Equatable {
  const SnakesPlayer({
    required this.character,
    required this.name,
    this.computer = false,
  });

  /// The brother whose token they move.
  final CharacterId character;
  final String name;

  /// Plays by itself and is never asked questions.
  final bool computer;

  @override
  List<Object?> get props => [character, name, computer];
}

enum SnakesPhase {
  /// The current player is answering [SnakesState.question].
  question,

  /// Answered: the right answer glows for a moment (then the dice, or
  /// the turn passes after a wrong one).
  answered,

  /// Waiting for the dice to be tapped (or for the computer).
  roll,

  /// The dice is tumbling.
  rolling,

  /// The token is hopping, climbing or sliding.
  moving,

  /// Someone reached the last square.
  done,
}

/// Something the page reacts to (sounds, the brothers).
enum SnakesEvent {
  none,

  /// A new turn for [SnakesState.current].
  turnStart,
  correct,
  wrong,

  /// The dice stopped on [SnakesState.roll].
  rolled,

  /// The token moved one square.
  hop,

  /// The roll went past the last square: no move.
  overshoot,

  /// Up a ladder.
  climb,

  /// Down a snake.
  slide,
  won,
}

class SnakesState extends Equatable {
  const SnakesState({
    required this.players,
    this.positions = const [0, 0],
    this.current = 0,
    this.phase = SnakesPhase.question,
    this.question,
    this.picked,
    this.roll,
    this.asked = const [0, 0],
    this.correct = const [0, 0],
    this.turns = const [0, 0],
    this.winner,
    this.firstWin = false,
    this.event = SnakesEvent.none,
    this.eventId = 0,
  });

  final List<SnakesPlayer> players;

  /// Each player's square (0 = not on the board yet).
  final List<int> positions;

  /// Whose turn it is.
  final int current;
  final SnakesPhase phase;

  /// The question being asked (null for the computer).
  final LetterQuestion? question;

  /// The answer tapped.
  final int? picked;

  /// The dice's last number.
  final int? roll;

  /// Per player: questions asked, answered right, and dice rolls.
  final List<int> asked;
  final List<int> correct;
  final List<int> turns;

  final int? winner;

  /// The child beat the computer for the first time on this level.
  final bool firstWin;
  final SnakesEvent event;
  final int eventId;

  SnakesPlayer get player => players[current];
  bool get finished => winner != null;

  SnakesState copyWith({
    List<int>? positions,
    int? current,
    SnakesPhase? phase,
    LetterQuestion? Function()? question,
    int? Function()? picked,
    int? roll,
    List<int>? asked,
    List<int>? correct,
    List<int>? turns,
    int? winner,
    bool? firstWin,
    SnakesEvent? event,
  }) => SnakesState(
    players: players,
    positions: positions ?? this.positions,
    current: current ?? this.current,
    phase: phase ?? this.phase,
    question: question == null ? this.question : question(),
    picked: picked == null ? this.picked : picked(),
    roll: roll ?? this.roll,
    asked: asked ?? this.asked,
    correct: correct ?? this.correct,
    turns: turns ?? this.turns,
    winner: winner ?? this.winner,
    firstWin: firstWin ?? this.firstWin,
    event: event ?? this.event,
    eventId: event == null ? eventId : eventId + 1,
  );

  @override
  List<Object?> get props => [
    players,
    positions,
    current,
    phase,
    question,
    picked,
    roll,
    asked,
    correct,
    turns,
    winner,
    firstWin,
    event,
    eventId,
  ];
}

/// Waits a while (swapped for an instant one in tests).
typedef SnakesWait = Future<void> Function(Duration);

/// Runs a game of snakes & ladders: a letter question before every human
/// roll (right = roll, wrong = the turn passes), the computer rolls without
/// questions, tokens hop square by square, ladders up, snakes down, and the
/// first to land exactly on the last square wins.
class SnakesCubit extends Cubit<SnakesState> {
  SnakesCubit(
    this._progress, {
    required this.config,
    required this.level,
    required List<SnakesPlayer> players,
    required this.templates,
    required this.pool,
    Random? random,
    SnakesWait? wait,
  }) : _random = random ?? Random(),
       _wait = wait ?? Future<void>.delayed,
       super(SnakesState(players: players));

  /// Key the wins against the computer are saved under.
  static const String id = 'snakes_ladders';

  /// Key for one level's "beat the computer".
  static String levelKey(GameLevel level) => 'level${level.number}';

  final GameProgressRepository _progress;
  final SnakesConfig config;
  final GameLevel level;

  /// The question recipes for [level], and the letters they ask about.
  final List<LetterQuestionTemplate> templates;
  final List<CopticLetter> pool;
  final Random _random;
  final SnakesWait _wait;

  /// The last letters asked, so the same one doesn't come straight back.
  final List<String> _recent = [];
  static const int _recentCount = 4;

  bool get _vsComputer => state.players.any((p) => p.computer);

  void start() => _beginTurn();

  void _emit(SnakesState s) {
    if (!isClosed) emit(s);
  }

  void _beginTurn() {
    if (state.player.computer) {
      _emit(
        state.copyWith(
          phase: SnakesPhase.roll,
          question: () => null,
          picked: () => null,
          event: SnakesEvent.turnStart,
        ),
      );
      _computerRoll();
      return;
    }
    final q = LetterQuestion.make(
      templates: templates,
      pool: pool,
      random: _random,
      avoid: _recent,
    );
    _recent.add(q.answer.id);
    if (_recent.length > _recentCount) _recent.removeAt(0);
    _emit(
      state.copyWith(
        phase: SnakesPhase.question,
        question: () => q,
        picked: () => null,
        event: SnakesEvent.turnStart,
      ),
    );
  }

  Future<void> _computerRoll() async {
    final turn = state.eventId;
    await _wait(config.computerWait);
    if (isClosed || state.eventId != turn) return;
    await roll();
  }

  /// The current player tapped answer [i].
  Future<void> answer(int i) async {
    final q = state.question;
    if (state.phase != SnakesPhase.question || q == null) return;
    final right = i == q.answerIndex;
    final c = state.current;
    final asked = [...state.asked]..[c] += 1;
    final correct = [...state.correct];
    if (right) correct[c] += 1;
    if (right) {
      _emit(
        state.copyWith(
          phase: SnakesPhase.answered,
          picked: () => i,
          asked: asked,
          correct: correct,
          event: SnakesEvent.correct,
        ),
      );
      await _wait(config.reveal ~/ 2);
      if (!isClosed) _emit(state.copyWith(phase: SnakesPhase.roll));
      return;
    }
    _emit(
      state.copyWith(
        phase: SnakesPhase.answered,
        picked: () => i,
        asked: asked,
        event: SnakesEvent.wrong,
      ),
    );
    await _wait(config.reveal);
    if (!isClosed) _nextTurn();
  }

  /// Rolls the dice and moves the current player's token.
  Future<void> roll() async {
    if (state.phase != SnakesPhase.roll) return;
    final c = state.current;
    final value = _random.nextInt(6) + 1;
    _emit(
      state.copyWith(
        phase: SnakesPhase.rolling,
        roll: value,
        turns: [...state.turns]..[c] += 1,
      ),
    );
    await _wait(config.diceRoll);
    if (isClosed) return;
    _emit(state.copyWith(phase: SnakesPhase.moving, event: SnakesEvent.rolled));

    final board = config.board;
    final plan = board.move(state.positions[c], value);
    if (plan.overshoot) {
      await _wait(config.turnPause);
      if (isClosed) return;
      _emit(state.copyWith(event: SnakesEvent.overshoot));
      await _wait(config.reveal);
      if (!isClosed) _nextTurn();
      return;
    }
    for (final square in plan.steps) {
      _emit(
        state.copyWith(
          positions: [...state.positions]..[c] = square,
          event: SnakesEvent.hop,
        ),
      );
      await _wait(config.hop);
      if (isClosed) return;
    }
    final to = plan.jumpTo;
    if (to != null) {
      await _wait(config.turnPause ~/ 2);
      if (isClosed) return;
      _emit(
        state.copyWith(
          positions: [...state.positions]..[c] = to,
          event: plan.climbed ? SnakesEvent.climb : SnakesEvent.slide,
        ),
      );
      await _wait(config.jump);
      if (isClosed) return;
    }
    if (plan.end == board.squares) return _win(c);
    await _wait(config.turnPause);
    if (!isClosed) _nextTurn();
  }

  Future<void> _win(int c) async {
    var first = false;
    if (_vsComputer && !state.players[c].computer) {
      final key = levelKey(level);
      first = !_progress.hasPassed(id, key);
      if (first) await _progress.savePassed(id, key);
    }
    _emit(
      state.copyWith(
        phase: SnakesPhase.done,
        winner: c,
        firstWin: first,
        event: SnakesEvent.won,
      ),
    );
  }

  void _nextTurn() {
    if (state.finished) return;
    _emit(state.copyWith(current: 1 - state.current));
    _beginTurn();
  }
}
