import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/app_strings.dart';
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
    _validate(draft.fullName);
    return _repo.createWorker(draft);
  }
}

class UpdateWorker {
  const UpdateWorker(this._repo);
  final WorkerRepository _repo;
  Future<Worker> call(Worker worker) {
    _validate(worker.fullName);
    return _repo.updateWorker(worker);
  }
}

class DeleteWorker {
  const DeleteWorker(this._repo);
  final WorkerRepository _repo;
  Future<void> call(String workerId) => _repo.deleteWorker(workerId);
}

void _validate(String fullName) {
  final error = Validators.required(
    fullName,
    message: appStrings.validatorRequired(appStrings.fieldFullName),
  );
  if (error != null) throw ValidationException(error);
}
