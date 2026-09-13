import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/usecases/user_admin_usecases.dart';

part 'user_management_state.dart';

/// Manages one role's user list plus the privileged mutations a manager can
/// perform on it.
class UserManagementCubit extends Cubit<UserManagementState> {
  UserManagementCubit({
    required WatchUsersByRole watchUsersByRole,
    required CreateParentAccount createParent,
    required CreateInternalAccount createInternal,
    required SetUserActive setUserActive,
    required UpdateParentLinks updateParentLinks,
    required DeleteUserAccount deleteUserAccount,
  }) : _watch = watchUsersByRole,
       _createParent = createParent,
       _createInternal = createInternal,
       _setActive = setUserActive,
       _updateLinks = updateParentLinks,
       _delete = deleteUserAccount,
       super(const UserManagementState());

  final WatchUsersByRole _watch;
  final CreateParentAccount _createParent;
  final CreateInternalAccount _createInternal;
  final SetUserActive _setActive;
  final UpdateParentLinks _updateLinks;
  final DeleteUserAccount _delete;

  StreamSubscription<List<AppUser>>? _sub;

  void start(UserRole role) {
    if (_sub != null) return;
    emit(state.copyWith(role: role, status: UsersStatus.loading));
    _sub = _watch(role).listen(
      (users) => emit(
        state.copyWith(
          status: UsersStatus.ready,
          users: users,
          clearError: true,
        ),
      ),
      onError: (Object e, StackTrace s) => emit(
        state.copyWith(
          status: UsersStatus.error,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      ),
    );
  }

  Future<bool> createParent({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> studentIds,
  }) => _mutate(
    () => _createParent(
      name: name,
      email: email,
      password: password,
      phone: phone,
      studentIds: studentIds,
    ),
  );

  Future<bool> createInternal({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) => _mutate(
    () => _createInternal(
      name: name,
      email: email,
      password: password,
      role: role,
    ),
  );

  Future<bool> setActive(String uid, bool isActive) =>
      _mutate(() => _setActive(uid: uid, isActive: isActive));

  Future<bool> updateLinks(String uid, List<String> studentIds) =>
      _mutate(() => _updateLinks(uid: uid, studentIds: studentIds));

  Future<bool> deleteUser(String uid, UserRole role) =>
      _mutate(() => _delete(uid: uid, role: role));

  Future<bool> _mutate(Future<void> Function() action) async {
    emit(state.copyWith(isMutating: true, clearActionError: true));
    try {
      await action();
      emit(state.copyWith(isMutating: false));
      return true;
    } catch (e, s) {
      emit(
        state.copyWith(
          isMutating: false,
          actionError: ErrorMapper.map(e, s).message,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
