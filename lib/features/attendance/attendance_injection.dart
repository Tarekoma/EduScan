import 'package:get_it/get_it.dart';

import 'data/datasources/attendance_remote_data_source.dart';
import 'data/repositories/attendance_repository_impl.dart';
import '../qr/domain/usecases/resolve_person.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/usecases/attendance_usecases.dart';
import 'presentation/cubit/record_attendance_cubit.dart';

void registerAttendanceDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => AttendanceRemoteDataSource(sl()))
    ..registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(sl<AttendanceRemoteDataSource>()),
    )
    ..registerLazySingleton(() => CheckInUseCase(sl()))
    ..registerLazySingleton(() => CheckOutUseCase(sl()))
    ..registerLazySingleton(() => UpdateAttendanceUseCase(sl()))
    ..registerLazySingleton(() => GetTodayRecord(sl()))
    ..registerLazySingleton(() => WatchTodayRecord(sl()))
    ..registerLazySingleton(() => WatchAttendanceByDate(sl()))
    ..registerLazySingleton(() => WatchPersonAttendance(sl()))
    ..registerFactory(
      () => RecordAttendanceCubit(
        authCubit: sl(),
        getTodayRecord: sl(),
        checkIn: sl(),
        checkOut: sl(),
        resolvePerson: sl<ResolvePerson>(),
      ),
    );
}
