import 'package:attendance_management/core/enums/pickup_status.dart';
import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/pickup/domain/pickup_rules.dart';
import 'package:attendance_management/features/pickup/domain/repositories/pickup_repository.dart';
import 'package:attendance_management/features/pickup/domain/usecases/pickup_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PickupRepository {}

void main() {
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
    setUp(() => repo = _MockRepo());

    test('rejects a student the parent is not linked to', () {
      expect(
        () => RequestPickup(repo)(
          studentId: 'STU_99999',
          studentName: 'Someone',
          requester: const PickupRequester(
            parentId: 'p1',
            parentName: 'Parent',
            linkedStudentIds: ['STU_00001'],
          ),
        ),
        throwsA(isA<PermissionException>()),
      );
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
