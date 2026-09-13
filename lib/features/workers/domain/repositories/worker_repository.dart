import '../entities/worker.dart';

class WorkerDraft {
  const WorkerDraft({
    required this.fullName,
    required this.job,
    this.department,
    this.phone,
  });

  final String fullName;
  final String job;
  final String? department;
  final String? phone;
}

abstract interface class WorkerRepository {
  Stream<List<Worker>> watchWorkers();

  Future<Worker> getWorker(String workerId);

  Future<Worker> createWorker(WorkerDraft draft);

  Future<Worker> updateWorker(Worker worker);

  Future<void> deleteWorker(String workerId);
}
