import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/asset_paths.dart';
import '../../../../core/domain/character_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../engines/characters/domain/character_action.dart';
import '../../../../engines/characters/domain/character_pose.dart';
import '../domain/snakes_board.dart';

/// Where things sit on a board drawn [side] wide: the squares, and the
/// start strip under the board where tokens wait before square 1.
class BoardGeometry {
  const BoardGeometry(this.board, this.side);

  final SnakesBoard board;
  final double side;

  /// Height of the start strip under the board, in cells.
  static const double startStrip = 0.7;

  double get cell => side / board.columns;
  double get height => side + cell * startStrip;

  Rect cellRect(int square) {
    final (row, col) = board.cellOf(square);
    return Rect.fromLTWH(col * cell, (board.rows - 1 - row) * cell, cell, cell);
  }

  /// Centre of [square]; 0 is the start spot (under square 1).
  Offset center(int square) => square <= 0
      ? Offset(cell * 0.5, side + cell * startStrip / 2)
      : cellRect(square).center;
}

/// The board with both tokens. Tokens glide to their square in
/// [moveDuration] (a hop, or a whole ladder / snake).
class SnakesBoardView extends StatelessWidget {
  const SnakesBoardView({
    super.key,
    required this.board,
    required this.side,
    required this.tokens,
    required this.positions,
    required this.current,
    required this.moveDuration,
  });

  final SnakesBoard board;
  final double side;

  /// Each player's brother, and their token colour.
  final List<(CharacterId, Color)> tokens;
  final List<int> positions;
  final int current;
  final Duration moveDuration;

  @override
  Widget build(BuildContext context) {
    final g = BoardGeometry(board, side);
    final tokenSize = g.cell * 0.78;
    final shared = positions[0] == positions[1];
    return SizedBox(
      width: side,
      height: g.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: side,
            height: side,
            child: CustomPaint(painter: _BoardPainter(board)),
          ),
          // Ladders under the snakes, both cut to the board.
          Positioned(
            left: 0,
            top: 0,
            width: side,
            height: side,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(g.cell * 0.18),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final MapEntry(key: from, value: to)
                      in board.ladders.entries)
                    _BoardPiece.ladder(g, from, to),
                  for (final (i, MapEntry(key: head, value: tail))
                      in board.snakes.entries.indexed)
                    _BoardPiece.snake(g, head, tail, i),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: side,
            width: side,
            height: g.height - side,
            child: const _StartStrip(),
          ),
          // The player whose turn it is goes on top.
          for (final i in [1 - current, current])
            _token(g, i, tokenSize, shared),
        ],
      ),
    );
  }

  Widget _token(BoardGeometry g, int i, double size, bool shared) {
    final (character, color) = tokens[i];
    // Two tokens on one square stand side by side, a bit smaller.
    final s = shared ? size * 0.72 : size;
    final c =
        g.center(positions[i]) +
        (shared ? Offset((i == 0 ? -1 : 1) * g.cell * 0.2, 0) : Offset.zero);
    return AnimatedPositioned(
      key: ValueKey('token$i'),
      duration: moveDuration,
      curve: Curves.easeInOut,
      left: c.dx - s / 2,
      top: c.dy - s / 2,
      width: s,
      height: s,
      child: IgnorePointer(
        child: CharacterToken(
          character: character,
          color: color,
          active: i == current,
        ),
      ),
    );
  }
}

/// A round token with the brother's face, ringed in the player's colour.
class CharacterToken extends StatelessWidget {
  const CharacterToken({
    super.key,
    required this.character,
    required this.color,
    this.active = false,
  });

