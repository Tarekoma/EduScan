import 'package:equatable/equatable.dart';

import '../../../../core/enums/user_role.dart';

/// An authenticated user with a Firestore profile (`users/{uid}`).
///
/// Fields only carry meaning for some roles: [studentIds] and [phone] are for
/// parents; [createdBy] is for internal users provisioned by a manager.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone,
    this.studentIds = const [],
    this.createdAt,
    this.createdBy,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? phone;
  final List<String> studentIds;
  final DateTime? createdAt;
  final String? createdBy;

  bool get isInternal => role.isInternal;
  bool get canRecordAttendance => role.canRecordAttendance;
  bool get canManagePeople => role.canManagePeople;
  bool get canHandlePickup => role.canHandlePickup;

  bool isLinkedToStudent(String studentId) => studentIds.contains(studentId);

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    role,
    isActive,
    phone,
    studentIds,
    createdAt,
    createdBy,
  ];
}
