import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A dashboard/report KPI tile: an icon, a big value, a label, and an
/// optional trend line (e.g. "+1.2% vs prior period").
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
    this.trendLabel,
    this.trendPositive,
    this.onTap,
  });

  /// Convenience constructor for integer counts (the dashboard's original
  /// usage) so call sites don't need to format the number themselves.
  StatCard.count({
    super.key,
    required this.label,
    required int value,
    required this.icon,
    this.tone,
    this.trendLabel,
    this.trendPositive,
    this.onTap,
  }) : value = '$value';

  final String label;
  final String value;
  final IconData icon;
  final Color? tone;

  /// e.g. "+1.2% vs prior period". Omit when there is no prior-period data.
  final String? trendLabel;

  /// Colours [trendLabel] green when true, red when false, neutral when null.
  final bool? trendPositive;

  /// When set the whole card is tappable (ripple + a small chevron beside the
  /// value) — used for the dashboard's drill-down cards.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = tone ?? scheme.primary;
    final trendColor = switch (trendPositive) {
      true => AppColors.success,
      false => AppColors.danger,
      null => scheme.onSurfaceVariant,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: accent, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  // Affordance for tappable cards; flips itself in RTL.
                  if (onTap != null)
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              if (trendLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  trendLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
