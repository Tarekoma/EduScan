import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/attendance_state.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/usecases/attendance_usecases.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/repositories/pickup_repository.dart';
import '../../domain/usecases/pickup_usecases.dart';

part 'parent_pickup_state.dart';

/// One child's pickup state for the parent: the live active request, today's
/// attendance state (so the UI never even offers the button unless the child
/// is actually checked in), plus the request / cancel actions.
class ParentPickupCubit extends Cubit<ParentPickupState> {
  ParentPickupCubit({
    required AuthCubit authCubit,
    required WatchStudentPickup watchStudentPickup,
    required WatchTodayRecord watchTodayRecord,
    required RequestPickup requestPickup,
    required CancelPickup cancelPickup,
  }) : _authCubit = authCubit,
       _watch = watchStudentPickup,
       _watchTodayRecord = watchTodayRecord,
       _request = requestPickup,
       _cancel = cancelPickup,
       super(const ParentPickupState());

  final AuthCubit _authCubit;
  final WatchStudentPickup _watch;
  final WatchTodayRecord _watchTodayRecord;
  final RequestPickup _request;
  final CancelPickup _cancel;

  StreamSubscription<PickupRequest?>? _sub;
  StreamSubscription<AttendanceRecord?>? _attendanceSub;

  void watch(String studentId) {
    _sub?.cancel();
    _attendanceSub?.cancel();
    emit(const ParentPickupState(status: ParentPickupStatus.loading));
    _sub = _watch(studentId).listen(
      (request) => emit(
        state.copyWith(
          status: ParentPickupStatus.ready,
          active: request,
          clearActive: request == null,
        ),
      ),
      onError: (Object e, StackTrace s) => emit(
        state.copyWith(
          status: ParentPickupStatus.ready,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      ),
    );
    // Non-critical for display: on error this just leaves childState at its
    // fail-safe default (absent), which keeps the request button hidden
    // rather than risking offering it when we can't confirm the child is in.
    _attendanceSub = _watchTodayRecord(
      personId: studentId,
      personType: PersonType.student,
    ).listen(
      (record) => emit(
        state.copyWith(childState: record?.state ?? AttendanceState.absent),
      ),
      onError: (Object _, StackTrace __) {},
    );
  }

  Future<void> request({
    required String studentId,
    required String studentName,
    String? className,
  }) async {
    final user = _authCubit.state.user;
    if (user == null) return;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _request(
        studentId: studentId,
        studentName: studentName,
        className: className,
        requester: PickupRequester(
          parentId: user.uid,
          parentName: user.name,
          linkedStudentIds: user.studentIds,
        ),
      );
      emit(state.copyWith(isSubmitting: false));
    } catch (e, s) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      );
    }
  }

  Future<void> cancel() async {
    final user = _authCubit.state.user;
    final request = state.active;
    if (user == null || request == null) return;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _cancel(
        requestId: request.requestId,
        byUid: user.uid,
        isParent: true,
      );
      emit(state.copyWith(isSubmitting: false));
    } catch (e, s) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _attendanceSub?.cancel();
    return super.close();
  }
}
