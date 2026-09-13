/// Derived state of a person for a given day, based on their attendance record.
enum AttendanceState {
  /// No record for the day.
  absent,

  /// Checked in, not yet checked out — currently inside.
  inside,

  /// Checked in and checked out.
  left;

  bool get isInside => this == AttendanceState.inside;
}
