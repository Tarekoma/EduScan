import 'package:flutter/widgets.dart';

import 'worker_job_title.dart';
import '../l10n/app_strings.dart';
import '../../l10n/app_localizations.dart';

/// Localized display label for [WorkerJobTitle].
extension WorkerJobTitleDisplay on WorkerJobTitle {
  String label(BuildContext context) => _label(AppLocalizations.of(context)!);

  /// For non-widget code (search filtering, domain-layer display subtitles)
  /// that has no [BuildContext] — see [appStrings].
  String get plainLabel => _label(appStrings);

  String _label(AppLocalizations l10n) => switch (this) {
    WorkerJobTitle.teacher => l10n.workerJobTitleTeacher,
    WorkerJobTitle.administrativeStaff => l10n.workerJobTitleAdministrativeStaff,
    WorkerJobTitle.other => l10n.workerJobTitleOther,
  };
}
