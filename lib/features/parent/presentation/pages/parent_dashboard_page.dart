import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/attendance_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/class_initials.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/locale_toggle_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/attendance_status_display.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(title: l10n.parentMyChildrenTitle),
        actions: const [
          ThemeToggleButton(),
          LocaleToggleButton(),
          SignOutButton(),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
          builder: (context, state) {
            switch (state.status) {
              case ParentStatus.initial:
              case ParentStatus.loading:
                return const LoadingView();
              case ParentStatus.empty:
                return EmptyView(
                  message: l10n.parentNoChildrenLinked,
                  icon: Icons.family_restroom,
                );
              case ParentStatus.error:
                return ErrorView(
                  message: state.errorMessage ?? l10n.parentCouldNotLoadChildren,
                  onRetry: () => context.read<ParentDashboardCubit>().start(),
                );
              case ParentStatus.ready:
                return _ReadyBody(state: state);
            }
          },
        ),
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
              leading: CircleAvatar(child: Text(classInitials(child.className))),
              title: Text(
                child.fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.personIdTypeLabel(
                  child.studentId,
                  AppLocalizations.of(context)!.personClassLabel(child.className),
                ),
              ),
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.sectionTodayAttendance,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                StatusBadge(
                  label: attendanceState.label(context),
                  tone: attendanceState.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _timeRow(l10n.checkInLabel, TimeFormat.time(record?.checkIn)),
            _timeRow(l10n.checkOutLabel, TimeFormat.time(record?.checkOut)),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.sectionHistory, style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                state.historyRange == null
                    ? l10n.filterButton
                    : l10n.dateRangeValue(
                        TimeFormat.date(state.historyRange!.start),
                        TimeFormat.date(state.historyRange!.end),
                      ),
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(l10n.parentNoRecordsForPeriod),
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
