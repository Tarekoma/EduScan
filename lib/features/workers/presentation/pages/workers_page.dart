import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/services/phone_launcher.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../qr/presentation/pages/person_qr_page.dart';
import '../cubit/workers_cubit.dart';
import 'worker_form_page.dart';

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
      appBar: AppBar(title: const Text('Workers')),
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
          return Column(
            children: [
              AppSearchBar(
                hintText: 'Search by name, ID, job or department',
                onChanged: context.read<WorkersCubit>().search,
              ),
              Expanded(child: _buildList(context, state)),
            ],
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
        return ListView.builder(
          itemCount: workers.length,
          itemBuilder: (context, i) {
            final w = workers[i];
            final subtitle = [
              w.workerId,
              w.job,
              if (w.department != null) w.department!,
            ].join(' • ');
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
              title: Text(w.fullName),
              subtitle: Text(subtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (w.phone != null && w.phone!.isNotEmpty)
                    IconButton(
                      tooltip: 'Call ${w.phone}',
                      icon: const Icon(Icons.call),
                      onPressed: () => dialPhone(context, w.phone!),
                    ),
                  IconButton(
                    tooltip: 'Show QR',
                    icon: const Icon(Icons.qr_code_2),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonQrPage(
                          value: w.qrCodeId,
                          title: w.fullName,
                          subtitle: subtitle,
                        ),
                      ),
                    ),
                  ),
                  if (!readOnly)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _openForm(context, existingId: w.workerId);
                        }
                        if (v == 'delete') {
                          _confirmDelete(context, w.workerId, w.fullName);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              onTap: readOnly
                  ? null
                  : () => _openForm(context, existingId: w.workerId),
            );
          },
        );
    }
  }

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
