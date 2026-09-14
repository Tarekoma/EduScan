import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../l10n/app_localizations.dart';

/// Sign-out icon action for page headers on mobile, where there is no
/// persistent sidebar (the sidebar's own footer already carries a sign-out
/// control on tablet/desktop — see [AppShell]).
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.commonSignOut,
      icon: const Icon(Icons.logout),
      onPressed: () => context.read<AuthCubit>().signOut(),
    );
  }
}
