import 'package:get_it/get_it.dart';

import '../students/domain/repositories/student_repository.dart';
import 'domain/usecases/get_linked_children.dart';
import 'presentation/cubit/parent_dashboard_cubit.dart';

void registerParentDependencies(GetIt sl) {
  sl
    ..registerLazySingleton(() => GetLinkedChildren(sl<StudentRepository>()))
    ..registerFactory(
      () => ParentDashboardCubit(
        authCubit: sl(),
        getLinkedChildren: sl(),
        watchTodayRecord: sl(),
        watchPersonAttendance: sl(),
      ),
    );
}
