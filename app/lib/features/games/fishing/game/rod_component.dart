import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../../../core/theme/app_colors.dart';

/// The صنارة: a rod from the hero's hands to its tip, the line, and either a
/// bobber on the water (waiting) or the hook wherever the game puts it.
///
/// When the hero's pose already holds a rod, set [drawRod] to false and keep
/// [restTip] on the pose's rod tip: only the line is drawn.
class RodComponent extends Component {
  RodComponent() : super(priority: 20);

  /// Where the hands hold the rod and where its tip rests.
  ui.Offset hand = ui.Offset.zero;
  ui.Offset restTip = ui.Offset.zero;

  bool drawRod = true;

  /// Hides the line too (the hero put the rod down to cheer).
  bool visible = true;

  /// Extra bend of the rod (radians, + = tip up), animated by the game.
  double bend = 0;

  /// The hook, or null to show the bobber resting on the water.
  ui.Offset? hook;
  ui.Offset bobber = ui.Offset.zero;

  double _time = 0;

  ui.Offset get tip {
    final d = restTip - hand;
    final a = atan2(d.dy, d.dx) - bend;
    final len = d.distance;
    return hand + ui.Offset(cos(a) * len, sin(a) * len);
  }

  @override
  void update(double dt) => _time += dt;

  @override
  void render(ui.Canvas canvas) {
    if (!visible) return;
    final t = drawRod ? tip : restTip;
    final len = (t - hand).distance;

    // Line first, so the rod sits on top of it.
    final line = ui.Paint()
      ..color = AppColors.fishingLine
      ..strokeWidth = 1.6
      ..style = ui.PaintingStyle.stroke;
    final end = hook ?? bobber + ui.Offset(0, sin(_time * 2.4) * 2);
    final sag = hook == null ? 10.0 : 4.0;
    canvas.drawPath(
      ui.Path()
        ..moveTo(t.dx, t.dy)
        ..quadraticBezierTo(
          (t.dx + end.dx) / 2 + sag,
          (t.dy + end.dy) / 2,
          end.dx,
          end.dy,
        ),
      line,
    );

    if (hook == null) {
      final r = max(5.0, len * 0.05);
      canvas.drawCircle(
        end + ui.Offset(0, r * 0.3),
        r,
        ui.Paint()..color = AppColors.bobberBottom,
      );
      canvas.drawArc(
        ui.Rect.fromCircle(center: end + ui.Offset(0, r * 0.3), radius: r),
        pi,
        pi,
        true,
        ui.Paint()..color = AppColors.bobberTop,
      );
      canvas.drawCircle(end + ui.Offset(0, r * 0.3), r, line);
    } else {
      final hookPath = ui.Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx, end.dy + 7)
        ..arcToPoint(
          ui.Offset(end.dx + 8, end.dy + 7),
          radius: const ui.Radius.circular(4),
          clockwise: false,
        );
      canvas.drawPath(hookPath, line..strokeWidth = 2);
    }

    if (!drawRod) return;

    // Rod: thick at the handle, thin at the tip.
    final dir = (t - hand) / len;
    final normal = ui.Offset(-dir.dy, dir.dx);
    final back = hand - dir * len * 0.12;
    final rod = ui.Path()
      ..moveTo(back.dx + normal.dx * 4, back.dy + normal.dy * 4)
      ..lineTo(t.dx + normal.dx * 1.2, t.dy + normal.dy * 1.2)
      ..lineTo(t.dx - normal.dx * 1.2, t.dy - normal.dy * 1.2)
      ..lineTo(back.dx - normal.dx * 4, back.dy - normal.dy * 4)
      ..close();
    canvas.drawPath(rod, ui.Paint()..color = AppColors.rod);
    canvas.drawLine(
      back,
      hand + dir * len * 0.1,
      ui.Paint()
        ..color = AppColors.rodHandle
        ..strokeWidth = 9
        ..strokeCap = ui.StrokeCap.round,
    );
    canvas.drawCircle(t, 2.5, ui.Paint()..color = AppColors.rodHandle);
  }
}
