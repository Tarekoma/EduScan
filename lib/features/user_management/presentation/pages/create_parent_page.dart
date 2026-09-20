import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/user_management_cubit.dart';
import 'student_multi_select_page.dart';

/// Create a parent account. Expects a [UserManagementCubit] from the caller.
class CreateParentPage extends StatefulWidget {
  const CreateParentPage({super.key});

  @override
  State<CreateParentPage> createState() => _CreateParentPageState();
}

class _CreateParentPageState extends State<CreateParentPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  List<String> _studentIds = const [];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickChildren() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => StudentMultiSelectPage(initial: _studentIds),
      ),
    );
    if (result != null) setState(() => _studentIds = result);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.linkAtLeastOneChildSnackbar,
          ),
        ),
      );
      return;
    }
    final ok = await context.read<UserManagementCubit>().createParent(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      phone: _phone.text,
      studentIds: _studentIds,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.newParentAccountTitle,
          style: const TextStyle(fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.fieldFullName,
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(
                  v,
                  message: l10n.validatorRequired(l10n.fieldName),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.fieldEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.fieldTemporaryPassword,
                controller: _password,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.fieldPhone,
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: ListTile(
                  title: Text(l10n.linkedChildrenLabel),
                  subtitle: Text(
                    _studentIds.isEmpty
                        ? l10n.noneSelectedLabel
                        : _studentIds.join(', '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickChildren,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<UserManagementCubit, UserManagementState>(
                buildWhen: (a, b) => a.isMutating != b.isMutating,
                builder: (context, state) => PrimaryButton(
                  label: l10n.createAccountButton,
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
