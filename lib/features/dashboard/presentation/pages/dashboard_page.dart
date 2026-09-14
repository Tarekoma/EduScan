import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/attendance_state.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/locale_toggle_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
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
            message: state.errorMessage ??
                AppLocalizations.of(context)!.dashboardCouldNotLoad,
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
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PageHeader(
                title: l10n.dashboardTitle,
                subtitle: l10n.dashboardSubtitle,
              ),
            ),
            if (context.isMobile) ...[
              const ThemeToggleButton(),
              const LocaleToggleButton(),
              const SignOutButton(),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        TodaySnapshotSection(state: state),

        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        const SizedBox(height: AppSpacing.md),

        // --- Reports --------------------------------------------------------
        SectionHeader(title: l10n.sectionAttendanceReports),
        const SizedBox(height: AppSpacing.sm),
        _ReportRangeBar(state: state),
        const SizedBox(height: AppSpacing.md),
        _ReportBody(state: state),
      ],
    );
  }
}

/// The "Today's snapshot" stat grid plus the "Recent activity" list — the
/// live, same-day view shared by the manager/supervisor [DashboardPage] and
/// the read-only security-role dashboard tab.
class TodaySnapshotSection extends StatelessWidget {
  const TodaySnapshotSection({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final l10n = AppLocalizations.of(context)!;
    final statColumns = responsiveValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.sectionTodaySnapshot),
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
              label: l10n.statTotalPeople,
              value: stats.totalPeople,
              icon: Icons.groups,
            ),
            StatCard.count(
              label: l10n.checkedInTitle,
              value: stats.checkedIn,
              icon: Icons.login,
            ),
            StatCard.count(
              label: l10n.statCurrentlyInside,
              value: stats.currentlyInside,
              icon: Icons.meeting_room,
              tone: Theme.of(context).colorScheme.tertiary,
            ),
            StatCard.count(
              label: l10n.checkedOutTitle,
              value: stats.checkedOut,
              icon: Icons.logout,
            ),
            StatCard.count(
              label: l10n.attendanceStateAbsent,
              value: stats.absent,
              icon: Icons.person_off,
              tone: AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.sectionRecentActivity,
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
          EmptyView(message: l10n.dashboardNoAttendanceForDay)
        else
          ...state.activity.map((item) => _ActivityTile(item: item)),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.reportStatus == DashboardReportStatus.loading ||
        state.reportStatus == DashboardReportStatus.initial) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.reportStatus == DashboardReportStatus.error) {
      return ErrorView(
        message: state.reportErrorMessage ?? l10n.dashboardReportCouldNotLoad,
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
          EmptyView(message: l10n.dashboardNoStudentsYet)
        else ...[
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns == 1 ? 2.6 : 1.7,
            children: [
              StatCard.count(
                label: l10n.statFrequentlyAbsent,
                value: report.chronicAbsenceCount,
                icon: Icons.person_off_outlined,
                tone: AppColors.danger,
                trendLabel: report.totalDays == 0
                    ? null
                    : l10n.dashboardMissedDays(
                        report.chronicAbsenceThresholdDays,
                        report.totalDays,
                      ),
              ),
              StatCard.count(
                label: l10n.statPerfectAttendance,
                value: report.perfectAttendanceCount,
                icon: Icons.emoji_events_outlined,
                tone: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceRateChart(
            points: report.dailyRates,
            totalStudents: state.students.length,
          ),
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
    final l10n = AppLocalizations.of(context)!;
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
          segments: [
            ButtonSegment(value: null, label: Text(l10n.filterAll)),
            ButtonSegment(value: PersonType.student, label: Text(l10n.filterStudents)),
            ButtonSegment(value: PersonType.worker, label: Text(l10n.filterWorkers)),
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
            AppLocalizations.of(context)!.dashboardActivitySubtitle(
              item.personId,
              TimeFormat.time(item.checkIn),
              TimeFormat.time(item.checkOut),
              item.recordedBy,
            ),
          ),
          isThreeLine: true,
          trailing: StatusBadge(label: derived.label(context), tone: derived.tone),
        ),
      ),
    );
  }
}
