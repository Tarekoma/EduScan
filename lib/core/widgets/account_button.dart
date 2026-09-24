import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../enums/user_role_display.dart';
import '../locale/locale_cubit.dart';
import '../theme/app_theme.dart';
import '../theme/theme_cubit.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../l10n/app_localizations.dart';
import 'edit_name_dialog.dart';

/// Avatar button for page headers on mobile, where there is no sidebar. Opens
/// a sheet with the signed-in user's name and role, the language and theme
/// switches, and sign out (the sidebar footer carries the same on
/// tablet/desktop — see [AppShell]).
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) return const SizedBox.shrink();
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: IconButton(
        tooltip: AppLocalizations.of(context)!.accountMenuTooltip,
        onPressed: () => _open(context),
        icon: CircleAvatar(
          radius: 20,
          child: Text(initial, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    // The sheet lives in its own route, so hand it the cubits explicitly.
    final auth = context.read<AuthCubit>();
    final theme = context.read<ThemeCubit>();
    final locale = context.read<LocaleCubit>();
    final action = await showModalBottomSheet<_AccountAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: theme),
          BlocProvider.value(value: locale),
        ],
        child: const _AccountSheet(),
      ),
    );
    // Wait for the sheet's closing animation before opening the dialog on
    // this (still-mounted) outer context.
    if (action == _AccountAction.editName && context.mounted) {
      await showEditNameDialog(context);
    }
  }
}

enum _AccountAction { editName }

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthCubit>().state.user;
    final isArabic = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final mode = context.watch<ThemeCubit>().state;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user != null)
            ListTile(
              leading: CircleAvatar(
                radius: 22,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              title: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              subtitle: Text(user.role.label(context)),
              trailing: IconButton(
                tooltip: l10n.accountEditName,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    Navigator.of(context).pop(_AccountAction.editName),
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(
              isArabic ? l10n.localeSwitchToEnglish : l10n.localeSwitchToArabic,
            ),
            onTap: () => context.read<LocaleCubit>().toggle(),
          ),
          ListTile(
            leading: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            title: Text(
              isDark ? l10n.themeSwitchToLight : l10n.themeSwitchToDark,
            ),
            onTap: () => context.read<ThemeCubit>().toggle(platformBrightness),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text(
              l10n.commonSignOut,
              style: TextStyle(color: scheme.error),
            ),
            onTap: () {
              final auth = context.read<AuthCubit>();
              Navigator.of(context).pop();
              auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
