import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/date_key.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/usecases/attendance_usecases.dart';

part 'worker_attendance_history_state.dart';

/// Attendance history for a single worker, opened from the Workers list
/// (manager, supervisor and security alike). Same live-stream pattern as
/// `StudentAttendanceHistoryCubit`, just scoped to [PersonType.worker].
class WorkerAttendanceHistoryCubit
    extends Cubit<WorkerAttendanceHistoryState> {
  WorkerAttendanceHistoryCubit({
    required WatchPersonAttendance watchPersonAttendance,
  }) : _watchHistory = watchPersonAttendance,
       super(const WorkerAttendanceHistoryState());

  final WatchPersonAttendance _watchHistory;
  StreamSubscription<List<AttendanceRecord>>? _sub;

  void start(String workerId) {
    _sub?.cancel();
    emit(state.copyWith(status: WorkerAttendanceHistoryStatus.loading));
    _sub =
        _watchHistory(
          personId: workerId,
          personType: PersonType.worker,
        ).listen(
          (records) => emit(
            state.copyWith(
              records: records,
              status: WorkerAttendanceHistoryStatus.ready,
            ),
          ),
          onError: (Object e, StackTrace s) => emit(
            state.copyWith(
              status: WorkerAttendanceHistoryStatus.error,
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
