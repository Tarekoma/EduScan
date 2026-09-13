import 'package:get_it/get_it.dart';

import '../students/domain/repositories/student_repository.dart';
import '../workers/domain/repositories/worker_repository.dart';
import 'domain/usecases/resolve_person.dart';

void registerQrDependencies(GetIt sl) {
  sl.registerLazySingleton(
    () => ResolvePerson(
      students: sl<StudentRepository>(),
      workers: sl<WorkerRepository>(),
    ),
  );
}
