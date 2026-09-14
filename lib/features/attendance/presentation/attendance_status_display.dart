import 'package:flutter/widgets.dart';

import '../../../core/enums/attendance_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';

/// Shared mapping from [AttendanceState] to user-facing label + badge tone, so
/// every screen shows attendance status consistently.
extension AttendanceStateDisplay on AttendanceState {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      AttendanceState.absent => l10n.attendanceStateAbsent,
      AttendanceState.inside => l10n.attendanceStateInside,
      AttendanceState.left => l10n.attendanceStateLeft,
    };
  }

  BadgeTone get tone => switch (this) {
    AttendanceState.absent => BadgeTone.negative,
    AttendanceState.inside => BadgeTone.positive,
    AttendanceState.left => BadgeTone.info,
  };
}
