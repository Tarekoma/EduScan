import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/locale_toggle_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/excel_cubit.dart';

/// Export attendance to Excel and import the institution's existing student
/// roster / attendance history (manager and supervisor). With [exportOnly]
/// (security) the import tab is not shown at all.
class ExcelPage extends StatelessWidget {
  const ExcelPage({super.key, this.exportOnly = false});

  final bool exportOnly;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExcelCubit>(),
      child: _ExcelView(exportOnly: exportOnly),
    );
  }
}

class _ExcelView extends StatefulWidget {
  const _ExcelView({required this.exportOnly});

  final bool exportOnly;

  @override
  State<_ExcelView> createState() => _ExcelViewState();
}

class _ExcelViewState extends State<_ExcelView> {
  late DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: widget.exportOnly ? 1 : 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: PageHeader(
            title: l10n.excelTitle,
            subtitle: l10n.excelSubtitle,
          ),
          actions: [
            if (context.isMobile) ...[
              const ThemeToggleButton(),
              const LocaleToggleButton(),
              const SignOutButton(),
            ],
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.exportTabLabel),
              if (!widget.exportOnly) Tab(text: l10n.importTabLabel),
            ],
          ),
        ),
        body: BlocConsumer<ExcelCubit, ExcelState>(
          listener: (context, state) {
            final msg = state.error ?? state.info;
            if (msg != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(msg)));
            }
          },
          builder: (context, state) => TabBarView(
            children: [
              _exportTab(context, state),
              if (!widget.exportOnly) _importTab(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportTab(BuildContext context, ExcelState state) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.excelAttendanceExportTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.excelExportColumnsHint),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(l10n.dateRangeLabel),
            subtitle: Text(
              l10n.dateRangeValue(
                TimeFormat.date(_range.start),
                TimeFormat.date(_range.end),
              ),
            ),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: now,
                initialDateRange: _range,
              );
              if (picked != null) setState(() => _range = picked);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.exportStudentsButton,
          icon: Icons.file_download,
          isLoading: state.exportingType == PersonType.student,
          onPressed: state.busy
              ? null
              : () => context.read<ExcelCubit>().exportStudentAttendance(
                  _range.start,
                  _range.end,
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: l10n.exportWorkersButton,
          icon: Icons.file_download,
          isLoading: state.exportingType == PersonType.worker,
          onPressed: state.busy
              ? null
              : () => context.read<ExcelCubit>().exportWorkerAttendance(
                  _range.start,
                  _range.end,
                ),
        ),
      ],
    );
  }

  Widget _importTab(BuildContext context, ExcelState state) {
    final cubit = context.read<ExcelCubit>();
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _ImportSection(
          title: l10n.filterStudents,
          hint: l10n.importStudentsHint,
          busy: state.busy,
          preview: state.studentPreview == null
              ? null
              : _PreviewInfo(
                  ready: state.studentPreview!.rows.length,
                  skipped: state.studentPreview!.skipped,
                ),
          onPick: cubit.pickStudentFile,
          onConfirm: cubit.confirmStudentImport,
          onClear: cubit.clearPreview,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ImportSection(
          title: l10n.filterWorkers,
          hint: l10n.importWorkersHint,
          busy: state.busy,
          preview: state.workerPreview == null
              ? null
              : _PreviewInfo(
                  ready: state.workerPreview!.rows.length,
                  skipped: state.workerPreview!.skipped,
                ),
          onPick: cubit.pickWorkerFile,
          onConfirm: cubit.confirmWorkerImport,
          onClear: cubit.clearPreview,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ImportSection(
          title: l10n.importAttendanceTitle,
          hint: l10n.importAttendanceHint,
          busy: state.busy,
          preview: state.attendancePreview == null
              ? null
              : _PreviewInfo(
                  ready: state.attendancePreview!.rows.length,
                  skipped: state.attendancePreview!.skipped,
                ),
          onPick: cubit.pickAttendanceFile,
          onConfirm: cubit.confirmAttendanceImport,
          onClear: cubit.clearPreview,
        ),
      ],
    );
  }
}

class _PreviewInfo {
  const _PreviewInfo({required this.ready, required this.skipped});
  final int ready;
  final List<int> skipped;
}

class _ImportSection extends StatelessWidget {
  const _ImportSection({
    required this.title,
    required this.hint,
    required this.busy,
    required this.preview,
    required this.onPick,
    required this.onConfirm,
    required this.onClear,
  });

  final String title;
  final String hint;
  final bool busy;
  final _PreviewInfo? preview;
  final VoidCallback onPick;
  final VoidCallback onConfirm;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            if (preview == null)
              OutlinedButton.icon(
                onPressed: busy ? null : onPick,
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.chooseXlsxFileButton),
              )
            else ...[
              Text(l10n.rowsReadyToImport(preview!.ready)),
              if (preview!.skipped.isNotEmpty)
                Text(
                  l10n.skippedRowsLabel(preview!.skipped.join(', ')),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.importButton(preview!.ready),
                      isLoading: busy,
                      onPressed: preview!.ready == 0 ? null : onConfirm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: busy ? null : onClear,
                    child: Text(l10n.commonCancel),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
