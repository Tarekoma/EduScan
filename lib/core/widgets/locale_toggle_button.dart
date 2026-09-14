import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../locale/locale_cubit.dart';
import '../../l10n/app_localizations.dart';

/// Language toggle for page headers on mobile, where there is no sidebar
/// (the sidebar carries its own toggle — see [AppShell]).
class LocaleToggleButton extends StatelessWidget {
  const LocaleToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    final isArabic = locale.languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: isArabic ? l10n.localeSwitchToEnglish : l10n.localeSwitchToArabic,
      icon: const Icon(Icons.translate),
      onPressed: () => context.read<LocaleCubit>().toggle(),
    );
  }
}
