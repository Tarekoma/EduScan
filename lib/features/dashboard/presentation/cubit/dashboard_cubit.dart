import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/person_type.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/date_key.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/domain/usecases/student_usecases.dart';
import '../../../user_management/domain/usecases/user_admin_usecases.dart';
import '../../../workers/domain/entities/worker.dart';
import '../../../workers/domain/usecases/worker_usecases.dart';
import '../../domain/attendance_breakdown.dart';
import '../../domain/attendance_report_stats.dart';
import '../../domain/dashboard_stats.dart';

part 'dashboard_state.dart';

/// Composes live students / workers / attendance / recorder-name streams into a
/// single dashboard view for managers and supervisors.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required WatchStudents watchStudents,
    required WatchWorkers watchWorkers,
    required AttendanceRepository attendanceRepository,
    required WatchUsersByRole watchUsersByRole,
  }) : _watchStudents = watchStudents,
       _watchWorkers = watchWorkers,
       _attendance = attendanceRepository,
       _watchSecurity = watchUsersByRole,
       super(
         DashboardState(
           date: DateTime.now(),
           reportFrom: DateTime.now().subtract(const Duration(days: 6)),
           reportTo: DateTime.now(),
         ),
       );

  final WatchStudents _watchStudents;
  final WatchWorkers _watchWorkers;
  final AttendanceRepository _attendance;
  final WatchUsersByRole _watchSecurity;

  StreamSubscription<List<Student>>? _studentsSub;
  StreamSubscription<List<Worker>>? _workersSub;
  StreamSubscription<List<AttendanceRecord>>? _attendanceSub;
  StreamSubscription<List<AppUser>>? _securitySub;
  int _reportRequestId = 0;

  void start() {
    if (_studentsSub != null) return;
    emit(state.copyWith(status: DashboardStatus.loading));

    _studentsSub = _watchStudents().listen(
      (s) => emit(state.copyWith(students: s, status: DashboardStatus.ready)),
      onError: _onError,
    );
    _workersSub = _watchWorkers().listen(
      (w) => emit(state.copyWith(workers: w)),
      onError: _onError,
    );
    _securitySub = _watchSecurity(UserRole.security).listen(
      (users) => emit(
        state.copyWith(recorderNames: {for (final u in users) u.uid: u.name}),
      ),
      onError: (_, __) {},
    );
    _subscribeAttendance();
    _loadReport();
  }

  void _subscribeAttendance() {
    _attendanceSub?.cancel();
    emit(state.copyWith(attendanceLoading: true));
    _attendanceSub = _attendance
        .watchByDate(DateKey.of(state.date))
        .listen(
          (records) => emit(
            state.copyWith(
              records: records,
              attendanceLoading: false,
              status: DashboardStatus.ready,
            ),
          ),
          onError: _onError,
        );
  }

  void setDate(DateTime date) {
    if (DateKey.of(date) == DateKey.of(state.date)) return;
    // A different day is a different list: start again from the first page.
    emit(
      state.copyWith(
        date: date,
        activityLimit: DashboardState.activityFirstPage,
      ),
    );
    _subscribeAttendance();
  }

  void setTypeFilter(PersonType? type) => emit(
    state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
      activityLimit: DashboardState.activityFirstPage,
    ),
  );

  /// "View more" on the recent-activity list: reveal another page of rows.
  void showMoreActivity() => emit(
    state.copyWith(
      activityLimit: state.activityLimit + DashboardState.activityPageSize,
    ),
  );

  /// Loads the report section (rate-over-time / class comparison) for a new date range. Uses a one-shot [AttendanceRepository.getInRange]
  /// fetch — historical reporting doesn't need a live subscription.
  Future<void> setReportRange(DateTime from, DateTime to) async {
    emit(state.copyWith(reportFrom: from, reportTo: to));
    await _loadReport();
  }

  Future<void> _loadReport() async {
    final requestId = ++_reportRequestId;
    emit(state.copyWith(reportStatus: DashboardReportStatus.loading));
    try {
      final records = await _attendance.getInRange(
        fromDate: DateKey.of(state.reportFrom),
        toDate: DateKey.of(state.reportTo),
      );
      if (requestId != _reportRequestId) return; // superseded by a newer pick
      emit(
        state.copyWith(
          reportRecords: records,
          reportStatus: DashboardReportStatus.ready,
        ),
      );
    } catch (e, s) {
      if (requestId != _reportRequestId) return;
      emit(
        state.copyWith(
          reportStatus: DashboardReportStatus.error,
          reportErrorMessage: ErrorMapper.map(e, s).message,
        ),
      );
    }
  }

  void _onError(Object e, StackTrace s) => emit(
    state.copyWith(
      status: DashboardStatus.error,
      errorMessage: ErrorMapper.map(e, s).message,
    ),
  );

  @override
  Future<void> close() {
    _studentsSub?.cancel();
    _workersSub?.cancel();
    _attendanceSub?.cancel();
    _securitySub?.cancel();
    return super.close();
  }
}
