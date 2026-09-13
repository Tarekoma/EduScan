import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/attendance_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/attendance_status_display.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../pickup/presentation/widgets/parent_pickup_card.dart';
import '../cubit/parent_dashboard_cubit.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ParentDashboardCubit>()..start(),
      child: const _ParentDashboardView(),
    );
  }
}

class _ParentDashboardView extends StatelessWidget {
  const _ParentDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const PageHeader(title: 'My children'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
        builder: (context, state) {
          switch (state.status) {
            case ParentStatus.initial:
            case ParentStatus.loading:
              return const LoadingView();
            case ParentStatus.empty:
              return const EmptyView(
                message:
                    'No children are linked to your account yet.\n'
                    'Please contact the school office.',
                icon: Icons.family_restroom,
              );
            case ParentStatus.error:
              return ErrorView(
                message: state.errorMessage ?? 'Could not load your children.',
                onRetry: () => context.read<ParentDashboardCubit>().start(),
              );
            case ParentStatus.ready:
              return _ReadyBody(state: state);
          }
        },
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state});

  final ParentDashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ParentDashboardCubit>();
    final child = state.selectedChild;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (state.children.length > 1)
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final c in state.children)
                ChoiceChip(
                  label: Text(c.fullName),
                  selected: c.studentId == state.selectedId,
                  onSelected: (_) => cubit.selectChild(c.studentId),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        if (child != null) ...[
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(child.className)),
              title: Text(
                child.fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('${child.studentId} • Class ${child.className}'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TodayCard(state: state),
          if (AppConfig.pickupEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            ParentPickupCard(
              key: ValueKey('pickup-${child.studentId}'),
              child: child,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _HistorySection(state: state),
        ],
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});

  final ParentDashboardState state;

  @override
  Widget build(BuildContext context) {
    if (!state.todayLoaded) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final record = state.today;
    final attendanceState = record?.state ?? AttendanceState.absent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's attendance",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                StatusBadge(
                  label: attendanceState.label,
                  tone: attendanceState.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _timeRow('Check-in', TimeFormat.time(record?.checkIn)),
            _timeRow('Check-out', TimeFormat.time(record?.checkOut)),
          ],
        ),
      ),
    );
  }

  Widget _timeRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    ),
  );
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.state});

  final ParentDashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ParentDashboardCubit>();
    final records = state.visibleHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('History', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                state.historyRange == null
                    ? 'Filter'
                    : '${TimeFormat.date(state.historyRange!.start)} – '
                          '${TimeFormat.date(state.historyRange!.end)}',
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 1),
                  lastDate: now,
                  initialDateRange: state.historyRange,
                );
                cubit.setHistoryRange(picked);
              },
            ),
            if (state.historyRange != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => cubit.setHistoryRange(null),
              ),
          ],
        ),
        if (state.historyLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text('No attendance records for this period.'),
            ),
          )
        else
          ...records.map((r) => _HistoryTile(record: r)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(record.date),
        subtitle: Text(
          'In ${TimeFormat.time(record.checkIn)}   •   '
          'Out ${TimeFormat.time(record.checkOut)}',
        ),
        trailing: StatusBadge(
          label: record.state.label,
          tone: record.state.tone,
        ),
      ),
    );
  }
}
