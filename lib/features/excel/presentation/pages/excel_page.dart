import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/excel_cubit.dart';

/// Manager screen: export attendance to Excel and import the institution's
/// existing student roster / attendance history.
class ExcelPage extends StatelessWidget {
  const ExcelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExcelCubit>(),
      child: const _ExcelView(),
    );
  }
}

class _ExcelView extends StatefulWidget {
  const _ExcelView();

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Excel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Export'),
              Tab(text: 'Import'),
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
            children: [_exportTab(context, state), _importTab(context, state)],
          ),
        ),
      ),
    );
  }

  Widget _exportTab(BuildContext context, ExcelState state) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Attendance export',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Columns: Date, Person ID, Name, Person Type, Check-in, Check-out, '
          'Recorded by, Recorded at.',
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Date range'),
            subtitle: Text(
              '${TimeFormat.date(_range.start)}  –  ${TimeFormat.date(_range.end)}',
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
          label: 'Export & share',
          icon: Icons.file_download,
          isLoading: state.exporting,
          onPressed: () => context.read<ExcelCubit>().exportAttendance(
            _range.start,
            _range.end,
          ),
        ),
      ],
    );
  }

  Widget _importTab(BuildContext context, ExcelState state) {
    final cubit = context.read<ExcelCubit>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _ImportSection(
          title: 'Students',
          hint: 'Headers: fullName, className',
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
          title: 'Attendance history',
          hint:
              'Headers: date (yyyy-MM-dd), Person ID, Person Type, '
              'Check-in (HH:mm), Check-out (HH:mm)',
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
                label: const Text('Choose .xlsx file'),
              )
            else ...[
              Text('${preview!.ready} row(s) ready to import.'),
              if (preview!.skipped.isNotEmpty)
                Text(
                  'Skipped rows: ${preview!.skipped.join(', ')}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Import ${preview!.ready}',
                      isLoading: busy,
                      onPressed: preview!.ready == 0 ? null : onConfirm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: busy ? null : onClear,
                    child: const Text('Cancel'),
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
