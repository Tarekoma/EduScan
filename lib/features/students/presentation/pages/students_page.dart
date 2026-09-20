import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/class_initials.dart';
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
import '../../domain/entities/student.dart';
import '../cubit/students_cubit.dart';
import 'student_attendance_details_page.dart';
import 'student_form_page.dart';

/// Students list. [readOnly] hides all mutation actions (security view);
/// [canDelete] hides only the delete action (supervisor view).
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key, this.readOnly = false, this.canDelete = true});

  final bool readOnly;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentsCubit>()..start(),
      child: _StudentsView(readOnly: readOnly, canDelete: canDelete),
    );
  }
}

class _StudentsView extends StatelessWidget {
  const _StudentsView({required this.readOnly, required this.canDelete});

  final bool readOnly;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(
          title: l10n.studentsPageTitle,
          subtitle: readOnly
              ? l10n.studentsViewSubtitle
              : l10n.studentsManageSubtitle,
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
              label: Text(l10n.addStudentButton),
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
          // The count + search/filter header scrolls away with the content and
          // floats back in on the first scroll up; the list below stays lazy.
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
                            l10n.studentsCount(state.filtered.length),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        _FilterRow(state: state),
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

  Widget _buildList(BuildContext context, StudentsState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.status) {
      case StudentsStatus.initial:
      case StudentsStatus.loading:
        return const LoadingView();
      case StudentsStatus.error:
        return ErrorView(
          message: state.errorMessage ?? l10n.studentsCouldNotLoad,
          onRetry: () => context.read<StudentsCubit>().start(),
        );
      case StudentsStatus.ready:
        if (state.all.isEmpty) {
          return EmptyView(message: l10n.studentsNoneYet);
        }
        final students = state.filtered;
        if (students.isEmpty) {
          return EmptyView(message: l10n.studentsNoneMatchSearch);
        }
        return context.isMobile
            ? ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _StudentCard(
                  student: students[i],
                  readOnly: readOnly,
                  onTap: () => _openDetails(context, students[i]),
                  onShowQr: () => _showQr(context, students[i]),
                  onEdit: () =>
                      _openForm(context, existingId: students[i].studentId),
                  onDelete: !canDelete
                      ? null
                      : () => _confirmDelete(
                          context,
                          students[i].studentId,
                          students[i].fullName,
                        ),
                ),
              )
            : _StudentsTable(
                students: students,
                readOnly: readOnly,
                onTap: (s) => _openDetails(context, s),
                onShowQr: (s) => _showQr(context, s),
                onEdit: (s) => _openForm(context, existingId: s.studentId),
                onDelete: !canDelete
                    ? null
                    : (s) => _confirmDelete(context, s.studentId, s.fullName),
              );
    }
  }

  void _openDetails(BuildContext context, Student student) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentAttendanceDetailsPage(student: student),
        ),
      );

  void _showQr(BuildContext context, Student student) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonQrPage(
          value: student.qrCodeId,
          title: student.fullName,
          subtitle: l10n.personIdTypeLabel(
            student.studentId,
            l10n.personClassLabel(student.className),
          ),
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteStudentDialogTitle,
      message: l10n.deleteConfirmMessage(name, id),
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (ok && context.mounted) {
      await context.read<StudentsCubit>().delete(id);
    }
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final StudentsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StudentsCubit>();
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: AppSearchBar(
            hintText: l10n.searchStudentsHint,
            onChanged: cubit.search,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        DropdownMenu<String?>(
          initialSelection: state.classFilter,
          hintText: l10n.allClassesLabel,
          onSelected: cubit.filterByClass,
          dropdownMenuEntries: [
            DropdownMenuEntry(value: null, label: l10n.allClassesLabel),
            for (final c in state.classNames)
              DropdownMenuEntry(value: c, label: c),
          ],
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.readOnly,
    required this.onTap,
    required this.onShowQr,
    required this.onEdit,
    required this.onDelete,
  });

  final Student student;
  final bool readOnly;
  final VoidCallback? onTap;
  final VoidCallback onShowQr;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(classInitials(student.className))),
        title: Text(student.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.studentId),
            Text(l10n.personClassLabel(student.className)),
          ],
        ),
        trailing: Row(
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
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.commonDelete),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentsTable extends StatelessWidget {
  const _StudentsTable({
    required this.students,
    required this.readOnly,
    required this.onTap,
    required this.onShowQr,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Student> students;
  final bool readOnly;
  final ValueChanged<Student> onTap;
  final ValueChanged<Student> onShowQr;
  final ValueChanged<Student> onEdit;
  final ValueChanged<Student>? onDelete;

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
                  child: Text(l10n.tableHeaderStudent, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.tableHeaderStudentId, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.tableHeaderClass, style: headerStyle),
                ),
                const SizedBox(width: 96),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = students[i];
                return InkWell(
                  onTap: () => onTap(s),
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
                              CircleAvatar(
                                radius: 16,
                                child: Text(
                                  s.className.isNotEmpty ? s.className[0] : '?',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  s.fullName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text(s.studentId)),
                        Expanded(flex: 2, child: Text(s.className)),
                        SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: l10n.showQrTooltip,
                                icon: const Icon(Icons.qr_code_2),
                                onPressed: () => onShowQr(s),
                              ),
                              if (!readOnly)
                                PopupMenuButton<String>(
                                  onSelected: (v) => v == 'edit'
                                      ? onEdit(s)
                                      : onDelete?.call(s),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(l10n.commonEdit),
                                    ),
                                    if (onDelete != null)
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(l10n.commonDelete),
                                      ),
                                  ],
                                ),
                            ],
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
