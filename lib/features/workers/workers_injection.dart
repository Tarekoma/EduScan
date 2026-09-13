import 'package:get_it/get_it.dart';

import 'data/datasources/worker_remote_data_source.dart';
import 'data/repositories/worker_repository_impl.dart';
import 'domain/repositories/worker_repository.dart';
import 'domain/usecases/worker_usecases.dart';
import 'presentation/cubit/workers_cubit.dart';

void registerWorkerDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => WorkerRemoteDataSource(sl()))
    ..registerLazySingleton<WorkerRepository>(
      () => WorkerRepositoryImpl(sl<WorkerRemoteDataSource>()),
    )
    ..registerLazySingleton(() => WatchWorkers(sl()))
    ..registerLazySingleton(() => GetWorker(sl()))
    ..registerLazySingleton(() => CreateWorker(sl()))
    ..registerLazySingleton(() => UpdateWorker(sl()))
    ..registerLazySingleton(() => DeleteWorker(sl()))
    ..registerFactory(
      () => WorkersCubit(
        watchWorkers: sl(),
        createWorker: sl(),
        updateWorker: sl(),
        deleteWorker: sl(),
      ),
    );
}
