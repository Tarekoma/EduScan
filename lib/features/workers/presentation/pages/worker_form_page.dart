import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/worker_job_title.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/worker.dart';
import '../../domain/repositories/worker_repository.dart';
import '../cubit/workers_cubit.dart';

class WorkerFormPage extends StatefulWidget {
  const WorkerFormPage({super.key, this.existingId});

  final String? existingId;

  @override
  State<WorkerFormPage> createState() => _WorkerFormPageState();
}

class _WorkerFormPageState extends State<WorkerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late WorkerJobTitle _jobTitle;
  Worker? _existing;

  bool get _isEdit => widget.existingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      for (final w in context.read<WorkersCubit>().state.all) {
        if (w.workerId == widget.existingId) {
          _existing = w;
          break;
        }
      }
    }
    _name = TextEditingController(text: _existing?.fullName ?? '');
    _jobTitle = _existing?.jobTitle ?? WorkerJobTitle.teacher;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<WorkersCubit>();
    final ok = _isEdit
        ? await cubit.update(
            _existing!.copyWith(fullName: _name.text, jobTitle: _jobTitle),
          )
        : await cubit.create(
            WorkerDraft(fullName: _name.text, jobTitle: _jobTitle),
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit worker' : 'Add worker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'ID ${_existing?.workerId ?? widget.existingId}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              AppTextField(
                label: 'Full name',
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, field: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<WorkerJobTitle>(
                initialValue: _jobTitle,
                decoration: const InputDecoration(labelText: 'Job title'),
                items: [
                  for (final title in WorkerJobTitle.values)
                    DropdownMenuItem(value: title, child: Text(title.label)),
                ],
                onChanged: (v) => setState(() => _jobTitle = v ?? _jobTitle),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<WorkersCubit, WorkersState>(
                buildWhen: (a, b) => a.isMutating != b.isMutating,
                builder: (context, state) => PrimaryButton(
                  label: _isEdit ? 'Save changes' : 'Create worker',
                  isLoading: state.isMutating,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
