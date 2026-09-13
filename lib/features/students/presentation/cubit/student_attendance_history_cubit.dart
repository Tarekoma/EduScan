import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/date_key.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/usecases/attendance_usecases.dart';

part 'student_attendance_history_state.dart';

/// Attendance history for a single student, opened from the Students list
/// (manager and supervisor). Same live-stream pattern as
/// `ParentDashboardCubit`'s history feed, just scoped to a student picked
/// from the roster instead of a signed-in parent's linked children.
class StudentAttendanceHistoryCubit
    extends Cubit<StudentAttendanceHistoryState> {
  StudentAttendanceHistoryCubit({
    required WatchPersonAttendance watchPersonAttendance,
  }) : _watchHistory = watchPersonAttendance,
       super(const StudentAttendanceHistoryState());

  final WatchPersonAttendance _watchHistory;
  StreamSubscription<List<AttendanceRecord>>? _sub;

  void start(String studentId) {
    _sub?.cancel();
    emit(state.copyWith(status: StudentAttendanceHistoryStatus.loading));
    _sub =
        _watchHistory(
          personId: studentId,
          personType: PersonType.student,
        ).listen(
          (records) => emit(
            state.copyWith(
              records: records,
              status: StudentAttendanceHistoryStatus.ready,
            ),
          ),
          onError: (Object e, StackTrace s) => emit(
            state.copyWith(
              status: StudentAttendanceHistoryStatus.error,
              errorMessage: ErrorMapper.map(e, s).message,
            ),
          ),
        );
  }

  void setRange(DateTimeRange? range) =>
      emit(state.copyWith(range: range, clearRange: range == null));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
