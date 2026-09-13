import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/date_key.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/usecases/attendance_usecases.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/usecases/get_linked_children.dart';

part 'parent_dashboard_state.dart';

/// Read-only dashboard for a parent: their linked children, the selected
/// child's status for today, and that child's attendance history.
class ParentDashboardCubit extends Cubit<ParentDashboardState> {
  ParentDashboardCubit({
    required AuthCubit authCubit,
    required GetLinkedChildren getLinkedChildren,
    required WatchTodayRecord watchTodayRecord,
    required WatchPersonAttendance watchPersonAttendance,
  }) : _authCubit = authCubit,
       _getLinkedChildren = getLinkedChildren,
       _watchToday = watchTodayRecord,
       _watchHistory = watchPersonAttendance,
       super(const ParentDashboardState());

  final AuthCubit _authCubit;
  final GetLinkedChildren _getLinkedChildren;
  final WatchTodayRecord _watchToday;
  final WatchPersonAttendance _watchHistory;

  StreamSubscription<AttendanceRecord?>? _todaySub;
  StreamSubscription<List<AttendanceRecord>>? _historySub;

  Future<void> start() async {
    final ids = _authCubit.state.user?.studentIds ?? const [];
    if (ids.isEmpty) {
      emit(state.copyWith(status: ParentStatus.empty));
      return;
    }
    emit(state.copyWith(status: ParentStatus.loading));
    try {
      final children = await _getLinkedChildren(ids);
      if (children.isEmpty) {
        emit(state.copyWith(status: ParentStatus.empty));
        return;
      }
      emit(state.copyWith(status: ParentStatus.ready, children: children));
      selectChild(children.first.studentId);
    } catch (e, s) {
      emit(
        state.copyWith(
          status: ParentStatus.error,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      );
    }
  }

  void selectChild(String studentId) {
    if (studentId == state.selectedId) return;
    _todaySub?.cancel();
    _historySub?.cancel();
    emit(
      state.copyWith(
        selectedId: studentId,
        clearToday: true,
        history: const [],
        historyLoading: true,
      ),
    );

    _todaySub = _watchToday(personId: studentId, personType: PersonType.student)
        .listen(
          (record) => emit(state.copyWith(today: record, todayLoaded: true)),
          onError: (Object e, StackTrace s) => emit(
            state.copyWith(
              todayLoaded: true,
              errorMessage: ErrorMapper.map(e, s).message,
            ),
          ),
        );

    _historySub =
        _watchHistory(
          personId: studentId,
          personType: PersonType.student,
        ).listen(
          (records) =>
              emit(state.copyWith(history: records, historyLoading: false)),
          onError: (Object e, StackTrace s) => emit(
            state.copyWith(
              historyLoading: false,
              errorMessage: ErrorMapper.map(e, s).message,
            ),
          ),
        );
  }

  void setHistoryRange(DateTimeRange? range) =>
      emit(state.copyWith(historyRange: range, clearRange: range == null));

  @override
  Future<void> close() {
    _todaySub?.cancel();
    _historySub?.cancel();
    return super.close();
  }
}
