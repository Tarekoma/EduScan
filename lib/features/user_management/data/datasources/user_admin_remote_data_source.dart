import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/services/user_provisioner.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Privileged user administration, client-side.
///
/// Account creation goes through [UserProvisioner] (a throwaway secondary app,
/// so the manager stays signed in); the `users/{uid}` profile is then written
/// directly and Security Rules validate it (`hasRole('manager')` + field
/// checks). Deactivation flips `isActive`; deletion removes the profile only —
/// see [UserProvisioner] for why the Auth record is left behind.
class UserAdminRemoteDataSource {
  UserAdminRemoteDataSource(this._firestore, this._auth, this._provisioner);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserProvisioner _provisioner;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection(FirestoreCollections.students);

  Stream<List<AppUser>> watchByRole(UserRole role) {
    return _users
        .where(UserFields.role, isEqualTo: role.value)
        .orderBy(UserFields.name)
        .snapshots()
        .map<List<AppUser>>(
          (snap) => snap.docs.map(AppUserModel.fromDoc).toList(),
        )
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  String get _managerUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException('Please sign in again.');
    return uid;
  }

  Future<void> createParent({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> studentIds,
  }) async {
    await _assertStudentsExist(studentIds);
    final uid = await _provisioner.createAccount(
      email: email,
      password: password,
      displayName: name,
    );
    try {
      final batch = _firestore.batch();
      batch.set(_users.doc(uid), {
        UserFields.uid: uid,
        UserFields.name: name,
        UserFields.email: email,
        UserFields.phone: phone,
        UserFields.role: UserRole.parent.value,
        UserFields.studentIds: studentIds,
        UserFields.isActive: true,
        UserFields.createdAt: FieldValue.serverTimestamp(),
        UserFields.createdBy: _managerUid,
      });
      // Stamp the back-reference so these students no longer show as
      // "unlinked" when picking children for another parent.
      for (final id in studentIds) {
        batch.update(_students.doc(id), {
          StudentFields.parentId: uid,
          StudentFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> createInternal({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final uid = await _provisioner.createAccount(
      email: email,
      password: password,
      displayName: name,
    );
    try {
      await _users.doc(uid).set({
        UserFields.uid: uid,
        UserFields.name: name,
        UserFields.email: email,
        UserFields.role: role.value,
        UserFields.isActive: true,
        UserFields.createdAt: FieldValue.serverTimestamp(),
        UserFields.createdBy: _managerUid,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> setActive({required String uid, required bool isActive}) async {
    try {
      await _users.doc(uid).update({
        UserFields.isActive: isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> setParentLinks({
    required String uid,
    required List<String> studentIds,
  }) async {
    await _assertStudentsExist(studentIds);
    try {
      final snap = await _users.doc(uid).get();
      if (!snap.exists || snap.data()?[UserFields.role] != UserRole.parent.value) {
        throw const NotFoundException('No such parent account.');
      }
      // Reconcile against the students' own back-reference — not the
      // parent's stored studentIds — so this also self-heals any link that
      // predates the back-reference existing (just re-saving fixes it).
      final linked = await _students
          .where(StudentFields.parentId, isEqualTo: uid)
          .get();
      final previousIds = linked.docs.map((d) => d.id).toSet();
      final newIds = studentIds.toSet();

      final batch = _firestore.batch();
      batch.update(_users.doc(uid), {
        UserFields.studentIds: studentIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Keep the students' back-reference in sync: stamp newly-linked ones,
      // clear it from any that were unlinked so they become available again.
      for (final id in newIds.difference(previousIds)) {
        batch.update(_students.doc(id), {
          StudentFields.parentId: uid,
          StudentFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }
      for (final id in previousIds.difference(newIds)) {
        batch.update(_students.doc(id), {
          StudentFields.parentId: FieldValue.delete(),
          StudentFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Removes the `users/{uid}` profile. The Auth record is orphaned (a client
  /// cannot delete another user); a manager clears it from the console. For a
  /// parent, also clears the back-reference on their linked students so those
  /// children aren't left permanently marked as linked to a deleted account.
  Future<void> deleteUser({required String uid, required UserRole role}) async {
    try {
      final batch = _firestore.batch();
      if (role == UserRole.parent) {
        final linked = await _students
            .where(StudentFields.parentId, isEqualTo: uid)
            .get();
        for (final doc in linked.docs) {
          batch.update(doc.reference, {
            StudentFields.parentId: FieldValue.delete(),
            StudentFields.updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }
      batch.delete(_users.doc(uid));
      await batch.commit();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> _assertStudentsExist(List<String> studentIds) async {
    final ids = studentIds.toSet();
    if (ids.isEmpty) return;
    try {
      final snaps = await Future.wait(ids.map((id) => _students.doc(id).get()));
      final missing = snaps.where((s) => !s.exists).map((s) => s.id).toList();
      if (missing.isNotEmpty) {
        throw ValidationException('Unknown student(s): ${missing.join(', ')}');
      }
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
