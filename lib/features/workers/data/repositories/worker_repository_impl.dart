import '../../domain/entities/worker.dart';
import '../../domain/repositories/worker_repository.dart';
import '../datasources/worker_remote_data_source.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  WorkerRepositoryImpl(this._remote);

  final WorkerRemoteDataSource _remote;

  @override
  Stream<List<Worker>> watchWorkers() => _remote.watchWorkers();

  @override
  Future<Worker> getWorker(String workerId) => _remote.getWorker(workerId);

  @override
  Future<Worker> createWorker(WorkerDraft draft) => _remote.createWorker(draft);

  @override
  Future<Worker> updateWorker(Worker worker) => _remote.updateWorker(worker);

  @override
  Future<void> deleteWorker(String workerId) => _remote.deleteWorker(workerId);
}
