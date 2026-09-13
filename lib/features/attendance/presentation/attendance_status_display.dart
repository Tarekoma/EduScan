import '../../../core/enums/attendance_state.dart';
import '../../../core/widgets/status_badge.dart';

/// Shared mapping from [AttendanceState] to user-facing label + badge tone, so
/// every screen shows attendance status consistently.
extension AttendanceStateDisplay on AttendanceState {
  String get label => switch (this) {
    AttendanceState.absent => 'Absent',
    AttendanceState.inside => 'Present',
    AttendanceState.left => 'Left',
  };

  BadgeTone get tone => switch (this) {
    AttendanceState.absent => BadgeTone.negative,
    AttendanceState.inside => BadgeTone.positive,
    AttendanceState.left => BadgeTone.info,
  };
}
