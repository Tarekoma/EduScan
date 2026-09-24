import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../errors/app_exception.dart';
import '../utils/validators.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../l10n/app_localizations.dart';

/// Opens a dialog letting the signed-in user rename themselves. Available to
/// every role (manager, supervisor, security, parent) from the account
/// menu/sidebar footer.
Future<void> showEditNameDialog(BuildContext context) {
  final auth = context.read<AuthCubit>();
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(value: auth, child: const _EditNameDialog()),
  );
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog();

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<AuthCubit>().state.user?.name ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthCubit>().updateName(_controller.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e is AppException
          ? e.message
          : AppLocalizations.of(context)!.errorSomethingWentWrong;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.accountEditNameTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          enabled: !_isSubmitting,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: l10n.fieldName),
          validator: (value) => Validators.required(
            value,
            message: l10n.validatorRequired(l10n.fieldName),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}
