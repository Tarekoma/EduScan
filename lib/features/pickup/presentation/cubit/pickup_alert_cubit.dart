import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/pickup_status.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/pickup_alert_player.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/usecases/pickup_usecases.dart';

part 'pickup_alert_state.dart';

/// Session-lifetime watcher that fires the alert sound **once per genuinely new
/// pending request** for the signed-in security user.
///
/// Correctness comes from tracking ids, not stream events:
///  * The first snapshot after (re)subscribing primes silently — existing
///    requests never sound.
///  * `_known` holds every id currently active, so acknowledging a request
///    (pending → acknowledged) does not re-trigger it.
///  * Being a singleton, navigation / page re-open / rebuilds keep `_known`
///    intact, so they cannot replay the sound.
class PickupAlertCubit extends Cubit<PickupAlertState> {
  PickupAlertCubit({
    required AuthCubit authCubit,
    required WatchActivePickupRequests watchActive,
    required PickupAlertPlayer player,
  }) : _authCubit = authCubit,
       _watchActive = watchActive,
       _player = player,
       super(const PickupAlertState()) {
    _authSub = _authCubit.stream.listen(_onAuthChanged);
    _onAuthChanged(_authCubit.state);
  }

  final AuthCubit _authCubit;
  final WatchActivePickupRequests _watchActive;
  final PickupAlertPlayer _player;

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<List<PickupRequest>>? _pickupSub;

  final Set<String> _known = {};
  bool _primed = false;

  void _onAuthChanged(AuthState auth) {
    final isSecurity = auth.user?.canHandlePickup ?? false;
    if (isSecurity && _pickupSub == null) {
      _subscribe();
    } else if (!isSecurity && _pickupSub != null) {
      _unsubscribe();
    }
  }

  void _subscribe() {
    _primed = false;
    _known.clear();
    _pickupSub = _watchActive().listen(_onSnapshot, onError: (_) {});
  }

  void _unsubscribe() {
    _pickupSub?.cancel();
    _pickupSub = null;
    _primed = false;
    _known.clear();
    emit(const PickupAlertState());
  }

  Future<void> _onSnapshot(List<PickupRequest> requests) async {
    final activeIds = requests.map((r) => r.requestId).toSet();
    final pendingIds = requests
        .where((r) => r.status == PickupStatus.pending)
        .map((r) => r.requestId)
        .toSet();

    if (_primed) {
      final fresh = pendingIds.difference(_known);
      if (fresh.isNotEmpty) {
        await _player.playAlert();
        final newest = requests.firstWhere((r) => fresh.contains(r.requestId));
        emit(
          state.copyWith(
            pendingCount: pendingIds.length,
            lastNewRequest: newest,
            unseen: state.unseen + fresh.length,
          ),
        );
      } else {
        emit(state.copyWith(pendingCount: pendingIds.length));
      }
    } else {
      _primed = true;
      emit(state.copyWith(pendingCount: pendingIds.length));
    }

    _known
      ..clear()
      ..addAll(activeIds);
  }

  /// Called by the security UI once it has shown the alert to the user.
  void acknowledgeSeen() => emit(state.copyWith(unseen: 0, clearLastNew: true));

  @override
  Future<void> close() {
    _authSub?.cancel();
    _pickupSub?.cancel();
    _player.dispose();
    return super.close();
  }
}
