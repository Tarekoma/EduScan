import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/worker.dart';
import '../../domain/repositories/worker_repository.dart';
import '../../domain/usecases/worker_usecases.dart';

part 'workers_state.dart';

class WorkersCubit extends Cubit<WorkersState> {
  WorkersCubit({
    required WatchWorkers watchWorkers,
    required CreateWorker createWorker,
    required UpdateWorker updateWorker,
    required DeleteWorker deleteWorker,
  }) : _watchWorkers = watchWorkers,
       _createWorker = createWorker,
       _updateWorker = updateWorker,
       _deleteWorker = deleteWorker,
       super(const WorkersState());

  final WatchWorkers _watchWorkers;
  final CreateWorker _createWorker;
  final UpdateWorker _updateWorker;
  final DeleteWorker _deleteWorker;

  StreamSubscription<List<Worker>>? _subscription;

  void start() {
    if (_subscription != null) return;
    emit(state.copyWith(status: WorkersStatus.loading));
    _subscription = _watchWorkers().listen(
      (workers) => emit(
        state.copyWith(
          status: WorkersStatus.ready,
          all: workers,
          clearError: true,
        ),
      ),
      onError: (Object e, StackTrace s) => emit(
        state.copyWith(
          status: WorkersStatus.error,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      ),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  Future<bool> create(WorkerDraft draft) => _mutate(() => _createWorker(draft));

  Future<bool> update(Worker worker) => _mutate(() => _updateWorker(worker));

  Future<bool> delete(String workerId) =>
      _mutate(() => _deleteWorker(workerId));

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
    _subscription?.cancel();
    return super.close();
  }
}
