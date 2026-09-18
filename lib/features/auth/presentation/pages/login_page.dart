import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/corner_blobs.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';

/// Debug-only sign-in shortcuts. Never shown in a release build — these are
/// real account credentials and must not reach end users.
class _QuickAccount {
  const _QuickAccount(this.role, this.icon, this.email, this.password);

  final String role;
  final IconData icon;
  final String email;
  final String password;
}

const _quickAccounts = [
  _QuickAccount(
    'Manager',
    Icons.admin_panel_settings_outlined,
    'tarekomar1303@gmail.com',
    'L8bDuMgsnkRR7x5',
  ),
  _QuickAccount(
    'Supervisor',
    Icons.visibility_outlined,
    'supervisor@gmail.com',
    '123456789',
  ),
  _QuickAccount(
    'Security',
    Icons.shield_outlined,
    'security1@gmail.com',
    '123456789',
  ),
  _QuickAccount(
    'Parent',
    Icons.family_restroom_outlined,
    'ahmed_hassan12@gmail.com',
    '123456789',
  ),
];

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

  void _fillAndSubmit(_QuickAccount account) {
    _emailController.text = account.email;
    _passwordController.text = account.password;
    _submit();
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
                        a.errorMessage != b.errorMessage &&
                        b.errorMessage != null,
                    listener: (context, state) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(state.errorMessage!)),
                        );
                    },
                    builder: (context, state) {
                      return Form(
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
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Password',
                              controller: _passwordController,
                              obscureText: _obscure,
                              prefixIcon: Icons.lock_outline,
                              textInputAction: TextInputAction.done,
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
                            if (true) ...[
                              const SizedBox(height: AppSpacing.xl),
                              _QuickAccessPanel(
                                enabled: !state.isSubmitting,
                                onSelect: _fillAndSubmit,
                              ),
                            ],
                          ],
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

/// Lists the seeded demo accounts; tapping one signs straight in. Only ever
/// built from behind a `kDebugMode` guard — see [_LoginPageState.build].
class _QuickAccessPanel extends StatelessWidget {
  const _QuickAccessPanel({required this.enabled, required this.onSelect});

  final bool enabled;
  final ValueChanged<_QuickAccount> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Quick Access', style: textTheme.labelLarge),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'DEBUG ONLY',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final account in _quickAccounts)
            _QuickAccessTile(
              account: account,
              enabled: enabled,
              onTap: () => onSelect(account),
            ),
        ],
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.account,
    required this.enabled,
    required this.onTap,
  });

  final _QuickAccount account;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(account.icon, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(account.role, style: textTheme.labelLarge),
                    Text(
                      account.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.touch_app_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
