import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../attendance/domain/attendance_rules.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/face_recognizer.dart';
import '../../domain/usecases/face_usecases.dart';

part 'face_attendance_state.dart';

/// Drives the face-recognition attendance fallback. A camera widget (added
/// with the model — see the feature README) feeds frames to [submitFrame];
/// the result flows through the same check-in / check-out use cases as QR.
class FaceAttendanceCubit extends Cubit<FaceAttendanceState> {
  FaceAttendanceCubit({
    required AuthCubit authCubit,
    required FaceRecognizer recognizer,
    required RecordAttendanceByFace recordByFace,
  }) : _authCubit = authCubit,
       _recognizer = recognizer,
       _record = recordByFace,
       super(
         FaceAttendanceState(
           status: recognizer.isAvailable
               ? FaceStatus.idle
               : FaceStatus.unavailable,
         ),
       );

  final AuthCubit _authCubit;
  final FaceRecognizer _recognizer;
  final RecordAttendanceByFace _record;

  bool get isAvailable => _recognizer.isAvailable;

  Future<void> submitFrame(
    FaceImageInput frame, {
    AttendanceAction? action,
  }) async {
    if (!_recognizer.isAvailable) {
      emit(state.copyWith(status: FaceStatus.unavailable));
      return;
    }
    if (state.status == FaceStatus.processing) return;

    final user = _authCubit.state.user;
    if (user == null || !user.canRecordAttendance) {
      emit(
        state.copyWith(
          status: FaceStatus.failure,
          message: appStrings.attendanceOnlySecurityCanRecord,
        ),
      );
      return;
    }

    emit(state.copyWith(status: FaceStatus.processing, clearMessage: true));
    try {
      final result = await _record(
        frame: frame,
        actor: AttendanceActor(uid: user.uid, canRecord: true),
        action: action,
      );
      emit(state.copyWith(status: FaceStatus.success, result: result));
    } on NoFaceDetected catch (e) {
      emit(state.copyWith(status: FaceStatus.failure, message: e.message));
    } on FaceRecognitionUnavailable {
      emit(state.copyWith(status: FaceStatus.unavailable));
    } on AppException catch (e) {
      emit(state.copyWith(status: FaceStatus.failure, message: e.message));
    } catch (e, s) {
      emit(
        state.copyWith(
          status: FaceStatus.failure,
          message: ErrorMapper.map(e, s).message,
        ),
      );
    }
  }

  void reset() => emit(
    state.copyWith(
      status: _recognizer.isAvailable
          ? FaceStatus.idle
          : FaceStatus.unavailable,
      clearMessage: true,
      clearResult: true,
    ),
  );
}
