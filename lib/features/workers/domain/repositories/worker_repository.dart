import '../../../../core/enums/worker_job_title.dart';
import '../entities/worker.dart';

class WorkerDraft {
  const WorkerDraft({required this.fullName, required this.jobTitle});

  final String fullName;
  final WorkerJobTitle jobTitle;
}

abstract interface class WorkerRepository {
  Stream<List<Worker>> watchWorkers();

  Future<Worker> getWorker(String workerId);

  Future<Worker> createWorker(WorkerDraft draft);

  Future<Worker> updateWorker(Worker worker);

  Future<void> deleteWorker(String workerId);
}
