import 'package:attendance_management/core/enums/user_role.dart';
import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/auth/domain/entities/app_user.dart';
import 'package:attendance_management/features/user_management/domain/repositories/user_admin_repository.dart';
import 'package:attendance_management/features/user_management/domain/usecases/user_admin_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements UserAdminRepository {
  Map<String, dynamic>? lastCreateParent;
  List<String>? lastLinks;

  @override
  Future<void> createParent({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> studentIds,
  }) async {
    lastCreateParent = {
      'name': name,
      'email': email,
      'phone': phone,
      'studentIds': studentIds,
    };
  }

  @override
  Future<void> setParentLinks({
    required String uid,
    required List<String> studentIds,
  }) async {
    lastLinks = studentIds;
  }

  @override
  Future<void> createInternal({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {}

  @override
  Future<void> setActive({required String uid, required bool isActive}) async {}

  @override
  Future<void> deleteUser({
    required String uid,
    required UserRole role,
  }) async {}

  @override
  Stream<List<AppUser>> watchByRole(UserRole role) => const Stream.empty();
}

void main() {
  late _FakeRepo repo;
  setUp(() => repo = _FakeRepo());

  group('CreateParentAccount', () {
    test('rejects invalid email', () {
      expect(
        () => CreateParentAccount(repo)(
          name: 'P',
          email: 'bad',
          password: 'secret1',
          phone: '0123456789',
          studentIds: const ['STU_00001'],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects an empty child list', () {
      expect(
        () => CreateParentAccount(repo)(
          name: 'P',
          email: 'p@x.com',
          password: 'secret1',
          phone: '0123456789',
          studentIds: const [],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('trims and forwards valid input', () async {
      await CreateParentAccount(repo)(
        name: '  Parent  ',
        email: '  P@X.com ',
        password: 'secret1',
        phone: ' 0123456789 ',
        studentIds: const ['STU_00001', 'STU_00002'],
      );
      expect(repo.lastCreateParent!['name'], 'Parent');
      expect(repo.lastCreateParent!['studentIds'], ['STU_00001', 'STU_00002']);
    });
  });

  group('CreateInternalAccount', () {
    test('rejects a parent role', () {
      expect(
        () => CreateInternalAccount(repo)(
          name: 'x',
          email: 'x@y.z',
          password: 'secret1',
          role: UserRole.parent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('UpdateParentLinks', () {
    test('rejects empty', () {
      expect(
        () => UpdateParentLinks(repo)(uid: 'u', studentIds: const []),
        throwsA(isA<ValidationException>()),
      );
    });

    test('forwards non-empty', () async {
      await UpdateParentLinks(repo)(uid: 'u', studentIds: const ['STU_00001']);
      expect(repo.lastLinks, ['STU_00001']);
    });
  });
}
