import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/person_type.dart';
import '../../../../core/enums/person_type_display.dart';
import '../../../../core/enums/worker_job_title_display.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/attendance_breakdown.dart';
import '../cubit/dashboard_cubit.dart';

/// Bottom sheet listing exactly the people behind one dashboard summary card
/// (checked in / checked out / absent / currently inside). One component for
/// all four categories.
///
/// It re-reads [DashboardCubit] while open, so the list stays live with the
/// same attendance stream the card counts come from.
abstract final class AttendanceDrillDownSheet {
  static Future<void> show(BuildContext context, AttendanceCategory category) {
    // The sheet lives on its own route, above the page's BlocProvider.
    final cubit = context.read<DashboardCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      // Keeps the sheet a comfortable width on tablet / desktop.
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) =>
              _SheetBody(category: category, controller: controller),
        ),
      ),
    );
  }
}

class _CategoryStyle {
  const _CategoryStyle(this.icon, this.tone);
  final IconData icon;
  final BadgeTone tone;
}

_CategoryStyle _styleOf(AttendanceCategory c) => switch (c) {
  AttendanceCategory.checkedIn => const _CategoryStyle(
    Icons.login,
    BadgeTone.positive,
  ),
  AttendanceCategory.checkedOut => const _CategoryStyle(
    Icons.logout,
    BadgeTone.neutral,
  ),
  AttendanceCategory.absent => const _CategoryStyle(
    Icons.person_off,
    BadgeTone.negative,
  ),
  AttendanceCategory.currentlyInside => const _CategoryStyle(
    Icons.meeting_room,
    BadgeTone.info,
  ),
};

String _titleOf(AppLocalizations l10n, AttendanceCategory c) => switch (c) {
  AttendanceCategory.checkedIn => l10n.checkedInTitle,
  AttendanceCategory.checkedOut => l10n.checkedOutTitle,
  AttendanceCategory.absent => l10n.attendanceStateAbsent,
  AttendanceCategory.currentlyInside => l10n.statCurrentlyInside,
};

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.category, required this.controller});

  final AttendanceCategory category;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final entries = state.breakdown(category);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(_styleOf(category).icon, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleOf(l10n, category),
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          '${l10n.drillDownCount(entries.length)}  •  '
                          '${TimeFormat.date(state.date)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? EmptyView(message: l10n.drillDownEmpty)
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: AppSpacing.md),
                      itemBuilder: (_, i) =>
                          _PersonTile(entry: entries[i], category: category),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.entry, required this.category});

  final BreakdownEntry entry;
  final AttendanceCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isStudent = entry.personType == PersonType.student;
    // Students are "Student"; workers show their actual role (Teacher, ...).
    final role = isStudent
        ? entry.personType.label(context)
        : (entry.jobTitle?.label(context) ?? entry.personType.label(context));
    final subtitle = [
      l10n.personIdTypeLabel(entry.personId, role),
      if (entry.className != null) entry.className!,
    ].join('  •  ');

    return ListTile(
      leading: CircleAvatar(
        child: Icon(isStudent ? Icons.school : Icons.badge),
      ),
      title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: StatusBadge(
        // Absent people have no time; everyone else shows theirs.
        label: entry.time == null
            ? l10n.attendanceStateAbsent
            : TimeFormat.time(entry.time),
        tone: _styleOf(category).tone,
      ),
    );
  }
}
