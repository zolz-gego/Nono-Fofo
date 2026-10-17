import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// A big dice. While [rolling] it tumbles through random faces, then
/// shows [value]. When [enabled] it bounces gently to ask for a tap.
class SnakesDice extends StatefulWidget {
  const SnakesDice({
    super.key,
    required this.size,
    required this.value,
    required this.rolling,
    required this.enabled,
    required this.onTap,
    this.color = AppColors.diceFace,
  });

  final double size;
  final int? value;
  final bool rolling;
  final bool enabled;
  final VoidCallback onTap;

  /// Face colour (the player's colour while it's their roll).
  final Color color;

  @override
  State<SnakesDice> createState() => _SnakesDiceState();
}

class _SnakesDiceState extends State<SnakesDice> {
  final Random _random = Random();
  Timer? _tumble;
  int _face = 5;
  double _turn = 0;

  @override
  void initState() {
    super.initState();
    if (widget.rolling) _startTumble();
  }

  @override
  void didUpdateWidget(SnakesDice old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !old.rolling) _startTumble();
    if (!widget.rolling && old.rolling) _stopTumble();
  }

  void _startTumble() {
    _tumble?.cancel();
    _tumble = Timer.periodic(const Duration(milliseconds: 90), (_) {
      setState(() {
        _face = _random.nextInt(6) + 1;
        _turn += 0.35 + _random.nextDouble() * 0.3;
      });
    });
  }

  void _stopTumble() {
    _tumble?.cancel();
    _tumble = null;
    setState(() => _turn = _turn.roundToDouble());
  }

  @override
  void dispose() {
    _tumble?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = widget.rolling ? _face : (widget.value ?? _face);
    Widget dice = AnimatedRotation(
      turns: _turn / 4,
      duration: const Duration(milliseconds: 90),
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _DicePainter(face, widget.color),
      ),
    );
    if (widget.enabled) {
      dice = dice
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 500.ms,
            curve: Curves.easeInOut,
          );
    }
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          value: '$face',
          child: SizedBox.square(dimension: widget.size, child: dice),
        ),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  _DicePainter(this.face, this.color);

  final int face;
  final Color color;

  static const Map<int, List<(double, double)>> _pips = {
    1: [(0.5, 0.5)],
    2: [(0.27, 0.27), (0.73, 0.73)],
    3: [(0.27, 0.27), (0.5, 0.5), (0.73, 0.73)],
    4: [(0.27, 0.27), (0.73, 0.27), (0.27, 0.73), (0.73, 0.73)],
    5: [(0.27, 0.27), (0.73, 0.27), (0.5, 0.5), (0.27, 0.73), (0.73, 0.73)],
    6: [
      (0.27, 0.25),
      (0.73, 0.25),
      (0.27, 0.5),
      (0.73, 0.5),
      (0.27, 0.75),
      (0.73, 0.75),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.04, s * 0.04, s * 0.92, s * 0.92),
      Radius.circular(s * 0.2),
    );
    canvas
      ..drawRRect(
        r.shift(Offset(0, s * 0.05)),
        Paint()..color = AppColors.shadow,
      )
      ..drawRRect(r, Paint()..color = color)
      ..drawRRect(
        r,
        Paint()
          ..color = AppColors.cocoa
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, s * 0.04),
      );
    final pip = Paint()..color = AppColors.dicePip;
    for (final (x, y) in _pips[face.clamp(1, 6)]!) {
      canvas.drawCircle(Offset(x * s, y * s), s * 0.085, pip);
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) =>
      old.face != face || old.color != color;
}
