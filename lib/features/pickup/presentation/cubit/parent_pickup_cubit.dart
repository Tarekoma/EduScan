import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/repositories/pickup_repository.dart';
import '../../domain/usecases/pickup_usecases.dart';

part 'parent_pickup_state.dart';

/// One child's pickup state for the parent: the live active request plus the
/// request / cancel actions.
class ParentPickupCubit extends Cubit<ParentPickupState> {
  ParentPickupCubit({
    required AuthCubit authCubit,
    required WatchStudentPickup watchStudentPickup,
    required RequestPickup requestPickup,
    required CancelPickup cancelPickup,
  }) : _authCubit = authCubit,
       _watch = watchStudentPickup,
       _request = requestPickup,
       _cancel = cancelPickup,
       super(const ParentPickupState());

  final AuthCubit _authCubit;
  final WatchStudentPickup _watch;
  final RequestPickup _request;
  final CancelPickup _cancel;

  StreamSubscription<PickupRequest?>? _sub;

  void watch(String studentId) {
    _sub?.cancel();
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
    return super.close();
  }
}
