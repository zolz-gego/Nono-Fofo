import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../domain/letter_mask.dart';
import '../domain/letter_strokes.dart';
import '../domain/writing_board.dart';
import 'writing_cubit.dart';

/// One chalk line the child drew.
class ChalkStroke {
  ChalkStroke(this.color, this.radius, Offset start) : points = [start];

  final Color color;
  final double radius;
  final List<Offset> points;
}

/// Holds the chalk on the board (so the page can wipe it or take a
/// picture of it).
class ChalkboardController extends ChangeNotifier {
  final List<ChalkStroke> _done = [];
  ChalkStroke? _current;
  ui.Picture? _cache;

  /// Wraps the board surface, letter and chalk (not the guides): what
  /// [capturePng] takes a picture of.
  final GlobalKey boundaryKey = GlobalKey();

  bool get isDrawing => _current != null;
  bool get isEmpty => _done.isEmpty && _current == null;

  void begin(Offset p, Color color, double radius) {
    end();
    _current = ChalkStroke(color, radius, p);
    notifyListeners();
  }

  void extend(Offset p) {
    final c = _current;
    if (c == null) return;
    c.points.add(p);
    notifyListeners();
  }

  void end() {
    final c = _current;
    if (c == null) return;
    _current = null;
    _done.add(c);
    _rebuildCache();
    notifyListeners();
  }

  void clear() {
    _current = null;
    _done.clear();
    _cache?.dispose();
    _cache = null;
    notifyListeners();
  }

  void _rebuildCache() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final s in _done) {
      paintStroke(canvas, s);
    }
    _cache?.dispose();
    _cache = recorder.endRecording();
  }

  /// A PNG of the board as it looks now ([pixelRatio] of the board's
  /// 800-unit width), or null if it isn't on screen.
  Future<Uint8List?> capturePng({double pixelRatio = 0.35}) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  static void paintStroke(Canvas canvas, ChalkStroke s) {
    final paint = Paint()
      ..color = s.color
      ..isAntiAlias = true;
    final pts = s.points;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, s.radius, paint);
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = Offset.lerp(pts[i], pts[i + 1], 0.5)!;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.radius * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  void dispose() {
    _cache?.dispose();
    super.dispose();
  }
}

/// The green chalkboard: its wooden frame, the big dotted hollow letter,
/// the numbered start dots, the stroke-order demo, the child's chalk and
/// the other brother's sponge. Laid out at its own fixed size
/// ([designSize]); wrap it in a `FittedBox`.
class Chalkboard extends StatefulWidget {
  const Chalkboard({
    super.key,
    required this.controller,
    required this.mask,
    required this.strokes,
    required this.phase,
    required this.chalkColor,
    required this.chalkRadius,
    required this.demoStrokeSeconds,
    required this.onChalk,
    required this.onDrawing,
    required this.onDemoDone,
    required this.onWipeDone,
    this.onDemoStroke,
    this.art,
  });

  /// Frame thickness around the 800 x 520 surface.
  static const double frame = 30;
  static const Size designSize = Size(
    WritingBoard.width + frame * 2,
    WritingBoard.height + frame * 2,
  );

  final ChalkboardController controller;
  final LetterMask? mask;
  final LetterStrokes strokes;
  final WritingPhase phase;
  final Color chalkColor;
  final double chalkRadius;
  final double demoStrokeSeconds;
  final void Function(Offset a, Offset b, double radius) onChalk;

  /// True while the child's finger is on the board.
  final ValueChanged<bool> onDrawing;
  final VoidCallback onDemoDone;
  final VoidCallback onWipeDone;

  /// Each time the demo starts a new stroke.
  final VoidCallback? onDemoStroke;

  /// Painted board (frame included); drawn in code when null.
  final ImageProvider? art;

  @override
  State<Chalkboard> createState() => _ChalkboardState();
}

class _ChalkboardState extends State<Chalkboard> with TickerProviderStateMixin {
  late final AnimationController _demo = AnimationController(vsync: this)
    ..addListener(_onDemoTick)
    ..addStatusListener(_onDemoStatus);
  late final AnimationController _wipe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..addStatusListener(_onWipeStatus);

  _LetterArt? _art;
  int _demoStroke = -1;
  bool _showDemo = false;
  int? _pointer;
  Offset? _last;

