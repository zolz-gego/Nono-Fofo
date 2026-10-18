import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../letters/domain/coptic_letter.dart';
import '../../../levels/domain/game_level.dart';
import '../../../questions/domain/letter_question.dart';
import '../../progress/domain/game_progress_repository.dart';
import '../domain/adventure_config.dart';

enum AdventurePhase {
  /// Running and jumping.
  playing,

  /// A question is open (the game is frozen).
  question,

  /// The child picked an answer; right / wrong is showing.
  answered,

  /// A won letter shows big for a moment.
  letterShow,

  /// The hero just lost a life.
  dead,
  gameOver,
  complete,
}

/// What a question is for.
enum AskKind { letter, page }

/// One-off moments the page reacts to (sounds, bubbles).
enum AdventureEvent {
  none,
  start,
  coin,
  lifeUp,
  letterWon,
  wrongLetter,
  grew,
  pageWrong,
  pageCoins,
  shrank,
  died,
  checkpoint,
  gateLocked,
  gateOpen,
  complete,
  gameOver,
}

class AdventureState extends Equatable {
  const AdventureState({
    this.level = 0,
    this.lives = 3,
    this.coins = 0,
    this.lifeCoins = 0,
    this.letters = const [],
    this.found = const {},
    this.big = false,
    this.phase = AdventurePhase.playing,
    this.paused = false,
    this.askKind,
    this.question,
    this.picked,
    this.shownLetter,
    this.event = AdventureEvent.none,
    this.eventId = 0,
    this.stars = 0,
    this.time = Duration.zero,
    this.allDone = false,
  });

  /// Index into the config's levels.
  final int level;
  final int lives;

  /// Coins collected in this level.
  final int coins;

  /// Coins toward the next extra life.
  final int lifeCoins;

  /// The letters hidden in this level, one per letter block, in order.
  final List<CopticLetter> letters;

  /// Indexes into [letters] already won.
  final Set<int> found;

  /// Playing as big Nono (else small Fofo).
  final bool big;
  final AdventurePhase phase;
  final bool paused;
  final AskKind? askKind;
  final LetterQuestion? question;
  final int? picked;

  /// The letter showing big after a right answer.
  final CopticLetter? shownLetter;
  final AdventureEvent event;
  final int eventId;

  /// Stars once complete.
  final int stars;

  /// Playing time once complete.
  final Duration time;

  /// This finish completed all levels for the first time.
  final bool allDone;

  int get missing => letters.length - found.length;

  /// The game world moves only while this is true.
  bool get running => phase == AdventurePhase.playing && !paused;

  AdventureState copyWith({
    int? level,
    int? lives,
    int? coins,
    int? lifeCoins,
    List<CopticLetter>? letters,
    Set<int>? found,
    bool? big,
    AdventurePhase? phase,
    bool? paused,
    AskKind? Function()? askKind,
    LetterQuestion? Function()? question,
    int? Function()? picked,
    CopticLetter? Function()? shownLetter,
    AdventureEvent? event,
    int? stars,
    Duration? time,
    bool? allDone,
  }) => AdventureState(
    level: level ?? this.level,
    lives: lives ?? this.lives,
    coins: coins ?? this.coins,
    lifeCoins: lifeCoins ?? this.lifeCoins,
    letters: letters ?? this.letters,
    found: found ?? this.found,
    big: big ?? this.big,
    phase: phase ?? this.phase,
    paused: paused ?? this.paused,
    askKind: askKind != null ? askKind() : this.askKind,
    question: question != null ? question() : this.question,
    picked: picked != null ? picked() : this.picked,
    shownLetter: shownLetter != null ? shownLetter() : this.shownLetter,
    event: event ?? AdventureEvent.none,
    eventId: event == null ? eventId : eventId + 1,
    stars: stars ?? this.stars,
    time: time ?? this.time,
    allDone: allDone ?? this.allDone,
  );

