import 'package:get_it/get_it.dart';

import 'data/datasources/user_admin_remote_data_source.dart';
import 'data/repositories/user_admin_repository_impl.dart';
import 'domain/repositories/user_admin_repository.dart';
import 'domain/usecases/user_admin_usecases.dart';
import 'presentation/cubit/user_management_cubit.dart';

void registerUserManagementDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => UserAdminRemoteDataSource(sl(), sl(), sl()))
    ..registerLazySingleton<UserAdminRepository>(
      () => UserAdminRepositoryImpl(sl<UserAdminRemoteDataSource>()),
    )
    ..registerLazySingleton(() => WatchUsersByRole(sl()))
    ..registerLazySingleton(() => CreateParentAccount(sl()))
    ..registerLazySingleton(() => CreateInternalAccount(sl()))
    ..registerLazySingleton(() => SetUserActive(sl()))
    ..registerLazySingleton(() => UpdateParentLinks(sl()))
    ..registerLazySingleton(() => DeleteUserAccount(sl()))
    ..registerFactory(
      () => UserManagementCubit(
        watchUsersByRole: sl(),
        createParent: sl(),
        createInternal: sl(),
        setUserActive: sl(),
        updateParentLinks: sl(),
        deleteUserAccount: sl(),
      ),
    );
}