  final CharacterId character;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final d = c.biggest.shortestSide;
        final pose = context.read<CharacterRoster>().pose(
          character,
          CharacterAction.idle,
        );
        return AnimatedScale(
          scale: active ? 1.08 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cream,
              border: Border.all(color: color, width: max(2, d * 0.09)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: d * 0.12,
                  offset: Offset(0, d * 0.06),
                ),
              ],
            ),
            // The head fills the top ~30% of the pose, about its full
            // width: show the pose about as wide as the token, from the top.
            child: ClipOval(
              child: OverflowBox(
                maxWidth: d,
                maxHeight: d * 3,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: d * 0.1),
                  child: Image.asset(
                    pose?.asset ??
                        AssetPaths.characterPose(character.name, 'idle'),
                    width: d * 0.92,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A ladder or snake picture lying between two squares: rotated to point
/// from [from] to [to] and stretched to reach both.
class _BoardPiece extends StatelessWidget {
  const _BoardPiece({
    required this.image,
    required this.from,
    required this.to,
    required this.width,
    required this.pastFrom,
    required this.pastTo,
    this.flip = false,
  });

  /// From the ladder's bottom square to its top one.
  factory _BoardPiece.ladder(BoardGeometry g, int from, int to) => _BoardPiece(
    image: AssetPaths.snakesLadder,
    from: g.center(from),
    to: g.center(to),
    width: g.cell * 0.62,
    pastFrom: g.cell * 0.3,
    pastTo: g.cell * 0.3,
  );

  /// From the snake's tail square to its head (the picture's head is at
  /// its top, so it ends a little past the head square's centre). Every
  /// other snake is mirrored, so they don't all wiggle the same way.
  factory _BoardPiece.snake(BoardGeometry g, int head, int tail, int i) {
    final length = (g.center(head) - g.center(tail)).distance;
    return _BoardPiece(
      image: AssetPaths.snake(i),
      from: g.center(tail),
      to: g.center(head),
      width: min(g.cell * 1.05, length * 0.55),
      pastFrom: g.cell * 0.1,
      pastTo: g.cell * 0.35,
      flip: i.isOdd,
    );
  }

  final String image;
  final Offset from;
  final Offset to;
  final double width;

  /// How far the picture reaches past each square's centre.
  final double pastFrom;
  final double pastTo;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final d = to - from;
    final u = d / d.distance;
    final start = from - u * pastFrom, end = to + u * pastTo;
    final length = (end - start).distance;
    final center = (start + end) / 2;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - length / 2,
      width: width,
      height: length,
      child: IgnorePointer(
        // The picture points up; turn it to point along from -> to.
        child: Transform.rotate(
          angle: atan2(d.dx, -d.dy),
          child: Transform.flip(
            flipX: flip,
            child: Image.asset(image, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
}

/// Sand strip under the board where tokens wait to start.
class _StartStrip extends StatelessWidget {
  const _StartStrip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pyramidDuneDark.withValues(alpha: 0.55),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
    );
  }
}

/// The painted squares with their numbers (the ladders and snakes are
/// pictures laid on top, see [_BoardPiece]).
class _BoardPainter extends CustomPainter {
  _BoardPainter(this.board);

  final SnakesBoard board;

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(board, size.width);
    final cell = g.cell;
    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cell * 0.18),
    );
    canvas
      ..save()
      ..clipRRect(frame);

    for (var sq = 1; sq <= board.squares; sq++) {
      final r = g.cellRect(sq);
      final (row, col) = board.cellOf(sq);
      final light = (row + col).isEven;
      final color = sq == board.squares
          ? AppColors.snakesFinish
          : light
          ? AppColors.snakesTileLight
          : AppColors.snakesTileDark;
      canvas.drawRect(r, Paint()..color = color);
      final number = TextPainter(
        text: TextSpan(
          text: '$sq',
          style: AppTextStyles.of(AppScript.english, AppTextVariant.h3)
              .copyWith(
                fontSize: cell * (sq == board.squares ? 0.34 : 0.24),
                height: 1,
                color: AppColors.snakesTileNumber,
              ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = sq == board.squares
          ? r.center - Offset(number.width / 2, number.height / 2)
          : r.topLeft + Offset(cell * 0.08, cell * 0.06);
      number.paint(canvas, at);
    }

    canvas.restore();
    canvas.drawRRect(
      frame,
      Paint()
        ..color = AppColors.snakesBoardFrame
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3, cell * 0.08),
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) => old.board != board;
}
