import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/assets/asset_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/text/app_texts.dart';

/// One stop on a [GameRoad].
class RoadStop {
  const RoadStop({
    required this.image,
    required this.placeholder,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  /// Name of the illustration in `assets/games/`.
  final String image;

  /// Shown while the illustration file doesn't exist yet.
  final FaIconData placeholder;
  final String title;
  final Color accent;
  final VoidCallback onTap;
}

/// Game cards along a winding road, [perRow] to a row. The first row runs
/// in reading direction (right to left in Arabic), the next one comes back,
/// and so on, like a board-game trail.
class GameRoad extends StatelessWidget {
  const GameRoad({super.key, required this.stops, this.perRow = 3});

  final List<RoadStop> stops;
  final int perRow;

  static const double _minGapX = AppDimens.spaceLg;
  static const double _maxCardWidth = 200;
  static const double _gapY = AppDimens.spaceXl + AppDimens.spaceMd;
  static const double _titleHeight = 64;

  /// Card column of stop [i], counted from the reading start.
  int _column(int i) {
    final row = i ~/ perRow;
    final c = i % perRow;
    return row.isEven ? c : perRow - 1 - c;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final rows = (stops.length + perRow - 1) ~/ perRow;
    return LayoutBuilder(
      builder: (context, c) {
        final cardW = ((c.maxWidth - _minGapX * (perRow - 1)) / perRow).clamp(
          0.0,
          _maxCardWidth,
        );
        // Wide screens: spread the cards so the road shows between them.
        final gapX = (c.maxWidth - cardW * perRow) / (perRow - 1);
        final cardH = cardW + _titleHeight;
        Offset topLeft(int i) {
          final col = _column(i);
          final fromStart = col * (cardW + gapX);
          return Offset(
            rtl ? c.maxWidth - fromStart - cardW : fromStart,
            (i ~/ perRow) * (cardH + _gapY),
          );
        }

        final centers = [
          for (var i = 0; i < stops.length; i++)
            topLeft(i) + Offset(cardW / 2, cardH / 2),
        ];
        return SizedBox(
          height: rows * cardH + (rows - 1) * _gapY,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoadPainter(centers, sideStep: cardW * 0.6),
                ),
              ),
              for (final (i, stop) in stops.indexed)
                Positioned(
                  left: topLeft(i).dx,
                  top: topLeft(i).dy,
                  width: cardW,
                  height: cardH,
                  child: _GameCard(number: i + 1, stop: stop),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A thick sandy road with a dashed middle line through every card center.
/// Turns between rows bulge outwards past the side of the cards.
class _RoadPainter extends CustomPainter {
  _RoadPainter(this.centers, {required this.sideStep});

  final List<Offset> centers;
  final double sideStep;

  static const double _width = 28;
  static const double _dash = 12;
  static const double _dashGap = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final a = centers[i - 1];
      final b = centers[i];
      if ((a.dy - b.dy).abs() < 1) {
        path.lineTo(b.dx, b.dy);
      } else {
        // Row change: swing out to the side the road is already on.
        final out = a.dx > size.width / 2 ? sideStep : -sideStep;
        path.cubicTo(a.dx + out, a.dy, b.dx + out, b.dy, b.dx, b.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.cocoa.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = _width + 8,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.sunYellow.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = _width,
    );
    final dashes = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += _dash + _dashGap) {
        canvas.drawPath(m.extractPath(d, d + _dash), dashes);
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.centers != centers || old.sideStep != sideStep;
}

/// One game: number badge, illustration and name. Grows under the mouse.
class _GameCard extends StatefulWidget {
  const _GameCard({required this.number, required this.stop});

  final int number;
  final RoadStop stop;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _hovered = false;
  bool _pressed = false;

  static const double _hoverScale = 1.06;
  static const double _pressScale = 0.96;
  static const double _badgeSize = 36;

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final scale = _pressed
        ? _pressScale
        : _hovered
        ? _hoverScale
        : 1.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: stop.onTap,
        child: Semantics(
          button: true,
          label: stop.title,
          child: AnimatedScale(
            scale: scale,
            duration: AppDimens.fast,
            curve: Curves.easeOutBack,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: AppDimens.fast,
                    padding: const EdgeInsets.all(AppDimens.spaceXs),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: stop.accent, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: _hovered ? 18 : 6,
                          offset: Offset(0, _hovered ? 8 : 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusSm,
                            ),
                            child: Image.asset(
                              AssetPaths.gameImage(stop.image),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _Placeholder(stop),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: GameRoad._titleHeight - AppDimens.spaceSm,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AppText.h3(
                                stop.title,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: -AppDimens.spaceSm,
                  start: -AppDimens.spaceSm,
                  child: Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: stop.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: AppText.h3('${widget.number}', color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.stop);

  final RoadStop stop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: stop.accent.withValues(alpha: 0.25),
      child: LayoutBuilder(
        builder: (context, c) => Center(
          child: FaIcon(
            stop.placeholder,
            size: c.biggest.shortestSide * 0.45,
            color: stop.accent,
          ),
        ),
      ),
    );
  }
}