  ChalkboardController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _prepare();
    if (widget.phase == WritingPhase.demo) _startDemo();
  }

  @override
  void didUpdateWidget(Chalkboard old) {
    super.didUpdateWidget(old);
    if (old.mask != widget.mask || old.strokes != widget.strokes) _prepare();
    if (widget.phase != old.phase) {
      if (!_canDraw) _stopDrawing();
      if (widget.phase == WritingPhase.demo) _startDemo();
      if (_isWipe(widget.phase) && !_isWipe(old.phase)) {
        _wipe.forward(from: 0);
      }
    }
  }

  static bool _isWipe(WritingPhase p) =>
      p == WritingPhase.wiping || p == WritingPhase.failed;

  bool get _canDraw => widget.phase == WritingPhase.drawing;

  void _prepare() {
    final mask = widget.mask;
    _art = mask == null ? null : _LetterArt(mask, widget.strokes);
  }

  // ---------------------------------------------------------------------------
  // Demo
  // ---------------------------------------------------------------------------

  void _startDemo() {
    final n = widget.strokes.strokes.length;
    if (n == 0 || widget.mask == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDemoDone());
      return;
    }
    _demoStroke = -1;
    _showDemo = true;
    _demo
      ..duration = Duration(
        milliseconds: (widget.demoStrokeSeconds * 1000 * n).round(),
      )
      ..forward(from: 0);
  }

  void _onDemoTick() {
    final n = widget.strokes.strokes.length;
    final i = math.min(n - 1, (_demo.value * n).floor());
    if (i != _demoStroke) {
      _demoStroke = i;
      widget.onDemoStroke?.call();
    }
  }

  void _onDemoStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _finishDemo();
  }

  void _finishDemo() {
    _demo.stop();
    widget.onDemoDone();
    // Let the demo chalk fade away.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showDemo = false);
    });
  }

  // ---------------------------------------------------------------------------
  // Wipe
  // ---------------------------------------------------------------------------

  void _onWipeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _c.clear();
    widget.onWipeDone();
  }

  // ---------------------------------------------------------------------------
  // Drawing
  // ---------------------------------------------------------------------------

  static Offset _clamp(Offset p) => Offset(
    p.dx.clamp(0, WritingBoard.width),
    p.dy.clamp(0, WritingBoard.height),
  );

  void _down(PointerDownEvent e) {
    if (widget.phase == WritingPhase.demo && _demo.isAnimating) {
      _finishDemo();
      return;
    }
    if (!_canDraw || _pointer != null) return;
    final p = _clamp(e.localPosition);
    _pointer = e.pointer;
    _last = p;
    _c.begin(p, widget.chalkColor, widget.chalkRadius);
    widget.onChalk(p, p, widget.chalkRadius);
    widget.onDrawing(true);
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || !_canDraw) return;
    final p = _clamp(e.localPosition);
    final last = _last!;
    if ((p - last).distance < 2) return;
    _c.extend(p);
    _last = p;
    widget.onChalk(last, p, widget.chalkRadius);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _stopDrawing();
  }

  void _stopDrawing() {
    if (_pointer == null) return;
    _pointer = null;
    _last = null;
    _c.end();
    widget.onDrawing(false);
  }

  @override
  void dispose() {
    _demo.dispose();
    _wipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = _art;
    final passed =
        widget.phase == WritingPhase.boardPassed ||
        widget.phase == WritingPhase.passed;
    final surface = SizedBox.fromSize(
      size: WritingBoard.size,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: Stack(
          children: [
            RepaintBoundary(
              key: _c.boundaryKey,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _SurfacePainter()),
                  ),
                  if (art != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LetterPainter(art, passed: passed),
                      ),
                    ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _wipe,
                      builder: (context, _) => CustomPaint(
                        painter: _ChalkPainter(
                          _c,
                          opacity: _wipe.isAnimating ? 1 - _wipe.value : 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (art != null && !passed)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _GuidePainter(art)),
                ),
              ),
            if (art != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showDemo ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedBuilder(
                      animation: _demo,
                      builder: (context, _) =>
                          CustomPaint(painter: _DemoPainter(art, _demo.value)),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _wipe,
                  builder: (context, _) => _wipe.isAnimating
                      ? CustomPaint(painter: _SpongePainter(_wipe.value))
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox.fromSize(
      size: Chalkboard.designSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.art == null
                ? const CustomPaint(painter: _FramePainter())
                : Image(image: widget.art!, fit: BoxFit.fill),
          ),
          Positioned(
            left: Chalkboard.frame,
            top: Chalkboard.frame,
            child: ClipRect(child: surface),
          ),
        ],
      ),
    );
  }
}

