part of 'record_attendance_cubit.dart';

enum RecordStatus { idle, submitting, success, failure }

class RecordAttendanceState extends Equatable {
  const RecordAttendanceState({
    this.status = RecordStatus.idle,
    this.record,
    this.action,
    this.message,
  });

  final RecordStatus status;
  final AttendanceRecord? record;
  final AttendanceAction? action;
  final String? message;

  bool get isSubmitting => status == RecordStatus.submitting;

  RecordAttendanceState failure(String message) =>
      RecordAttendanceState(status: RecordStatus.failure, message: message);

  @override
  List<Object?> get props => [status, record, action, message];
}
