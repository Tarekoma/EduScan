import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../students/presentation/cubit/students_cubit.dart';

/// Pick one or more students. Pops with the selected `List<String>` of ids, or
/// null if cancelled.
class StudentMultiSelectPage extends StatelessWidget {
  const StudentMultiSelectPage({super.key, this.initial = const []});

  final List<String> initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentsCubit>()..start(),
      child: _MultiSelectView(initial: initial.toSet()),
    );
  }
}

class _MultiSelectView extends StatefulWidget {
  const _MultiSelectView({required this.initial});

  final Set<String> initial;

  @override
  State<_MultiSelectView> createState() => _MultiSelectViewState();
}

class _MultiSelectViewState extends State<_MultiSelectView> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select children (${_selected.length})'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selected.toList()),
            child: const Text('Done'),
          ),
        ],
      ),
      body: BlocBuilder<StudentsCubit, StudentsState>(
        builder: (context, state) {
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
                return const EmptyView(message: 'No students to link.');
              }
              // Only offer children with no parent yet — a student already
              // linked elsewhere isn't up for grabs here. The exception is
              // this parent's own already-linked children (in `initial`), so
              // editing an existing parent's links still shows them.
              final students = state.filtered
                  .where(
                    (s) =>
                        s.parentId == null ||
                        widget.initial.contains(s.studentId),
                  )
                  .toList();
              return Column(
                children: [
                  AppSearchBar(
                    hintText: 'Search students',
                    onChanged: context.read<StudentsCubit>().search,
                  ),
                  Expanded(
                    child: students.isEmpty
                        ? EmptyView(
                            message: state.query.isEmpty
                                ? 'All students are already linked to a parent.'
                                : 'No unlinked students match your search.',
                          )
                        : ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final s = students[i];
                              return CheckboxListTile(
                                value: _selected.contains(s.studentId),
                                title: Text(s.fullName),
                                subtitle: Text(
                                  '${s.studentId} • Class ${s.className}',
                                ),
                                onChanged: (checked) => setState(() {
                                  if (checked ?? false) {
                                    _selected.add(s.studentId);
                                  } else {
                                    _selected.remove(s.studentId);
                                  }
                                }),
                              );
                            },
                          ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}
