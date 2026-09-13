import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../qr/presentation/pages/person_qr_page.dart';
import '../../domain/entities/worker.dart';
import '../cubit/workers_cubit.dart';
import 'worker_attendance_details_page.dart';
import 'worker_form_page.dart';

/// Workers list. [readOnly] hides all mutation actions (security/supervisor
/// views still get the QR action).
class WorkersPage extends StatelessWidget {
  const WorkersPage({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WorkersCubit>()..start(),
      child: _WorkersView(readOnly: readOnly),
    );
  }
}

class _WorkersView extends StatelessWidget {
  const _WorkersView({required this.readOnly});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(
          title: 'Workers',
          subtitle: readOnly
              ? 'View staff records and QR codes'
              : 'Manage staff records and QR codes',
        ),
        actions: [
          if (context.isMobile) ...[
            const ThemeToggleButton(),
            const SignOutButton(),
          ],
        ],
      ),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add worker'),
            ),
      body: BlocConsumer<WorkersCubit, WorkersState>(
        listenWhen: (a, b) =>
            a.actionError != b.actionError && b.actionError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.actionError!)));
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.all.isNotEmpty)
                  Text(
                    '${state.all.length} worker${state.all.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppSearchBar(
                  hintText: 'Search by name, ID or job title',
                  onChanged: context.read<WorkersCubit>().search,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _buildList(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, WorkersState state) {
    switch (state.status) {
      case WorkersStatus.initial:
      case WorkersStatus.loading:
        return const LoadingView();
      case WorkersStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'Could not load workers.',
          onRetry: () => context.read<WorkersCubit>().start(),
        );
      case WorkersStatus.ready:
        if (state.all.isEmpty) {
          return const EmptyView(message: 'No workers yet.');
        }
        final workers = state.filtered;
        if (workers.isEmpty) {
          return const EmptyView(message: 'No workers match your search.');
        }
        return context.isMobile
            ? ListView.separated(
                itemCount: workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _WorkerCard(
                  worker: workers[i],
                  readOnly: readOnly,
                  onTap: () => _openDetails(context, workers[i]),
                  onShowQr: () => _showQr(context, workers[i]),
                  onEdit: () => _openForm(context, existingId: workers[i].workerId),
                  onDelete: () =>
                      _confirmDelete(context, workers[i].workerId, workers[i].fullName),
                ),
              )
            : _WorkersTable(
                workers: workers,
                readOnly: readOnly,
                onTap: (w) => _openDetails(context, w),
                onShowQr: (w) => _showQr(context, w),
                onEdit: (w) => _openForm(context, existingId: w.workerId),
                onDelete: (w) => _confirmDelete(context, w.workerId, w.fullName),
              );
    }
  }

  static String _subtitle(Worker w) => '${w.workerId} • ${w.jobTitle.label}';

  void _openDetails(BuildContext context, Worker worker) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkerAttendanceDetailsPage(worker: worker),
        ),
      );

  void _showQr(BuildContext context, Worker worker) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PersonQrPage(
        value: worker.qrCodeId,
        title: worker.fullName,
        subtitle: _subtitle(worker),
      ),
    ),
  );

  Future<void> _openForm(BuildContext context, {String? existingId}) {
    final cubit = context.read<WorkersCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: WorkerFormPage(existingId: existingId),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String name,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete worker',
      message: 'Delete "$name" ($id)? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      await context.read<WorkersCubit>().delete(id);
    }
  }
}

class _WorkerActions extends StatelessWidget {
  const _WorkerActions({
    required this.worker,
    required this.readOnly,
    required this.onShowQr,
    required this.onEdit,
    required this.onDelete,
  });

  final Worker worker;
  final bool readOnly;
  final VoidCallback onShowQr;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Show QR',
          icon: const Icon(Icons.qr_code_2),
          onPressed: onShowQr,
        ),
        if (!readOnly)
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
      ],
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.worker,
    required this.readOnly,
    required this.onTap,
    required this.onShowQr,
    required this.onEdit,
    required this.onDelete,
  });

  final Worker worker;
  final bool readOnly;
  final VoidCallback? onTap;
  final VoidCallback onShowQr;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
        title: Text(worker.fullName),
        subtitle: Text(_WorkersView._subtitle(worker)),
        trailing: _WorkerActions(
          worker: worker,
          readOnly: readOnly,
          onShowQr: onShowQr,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class _WorkersTable extends StatelessWidget {
  const _WorkersTable({
    required this.workers,
    required this.readOnly,
    required this.onTap,
    required this.onShowQr,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Worker> workers;
  final bool readOnly;
  final ValueChanged<Worker> onTap;
  final ValueChanged<Worker> onShowQr;
  final ValueChanged<Worker> onEdit;
  final ValueChanged<Worker> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('STAFF', style: headerStyle)),
                Expanded(flex: 2, child: Text('WORKER ID', style: headerStyle)),
                Expanded(flex: 2, child: Text('JOB TITLE', style: headerStyle)),
                const SizedBox(width: 96),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: workers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final w = workers[i];
                return InkWell(
                  onTap: () => onTap(w),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                child: Icon(Icons.badge_outlined, size: 16),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(w.fullName, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text(w.workerId)),
                        Expanded(flex: 2, child: Text(w.jobTitle.label)),
                        SizedBox(
                          width: 96,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _WorkerActions(
                              worker: w,
                              readOnly: readOnly,
                              onShowQr: () => onShowQr(w),
                              onEdit: () => onEdit(w),
                              onDelete: () => onDelete(w),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
