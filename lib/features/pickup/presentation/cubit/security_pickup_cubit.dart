import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/pickup_status.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/repositories/pickup_repository.dart';
import '../../domain/usecases/pickup_usecases.dart';

part 'security_pickup_state.dart';

/// The security-side live queue of active pickup requests, plus the acknowledge
/// / complete / cancel actions. Real-time alert + sound is layered on in
/// Phase 10.
class SecurityPickupCubit extends Cubit<SecurityPickupState> {
  SecurityPickupCubit({
    required AuthCubit authCubit,
    required WatchActivePickupRequests watchActive,
    required AcknowledgePickup acknowledge,
    required CompletePickup complete,
    required CancelPickup cancel,
  }) : _authCubit = authCubit,
       _watchActive = watchActive,
       _acknowledge = acknowledge,
       _complete = complete,
       _cancel = cancel,
       super(const SecurityPickupState());

  final AuthCubit _authCubit;
  final WatchActivePickupRequests _watchActive;
  final AcknowledgePickup _acknowledge;
  final CompletePickup _complete;
  final CancelPickup _cancel;

  StreamSubscription<List<PickupRequest>>? _sub;

  void start() {
    if (_sub != null) return;
    emit(state.copyWith(status: PickupQueueStatus.loading));
    _sub = _watchActive().listen(
      (requests) => emit(
        state.copyWith(
          status: PickupQueueStatus.ready,
          requests: requests,
          clearError: true,
        ),
      ),
      onError: (Object e, StackTrace s) => emit(
        state.copyWith(
          status: PickupQueueStatus.error,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      ),
    );
  }

  PickupHandler _handler() {
    final user = _authCubit.state.user;
    return PickupHandler(
      uid: user?.uid ?? '',
      canHandle: user?.canHandlePickup ?? false,
    );
  }

  Future<bool> acknowledge(String requestId) =>
      _mutate(() => _acknowledge(requestId: requestId, handler: _handler()));

  Future<bool> complete(String requestId) =>
      _mutate(() => _complete(requestId: requestId, handler: _handler()));

  Future<bool> cancel(String requestId) => _mutate(
    () => _cancel(requestId: requestId, byUid: _handler().uid, isParent: false),
  );

  Future<bool> _mutate(Future<void> Function() action) async {
    emit(state.copyWith(isMutating: true, clearActionError: true));
    try {
      await action();
      emit(state.copyWith(isMutating: false));
      return true;
    } catch (e, s) {
      emit(
        state.copyWith(
          isMutating: false,
          actionError: ErrorMapper.map(e, s).message,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
