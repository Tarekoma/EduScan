import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BadgeTone { neutral, positive, warning, negative, info }

/// Small rounded status chip used across attendance and pickup UIs.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      BadgeTone.neutral => (AppColors.neutralBg, AppColors.neutralFg),
      BadgeTone.positive => (AppColors.successBg, AppColors.success),
      BadgeTone.warning => (AppColors.warningBg, AppColors.warning),
      BadgeTone.negative => (AppColors.dangerBg, AppColors.danger),
      BadgeTone.info => (AppColors.infoBg, AppColors.info),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