  @override
  List<Object?> get props => [
    level,
    lives,
    coins,
    lifeCoins,
    letters,
    found,
    big,
    phase,
    paused,
    askKind,
    question,
    picked,
    shownLetter,
    event,
    eventId,
    stars,
    time,
    allDone,
  ];
}

typedef AdventureWait = Future<void> Function(Duration d);

/// The rules around the running and jumping: lives, coins, letters,
/// questions and saved stars. The Flame game does the moving and calls in
/// here; the page draws the HUD and pop-ups from the state.
class AdventureCubit extends Cubit<AdventureState> {
  AdventureCubit(
    this._progress, {
    required this.config,
    required this.gameLevel,
    required this.templates,
    required this.pool,
    Random? random,
    AdventureWait? wait,
  }) : _random = random ?? Random(),
       _wait = wait ?? Future<void>.delayed,
       super(AdventureState(lives: config.lives));

  /// Key the stars and the finished challenge are saved under.
  static const String id = 'adventure';

  /// Key for one level's best stars, e.g. `level1.nile`.
  static String starsKey(GameLevel road, String levelId) =>
      'level${road.number}.$levelId';

  /// Key for "every level finished" on a road level.
  static String doneKey(GameLevel road) => 'level${road.number}';

  static const Duration reveal = Duration(milliseconds: 1500);
  static const Duration letterShow = Duration(milliseconds: 1700);

  final GameProgressRepository _progress;
  final AdventureConfig config;

  /// The road level this challenge belongs to (its letters are asked).
  final GameLevel gameLevel;
  final List<LetterQuestionTemplate> templates;
  final List<CopticLetter> pool;
  final Random _random;
  final AdventureWait _wait;

  Completer<bool>? _asking;

  void _emit(AdventureState s) {
    if (!isClosed) emit(s);
  }

  /// Best stars for level [i] (0 = never finished).
  int bestStars(int i) =>
      _progress.bestStars(id, starsKey(gameLevel, config.levels[i].id));

  /// Level [i] is open once the one before it was finished.
  bool unlocked(int i) => i == 0 || bestStars(i - 1) > 0;

  /// Starts level [i] fresh: full lives, small Fofo, new random letters.
  void startLevel(int i) {
    _asking?.complete(false);
    _asking = null;
    final letters = [...pool]..shuffle(_random);
    _emit(
      AdventureState(
        level: i,
        lives: config.lives,
        letters: letters.take(min(config.letters, letters.length)).toList(),
        eventId: state.eventId + 1,
        event: AdventureEvent.start,
      ),
    );
  }

  void addCoins([int n = 1]) {
    var lives = state.lives;
    var toward = state.lifeCoins + n;
    var event = n > 1 ? AdventureEvent.pageCoins : AdventureEvent.coin;
    while (toward >= config.coinsPerLife) {
      toward -= config.coinsPerLife;
      if (lives < config.maxLives) {
        lives++;
        event = AdventureEvent.lifeUp;
      }
    }
    _emit(
      state.copyWith(
        coins: state.coins + n,
        lifeCoins: toward,
        lives: lives,
        event: event,
      ),
    );
  }

  /// Opens a question and completes with true once the child answered
  /// right (and the letter was shown), false otherwise.
  Future<bool> ask(AskKind kind, {int? letterIndex}) {
    _asking?.complete(false);
    final completer = _asking = Completer<bool>();
    final about = letterIndex == null ? null : state.letters[letterIndex];
    _pendingLetter = letterIndex;
    _emit(
      state.copyWith(
        phase: AdventurePhase.question,
        askKind: () => kind,
        question: () => LetterQuestion.make(
          templates: templates,
          pool: pool,
          random: _random,
          about: about,
        ),
        picked: () => null,
      ),
    );
    return completer.future;
  }

  int? _pendingLetter;

