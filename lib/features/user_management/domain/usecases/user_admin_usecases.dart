import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../repositories/user_admin_repository.dart';

class WatchUsersByRole {
  const WatchUsersByRole(this._repo);
  final UserAdminRepository _repo;
  Stream<List<AppUser>> call(UserRole role) => _repo.watchByRole(role);
}

class CreateParentAccount {
  const CreateParentAccount(this._repo);
  final UserAdminRepository _repo;

  Future<void> call({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> studentIds,
  }) {
    final error =
        Validators.required(
          name,
          message: appStrings.validatorRequired(appStrings.fieldName),
        ) ??
        Validators.email(email) ??
        Validators.password(password) ??
        Validators.phone(phone);
    if (error != null) throw ValidationException(error);
    if (studentIds.isEmpty) {
      throw ValidationException(appStrings.linkAtLeastOneChildSnackbar);
    }
    return _repo.createParent(
      name: name.trim(),
      email: email.trim(),
      password: password,
      phone: phone.trim(),
      studentIds: studentIds,
    );
  }
}

class CreateInternalAccount {
  const CreateInternalAccount(this._repo);
  final UserAdminRepository _repo;

  Future<void> call({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    if (!role.isInternal) {
      throw ValidationException(appStrings.roleMustBeInternal);
    }
    final error =
        Validators.required(
          name,
          message: appStrings.validatorRequired(appStrings.fieldName),
        ) ??
        Validators.email(email) ??
        Validators.password(password);
    if (error != null) throw ValidationException(error);
    return _repo.createInternal(
      name: name.trim(),
      email: email.trim(),
      password: password,
      role: role,
    );
  }
}

class SetUserActive {
  const SetUserActive(this._repo);
  final UserAdminRepository _repo;
  Future<void> call({required String uid, required bool isActive}) =>
      _repo.setActive(uid: uid, isActive: isActive);
}

class UpdateParentLinks {
  const UpdateParentLinks(this._repo);
  final UserAdminRepository _repo;

  Future<void> call({required String uid, required List<String> studentIds}) {
    if (studentIds.isEmpty) {
      throw ValidationException(appStrings.parentMustHaveOneChild);
    }
    return _repo.setParentLinks(uid: uid, studentIds: studentIds);
  }
}

class DeleteUserAccount {
  const DeleteUserAccount(this._repo);
  final UserAdminRepository _repo;
  Future<void> call({required String uid, required UserRole role}) =>
      _repo.deleteUser(uid: uid, role: role);
}
