import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/user_role.dart';
import '../../domain/entities/app_user.dart';

/// Firestore serialisation for [AppUser] (`users/{uid}`).
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.role,
    required super.isActive,
    super.phone,
    super.studentIds,
    super.createdAt,
    super.createdBy,
  });

  factory AppUserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUserModel(
      uid: doc.id,
      name: (data[UserFields.name] as String?) ?? '',
      email: (data[UserFields.email] as String?) ?? '',
      role: UserRole.fromValue(data[UserFields.role] as String?),
      isActive: (data[UserFields.isActive] as bool?) ?? false,
      phone: data[UserFields.phone] as String?,
      studentIds:
          (data[UserFields.studentIds] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      createdAt: (data[UserFields.createdAt] as Timestamp?)?.toDate(),
      createdBy: data[UserFields.createdBy] as String?,
    );
  }
}
