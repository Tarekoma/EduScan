import 'package:get_it/get_it.dart';

import '../attendance/domain/repositories/attendance_repository.dart';
import 'presentation/cubit/dashboard_cubit.dart';

void registerDashboardDependencies(GetIt sl) {
  sl.registerFactory(
    () => DashboardCubit(
      watchStudents: sl(),
      watchWorkers: sl(),
      attendanceRepository: sl<AttendanceRepository>(),
      watchUsersByRole: sl(),
    ),
  );
}
