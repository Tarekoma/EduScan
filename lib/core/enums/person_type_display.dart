import 'package:flutter/widgets.dart';

import 'person_type.dart';
import '../../l10n/app_localizations.dart';

/// Localized display label for [PersonType], so the raw persisted `.value`
/// (e.g. `'student'`) never leaks straight into the UI untranslated.
extension PersonTypeDisplay on PersonType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      PersonType.student => l10n.personTypeStudent,
      PersonType.worker => l10n.personTypeWorker,
    };
  }
}
