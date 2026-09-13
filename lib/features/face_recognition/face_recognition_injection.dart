import 'package:get_it/get_it.dart';

import '../attendance/domain/usecases/attendance_usecases.dart';
import 'data/face_enrollment_remote_data_source.dart';
import 'domain/face_recognizer.dart';
import 'domain/repositories/face_enrollment_repository.dart';
import 'domain/usecases/face_usecases.dart';
import 'presentation/cubit/face_attendance_cubit.dart';

/// Face recognition is fully isolated. To enable it, register a real
/// [FaceRecognizer] here in place of [UnavailableFaceRecognizer] — nothing else
/// in the app changes. See `features/face_recognition/README.md`.
void registerFaceRecognitionDependencies(GetIt sl) {
  sl
    ..registerLazySingleton<FaceRecognizer>(
      () => const UnavailableFaceRecognizer(),
    )
    ..registerLazySingleton<FaceEnrollmentRepository>(
      () => FaceEnrollmentRemoteDataSource(sl()),
    )
    ..registerLazySingleton(() => EnrollFace(sl(), sl()))
    ..registerLazySingleton(() => IdentifyByFace(sl(), sl()))
    ..registerLazySingleton(() => LoadEnrolledFaces(sl()))
    ..registerLazySingleton(
      () => RecordAttendanceByFace(
        identify: sl(),
        getTodayRecord: sl<GetTodayRecord>(),
        checkIn: sl(),
        checkOut: sl(),
      ),
    )
    ..registerFactory(
      () => FaceAttendanceCubit(
        authCubit: sl(),
        recognizer: sl(),
        recordByFace: sl(),
      ),
    );
}
