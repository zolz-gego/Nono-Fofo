import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/typography/app_text_styles.dart';
import '../domain/character_action.dart';
import '../domain/character_motion.dart';
import '../domain/character_pose.dart';
import '../domain/character_reaction.dart';
import 'character_controller.dart';
import 'speech_bubble.dart';

/// Draws one brother with live procedural motion. Everything is driven by
/// [controller]; this widget never needs to change per game.
///
/// [size] is Nono's standing height in logical pixels. Fofo uses the same
/// scale, so he is drawn ~75% as tall — the brothers always stay in
/// proportion when shown side by side.
class AnimatedCharacter extends StatefulWidget {
  const AnimatedCharacter({
    super.key,
    required this.controller,
    this.size = 240,
    this.mirror = false,
    this.showShadow = true,
    this.tapReaction = CharacterReaction.greet,
    this.onTap,
  });

  final CharacterController controller;
  final double size;

  /// Flip horizontally (e.g. to face the other brother).
  final bool mirror;
  final bool showShadow;

  /// What happens when the child taps the character (null = nothing),
  /// unless [onTap] is given.
  final CharacterReaction? tapReaction;
  final VoidCallback? onTap;

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this)
    ..addStatusListener(_onMotionStatus);
  late MotionSpec _spec;
  CharacterAction? _shownAction;
  int _shownToken = -1;
  bool _precached = false;

  CharacterController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onControllerChanged);
    _syncMotion();
  }

  @override
  void didUpdateWidget(AnimatedCharacter old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      _c.addListener(_onControllerChanged);
      _syncMotion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final pose in context.read<CharacterRoster>().posesOf(_c.character)) {
      precacheImage(AssetImage(pose.asset), context);
    }
  }

  void _onControllerChanged() {
    _syncMotion();
    setState(() {});
  }

  /// Restarts the motion when the action (or play token) changes.
  void _syncMotion() {
    if (_shownAction == _c.action && _shownToken == _c.playToken) return;
    _shownAction = _c.action;
    _shownToken = _c.playToken;
    _start(CharacterMotions.of(_c.action));
  }

  void _start(MotionSpec spec) {
    _spec = spec;
    _motion.duration = spec.period;
    if (spec.loop) {
      _motion.repeat();
    } else {
      _motion.forward(from: 0);
    }
  }

  /// After a one-shot motion, keep breathing in the same pose.
  void _onMotionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_spec.loop) {
      _start(CharacterMotions.breathe);
    }
  }

  void _handleTap() {
    if (widget.onTap != null) return widget.onTap!();
    if (widget.tapReaction != null) _c.react(widget.tapReaction!);
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roster = context.read<CharacterRoster>();
    final idle = roster.pose(_c.character, CharacterAction.idle);
    final pose = roster.pose(_c.character, _c.action);
    if (idle == null || pose == null) return const SizedBox.shrink();

    final k = widget.size / roster.referenceHeight;
    final boxW = idle.width * k;
    final boxH = idle.height * k;
    final drawnHeight = idle.height * k;

    final posed = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(anim),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        clipBehavior: Clip.none,
        children: [...previous, ?current],
      ),
      child: _PoseImage(
        key: ValueKey(pose.action),
        pose: pose,
        scale: k,
        boxWidth: boxW,
        boxHeight: boxH,
      ),
    );

    return Semantics(
      button: widget.tapReaction != null || widget.onTap != null,
      label: _c.character.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox(
          width: boxW,
          height: boxH,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedBuilder(
                animation: _motion,
                builder: (context, child) {
                  final f = _spec.frameAt(_motion.value);
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (widget.showShadow)
                        _GroundShadow(width: boxW * 0.8, lift: -f.dy),
                      Transform.flip(
                        flipX: widget.mirror,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.translationValues(
                              f.dx * drawnHeight, f.dy * drawnHeight, 0)
                            ..rotateZ(f.rotation)
                            ..scaleByDouble(f.scaleX, f.scaleY, 1, 1),
                          child: child,
                        ),
                      ),
                    ],
                  );
                },
                child: posed,
              ),
              if (_c.action == CharacterAction.sleep)
                Positioned(
                  top: 0,
                  right: widget.mirror ? null : 0,
                  left: widget.mirror ? 0 : null,
                  child: _SleepZs(size: widget.size * 0.12),
                ),
              Positioned(
                bottom: boxH + 6,
                child: SpeechBubble(text: _c.speech),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pose image positioned so the head stays at the same x across poses
/// (no sideways jump when switching) and the feet stay on the ground.
class _PoseImage extends StatelessWidget {
  const _PoseImage({
    super.key,
    required this.pose,
    required this.scale,
    required this.boxWidth,
    required this.boxHeight,
  });

  final CharacterPose pose;
  final double scale;
  final double boxWidth;
  final double boxHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: boxWidth / 2 - pose.headCenter.dx * scale,
            bottom: 0,
            width: pose.width * scale,
            height: pose.height * scale,
            child: Image.asset(
              pose.asset,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundShadow extends StatelessWidget {
  const _GroundShadow({required this.width, required this.lift});

  final double width;

  /// How high the character is off the ground (fraction of height).
  final double lift;

  @override
  Widget build(BuildContext context) {
    final shrink = (1 - lift * 4).clamp(0.5, 1.0);
    return Positioned(
      bottom: -width * 0.05,
      child: Container(
        width: width * shrink,
        height: width * 0.12 * shrink,
        decoration: BoxDecoration(
          color: AppColors.shadow,
          borderRadius: BorderRadius.all(Radius.elliptical(width, width * 0.12)),
        ),
      ),
    );
  }
}

class _SleepZs extends StatelessWidget {
  const _SleepZs({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.english(AppTextVariant.h2)
        .copyWith(fontSize: size, color: AppColors.slateTeal);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++)
          Text('z', style: style.copyWith(fontSize: size * (0.7 + i * 0.25)))
              .animate(onPlay: (c) => c.repeat(), delay: (i * 400).ms)
              .fadeIn(duration: 400.ms)
              .moveY(begin: 0, end: -size, duration: 1600.ms)
              .fadeOut(delay: 1000.ms, duration: 600.ms),
      ],
    );
  }
}
