/// When a missing check-in in an exported report turns into an absence.
///
/// Report-only: nothing here is ever written back to Firestore.
///
/// An attendance day opens at [dayStartHour] (05:00) and people can still
/// check in until [absenceCutoffHour] (18:00). From the cutoff onwards, a
/// person with no check-in for that date is reported as absent. Someone who
/// checked in but has not checked out yet is never absent.
class AttendanceAbsenceRule {
  const AttendanceAbsenceRule({
    this.dayStartHour = 5,
    this.absenceCutoffHour = 18,
  });

  static const standard = AttendanceAbsenceRule();

  final int dayStartHour;
  final int absenceCutoffHour;

  /// Whether [dateKey] (`yyyy-MM-dd`) is closed for check-ins at [now]
  /// (local time). Future dates and the current day before the cutoff are
  /// still open; every earlier day is closed.
  bool isCheckInWindowClosed(String dateKey, DateTime now) {
    final day = DateTime.parse(dateKey);
    final cutoff = DateTime(day.year, day.month, day.day, absenceCutoffHour);
    return !now.isBefore(cutoff);
  }

  /// True when the person should be shown as absent for [dateKey]: the
  /// check-in window is closed and no check-in was recorded.
  bool isAbsent({
    required String dateKey,
    required DateTime? checkIn,
    required DateTime now,
  }) => checkIn == null && isCheckInWindowClosed(dateKey, now);
}
