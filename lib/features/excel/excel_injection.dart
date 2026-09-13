import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/file_service.dart';
import '../attendance/domain/repositories/attendance_repository.dart';
import '../students/domain/repositories/student_repository.dart';
import '../workers/domain/repositories/worker_repository.dart';
import 'data/excel_codec.dart';
import 'data/excel_repository_impl.dart';
import 'domain/repositories/excel_repository.dart';
import 'presentation/cubit/excel_cubit.dart';

void registerExcelDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => ExcelCodec())
    ..registerLazySingleton<FileService>(() => const PlatformFileService())
    ..registerLazySingleton<ExcelRepository>(
      () => ExcelRepositoryImpl(
        codec: sl(),
        attendance: sl<AttendanceRepository>(),
        students: sl<StudentRepository>(),
        workers: sl<WorkerRepository>(),
        watchUsersByRole: sl(),
        firestore: sl<FirebaseFirestore>(),
        auth: sl<FirebaseAuth>(),
      ),
    )
    ..registerFactory(() => ExcelCubit(repository: sl(), fileService: sl()));
}
