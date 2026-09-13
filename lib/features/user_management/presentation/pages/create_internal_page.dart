import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/user_management_cubit.dart';

/// Create a security or supervisor account. Expects a [UserManagementCubit].
class CreateInternalPage extends StatefulWidget {
  const CreateInternalPage({super.key, required this.role})
    : assert(role != UserRole.parent && role != UserRole.manager);

  final UserRole role;

  @override
  State<CreateInternalPage> createState() => _CreateInternalPageState();
}

class _CreateInternalPageState extends State<CreateInternalPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<UserManagementCubit>().createInternal(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: widget.role,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New ${widget.role.value} account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Temporary password',
                controller: _password,
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<UserManagementCubit, UserManagementState>(
                buildWhen: (a, b) => a.isMutating != b.isMutating,
                builder: (context, state) => PrimaryButton(
                  label: 'Create account',
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
