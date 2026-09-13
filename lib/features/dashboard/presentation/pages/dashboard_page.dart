import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../attendance/presentation/attendance_status_display.dart';
import '../../../../core/enums/attendance_state.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/checkins_chart.dart';
import '../widgets/stat_card.dart';

/// Shared read-only dashboard for managers and supervisors.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<DashboardCubit, DashboardState>(
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
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final columns = responsiveValue(context, mobile: 2, tablet: 3, desktop: 4);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _FilterBar(state: state),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.4,
          children: [
            StatCard(
              label: 'Total people',
              value: stats.totalPeople,
              icon: Icons.groups,
            ),
            StatCard(
              label: 'Students',
              value: stats.totalStudents,
              icon: Icons.school,
            ),
            StatCard(
              label: 'Workers',
              value: stats.totalWorkers,
              icon: Icons.badge,
            ),
            StatCard(
              label: 'Checked in',
              value: stats.checkedIn,
              icon: Icons.login,
            ),
            StatCard(
              label: 'Checked out',
              value: stats.checkedOut,
              icon: Icons.logout,
            ),
            StatCard(
              label: 'Currently inside',
              value: stats.currentlyInside,
              icon: Icons.meeting_room,
              tone: Theme.of(context).colorScheme.tertiary,
            ),
            StatCard(
              label: 'Absent',
              value: stats.absent,
              icon: Icons.person_off,
              tone: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        CheckInsChart(points: state.chart),
        const SizedBox(height: AppSpacing.md),
        Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
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
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            'Showing ${TimeFormat.date(state.date)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state});

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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            item.personType == PersonType.student ? Icons.school : Icons.badge,
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
    );
  }
}
