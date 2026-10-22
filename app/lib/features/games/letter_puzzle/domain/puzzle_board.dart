import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../letters/domain/coptic_letter.dart';

/// How a cube looks after a check.
enum SlotMark { none, right, wrong }

/// One word on the table: the empty cubes ([slots], in reading order) and
/// the letter tiles ([tiles], the word's own letters shuffled). A tile is
/// known by its index in [tiles]; a cube holds a tile index or null.
/// Locked cubes were right on a check (or filled by a hint) and can't move.
class PuzzleBoard extends Equatable {
  const PuzzleBoard({
    required this.answer,
    required this.tiles,
    required this.slots,
    required this.locked,
    required this.marks,
  });

  /// A fresh board for [answer]: every cube empty, the tiles shuffled so
  /// they don't already spell the word (when the letters allow it).
  factory PuzzleBoard.start(List<CopticLetter> answer, Random random) {
    final tiles = [...answer];
    for (var i = 0; i < 10; i++) {
      tiles.shuffle(random);
      if (!_sameOrder(tiles, answer)) break;
    }
    return PuzzleBoard(
      answer: answer,
      tiles: tiles,
      slots: List.filled(answer.length, null),
      locked: List.filled(answer.length, false),
      marks: List.filled(answer.length, SlotMark.none),
    );
  }

  final List<CopticLetter> answer;
  final List<CopticLetter> tiles;
  final List<int?> slots;
  final List<bool> locked;
  final List<SlotMark> marks;

  int get length => answer.length;

  /// Every cube has a tile: the child can check.
  bool get full => slots.every((s) => s != null);

  bool get solved => locked.every((l) => l);

  bool get hasWrongMarks => marks.contains(SlotMark.wrong);

  /// The cube tile [tile] sits in, or null when it's in the tray.
  int? slotOf(int tile) {
    final i = slots.indexOf(tile);
    return i < 0 ? null : i;
  }

  bool inTray(int tile) => slotOf(tile) == null;

  /// Tile [tile] goes into cube [slot]. A loose tile already there goes
  /// where [tile] came from (the tray, or the cube it left). Locked cubes
  /// and locked tiles don't move.
  PuzzleBoard place(int tile, int slot) {
    if (locked[slot]) return this;
    final from = slotOf(tile);
    if (from == slot) return this;
    if (from != null && locked[from]) return this;
    final slots = [...this.slots];
    final marks = [...this.marks];
    final there = slots[slot];
    slots[slot] = tile;
    marks[slot] = SlotMark.none;
    if (from != null) {
      slots[from] = there;
      marks[from] = SlotMark.none;
    }
    return _with(slots: slots, marks: marks);
  }

  /// Tile [tile] goes into the first empty cube (null: no room).
  PuzzleBoard? placeNext(int tile) {
    final i = slots.indexOf(null);
    return i < 0 ? null : place(tile, i);
  }

  /// The loose tile in cube [slot] goes back to the tray.
  PuzzleBoard remove(int slot) {
    if (locked[slot] || this.slots[slot] == null) return this;
    final slots = [...this.slots];
    final marks = [...this.marks];
    slots[slot] = null;
    marks[slot] = SlotMark.none;
    return _with(slots: slots, marks: marks);
  }

  /// Checks every cube: right ones turn green and lock, wrong ones red.
  PuzzleBoard check() {
    final marks = [
      for (var i = 0; i < length; i++)
        _rightAt(i) ? SlotMark.right : SlotMark.wrong,
    ];
    return _with(
      marks: marks,
      locked: [for (final m in marks) m == SlotMark.right],
    );
  }

  /// After a check: the red tiles go back to the tray.
  PuzzleBoard clearWrong() {
    final slots = [...this.slots];
    final marks = [...this.marks];
    for (var i = 0; i < length; i++) {
      if (marks[i] == SlotMark.wrong) {
        slots[i] = null;
        marks[i] = SlotMark.none;
      }
    }
    return _with(slots: slots, marks: marks);
  }

  /// A hint: the first unlocked cube gets its right letter and locks. The
  /// tile is the one already there if it fits, else one from the tray, else
  /// one from another cube. Null when every cube is already locked.
  PuzzleBoard? hint() {
    final slot = locked.indexOf(false);
    if (slot < 0) return null;
    final want = answer[slot].id;
    bool fits(int t) => tiles[t].id == want;
    final candidates = [
      for (var t = 0; t < tiles.length; t++)
        if (fits(t) && !_isLockedTile(t)) t,
    ];
    if (candidates.isEmpty) return null;
    final tile = candidates.firstWhere(
      (t) => slotOf(t) == slot,
      orElse: () =>
          candidates.firstWhere(inTray, orElse: () => candidates.first),
    );
    final slots = [...this.slots];
    final marks = [...this.marks];
    final from = slotOf(tile);
    if (from != null && from != slot) {
      slots[from] = null;
      marks[from] = SlotMark.none;
    }
    // A wrong tile in the cube goes back to the tray.
    slots[slot] = tile;
    marks[slot] = SlotMark.right;
    return _with(
      slots: slots,
      marks: marks,
      locked: [...locked]..[slot] = true,
    );
  }

  bool _isLockedTile(int t) {
    final s = slotOf(t);
    return s != null && locked[s];
  }

  bool _rightAt(int i) {
    final t = slots[i];
    return t != null && tiles[t].id == answer[i].id;
  }

  PuzzleBoard _with({
    List<int?>? slots,
    List<bool>? locked,
    List<SlotMark>? marks,
  }) => PuzzleBoard(
    answer: answer,
    tiles: tiles,
    slots: slots ?? this.slots,
    locked: locked ?? this.locked,
    marks: marks ?? this.marks,
  );

  static bool _sameOrder(List<CopticLetter> a, List<CopticLetter> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [answer, tiles, slots, locked, marks];
}
