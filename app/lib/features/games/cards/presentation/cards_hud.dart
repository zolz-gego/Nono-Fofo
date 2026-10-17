import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/text/app_texts.dart';
import '../../progress/domain/timed_record.dart';

/// Time, moves and pairs found, over the table.
class CardsHud extends StatefulWidget {
  const CardsHud({
    super.key,
    required this.elapsed,
    required this.running,
    required this.moves,
    required this.pairsFound,
    required this.pairs,
  });

  /// Reads the clock (called a few times a second while [running]).
  final Duration Function() elapsed;
  final bool running;
  final int moves;
  final int pairsFound;
  final int pairs;

  @override
  State<CardsHud> createState() => _CardsHudState();
}

class _CardsHudState extends State<CardsHud> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(CardsHud old) {
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
          icon: AppIcons.moves,
          label: l10n.cardsMoves,
          value: '${widget.moves}',
        ),
        const SizedBox(width: AppDimens.spaceSm),
        _Chip(
          icon: AppIcons.pairs,
          label: l10n.cardsPairs,
          value: '${widget.pairsFound}/${widget.pairs}',
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