/// What gets drawn for one letter, worked out once per board.
class _LetterArt {
  _LetterArt(LetterMask mask, LetterStrokes strokes)
    : strokes = [
        for (final s in strokes.strokes)
          [for (final p in s) mask.inkPoint(p.dx, p.dy)],
      ] {
    final loops = mask.outline();
    hollow = Path()..fillType = PathFillType.evenOdd;
    final dots = <double>[];
    for (final loop in loops) {
      hollow.addPolygon(loop, true);
      var carry = 0.0;
      for (var i = 0; i < loop.length; i++) {
        final a = loop[i], b = loop[(i + 1) % loop.length];
        final d = (b - a).distance;
        var t = _dotGap - carry;
        while (t <= d) {
          final p = Offset.lerp(a, b, t / d)!;
          dots
            ..add(p.dx)
            ..add(p.dy);
          t += _dotGap;
        }
        carry = d - (t - _dotGap);
      }
    }
    this.dots = Float32List.fromList(dots);
  }

  static const double _dotGap = 12;

  late final Path hollow;
  late final Float32List dots;

  /// Stroke order in board units.
  final List<List<Offset>> strokes;
}

class _SurfacePainter extends CustomPainter {
  const _SurfacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 1.1,
          colors: [AppColors.board, AppColors.boardDark],
        ).createShader(rect),
    );
    // Old chalk smudges.
    final smudge = Paint()..color = AppColors.boardSmudge;
    final r = math.Random(3);
    for (var i = 0; i < 7; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            r.nextDouble() * size.width,
            r.nextDouble() * size.height,
          ),
          width: 120 + r.nextDouble() * 160,
          height: 30 + r.nextDouble() * 40,
        ),
        smudge,
      );
    }
  }

  @override
  bool shouldRepaint(_SurfacePainter old) => false;
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const f = Chalkboard.frame;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(
      outer.shift(const Offset(0, 8)),
      Paint()..color = AppColors.shadow,
    );
    canvas.drawRRect(outer, Paint()..color = AppColors.boardFrame);
    canvas.drawRRect(
      outer.deflate(6),
      Paint()
        ..color = AppColors.boardFrameLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    // Wood grain.
    final grain = Paint()
      ..color = AppColors.boardFrameDark.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (var y = 8.0; y < f - 4; y += 7) {
      canvas
        ..drawLine(Offset(24, y), Offset(size.width - 24, y), grain)
        ..drawLine(
          Offset(24, size.height - y),
          Offset(size.width - 24, size.height - y),
          grain,
        );
    }
    // Corner pegs.
    final peg = Paint()..color = AppColors.boardFrameDark;
    for (final c in [
      const Offset(f / 2, f / 2),
      Offset(size.width - f / 2, f / 2),
      Offset(f / 2, size.height - f / 2),
      Offset(size.width - f / 2, size.height - f / 2),
    ]) {
      canvas.drawCircle(c, 6, peg);
    }
    canvas.drawRect(
      Rect.fromLTWH(
        f - 3,
        f - 3,
        size.width - f * 2 + 6,
        size.height - f * 2 + 6,
      ),
      Paint()..color = AppColors.boardFrameDark,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}

class _LetterPainter extends CustomPainter {
  _LetterPainter(this.art, {required this.passed});

  final _LetterArt art;
  final bool passed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(art.hollow, Paint()..color = AppColors.letterHollow);
    canvas.drawRawPoints(
      ui.PointMode.points,
      art.dots,
      Paint()
        ..color = passed ? AppColors.passGlow : AppColors.letterDots
        ..strokeWidth = passed ? 7 : 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LetterPainter old) =>
      old.art != art || old.passed != passed;
}

/// The child's chalk, with a grainy chalk texture.
class _ChalkPainter extends CustomPainter {
  _ChalkPainter(this.c, {required this.opacity}) : super(repaint: c);

  final ChalkboardController c;
  final double opacity;

  static final Float32List _grain = () {
    final r = math.Random(7);
    return Float32List.fromList([
      for (var i = 0; i < 9000; i++) ...[
        r.nextDouble() * WritingBoard.width,
        r.nextDouble() * WritingBoard.height,
      ],
    ]);
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (c.isEmpty || opacity <= 0) return;
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0, 1)),
    );
    final cache = c._cache;
    if (cache != null) canvas.drawPicture(cache);
    final current = c._current;
    if (current != null) ChalkboardController.paintStroke(canvas, current);
    // Punch tiny holes so it looks like chalk, not paint.
    canvas.drawRawPoints(
      ui.PointMode.points,
      _grain,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = const Color(0x8C000000)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChalkPainter old) => old.opacity != opacity;
}

/// Numbered start dot and a small arrow for every stroke.
class _GuidePainter extends CustomPainter {
  _GuidePainter(this.art);

