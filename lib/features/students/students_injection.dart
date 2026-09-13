import 'package:get_it/get_it.dart';

import 'data/datasources/student_remote_data_source.dart';
import 'data/repositories/student_repository_impl.dart';
import 'domain/repositories/student_repository.dart';
import 'domain/usecases/student_usecases.dart';
import 'presentation/cubit/students_cubit.dart';

void registerStudentDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => StudentRemoteDataSource(sl()))
    ..registerLazySingleton<StudentRepository>(
      () => StudentRepositoryImpl(sl<StudentRemoteDataSource>()),
    )
    ..registerLazySingleton(() => WatchStudents(sl()))
    ..registerLazySingleton(() => GetStudent(sl()))
    ..registerLazySingleton(() => CreateStudent(sl()))
    ..registerLazySingleton(() => UpdateStudent(sl()))
    ..registerLazySingleton(() => DeleteStudent(sl()))
    ..registerFactory(
      () => StudentsCubit(
        watchStudents: sl(),
        createStudent: sl(),
        updateStudent: sl(),
        deleteStudent: sl(),
      ),
    );
}
