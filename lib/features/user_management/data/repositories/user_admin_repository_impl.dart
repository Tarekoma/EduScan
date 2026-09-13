import '../../../../core/enums/user_role.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/user_admin_repository.dart';
import '../datasources/user_admin_remote_data_source.dart';

class UserAdminRepositoryImpl implements UserAdminRepository {
  UserAdminRepositoryImpl(this._remote);

  final UserAdminRemoteDataSource _remote;

  @override
  Stream<List<AppUser>> watchByRole(UserRole role) => _remote.watchByRole(role);

  @override
  Future<void> createParent({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> studentIds,
  }) => _remote.createParent(
    name: name,
    email: email,
    password: password,
    phone: phone,
    studentIds: studentIds,
  );

  @override
  Future<void> createInternal({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) => _remote.createInternal(
    name: name,
    email: email,
    password: password,
    role: role,
  );

  @override
  Future<void> setActive({required String uid, required bool isActive}) =>
      _remote.setActive(uid: uid, isActive: isActive);

  @override
  Future<void> setParentLinks({
    required String uid,
    required List<String> studentIds,
  }) => _remote.setParentLinks(uid: uid, studentIds: studentIds);

  @override
  Future<void> deleteUser({required String uid, required UserRole role}) =>
      _remote.deleteUser(uid: uid, role: role);
}
