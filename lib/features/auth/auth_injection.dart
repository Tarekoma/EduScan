import 'package:get_it/get_it.dart';

import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/sign_in.dart';
import 'domain/usecases/sign_out.dart';
import 'domain/usecases/update_name.dart';
import 'domain/usecases/watch_auth_state.dart';
import 'presentation/cubit/auth_cubit.dart';

void registerAuthDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => AuthRemoteDataSource(sl(), sl()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
    )
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => UpdateName(sl()))
    ..registerLazySingleton(() => WatchAuthState(sl()))
    // App-wide singleton: one auth state for the whole session.
    ..registerLazySingleton(
      () => AuthCubit(
        watchAuthState: sl(),
        signIn: sl(),
        signOut: sl(),
        updateName: sl(),
      ),
    );
}
