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

/// The painted board (until a drawn one is added): sandy squares with
/// their numbers, wooden ladders and friendly cartoon snakes.
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

    board.ladders.forEach((from, to) {
      _ladder(canvas, g.center(from), g.center(to), cell);
    });
    var i = 0;
    board.snakes.forEach((head, tail) {
      _snake(
        canvas,
        g.center(head),
        g.center(tail),
        cell,
        AppColors.snakes[i++ % AppColors.snakes.length],
      );
    });
    canvas.restore();
    canvas.drawRRect(
      frame,
      Paint()
        ..color = AppColors.snakesBoardFrame
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3, cell * 0.08),
    );
  }

  void _ladder(Canvas canvas, Offset a, Offset b, double cell) {
    final dir = b - a;
    final len = dir.distance;
    final u = dir / len;
    final n = Offset(-u.dy, u.dx) * (cell * 0.2);
    // Rails run a little past both squares' centres.
    final start = a - u * cell * 0.25, end = b + u * cell * 0.25;
    final shadow = Paint()
      ..color = AppColors.shadow
      ..strokeWidth = cell * 0.11
      ..strokeCap = StrokeCap.round;
    final rail = Paint()
      ..color = AppColors.ladderRail
      ..strokeWidth = cell * 0.09
      ..strokeCap = StrokeCap.round;
    final railEdge = Paint()
      ..color = AppColors.ladderRailDark
      ..strokeWidth = cell * 0.13
      ..strokeCap = StrokeCap.round;
    final rung = Paint()
      ..color = AppColors.ladderRung
      ..strokeWidth = cell * 0.07
      ..strokeCap = StrokeCap.round;
    const lift = Offset(3, 4);
    for (final side in [n, -n]) {
      canvas.drawLine(start + side + lift, end + side + lift, shadow);
    }
    final total = (end - start).distance;
    final rungs = max(2, (total / (cell * 0.38)).floor());
    for (var k = 1; k < rungs; k++) {
      final p = start + u * (total * k / rungs);
      canvas
        ..drawLine(p + n, p - n, railEdge..strokeWidth = cell * 0.09)
        ..drawLine(p + n, p - n, rung);
    }
    for (final side in [n, -n]) {
      canvas
        ..drawLine(
          start + side,
          end + side,
          railEdge..strokeWidth = cell * 0.13,
        )
        ..drawLine(start + side, end + side, rail);
    }
  }

  void _snake(
    Canvas canvas,
    Offset head,
    Offset tail,
    double cell,
    (Color, Color) colors,
  ) {
    final (body, belly) = colors;
    final dir = tail - head;
    final len = dir.distance;
    final u = dir / len;
    final n = Offset(-u.dy, u.dx);
    final waves = max(1.0, (len / (cell * 2.2)).roundToDouble());
    final amp = cell * 0.32;
    Offset at(double t) {
      // Wiggles calm down near the head and the tail.
      final calm = sin(pi * t);
      return head + dir * t + n * (sin(t * pi * 2 * waves) * amp * calm);
    }

    final samples = max(24, (len / (cell * 0.08)).round());
    final points = [for (var k = 0; k <= samples; k++) at(k / samples)];
    final thick = cell * 0.3;
    double radius(double t) => thick / 2 * (1 - 0.75 * t);

    final shadow = Paint()..color = AppColors.shadow;
    final outline = Paint()..color = AppColors.cocoa.withValues(alpha: 0.6);
    final fill = Paint()..color = body;
    final spots = Paint()..color = belly;
    for (final (k, p) in points.indexed) {
      final t = k / samples;
      canvas.drawCircle(p + const Offset(3, 4), radius(t), shadow);
    }
    for (final (k, p) in points.indexed) {
      final t = k / samples;
      canvas.drawCircle(p, radius(t) + 1.5, outline);
    }
    for (final (k, p) in points.indexed) {
      final t = k / samples;
      canvas.drawCircle(p, radius(t), fill);
    }
    final every = max(1, samples ~/ (waves * 6));
    for (var k = every; k < samples - every; k += every * 2) {
      final t = k / samples;
      canvas.drawCircle(points[k], radius(t) * 0.45, spots);
    }

    // The head: a round face looking away from the body, with a tongue.
    final face = -u;
    final side = Offset(-face.dy, face.dx);
    final hr = thick * 0.75;
    final h = head + face * (hr * 0.2);
    final tongue = Path()
      ..moveTo(h.dx + face.dx * hr * 0.8, h.dy + face.dy * hr * 0.8);
    final tip = h + face * (hr * 1.6);
    tongue
      ..lineTo(tip.dx, tip.dy)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (tip + face * (hr * 0.35) + side * (hr * 0.3)).dx,
        (tip + face * (hr * 0.35) + side * (hr * 0.3)).dy,
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (tip + face * (hr * 0.35) - side * (hr * 0.3)).dx,
        (tip + face * (hr * 0.35) - side * (hr * 0.3)).dy,
      );
    canvas
      ..drawPath(
        tongue,
        Paint()
          ..color = AppColors.snakeTongue
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, cell * 0.035)
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(h + const Offset(3, 4), hr, shadow)
      ..drawCircle(h, hr + 1.5, outline)
      ..drawCircle(h, hr, fill);
    for (final s in [side, -side]) {
      final eye = h + face * (hr * 0.25) + s * (hr * 0.42);
      canvas
        ..drawCircle(eye, hr * 0.3, Paint()..color = AppColors.snakeEye)
        ..drawCircle(
          eye + face * (hr * 0.08),
          hr * 0.15,
          Paint()..color = AppColors.snakePupil,
        );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => old.board != board;
}
