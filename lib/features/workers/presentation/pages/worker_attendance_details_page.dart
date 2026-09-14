import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/worker_job_title_display.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/attendance_status_display.dart';
import '../../domain/entities/worker.dart';
import '../cubit/worker_attendance_history_cubit.dart';

/// Attendance history for one worker, opened from the Workers list (manager,
/// supervisor and security alike). [worker] is passed in directly from the
/// tapped row — no re-fetch needed.
class WorkerAttendanceDetailsPage extends StatelessWidget {
  const WorkerAttendanceDetailsPage({super.key, required this.worker});

  final Worker worker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<WorkerAttendanceHistoryCubit>()..start(worker.workerId),
      child: _DetailsView(worker: worker),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.worker});

  final Worker worker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(
          title: worker.fullName,
          subtitle: AppLocalizations.of(context)!.attendanceHistorySubtitle,
        ),
      ),
      body: BlocBuilder<WorkerAttendanceHistoryCubit, WorkerAttendanceHistoryState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkerHeaderCard(worker: worker),
                const SizedBox(height: AppSpacing.md),
                _RangeBar(state: state),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _HistoryList(
                    state: state,
                    workerId: worker.workerId,
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

class _WorkerHeaderCard extends StatelessWidget {
  const _WorkerHeaderCard({required this.worker});

  final Worker worker;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
        title: Text(
          worker.fullName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.personIdTypeLabel(
            worker.workerId,
            worker.jobTitle.label(context),
          ),
        ),
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.state});

  final WorkerAttendanceHistoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkerAttendanceHistoryCubit>();
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              state.range == null
                  ? l10n.allAvailableDaysLabel
                  : l10n.dateRangeValue(
                      TimeFormat.date(state.range!.start),
                      TimeFormat.date(state.range!.end),
                    ),
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
            tooltip: l10n.clearFilterTooltip,
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => cubit.setRange(null),
          ),
        if (state.status == WorkerAttendanceHistoryStatus.ready)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: Text(
              l10n.presentCountLabel(state.presentCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state, required this.workerId});

  final WorkerAttendanceHistoryState state;
  final String workerId;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case WorkerAttendanceHistoryStatus.initial:
      case WorkerAttendanceHistoryStatus.loading:
        return const LoadingView();
      case WorkerAttendanceHistoryStatus.error:
        return ErrorView(
          message: state.errorMessage ??
              AppLocalizations.of(context)!.attendanceHistoryCouldNotLoad,
          onRetry: () =>
              context.read<WorkerAttendanceHistoryCubit>().start(workerId),
        );
      case WorkerAttendanceHistoryStatus.ready:
        final records = state.visibleRecords;
        if (records.isEmpty) {
          return EmptyView(
            message: AppLocalizations.of(context)!.noAttendanceRecordsFound,
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
          AppLocalizations.of(context)!.historyInOutSubtitle(
            TimeFormat.time(record.checkIn),
            TimeFormat.time(record.checkOut),
          ),
        ),
        trailing: StatusBadge(
          label: record.state.label(context),
          tone: record.state.tone,
        ),
      ),
    );
  }
}
