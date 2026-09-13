import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/core/enums/pickup_status.dart';
import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_management/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:attendance_management/features/pickup/domain/pickup_rules.dart';
import 'package:attendance_management/features/pickup/domain/repositories/pickup_repository.dart';
import 'package:attendance_management/features/pickup/domain/usecases/pickup_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PickupRepository {}

class _MockGetTodayRecord extends Mock implements GetTodayRecord {}

void main() {
  setUpAll(() {
    registerFallbackValue(PersonType.student);
    registerFallbackValue(
      const PickupRequester(
        parentId: 'fallback',
        parentName: 'fallback',
        linkedStudentIds: [],
      ),
    );
  });

  group('PickupRules.canTransition', () {
    test('valid forward transitions', () {
      expect(
        PickupRules.canTransition(
          PickupStatus.pending,
          PickupStatus.acknowledged,
        ),
        isTrue,
      );
      expect(
        PickupRules.canTransition(
          PickupStatus.acknowledged,
          PickupStatus.completed,
        ),
        isTrue,
      );
      expect(
        PickupRules.canTransition(PickupStatus.pending, PickupStatus.cancelled),
        isTrue,
      );
    });

    test('invalid transitions', () {
      expect(
        PickupRules.canTransition(PickupStatus.pending, PickupStatus.completed),
        isFalse,
      );
      expect(
        PickupRules.canTransition(
          PickupStatus.completed,
          PickupStatus.acknowledged,
        ),
        isFalse,
      );
      expect(
        PickupRules.canTransition(PickupStatus.cancelled, PickupStatus.pending),
        isFalse,
      );
    });

    test('assertTransition throws BusinessRuleException on invalid', () {
      expect(
        () => PickupRules.assertTransition(
          PickupStatus.completed,
          PickupStatus.completed,
        ),
        throwsA(isA<BusinessRuleException>()),
      );
    });
  });

  group('RequestPickup', () {
    late _MockRepo repo;
    late _MockGetTodayRecord getTodayRecord;

    const requester = PickupRequester(
      parentId: 'p1',
      parentName: 'Parent',
      linkedStudentIds: ['STU_00001'],
    );

    setUp(() {
      repo = _MockRepo();
      getTodayRecord = _MockGetTodayRecord();
    });

    test('rejects a student the parent is not linked to', () {
      expect(
        () => RequestPickup(repo, getTodayRecord)(
          studentId: 'STU_99999',
          studentName: 'Someone',
          requester: requester,
        ),
        throwsA(isA<PermissionException>()),
      );
    });

    test('rejects when the child has not checked in today', () {
      when(
        () => getTodayRecord(
          personId: any(named: 'personId'),
          personType: any(named: 'personType'),
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => RequestPickup(repo, getTodayRecord)(
          studentId: 'STU_00001',
          studentName: 'Kid',
          requester: requester,
        ),
        throwsA(isA<BusinessRuleException>()),
      );
    });

    test('rejects when the child has already checked out today', () {
      when(
        () => getTodayRecord(
          personId: any(named: 'personId'),
          personType: any(named: 'personType'),
        ),
      ).thenAnswer(
        (_) async => AttendanceRecord(
          id: 'student_STU_00001_2026-01-01',
          personId: 'STU_00001',
          personType: PersonType.student,
          date: '2026-01-01',
          checkIn: DateTime(2026, 1, 1, 7),
          checkOut: DateTime(2026, 1, 1, 14),
        ),
      );

      expect(
        () => RequestPickup(repo, getTodayRecord)(
          studentId: 'STU_00001',
          studentName: 'Kid',
          requester: requester,
        ),
        throwsA(isA<BusinessRuleException>()),
      );
    });

    test('succeeds when the child is checked in and still inside', () async {
      when(
        () => getTodayRecord(
          personId: any(named: 'personId'),
          personType: any(named: 'personType'),
        ),
      ).thenAnswer(
        (_) async => AttendanceRecord(
          id: 'student_STU_00001_2026-01-01',
          personId: 'STU_00001',
          personType: PersonType.student,
          date: '2026-01-01',
          checkIn: DateTime(2026, 1, 1, 7),
        ),
      );
      when(
        () => repo.requestPickup(
          studentId: any(named: 'studentId'),
          studentName: any(named: 'studentName'),
          className: any(named: 'className'),
          requester: any(named: 'requester'),
        ),
      ).thenAnswer((_) async {});

      await RequestPickup(repo, getTodayRecord)(
        studentId: 'STU_00001',
        studentName: 'Kid',
        requester: requester,
      );

      verify(
        () => repo.requestPickup(
          studentId: 'STU_00001',
          studentName: 'Kid',
          className: null,
          requester: requester,
        ),
      ).called(1);
    });
  });

  group('AcknowledgePickup / CompletePickup', () {
    late _MockRepo repo;
    setUp(() => repo = _MockRepo());

    test('reject a non-security handler', () {
      const handler = PickupHandler(uid: 'x', canHandle: false);
      expect(
        () => AcknowledgePickup(repo)(requestId: 'r1', handler: handler),
        throwsA(isA<PermissionException>()),
      );
      expect(
        () => CompletePickup(repo)(requestId: 'r1', handler: handler),
        throwsA(isA<PermissionException>()),
      );
    });
  });
}
