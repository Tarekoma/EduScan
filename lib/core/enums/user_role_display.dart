import 'package:flutter/widgets.dart';

import 'user_role.dart';
import '../../l10n/app_localizations.dart';

/// Localized display label for [UserRole], so the raw persisted `.value`
/// (e.g. `'security'`) never leaks straight into the UI untranslated.
extension UserRoleDisplay on UserRole {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      UserRole.security => l10n.userRoleSecurity,
      UserRole.manager => l10n.userRoleManager,
      UserRole.supervisor => l10n.userRoleSupervisor,
      UserRole.parent => l10n.userRoleParent,
    };
  }
}
