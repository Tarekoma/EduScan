/// The four roles in the system.
///
/// [security], [manager] and [supervisor] are internal application roles.
/// [parent] is an external role limited to their own linked children.
enum UserRole {
  security('security'),
  manager('manager'),
  supervisor('supervisor'),
  parent('parent');

  const UserRole(this.value);

  /// The value persisted in Firestore (`users/{uid}.role`).
  final String value;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw ArgumentError('Unknown UserRole: $value'),
    );
  }

  bool get isInternal => this != UserRole.parent;

  /// Only security guards may record attendance.
  bool get canRecordAttendance => this == UserRole.security;

  /// Only the manager has full control (including deletion). The supervisor
  /// may add and edit people but never delete; that is enforced in the rules.
  bool get canManagePeople => this == UserRole.manager;

  /// Only security may acknowledge / complete pickup requests.
  bool get canHandlePickup => this == UserRole.security;
}
