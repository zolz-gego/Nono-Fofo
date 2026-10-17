import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../progress/domain/timed_record.dart';

/// Time, letters found and the hint button, over the room.
class MonasteryHud extends StatefulWidget {
  const MonasteryHud({
    super.key,
    required this.elapsed,
    required this.running,
    required this.found,
    required this.total,
    required this.onHint,
  });

  /// Reads the clock (called a few times a second while [running]).
  final Duration Function() elapsed;
  final bool running;
  final int found;
  final int total;

  /// Null while a hint is showing (or the game is over).
  final VoidCallback? onHint;

  @override
  State<MonasteryHud> createState() => _MonasteryHudState();
}

class _MonasteryHudState extends State<MonasteryHud> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(MonasteryHud old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.running && _tick == null) {
      _tick = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => setState(() {}),
      );
    } else if (!widget.running) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          icon: AppIcons.timer,
          label: l10n.cardsTime,
          value: formatClock(widget.elapsed()),
        ),
        const SizedBox(width: AppDimens.spaceSm),
        _Chip(
          icon: AppIcons.found,
          label: l10n.monasteryFound,
          value: '${widget.found}/${widget.total}',
        ),
        const SizedBox(width: AppDimens.spaceSm),
        FilledButton.tonalIcon(
          onPressed: widget.onHint,
          icon: const FaIcon(AppIcons.hintBulb, size: 18),
          label: Text(l10n.monasteryHint),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.value});

  final FaIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceMd,
          vertical: AppDimens.spaceXs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.speechBubbleBorder, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppDimens.spaceSm),
            AppText.h3(value),
          ],
        ),
      ),
    );
  }
}
