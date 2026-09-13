import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';
import '../cubit/students_cubit.dart';

/// Create (when [existingId] is null) or edit a student. Expects a
/// [StudentsCubit] provided by the caller.
class StudentFormPage extends StatefulWidget {
  const StudentFormPage({super.key, this.existingId});

  final String? existingId;

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _className;
  Student? _existing;

  bool get _isEdit => widget.existingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      for (final s in context.read<StudentsCubit>().state.all) {
        if (s.studentId == widget.existingId) {
          _existing = s;
          break;
        }
      }
    }
    _name = TextEditingController(text: _existing?.fullName ?? '');
    _className = TextEditingController(text: _existing?.className ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _className.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<StudentsCubit>();
    final ok = _isEdit
        ? await cubit.update(
            _existing!.copyWith(
              fullName: _name.text,
              className: _className.text,
            ),
          )
        : await cubit.create(
            StudentDraft(fullName: _name.text, className: _className.text),
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit student' : 'Add student')),
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
                    'ID ${_existing?.studentId ?? widget.existingId}',
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
                label: 'Class',
                controller: _className,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => Validators.required(v, field: 'Class'),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<StudentsCubit, StudentsState>(
                buildWhen: (a, b) => a.isMutating != b.isMutating,
                builder: (context, state) => PrimaryButton(
                  label: _isEdit ? 'Save changes' : 'Create student',
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
