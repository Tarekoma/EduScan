import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/attendance_report_stats.dart';

/// Per-class attendance/absence rate breakdown. A table on tablet/desktop, a
/// stack of cards on mobile so nothing forces horizontal scrolling on a
/// phone-width screen.
class DetailedAttendanceTable extends StatelessWidget {
  const DetailedAttendanceTable({super.key, required this.rows});

  final List<ClassAttendanceRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Detailed attendance'),
            const SizedBox(height: AppSpacing.md),
            if (rows.isEmpty)
              const EmptyView(message: 'No attendance data for this range.')
            else if (context.isMobile)
              Column(children: [for (final r in rows) _MobileRow(row: r)])
            else
              _DesktopTable(rows: rows),
          ],
        ),
      ),
    );
  }
}

BadgeTone _toneFor(double ratePct) {
  if (ratePct >= 90) return BadgeTone.positive;
  if (ratePct >= 75) return BadgeTone.warning;
  return BadgeTone.negative;
}

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.rows});

  final List<ClassAttendanceRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('CLASS', style: headerStyle)),
              Expanded(flex: 2, child: Text('STUDENTS', style: headerStyle)),
              Expanded(
                flex: 3,
                child: Text('ATTENDANCE RATE', style: headerStyle),
              ),
              Expanded(flex: 3, child: Text('ABSENCE RATE', style: headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final r in rows)
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(r.className)),
                Expanded(flex: 2, child: Text('${r.studentCount}')),
                Expanded(
                  flex: 3,
                  child: StatusBadge(
                    label: '${(r.attendanceRate * 100).toStringAsFixed(1)}%',
                    tone: _toneFor(r.attendanceRate * 100),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text('${(r.absenceRate * 100).toStringAsFixed(1)}%'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.row});

  final ClassAttendanceRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.className,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              StatusBadge(
                label: '${(row.attendanceRate * 100).toStringAsFixed(1)}%',
                tone: _toneFor(row.attendanceRate * 100),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${row.studentCount} students  •  '
            '${(row.absenceRate * 100).toStringAsFixed(1)}% absence',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
