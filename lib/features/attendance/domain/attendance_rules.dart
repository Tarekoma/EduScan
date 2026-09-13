import '../../../core/enums/attendance_state.dart';
import '../../../core/errors/app_exception.dart';
import 'entities/attendance_record.dart';

enum AttendanceAction { checkIn, checkOut }

/// The single source of truth for attendance business rules (spec Rules 1–3).
/// Pure and Flutter-free so it is fully unit-testable and never duplicated
/// across screens.
abstract final class AttendanceRules {
  /// Rule 1: a person cannot check in twice while already inside, and cannot
  /// check in again after completing the day.
  static void assertCanCheckIn(AttendanceRecord? current) {
    if (current == null) return;
    switch (current.state) {
      case AttendanceState.absent:
        return;
      case AttendanceState.inside:
        throw const BusinessRuleException(
          'This person is already checked in and currently inside.',
        );
      case AttendanceState.left:
        throw const BusinessRuleException(
          'This person has already completed attendance for today.',
        );
    }
  }

  /// Rule 2: cannot check out without checking in.
  /// Rule 3: cannot check out twice.
  static void assertCanCheckOut(AttendanceRecord? current) {
    if (current == null || current.checkIn == null) {
      throw const BusinessRuleException('This person has not checked in yet.');
    }
    if (current.checkOut != null) {
      throw const BusinessRuleException(
        'This person has already checked out today.',
      );
    }
  }

  /// The action a scan should perform given the person's current day state.
  /// Throws when neither action is valid (already left for the day).
  static AttendanceAction nextAction(AttendanceRecord? current) {
    final state = current?.state ?? AttendanceState.absent;
    return switch (state) {
      AttendanceState.absent => AttendanceAction.checkIn,
      AttendanceState.inside => AttendanceAction.checkOut,
      AttendanceState.left => throw const BusinessRuleException(
        'This person has already completed attendance for today.',
      ),
    };
  }
}
