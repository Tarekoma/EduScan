part of 'face_attendance_cubit.dart';

enum FaceStatus { unavailable, idle, processing, success, failure }

class FaceAttendanceState extends Equatable {
  const FaceAttendanceState({
    this.status = FaceStatus.idle,
    this.result,
    this.message,
  });

  final FaceStatus status;
  final FaceAttendanceResult? result;
  final String? message;

  FaceAttendanceState copyWith({
    FaceStatus? status,
    FaceAttendanceResult? result,
    bool clearResult = false,
    String? message,
    bool clearMessage = false,
  }) {
    return FaceAttendanceState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, result, message];
}
