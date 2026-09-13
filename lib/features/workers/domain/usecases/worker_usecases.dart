import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../entities/worker.dart';
import '../repositories/worker_repository.dart';

class WatchWorkers {
  const WatchWorkers(this._repo);
  final WorkerRepository _repo;
  Stream<List<Worker>> call() => _repo.watchWorkers();
}

class GetWorker {
  const GetWorker(this._repo);
  final WorkerRepository _repo;
  Future<Worker> call(String workerId) => _repo.getWorker(workerId);
}

class CreateWorker {
  const CreateWorker(this._repo);
  final WorkerRepository _repo;
  Future<Worker> call(WorkerDraft draft) {
    _validate(draft.fullName, draft.job, draft.phone);
    return _repo.createWorker(draft);
  }
}

class UpdateWorker {
  const UpdateWorker(this._repo);
  final WorkerRepository _repo;
  Future<Worker> call(Worker worker) {
    _validate(worker.fullName, worker.job, worker.phone);
    return _repo.updateWorker(worker);
  }
}

class DeleteWorker {
  const DeleteWorker(this._repo);
  final WorkerRepository _repo;
  Future<void> call(String workerId) => _repo.deleteWorker(workerId);
}

void _validate(String fullName, String job, String? phone) {
  final error =
      Validators.required(fullName, field: 'Full name') ??
      Validators.required(job, field: 'Job') ??
      (phone == null || phone.trim().isEmpty ? null : Validators.phone(phone));
  if (error != null) throw ValidationException(error);
}
