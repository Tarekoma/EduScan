import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../qr/presentation/pages/person_qr_page.dart';
import '../cubit/students_cubit.dart';
import 'student_form_page.dart';

/// Students list. [readOnly] hides all mutation actions (supervisor view).
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentsCubit>()..start(),
      child: _StudentsView(readOnly: readOnly),
    );
  }
}

class _StudentsView extends StatelessWidget {
  const _StudentsView({required this.readOnly});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add student'),
            ),
      body: BlocConsumer<StudentsCubit, StudentsState>(
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
                hintText: 'Search by name, ID, class or QR',
                onChanged: context.read<StudentsCubit>().search,
              ),
              Expanded(child: _buildList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, StudentsState state) {
    switch (state.status) {
      case StudentsStatus.initial:
      case StudentsStatus.loading:
        return const LoadingView();
      case StudentsStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'Could not load students.',
          onRetry: () => context.read<StudentsCubit>().start(),
        );
      case StudentsStatus.ready:
        if (state.all.isEmpty) {
          return const EmptyView(message: 'No students yet.');
        }
        final students = state.filtered;
        if (students.isEmpty) {
          return const EmptyView(message: 'No students match your search.');
        }
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, i) {
            final s = students[i];
            return ListTile(
              leading: CircleAvatar(child: Text(s.className)),
              title: Text(s.fullName),
              subtitle: Text('${s.studentId} • Class ${s.className}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Show QR',
                    icon: const Icon(Icons.qr_code_2),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonQrPage(
                          value: s.qrCodeId,
                          title: s.fullName,
                          subtitle: '${s.studentId} • Class ${s.className}',
                        ),
                      ),
                    ),
                  ),
                  if (!readOnly)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _openForm(context, existingId: s.studentId);
                        }
                        if (v == 'delete') {
                          _confirmDelete(context, s.studentId, s.fullName);
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
                  : () => _openForm(context, existingId: s.studentId),
            );
          },
        );
    }
  }

  Future<void> _openForm(BuildContext context, {String? existingId}) {
    final cubit = context.read<StudentsCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: StudentFormPage(existingId: existingId),
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
      title: 'Delete student',
      message: 'Delete "$name" ($id)? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      await context.read<StudentsCubit>().delete(id);
    }
  }
}
