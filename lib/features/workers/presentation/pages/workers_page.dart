import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/worker_job_title_display.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/locale_toggle_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../qr/presentation/pages/person_qr_page.dart';
import '../../domain/entities/worker.dart';
import '../cubit/workers_cubit.dart';
import 'worker_attendance_details_page.dart';
import 'worker_form_page.dart';

/// Workers list. [readOnly] hides all mutation actions (security view still
/// gets the QR action); [canDelete] hides only the delete action (supervisor).
class WorkersPage extends StatelessWidget {
  const WorkersPage({super.key, this.readOnly = false, this.canDelete = true});

  final bool readOnly;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WorkersCubit>()..start(),
      child: _WorkersView(readOnly: readOnly, canDelete: canDelete),
    );
  }
}

class _WorkersView extends StatelessWidget {
  const _WorkersView({required this.readOnly, required this.canDelete});

  final bool readOnly;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(
          title: l10n.workersPageTitle,
          subtitle: readOnly
              ? l10n.workersViewSubtitle
              : l10n.workersManageSubtitle,
        ),
        actions: [
          if (context.isMobile) ...[
            const ThemeToggleButton(),
            const LocaleToggleButton(),
            const SignOutButton(),
          ],
        ],
      ),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addWorkerButton),
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
          // The count + search header scrolls away with the content and floats
          // back in on the first scroll up; the list below stays lazy.
          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverFloatingHeader(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.all.isNotEmpty)
                          Text(
                            l10n.workersCount(state.filtered.length),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        AppSearchBar(
                          hintText: l10n.searchWorkersHint,
                          onChanged: context.read<WorkersCubit>().search,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _buildList(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, WorkersState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.status) {
      case WorkersStatus.initial:
      case WorkersStatus.loading:
        return const LoadingView();
      case WorkersStatus.error:
        return ErrorView(
          message: state.errorMessage ?? l10n.workersCouldNotLoad,
          onRetry: () => context.read<WorkersCubit>().start(),
        );
      case WorkersStatus.ready:
        if (state.all.isEmpty) {
          return EmptyView(message: l10n.workersNoneYet);
        }
        final workers = state.filtered;
        if (workers.isEmpty) {
          return EmptyView(message: l10n.workersNoneMatchSearch);
        }
        return context.isMobile
            ? ListView.separated(
                itemCount: workers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _WorkerCard(
                  worker: workers[i],
                  readOnly: readOnly,
                  onTap: () => _openDetails(context, workers[i]),
                  onShowQr: () => _showQr(context, workers[i]),
                  onEdit: () =>
                      _openForm(context, existingId: workers[i].workerId),
                  onDelete: !canDelete
                      ? null
                      : () => _confirmDelete(
                          context,
                          workers[i].workerId,
                          workers[i].fullName,
                        ),
                ),
              )
            : _WorkersTable(
                workers: workers,
                readOnly: readOnly,
                onTap: (w) => _openDetails(context, w),
                onShowQr: (w) => _showQr(context, w),
                onEdit: (w) => _openForm(context, existingId: w.workerId),
                onDelete: !canDelete
                    ? null
                    : (w) => _confirmDelete(context, w.workerId, w.fullName),
              );
    }
  }

  static String _subtitle(BuildContext context, Worker w) =>
      '${w.workerId} • ${w.jobTitle.label(context)}';

  void _openDetails(BuildContext context, Worker worker) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkerAttendanceDetailsPage(worker: worker),
        ),
      );

  void _showQr(BuildContext context, Worker worker) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonQrPage(
            value: worker.qrCodeId,
            title: worker.fullName,
            subtitle: _subtitle(context, worker),
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteWorkerDialogTitle,
      message: l10n.deleteConfirmMessage(name, id),
      confirmLabel: l10n.commonDelete,
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
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.showQrTooltip,
          icon: const Icon(Icons.qr_code_2),
          onPressed: onShowQr,
        ),
        if (!readOnly)
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete?.call(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.commonEdit)),
              if (onDelete != null)
                PopupMenuItem(value: 'delete', child: Text(l10n.commonDelete)),
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
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
        title: Text(worker.fullName),
        subtitle: Text(_WorkersView._subtitle(context, worker)),
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
  final ValueChanged<Worker>? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
                Expanded(
                  flex: 3,
                  child: Text(l10n.tableHeaderStaff, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.tableHeaderWorkerId, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.tableHeaderJobTitle, style: headerStyle),
                ),
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
                                child: Text(
                                  w.fullName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text(w.workerId)),
                        Expanded(
                          flex: 2,
                          child: Text(w.jobTitle.label(context)),
                        ),
                        SizedBox(
                          width: 96,
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _WorkerActions(
                              worker: w,
                              readOnly: readOnly,
                              onShowQr: () => onShowQr(w),
                              onEdit: () => onEdit(w),
                              onDelete: onDelete == null
                                  ? null
                                  : () => onDelete!(w),
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
