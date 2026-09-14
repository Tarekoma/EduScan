import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/theme_cubit.dart';
import '../../l10n/app_localizations.dart';

/// Theme toggle for page headers on mobile, where there is no sidebar
/// (the sidebar carries its own toggle on tablet/desktop — see [AppShell]).
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: isDark ? l10n.themeSwitchToLight : l10n.themeSwitchToDark,
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
      onPressed: () => context.read<ThemeCubit>().toggle(platformBrightness),
    );
  }
}
