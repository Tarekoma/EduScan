import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/attendance/domain/attendance_rules.dart';
import 'package:attendance_management/features/attendance/domain/entities/attendance_record.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceRecord _record({DateTime? checkIn, DateTime? checkOut}) {
  return AttendanceRecord(
    id: 'student_STU_00001_2026-09-10',
    personId: 'STU_00001',
    personType: PersonType.student,
    date: '2026-09-10',
    checkIn: checkIn,
    checkOut: checkOut,
  );
}

void main() {
  final t1 = DateTime(2026, 9, 10, 7, 42);
  final t2 = DateTime(2026, 9, 10, 14, 5);

  group('assertCanCheckIn', () {
    test('allows when no record exists', () {
      expect(() => AttendanceRules.assertCanCheckIn(null), returnsNormally);
    });

    test('Rule 1: blocks a second check-in while inside', () {
      expect(
        () => AttendanceRules.assertCanCheckIn(_record(checkIn: t1)),
        throwsA(isA<BusinessRuleException>()),
      );
    });

    test('blocks check-in after the day is completed', () {
      expect(
        () => AttendanceRules.assertCanCheckIn(
          _record(checkIn: t1, checkOut: t2),
        ),
        throwsA(isA<BusinessRuleException>()),
      );
    });
  });

  group('assertCanCheckOut', () {
    test('Rule 2: blocks check-out with no check-in', () {
      expect(
        () => AttendanceRules.assertCanCheckOut(null),
        throwsA(isA<BusinessRuleException>()),
      );
    });

    test('allows check-out when inside', () {
      expect(
        () => AttendanceRules.assertCanCheckOut(_record(checkIn: t1)),
        returnsNormally,
      );
    });

    test('Rule 3: blocks a second check-out', () {
      expect(
        () => AttendanceRules.assertCanCheckOut(
          _record(checkIn: t1, checkOut: t2),
        ),
        throwsA(isA<BusinessRuleException>()),
      );
    });
  });

  group('nextAction', () {
    test('absent -> checkIn', () {
      expect(AttendanceRules.nextAction(null), AttendanceAction.checkIn);
    });

    test('inside -> checkOut', () {
      expect(
        AttendanceRules.nextAction(_record(checkIn: t1)),
        AttendanceAction.checkOut,
      );
    });

    test('left -> throws', () {
      expect(
        () => AttendanceRules.nextAction(_record(checkIn: t1, checkOut: t2)),
        throwsA(isA<BusinessRuleException>()),
      );
    });
  });
}
