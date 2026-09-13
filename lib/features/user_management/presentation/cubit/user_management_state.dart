part of 'user_management_cubit.dart';

enum UsersStatus { initial, loading, ready, error }

class UserManagementState extends Equatable {
  const UserManagementState({
    this.role = UserRole.parent,
    this.status = UsersStatus.initial,
    this.users = const [],
    this.errorMessage,
    this.isMutating = false,
    this.actionError,
  });

  final UserRole role;
  final UsersStatus status;
  final List<AppUser> users;
  final String? errorMessage;
  final bool isMutating;
  final String? actionError;

  bool get isEmpty => status == UsersStatus.ready && users.isEmpty;

  UserManagementState copyWith({
    UserRole? role,
    UsersStatus? status,
    List<AppUser>? users,
    String? errorMessage,
    bool clearError = false,
    bool? isMutating,
    String? actionError,
    bool clearActionError = false,
  }) {
    return UserManagementState(
      role: role ?? this.role,
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isMutating: isMutating ?? this.isMutating,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    role,
    status,
    users,
    errorMessage,
    isMutating,
    actionError,
  ];
}
