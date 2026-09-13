import 'package:get_it/get_it.dart';

import 'data/datasources/pickup_remote_data_source.dart';
import 'data/pickup_alert_player.dart';
import 'data/repositories/pickup_repository_impl.dart';
import 'domain/repositories/pickup_repository.dart';
import 'domain/usecases/pickup_usecases.dart';
import 'presentation/cubit/parent_pickup_cubit.dart';
import 'presentation/cubit/pickup_alert_cubit.dart';
import 'presentation/cubit/security_pickup_cubit.dart';

void registerPickupDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => PickupRemoteDataSource(sl()))
    ..registerLazySingleton<PickupRepository>(
      () => PickupRepositoryImpl(sl<PickupRemoteDataSource>()),
    )
    ..registerLazySingleton(() => WatchActivePickupRequests(sl()))
    ..registerLazySingleton(() => WatchStudentPickup(sl()))
    ..registerLazySingleton(() => WatchPickupHistory(sl()))
    ..registerLazySingleton(() => RequestPickup(sl()))
    ..registerLazySingleton(() => AcknowledgePickup(sl()))
    ..registerLazySingleton(() => CompletePickup(sl()))
    ..registerLazySingleton(() => CancelPickup(sl()))
    ..registerFactory(
      () => ParentPickupCubit(
        authCubit: sl(),
        watchStudentPickup: sl(),
        requestPickup: sl(),
        cancelPickup: sl(),
      ),
    )
    ..registerFactory(
      () => SecurityPickupCubit(
        authCubit: sl(),
        watchActive: sl(),
        acknowledge: sl(),
        complete: sl(),
        cancel: sl(),
      ),
    )
    // Session-lifetime alert watcher (one instance, survives navigation).
    ..registerLazySingleton<PickupAlertPlayer>(() => AudioPickupAlertPlayer())
    ..registerLazySingleton(
      () => PickupAlertCubit(authCubit: sl(), watchActive: sl(), player: sl()),
    );
}
