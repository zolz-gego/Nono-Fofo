import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';

/// How a line looks after a check.
enum LineMark { none, right, wrong }

/// One word on the board: its Coptic [letters] top to bottom (one row each,
/// repeats too), what each sounds like in the word ([answers]), and those
/// sounds shuffled in the second column ([sounds]). A row is linked to a
/// sound by its index in [sounds]. Rows whose answers are the same sound
/// can take either one: a line is right when its sound matches.
/// Locked rows were right on a check (or drawn by a hint) and can't change.
class MatchBoard extends Equatable {
  const MatchBoard({
    required this.letters,
    required this.answers,
    required this.sounds,
    required this.links,
    required this.locked,
    required this.marks,
  });

  /// A fresh board: no lines, the sounds shuffled so they don't already
  /// line up with the letters (when they allow it).
  factory MatchBoard.start(
    List<CopticLetter> letters,
    List<String> answers,
    Random random,
  ) {
    final sounds = [...answers];
    for (var i = 0; i < 10; i++) {
      sounds.shuffle(random);
      if (!_sameOrder(sounds, answers)) break;
    }
    return MatchBoard(
      letters: letters,
      answers: answers,
      sounds: sounds,
      links: List.filled(letters.length, null),
      locked: List.filled(letters.length, false),
      marks: List.filled(letters.length, LineMark.none),
    );
  }

  final List<CopticLetter> letters;
  final List<String> answers;
  final List<String> sounds;

  /// Per row: the sound it's linked to, or null.
  final List<int?> links;
  final List<bool> locked;
  final List<LineMark> marks;

  int get length => letters.length;

  /// Every row has a line: time to check.
  bool get full => links.every((l) => l != null);

  bool get solved => locked.every((l) => l);

  /// Red lines from the last check.
  int get wrongCount => marks.where((m) => m == LineMark.wrong).length;

  /// The row linked to sound [sound], or null.
  int? rowOf(int sound) {
    final i = links.indexOf(sound);
    return i < 0 ? null : i;
  }

  /// Sound [sound] belongs to a locked (green) line.
  bool soundLocked(int sound) {
    final row = rowOf(sound);
    return row != null && locked[row];
  }

  /// A line from row [row] to sound [sound]. Lines the row or the sound
  /// had before go. Locked rows and sounds don't change.
  MatchBoard link(int row, int sound) {
    if (locked[row] || soundLocked(sound) || this.links[row] == sound) {
      return this;
    }
    final links = [...this.links];
    final marks = [...this.marks];
    final other = rowOf(sound);
    if (other != null) {
      links[other] = null;
      marks[other] = LineMark.none;
    }
    links[row] = sound;
    marks[row] = LineMark.none;
    return _with(links: links, marks: marks);
  }

  /// Checks every line: right ones turn green and lock, wrong ones red.
  MatchBoard check() {
    final marks = [
      for (var i = 0; i < length; i++)
        _rightAt(i) ? LineMark.right : LineMark.wrong,
    ];
    return _with(
      marks: marks,
      locked: [for (final m in marks) m == LineMark.right],
    );
  }

  /// After a check: the red lines go.
  MatchBoard clearWrong() {
    final links = [...this.links];
    final marks = [...this.marks];
    for (var i = 0; i < length; i++) {
      if (marks[i] == LineMark.wrong) {
        links[i] = null;
        marks[i] = LineMark.none;
      }
    }
    return _with(links: links, marks: marks);
  }

  /// A hint: the first row without a green line gets a right line and
  /// locks. The sound is the one it already has if that fits, else a free
  /// one, else one taken from another row. Null when every row is locked.
  MatchBoard? hint() {
    final row = locked.indexOf(false);
    if (row < 0) return null;
    final candidates = [
      for (var s = 0; s < sounds.length; s++)
        if (sounds[s] == answers[row] && !soundLocked(s)) s,
    ];
    if (candidates.isEmpty) return null;
    final sound = candidates.firstWhere(
      (s) => links[row] == s,
      orElse: () => candidates.firstWhere(
        (s) => rowOf(s) == null,
        orElse: () => candidates.first,
      ),
    );
    final board = link(row, sound);
    return board._with(
      marks: [...board.marks]..[row] = LineMark.right,
      locked: [...board.locked]..[row] = true,
    );
  }

  bool _rightAt(int i) {
    final s = links[i];
    return s != null && sounds[s] == answers[i];
  }

  MatchBoard _with({
    List<int?>? links,
    List<bool>? locked,
    List<LineMark>? marks,
  }) => MatchBoard(
    letters: letters,
    answers: answers,
    sounds: sounds,
    links: links ?? this.links,
    locked: locked ?? this.locked,
    marks: marks ?? this.marks,
  );

  static bool _sameOrder(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [letters, answers, sounds, links, locked, marks];
}
