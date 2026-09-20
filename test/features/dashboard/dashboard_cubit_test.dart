import 'dart:async';

import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:attendance_management/features/auth/domain/entities/app_user.dart';
import 'package:attendance_management/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:attendance_management/features/students/domain/entities/student.dart';
import 'package:attendance_management/features/students/domain/repositories/student_repository.dart';
import 'package:attendance_management/features/students/domain/usecases/student_usecases.dart';
import 'package:attendance_management/features/user_management/domain/repositories/user_admin_repository.dart';
import 'package:attendance_management/features/user_management/domain/usecases/user_admin_usecases.dart';
import 'package:attendance_management/features/workers/domain/entities/worker.dart';
import 'package:attendance_management/features/workers/domain/repositories/worker_repository.dart';
import 'package:attendance_management/features/workers/domain/usecases/worker_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class _StudentRepo implements StudentRepository {
  @override
  Stream<List<Student>> watchStudents() => Stream.value(const []);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _WorkerRepo implements WorkerRepository {
  @override
  Stream<List<Worker>> watchWorkers() => Stream.value(const []);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _UserRepo implements UserAdminRepository {
  @override
  Stream<List<AppUser>> watchByRole(role) => Stream.value(const []);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _AttendanceRepo implements AttendanceRepository {
  @override
  Stream<List<AttendanceRecord>> watchByDate(String date) =>
      Stream.value(const []);
  @override
  Future<List<AttendanceRecord>> getInRange({
    required String fromDate,
    required String toDate,
  }) async => const [];
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late DashboardCubit cubit;

  setUp(() {
    cubit = DashboardCubit(
      watchStudents: WatchStudents(_StudentRepo()),
      watchWorkers: WatchWorkers(_WorkerRepo()),
      attendanceRepository: _AttendanceRepo(),
      watchUsersByRole: WatchUsersByRole(_UserRepo()),
    );
  });

  tearDown(() => cubit.close());

  group('recent activity paging', () {
    test('starts at the first page of 4', () {
      expect(cubit.state.activityLimit, 4);
    });

    test('showMoreActivity reveals 8 more rows each time', () {
      cubit.showMoreActivity();
      expect(cubit.state.activityLimit, 12);
      cubit.showMoreActivity();
      expect(cubit.state.activityLimit, 20);
    });

    test('changing the type filter goes back to the first page', () {
      cubit.showMoreActivity();
      cubit.setTypeFilter(PersonType.student);
      expect(cubit.state.activityLimit, 4);
    });

    test('changing the date goes back to the first page', () {
      cubit.showMoreActivity();
      cubit.setDate(DateTime.now().subtract(const Duration(days: 1)));
      expect(cubit.state.activityLimit, 4);
    });
  });
}
