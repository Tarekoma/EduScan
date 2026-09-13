import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/core/enums/user_role.dart';
import 'package:attendance_management/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('parses known values and rejects unknown', () {
      expect(UserRole.fromValue('manager'), UserRole.manager);
      expect(() => UserRole.fromValue('admin'), throwsArgumentError);
    });

    test('permission helpers', () {
      expect(UserRole.security.canRecordAttendance, isTrue);
      expect(UserRole.manager.canRecordAttendance, isFalse);
      expect(UserRole.manager.canManagePeople, isTrue);
      expect(UserRole.parent.isInternal, isFalse);
    });
  });

  group('PersonType.fromQrCode', () {
    test('resolves prefixes', () {
      expect(PersonType.fromQrCode('STU_00125'), PersonType.student);
      expect(PersonType.fromQrCode('WRK_00015'), PersonType.worker);
      expect(PersonType.fromQrCode('XXX_1'), isNull);
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
  });
}
