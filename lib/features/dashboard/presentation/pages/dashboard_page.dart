import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/attendance_state.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../attendance/presentation/attendance_status_display.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/attendance_rate_chart.dart';
import '../widgets/class_comparison_list.dart';
import '../widgets/detailed_attendance_table.dart';
import '../widgets/stat_card.dart';

/// Shared dashboard + attendance-reports view for managers and supervisors.
/// Top section is a live "today" snapshot; below it is a date-range report
/// (rate over time, per-class comparison, detailed table) built from the
/// same real attendance records via [AttendanceReportStats].
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardCubit>()..start(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading ||
            state.status == DashboardStatus.initial) {
          return const LoadingView();
        }
        if (state.status == DashboardStatus.error) {
          return ErrorView(
            message: state.errorMessage ?? 'Could not load the dashboard.',
            onRetry: () => context.read<DashboardCubit>().start(),
          );
        }
        return _Content(state: state);
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final statColumns = responsiveValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 5,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: PageHeader(
                title: 'Dashboard',
                subtitle: "Today's attendance and historical reports",
              ),
            ),
            if (context.isMobile) ...[
              const ThemeToggleButton(),
              const SignOutButton(),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // --- Today's snapshot --------------------------------------------
        const SectionHeader(title: "Today's snapshot"),
        const SizedBox(height: AppSpacing.sm),
        _TodayFilterBar(state: state),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: statColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: [
            StatCard.count(
              label: 'Total people',
              value: stats.totalPeople,
              icon: Icons.groups,
            ),
            StatCard.count(
              label: 'Checked in',
              value: stats.checkedIn,
              icon: Icons.login,
            ),
            StatCard.count(
              label: 'Currently inside',
              value: stats.currentlyInside,
              icon: Icons.meeting_room,
              tone: Theme.of(context).colorScheme.tertiary,
            ),
            StatCard.count(
              label: 'Checked out',
              value: stats.checkedOut,
              icon: Icons.logout,
            ),
            StatCard.count(
              label: 'Absent',
              value: stats.absent,
              icon: Icons.person_off,
              tone: AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: 'Recent activity',
          trailing: Text(
            TimeFormat.date(state.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.attendanceLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.activity.isEmpty)
          const EmptyView(message: 'No attendance recorded for this day.')
        else
          ...state.activity.map((item) => _ActivityTile(item: item)),

        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        const SizedBox(height: AppSpacing.md),

        // --- Reports --------------------------------------------------------
        const SectionHeader(title: 'Attendance reports'),
        const SizedBox(height: AppSpacing.sm),
        _ReportRangeBar(state: state),
        const SizedBox(height: AppSpacing.md),
        _ReportBody(state: state),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    if (state.reportStatus == DashboardReportStatus.loading ||
        state.reportStatus == DashboardReportStatus.initial) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.reportStatus == DashboardReportStatus.error) {
      return ErrorView(
        message: state.reportErrorMessage ?? 'Could not load the report.',
        onRetry: () => context.read<DashboardCubit>().setReportRange(
          state.reportFrom,
          state.reportTo,
        ),
      );
    }

    final report = state.report;
    final columns = responsiveValue(context, mobile: 1, tablet: 3, desktop: 3);

    return Column(
      children: [
        if (state.students.isEmpty)
          const EmptyView(
            message: 'No students yet — add students to see reports.',
          )
        else ...[
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns == 1 ? 2.6 : 1.7,
            children: [
              StatCard(
                label: 'Avg attendance rate',
                value:
                    '${(report.avgAttendanceRate * 100).toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                tone: AppColors.success,
              ),
              StatCard.count(
                label: 'Frequently absent',
                value: report.chronicAbsenceCount,
                icon: Icons.person_off_outlined,
                tone: AppColors.danger,
                trendLabel: report.totalDays == 0
                    ? null
                    : 'Missed ≥${report.chronicAbsenceThresholdDays} of '
                          '${report.totalDays} day(s)',
              ),
              StatCard.count(
                label: 'Perfect attendance',
                value: report.perfectAttendanceCount,
                icon: Icons.emoji_events_outlined,
                tone: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceRateChart(points: report.dailyRates),
          const SizedBox(height: AppSpacing.md),
          ClassComparisonList(rows: report.perClass),
          const SizedBox(height: AppSpacing.md),
          DetailedAttendanceTable(rows: report.perClass),
        ],
      ],
    );
  }
}

class _TodayFilterBar extends StatelessWidget {
  const _TodayFilterBar({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ActionChip(
          avatar: const Icon(Icons.calendar_today, size: 16),
          label: Text(TimeFormat.date(state.date)),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: state.date,
              firstDate: DateTime(now.year - 1),
              lastDate: now,
            );
            if (picked != null) cubit.setDate(picked);
          },
        ),
        SegmentedButton<PersonType?>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: null, label: Text('All')),
            ButtonSegment(value: PersonType.student, label: Text('Students')),
            ButtonSegment(value: PersonType.worker, label: Text('Workers')),
          ],
          selected: {state.typeFilter},
          onSelectionChanged: (s) => cubit.setTypeFilter(s.first),
        ),
      ],
    );
  }
}

class _ReportRangeBar extends StatelessWidget {
  const _ReportRangeBar({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final label =
        '${TimeFormat.date(state.reportFrom)} — ${TimeFormat.date(state.reportTo)}';
    return ActionChip(
      avatar: const Icon(Icons.date_range, size: 16),
      label: Text(label),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 2),
          lastDate: now,
          initialDateRange: DateTimeRange(
            start: state.reportFrom,
            end: state.reportTo,
          ),
        );
        if (picked != null) {
          cubit.setReportRange(picked.start, picked.end);
        }
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final derived = item.checkIn == null
        ? AttendanceState.absent
        : (item.checkOut == null
              ? AttendanceState.inside
              : AttendanceState.left);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(
              item.personType == PersonType.student
                  ? Icons.school
                  : Icons.badge,
            ),
          ),
          title: Text(item.personName),
          subtitle: Text(
            '${item.personId}  •  In ${TimeFormat.time(item.checkIn)}  •  '
            'Out ${TimeFormat.time(item.checkOut)}\nRecorded by ${item.recordedBy}',
          ),
          isThreeLine: true,
          trailing: StatusBadge(label: derived.label, tone: derived.tone),
        ),
      ),
    );
  }
}
