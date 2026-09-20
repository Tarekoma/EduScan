part of 'record_attendance_cubit.dart';

enum RecordStatus { idle, submitting, success, failure }

class RecordAttendanceState extends Equatable {
  const RecordAttendanceState({
    this.status = RecordStatus.idle,
    this.record,
    this.action,
    this.person,
    this.recordedByName,
    this.message,
  });

  final RecordStatus status;
  final AttendanceRecord? record;
  final AttendanceAction? action;

  /// Who was just checked in/out (name, class / job title) — so security can
  /// confirm the right person without having to recognise an id.
  final ResolvedPerson? person;

  /// Name of the security user who recorded it.
  final String? recordedByName;
  final String? message;

  bool get isSubmitting => status == RecordStatus.submitting;

  RecordAttendanceState failure(String message) =>
      RecordAttendanceState(status: RecordStatus.failure, message: message);

  @override
  List<Object?> get props => [
    status,
    record,
    action,
    person,
    recordedByName,
    message,
  ];
}