  final _LetterArt art;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppColors.guide.withValues(alpha: 0.92);
    final arrow = Paint()
      ..color = AppColors.guide.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final (i, s) in art.strokes.indexed) {
      if (s.isEmpty) continue;
      final start = s.first;
      // Arrow: a short way along the stroke, pointing the way to go.
      final a = _along(s, 26), b = _along(s, 58);
      if ((b - a).distance > 4) {
        final dir = (b - a) / (b - a).distance;
        final side = Offset(-dir.dy, dir.dx);
        canvas
          ..drawLine(a, b, arrow)
          ..drawPath(
            Path()
              ..moveTo(
                b.dx - dir.dx * 10 + side.dx * 8,
                b.dy - dir.dy * 10 + side.dy * 8,
              )
              ..lineTo(b.dx, b.dy)
              ..lineTo(
                b.dx - dir.dx * 10 - side.dx * 8,
                b.dy - dir.dy * 10 - side.dy * 8,
              ),
            arrow,
          );
      }
      canvas.drawCircle(start, 15, dot);
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontFamily: AppFonts.english,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.guideText,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        start - Offset(label.width / 2, label.height / 2 - 1),
      );
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.art != art;
}

/// The point [distance] units along polyline [s].
Offset _along(List<Offset> s, double distance) {
  var left = distance;
  for (var i = 0; i < s.length - 1; i++) {
    final d = (s[i + 1] - s[i]).distance;
    if (left <= d) return Offset.lerp(s[i], s[i + 1], d == 0 ? 0 : left / d)!;
    left -= d;
  }
  return s.last;
}

double _length(List<Offset> s) {
  var total = 0.0;
  for (var i = 0; i < s.length - 1; i++) {
    total += (s[i + 1] - s[i]).distance;
  }
  return total;
}

/// Chalk drawing the letter stroke by stroke ([t] 0..1 over all strokes).
class _DemoPainter extends CustomPainter {
  _DemoPainter(this.art, this.t);

  final _LetterArt art;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final n = art.strokes.length;
    if (n == 0 || t <= 0) return;
    final chalk = Paint()
      ..color = AppColors.demoChalk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final progress = t * n;
    Offset? tip;
    for (var i = 0; i < n; i++) {
      final s = art.strokes[i];
      if (s.isEmpty || i > progress) break;
      final part = (progress - i).clamp(0.0, 1.0);
      final upTo = _length(s) * Curves.easeInOut.transform(part);
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      var walked = 0.0;
      for (var j = 0; j < s.length - 1; j++) {
        final d = (s[j + 1] - s[j]).distance;
        if (walked + d >= upTo) {
          final p = Offset.lerp(
            s[j],
            s[j + 1],
            d == 0 ? 0 : (upTo - walked) / d,
          )!;
          path.lineTo(p.dx, p.dy);
          tip = p;
          break;
        }
        path.lineTo(s[j + 1].dx, s[j + 1].dy);
        walked += d;
        tip = s[j + 1];
      }
      canvas.drawPath(path, chalk);
    }
    if (tip != null && t < 1) {
      canvas.drawCircle(tip, 11, Paint()..color = AppColors.white);
    }
  }

  @override
  bool shouldRepaint(_DemoPainter old) => old.t != t || old.art != art;
}

/// A yellow sponge sweeping the board in three rows ([t] 0..1).
class _SpongePainter extends CustomPainter {
  _SpongePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 3;
    final row = math.min(rows - 1, (t * rows).floor());
    final local = t * rows - row;
    final leftToRight = row.isEven;
    final x = ui.lerpDouble(
      -80,
      size.width + 80,
      leftToRight ? local : 1 - local,
    )!;
    final y =
        size.height * (row + 1) / (rows + 1) +
        math.sin(local * math.pi * 6) * 14;
    canvas
      ..save()
      ..translate(x, y)
      ..rotate(math.sin(local * math.pi * 6) * 0.12);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 150, height: 86),
      const Radius.circular(22),
    );
    canvas
      ..drawRRect(
        body.shift(const Offset(0, 6)),
        Paint()..color = AppColors.shadow,
      )
      ..drawRRect(body, Paint()..color = AppColors.sponge);
    final hole = Paint()..color = AppColors.spongeHoles;
    final r = math.Random(5);
    for (var i = 0; i < 14; i++) {
      canvas.drawCircle(
        Offset(-60 + r.nextDouble() * 120, -30 + r.nextDouble() * 60),
        3 + r.nextDouble() * 5,
        hole,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpongePainter old) => old.t != t;
}
