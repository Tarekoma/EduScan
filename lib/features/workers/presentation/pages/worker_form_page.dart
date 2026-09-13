import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late final TextEditingController _job;
  late final TextEditingController _department;
  late final TextEditingController _phone;
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
    _job = TextEditingController(text: _existing?.job ?? '');
    _department = TextEditingController(text: _existing?.department ?? '');
    _phone = TextEditingController(text: _existing?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _job.dispose();
    _department.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<WorkersCubit>();
    final ok = _isEdit
        ? await cubit.update(
            _existing!.copyWith(
              fullName: _name.text,
              job: _job.text,
              department: _department.text,
              phone: _phone.text,
            ),
          )
        : await cubit.create(
            WorkerDraft(
              fullName: _name.text,
              job: _job.text,
              department: _department.text,
              phone: _phone.text,
            ),
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
              AppTextField(
                label: 'Job',
                controller: _job,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, field: 'Job'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Department (optional)',
                controller: _department,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Phone (optional)',
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? null
                    : Validators.phone(v),
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
