import 'package:flutter/widgets.dart';

import '../di/injection.dart';
import '../locale/locale_cubit.dart';
import '../../l10n/app_localizations.dart';

/// Locale-aware strings for code that has no [BuildContext] — domain rules,
/// data sources, use cases, Cubit fallback messages. Widgets should prefer
/// `AppLocalizations.of(context)!` directly; this exists only because
/// exceptions are built deep in layers that never see a [BuildContext].
///
/// Resolves against the live [LocaleCubit] state (a synchronous read), so a
/// message built after the user switches language is in the new language —
/// without threading [BuildContext] through the domain layer. Falls back to
/// English when [LocaleCubit] isn't registered — plain `flutter test` unit
/// tests for domain rules/use cases never call `configureDependencies()`, so
/// this keeps them running without wiring up the full DI container.
///
/// Named `appStrings` (not the common single-letter `s`) because `s` is
/// already used throughout this codebase as a local variable name for
/// "student" — see e.g. `resolve_person.dart`.
AppLocalizations get appStrings => lookupAppLocalizations(
  sl.isRegistered<LocaleCubit>() ? sl<LocaleCubit>().state : const Locale('en'),
);
