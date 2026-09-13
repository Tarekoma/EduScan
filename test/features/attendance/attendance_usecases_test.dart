import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:attendance_management/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AttendanceRepository {}

const _security = AttendanceActor(uid: 'sec1', canRecord: true);
const _supervisor = AttendanceActor(uid: 'sup1', canRecord: false);

final _sample = AttendanceRecord(
  id: 'student_STU_00001_2026-09-10',
  personId: 'STU_00001',
  personType: PersonType.student,
  date: '2026-09-10',
  checkIn: DateTime(2026, 9, 10, 8),
);

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(const AttendanceCorrectionInput());
    registerFallbackValue(PersonType.student);
    registerFallbackValue(const AttendanceActor(uid: 'x', canRecord: false));
  });

  setUp(() => repo = _MockRepo());

  test('Rule 9: CheckInUseCase rejects a non-security actor', () {
    expect(
      () => CheckInUseCase(repo)(
        personId: 'STU_00001',
        personType: PersonType.student,
        actor: _supervisor,
      ),
      throwsA(isA<PermissionException>()),
    );
    verifyNever(
      () => repo.checkIn(
        personId: any(named: 'personId'),
        personType: any(named: 'personType'),
        date: any(named: 'date'),
        actor: any(named: 'actor'),
      ),
    );
  });

  test('CheckInUseCase delegates to the repository for security', () async {
    when(
      () => repo.checkIn(
        personId: any(named: 'personId'),
        personType: any(named: 'personType'),
        date: any(named: 'date'),
        actor: any(named: 'actor'),
      ),
    ).thenAnswer((_) async => _sample);

    final result = await CheckInUseCase(repo)(
      personId: 'STU_00001',
      personType: PersonType.student,
      actor: _security,
      now: DateTime(2026, 9, 10),
    );

    expect(result, _sample);
    verify(
      () => repo.checkIn(
        personId: 'STU_00001',
        personType: PersonType.student,
        date: '2026-09-10',
        actor: _security,
      ),
    ).called(1);
  });

  test('UpdateAttendanceUseCase rejects an empty correction', () {
    expect(
      () => UpdateAttendanceUseCase(repo)(
        recordId: _sample.id,
        input: const AttendanceCorrectionInput(),
        actor: _security,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('UpdateAttendanceUseCase rejects check-out before check-in', () {
    expect(
      () => UpdateAttendanceUseCase(repo)(
        recordId: _sample.id,
        input: AttendanceCorrectionInput(
          checkIn: DateTime(2026, 9, 10, 10),
          checkOut: DateTime(2026, 9, 10, 9),
        ),
        actor: _security,
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
