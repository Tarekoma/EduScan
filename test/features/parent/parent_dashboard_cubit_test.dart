import 'dart:async';

import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/core/enums/user_role.dart';
import 'package:attendance_management/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:attendance_management/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:attendance_management/features/auth/domain/entities/app_user.dart';
import 'package:attendance_management/features/auth/domain/usecases/sign_in.dart';
import 'package:attendance_management/features/auth/domain/usecases/sign_out.dart';
import 'package:attendance_management/features/auth/domain/usecases/update_name.dart';
import 'package:attendance_management/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:attendance_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:attendance_management/features/parent/domain/usecases/get_linked_children.dart';
import 'package:attendance_management/features/parent/presentation/cubit/parent_dashboard_cubit.dart';
import 'package:attendance_management/features/students/domain/entities/student.dart';
import 'package:attendance_management/features/students/domain/repositories/student_repository.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchAuth extends Mock implements WatchAuthState {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignOut extends Mock implements SignOut {}

class _MockUpdateName extends Mock implements UpdateName {}

class _StudentRepo implements StudentRepository {
  @override
  Future<Student> getStudent(String id) async => Student(
    studentId: id,
    fullName: 'Child $id',
    className: '5A',
    qrCodeId: id,
  );
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _AttendanceRepo implements AttendanceRepository {
  final todayController = StreamController<AttendanceRecord?>.broadcast();
  final historyController =
      StreamController<List<AttendanceRecord>>.broadcast();

  @override
  Stream<AttendanceRecord?> watchRecord({
    required String personId,
    required PersonType personType,
    required String date,
  }) => todayController.stream;

  @override
  Stream<List<AttendanceRecord>> watchByPerson({
    required String personId,
    required PersonType personType,
    int limit = 60,
  }) => historyController.stream;

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

AttendanceRecord _rec(String date) => AttendanceRecord(
  id: 'student_STU_00001_$date',
  personId: 'STU_00001',
  personType: PersonType.student,
  date: date,
);

void main() {
  late _MockWatchAuth watchAuth;
  late AuthCubit authCubit;
  late _AttendanceRepo attendance;
  late StreamController<AppUser?> authStream;

  setUp(() {
    watchAuth = _MockWatchAuth();
    authStream = StreamController<AppUser?>.broadcast();
    when(watchAuth.call).thenAnswer((_) => authStream.stream);
    authCubit = AuthCubit(
      watchAuthState: watchAuth,
      signIn: _MockSignIn(),
      signOut: _MockSignOut(),
      updateName: _MockUpdateName(),
    );
    attendance = _AttendanceRepo();
  });

  tearDown(() async {
    await authCubit.close();
    await authStream.close();
    await attendance.todayController.close();
    await attendance.historyController.close();
  });

  ParentDashboardCubit build() => ParentDashboardCubit(
    authCubit: authCubit,
    getLinkedChildren: GetLinkedChildren(_StudentRepo()),
    watchTodayRecord: WatchTodayRecord(attendance),
    watchPersonAttendance: WatchPersonAttendance(attendance),
  );

  void signInParent(List<String> studentIds) {
    authStream.add(
      AppUser(
        uid: 'p1',
        name: 'Parent',
        email: 'p@x.com',
        role: UserRole.parent,
        isActive: true,
        studentIds: studentIds,
      ),
    );
  }

  test('empty state when no children are linked', () async {
    signInParent(const []);
    await Future<void>.delayed(Duration.zero);
    final cubit = build();
    await cubit.start();
    expect(cubit.state.status, ParentStatus.empty);
    await cubit.close();
  });

  test('loads children and selects the first', () async {
    signInParent(const ['STU_00002', 'STU_00001']);
    await Future<void>.delayed(Duration.zero);
    final cubit = build();
    await cubit.start();
    expect(cubit.state.status, ParentStatus.ready);
    expect(cubit.state.children.length, 2);
    // sorted by name: "Child STU_00001" before "Child STU_00002"
    expect(cubit.state.selectedId, 'STU_00001');
    await cubit.close();
  });

  test('history range filter narrows visibleHistory', () async {
    signInParent(const ['STU_00001']);
    await Future<void>.delayed(Duration.zero);
    final cubit = build();
    await cubit.start();
    attendance.historyController.add([
      _rec('2026-09-01'),
      _rec('2026-09-05'),
      _rec('2026-09-10'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.visibleHistory.length, 3);

    cubit.setHistoryRange(
      DateTimeRange(start: DateTime(2026, 9, 4), end: DateTime(2026, 9, 6)),
    );
    expect(cubit.state.visibleHistory.map((r) => r.date), ['2026-09-05']);
    await cubit.close();
  });
}
