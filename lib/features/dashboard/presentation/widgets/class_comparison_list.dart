import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/attendance_report_stats.dart';

/// Horizontal-bar comparison of attendance rate per class, sorted best first.
class ClassComparisonList extends StatelessWidget {
  const ClassComparisonList({super.key, required this.rows});

  final List<ClassAttendanceRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: AppLocalizations.of(context)!.dashboardClassWiseComparison),
            const SizedBox(height: AppSpacing.md),
            if (rows.isEmpty)
              EmptyView(message: AppLocalizations.of(context)!.dashboardNoClassesYet)
            else
              ...rows.map((r) => _ClassBar(row: r)),
          ],
        ),
      ),
    );
  }
}

class _ClassBar extends StatelessWidget {
  const _ClassBar({required this.row});

  final ClassAttendanceRow row;

  @override
  Widget build(BuildContext context) {
    final color = row.attendanceRate >= 0.9
        ? AppColors.success
        : (row.attendanceRate >= 0.75 ? AppColors.warning : AppColors.danger);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.className,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${row.presentCount}/${row.presentCount + row.absentCount}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: row.attendanceRate.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
