import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/corner_blobs.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Stack(
        children: [
          const CornerBlobs(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: BlocConsumer<AuthCubit, AuthState>(
                    listenWhen: (a, b) =>
                        (a.errorMessage != b.errorMessage &&
                            b.errorMessage != null) ||
                        (a.status != b.status &&
                            b.status == AuthStatus.authenticated),
                    listener: (context, state) {
                      if (state.status == AuthStatus.authenticated) {
                        // Only a successful sign-in lets the OS offer to save
                        // (or update) the password — never a failed attempt.
                        TextInput.finishAutofillContext();
                        return;
                      }
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(state.errorMessage!)),
                        );
                    },
                    builder: (context, state) {
                      return AutofillGroup(
                        // Saving is decided explicitly in the listener above.
                        onDisposeAction: AutofillContextAction.cancel,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: ClipOval(
                                  child: Image.asset(
                                    AppConfig.logoAsset,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                AppConfig.appName,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppConfig.tagline.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.2,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to your account to continue',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AppTextField(
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                                enabled: !state.isSubmitting,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                label: 'Password',
                                controller: _passwordController,
                                obscureText: _obscure,
                                prefixIcon: Icons.lock_outline,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) =>
                                    Validators.required(v, field: 'Password'),
                                enabled: !state.isSubmitting,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              PrimaryButton(
                                label: 'Login',
                                trailingIcon: Icons.arrow_forward,
                                isLoading: state.isSubmitting,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
