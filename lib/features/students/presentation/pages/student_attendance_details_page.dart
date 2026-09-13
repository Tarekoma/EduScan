import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/attendance_status_display.dart';
import '../../domain/entities/student.dart';
import '../cubit/student_attendance_history_cubit.dart';

/// Attendance history for one student, opened from the Students list
/// (manager and supervisor alike). [student] is passed in directly from the
/// tapped row — no re-fetch needed.
class StudentAttendanceDetailsPage extends StatelessWidget {
  const StudentAttendanceDetailsPage({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<StudentAttendanceHistoryCubit>()..start(student.studentId),
      child: _DetailsView(student: student),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(title: student.fullName, subtitle: 'Attendance history'),
      ),
      body: BlocBuilder<StudentAttendanceHistoryCubit, StudentAttendanceHistoryState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StudentHeaderCard(student: student),
                const SizedBox(height: AppSpacing.md),
                _RangeBar(state: state),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _HistoryList(
                    state: state,
                    studentId: student.studentId,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentHeaderCard extends StatelessWidget {
  const _StudentHeaderCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student.className.isNotEmpty ? student.className[0] : '?'),
        ),
        title: Text(
          student.fullName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text('${student.studentId} • Class ${student.className}'),
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.state});

  final StudentAttendanceHistoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StudentAttendanceHistoryCubit>();
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              state.range == null
                  ? 'All available days'
                  : '${TimeFormat.date(state.range!.start)} – '
                        '${TimeFormat.date(state.range!.end)}',
            ),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: now,
                initialDateRange: state.range,
              );
              if (picked != null) cubit.setRange(picked);
            },
          ),
        ),
        if (state.range != null)
          IconButton(
            tooltip: 'Clear filter',
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => cubit.setRange(null),
          ),
        if (state.status == StudentAttendanceHistoryStatus.ready)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              '${state.presentCount} present',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state, required this.studentId});

  final StudentAttendanceHistoryState state;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case StudentAttendanceHistoryStatus.initial:
      case StudentAttendanceHistoryStatus.loading:
        return const LoadingView();
      case StudentAttendanceHistoryStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'Could not load attendance history.',
          onRetry: () =>
              context.read<StudentAttendanceHistoryCubit>().start(studentId),
        );
      case StudentAttendanceHistoryStatus.ready:
        final records = state.visibleRecords;
        if (records.isEmpty) {
          return const EmptyView(
            message: 'No attendance records found.',
            icon: Icons.event_busy_outlined,
          );
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) => _HistoryTile(record: records[i]),
        );
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(TimeFormat.date(DateTime.parse(record.date))),
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
