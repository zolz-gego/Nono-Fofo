import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../engines/characters/presentation/speech_bubble.dart';
import '../domain/hidden_letter.dart';
import '../domain/monastery_config.dart';
import 'monastery_room.dart';

/// A pulsing glow near letter [index] (a little off, so it only helps).
class HintGlow {
  const HintGlow({required this.index, required this.offset, required this.id});

  final int index;

  /// How far off the letter the glow sits, in scene fractions.
  final Offset offset;
  final int id;
}

/// A missed tap, shown as a little cross for a moment.
class MissMark {
  const MissMark({required this.at, required this.id});

  /// Scene fractions.
  final Offset at;
  final int id;
}

/// A speech bubble pinned to a scene point (small screens: no brothers).
class SceneBubble {
  const SceneBubble({required this.text, required this.at});

  final String text;
  final Offset at;
}

/// The room, in layers: background, the hidden letters, every object in
/// front of them, then the found letters (lifted, gold), hints and missed
/// taps. Taps come back as scene fractions.
class MonasterySceneView extends StatelessWidget {
  const MonasterySceneView({
    super.key,
    required this.config,
    required this.scene,
    required this.letters,
    required this.onTap,
    this.hint,
    this.misses = const [],
    this.bubble,
  });

  final MonasteryConfig config;
  final MonasteryScene scene;
  final List<HiddenLetter> letters;
  final void Function(Offset scenePoint) onTap;
  final HintGlow? hint;
  final List<MissMark> misses;
  final SceneBubble? bubble;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        Rect frac(Rect r) => Rect.fromLTWH(
          r.left * size.width,
          r.top * size.height,
          r.width * size.width,
          r.height * size.height,
        );
        Offset point(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
        final hint = this.hint;
        final bubble = this.bubble;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(
            Offset(
              d.localPosition.dx / size.width,
              d.localPosition.dy / size.height,
            ),
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: MonasteryBackground(
                    room: scene.id,
                    image: scene.background == null
                        ? null
                        : AssetImage(scene.background!),
                  ),
                ),
                for (final l in letters)
                  if (!l.found) _letter(l, size, point, found: false),
                for (final o in scene.objects)
                  Positioned.fromRect(
                    rect: frac(o.rect),
                    child: MonasteryObject(
                      shape: o.shape,
                      image: o.image == null ? null : AssetImage(o.image!),
                    ),
                  ),
                if (config.showSpots)
                  for (final s in scene.spots)
                    Positioned.fromRect(
                      rect: Rect.fromCircle(
                        center: point(Offset(s.x, s.y)),
                        radius: s.size * size.height * 0.75 * config.tapRadius,
                      ),
                      child: const IgnorePointer(child: _SpotOutline()),
                    ),
                if (hint != null && hint.index < letters.length)
                  _hintGlow(hint, size, point),
                for (final (i, l) in letters.indexed)
                  if (l.found)
                    KeyedSubtree(
                      key: ValueKey('found$i'),
                      child: _letter(l, size, point, found: true),
                    ),
                for (final m in misses)
                  Positioned(
                    key: ValueKey('miss${m.id}'),
                    left: point(m.at).dx - 18,
                    top: point(m.at).dy - 18,
                    width: 36,
                    height: 36,
                    child: const IgnorePointer(child: _MissCross()),
                  ),
                if (bubble != null) _bubble(bubble, size, point),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _letter(
    HiddenLetter l,
    Size size,
    Offset Function(Offset) point, {
    required bool found,
  }) {
    final px = l.spot.size * size.height;
    final box = px * 1.6;
    final c = point(l.center);
    final glyph = Text(
      l.glyph,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: AppFonts.coptic,
        fontSize: px,
        height: 1,
        color: found
            ? AppColors.letterGold
            : l.color.withValues(alpha: config.letterOpacity),
        shadows: found
            ? const [Shadow(color: AppColors.cocoa, blurRadius: 2)]
            : null,
      ),
    );
    Widget child = Transform.rotate(
      angle: found ? 0 : l.rotation,
      child: Center(child: glyph),
    );
    if (found) {
      child =
          DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.foundGlow,
                  border: Border.all(
                    color: AppColors.correct,
                    width: max(2, px * 0.06),
                  ),
                ),
                child: child,
              )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.25, 1.25),
                duration: 280.ms,
                curve: Curves.easeOut,
              )
              .then()
              .scale(
                begin: const Offset(1.25, 1.25),
                end: const Offset(1, 1),
                duration: 200.ms,
              );
    }
    return Positioned(
      left: c.dx - box / 2,
      top: c.dy - box / 2,
      width: box,
      height: box,
      child: IgnorePointer(child: child),
    );
  }

  Widget _hintGlow(HintGlow hint, Size size, Offset Function(Offset) point) {
    final l = letters[hint.index];
    final r = l.spot.size * size.height * 2.4;
    final c = point(l.center + hint.offset);
    return Positioned(
      key: ValueKey('hint${hint.id}'),
      left: c.dx - r,
      top: c.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child:
            DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppColors.hintGlow, Color(0x33FFD54F)],
                    ),
                    border: Border.all(color: AppColors.hintRing, width: 4),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.1, 1.1),
                  duration: 550.ms,
                  curve: Curves.easeInOut,
                ),
      ),
    );
  }

  Widget _bubble(SceneBubble b, Size size, Offset Function(Offset) point) {
    final c = point(b.at);
    // Above the point, or below it when too close to the top.
    final above = c.dy > size.height * 0.25;
    const w = 180.0;
    return Positioned(
      key: ValueKey('bubble${b.text}${b.at}'),
      left: (c.dx - w / 2).clamp(4.0, max(4.0, size.width - w - 4)),
      top: above ? null : c.dy + size.height * 0.07,
      bottom: above ? size.height - c.dy + size.height * 0.07 : null,
      width: w,
      child: IgnorePointer(
        child: Center(
          child: SpeechBubble(text: b.text, showTail: false, maxWidth: w),
        ),
      ),
    );
  }
}

class _SpotOutline extends StatelessWidget {
  const _SpotOutline();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.coral, width: 2),
    ),
  );
}

class _MissCross extends StatelessWidget {
  const _MissCross();

  @override
  Widget build(BuildContext context) =>
      const Center(
            child: FaIcon(AppIcons.miss, color: AppColors.wrong, size: 30),
          )
          .animate()
          .scale(
            begin: const Offset(0.4, 0.4),
            duration: 160.ms,
            curve: Curves.easeOutBack,
          )
          .shakeX(hz: 6, amount: 3, duration: 300.ms)
          .then(delay: 250.ms)
          .fadeOut(duration: 250.ms);
}
