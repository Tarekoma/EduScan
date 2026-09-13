import '../../../../core/enums/user_role.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Privileged user administration (manager only). Auth accounts are created on
/// a throwaway secondary app so the manager stays signed in; profile writes are
/// validated by Security Rules. Deactivation is an `isActive` flag;
/// [deleteUser] removes the profile only (the Auth record is orphaned).
abstract interface class UserAdminRepository {
  Stream<List<AppUser>> watchByRole(UserRole role);

  Future<void> createParent({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> studentIds,
  });

  Future<void> createInternal({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> setActive({required String uid, required bool isActive});

  Future<void> setParentLinks({
    required String uid,
    required List<String> studentIds,
  });

  Future<void> deleteUser({required String uid, required UserRole role});
}