  Future<void> answer(int i) async {
    final q = state.question;
    if (q == null || state.phase != AdventurePhase.question) return;
    final right = i == q.answerIndex;
    _emit(state.copyWith(phase: AdventurePhase.answered, picked: () => i));
    await _wait(reveal);
    if (isClosed) return;
    final kind = state.askKind;
    final letter = _pendingLetter;
    if (kind == AskKind.letter && letter != null) {
      if (right) {
        _emit(
          state.copyWith(
            phase: AdventurePhase.letterShow,
            found: {...state.found, letter},
            shownLetter: () => state.letters[letter],
            question: () => null,
            event: AdventureEvent.letterWon,
          ),
        );
        await _wait(letterShow);
        if (isClosed) return;
        _resume(right: true);
      } else {
        final lives = state.lives - 1;
        _emit(
          state.copyWith(
            lives: max(0, lives),
            question: () => null,
            event: AdventureEvent.wrongLetter,
          ),
        );
        if (lives <= 0) {
          _finishAsk(false);
          return _gameOver();
        }
        _resume(right: false);
      }
    } else {
      _emit(
        state.copyWith(
          big: right ? true : null,
          question: () => null,
          event: right ? AdventureEvent.grew : AdventureEvent.pageWrong,
        ),
      );
      _resume(right: right);
    }
  }

  void _resume({required bool right}) {
    _emit(
      state.copyWith(
        phase: AdventurePhase.playing,
        askKind: () => null,
        shownLetter: () => null,
        picked: () => null,
      ),
    );
    _finishAsk(right);
  }

  void _finishAsk(bool right) {
    final c = _asking;
    _asking = null;
    _pendingLetter = null;
    if (c != null && !c.isCompleted) c.complete(right);
  }

  /// Big Nono already: Grandpa's page gives coins instead.
  void pageWhileBig() => addCoins(config.pageCoins);

  /// An enemy hit big Nono: back to Fofo.
  void shrink() =>
      _emit(state.copyWith(big: false, event: AdventureEvent.shrank));

  /// Small Fofo was hit or fell: one life less. The game calls
  /// [afterDeath] once the fall is over.
  void died() => _emit(
    state.copyWith(
      lives: max(0, state.lives - 1),
      big: false,
      phase: AdventurePhase.dead,
      event: AdventureEvent.died,
    ),
  );

  /// Returns true if the hero respawns (lives left), else it's game over.
  bool afterDeath() {
    if (state.lives <= 0) {
      _gameOver();
      return false;
    }
    _emit(state.copyWith(phase: AdventurePhase.playing));
    return true;
  }

  void _gameOver() => _emit(
    state.copyWith(
      phase: AdventurePhase.gameOver,
      event: AdventureEvent.gameOver,
    ),
  );

  void checkpoint() => _emit(state.copyWith(event: AdventureEvent.checkpoint));

  /// The hero reached the gate with letters still missing.
  void gateLocked() => _emit(state.copyWith(event: AdventureEvent.gateLocked));

  void gateOpen() => _emit(state.copyWith(event: AdventureEvent.gateOpen));

  void setPaused(bool paused) => _emit(state.copyWith(paused: paused));

  /// The letters reached Grandpa's book: stars, saved progress.
  Future<void> complete(Duration time, int totalCoins) async {
    if (state.phase == AdventurePhase.complete) return;
    final stars = config.starsFor(state.coins, totalCoins);
    final level = config.levels[state.level];
    final wasDone = _progress.hasPassed(id, doneKey(gameLevel));
    await _progress.saveStars(id, starsKey(gameLevel, level.id), stars);
    final allFinished = [
      for (var i = 0; i < config.levels.length; i++) bestStars(i) > 0,
    ].every((f) => f);
    if (allFinished && !wasDone) {
      await _progress.savePassed(id, doneKey(gameLevel));
    }
    _emit(
      state.copyWith(
        phase: AdventurePhase.complete,
        stars: stars,
        time: time,
        allDone: allFinished && !wasDone,
        event: AdventureEvent.complete,
      ),
    );
  }

  @override
  Future<void> close() {
    _finishAsk(false);
    return super.close();
  }
}
