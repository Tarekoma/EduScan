import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../models/app_user_model.dart';

/// Talks to Firebase Auth and the `users` collection. Raw SDK errors are mapped
/// to [AppException] here so upper layers never see them.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Loads and validates the profile for [uid]. Throws when it is missing or
  /// deactivated.
  Future<AppUserModel> fetchProfile(String uid) async {
    try {
      // ignore: avoid_print
      print('FETCH PROFILE uid=$uid');
      final doc = await _userRef(uid).get();
      // ignore: avoid_print
      print('FETCH PROFILE exists=${doc.exists} data=${doc.data()}');
      if (!doc.exists) {
        throw const AuthException(
          'Your account has no profile. Contact an administrator.',
        );
      }
      final user = AppUserModel.fromDoc(doc);
      if (!user.isActive) {
        throw const AuthException('This account has been deactivated.');
      }
      return user;
    } on AppException {
      rethrow;
    } catch (e, s) {
      // ignore: avoid_print
      print('FETCH PROFILE ERROR: $e\n$s');
      throw ErrorMapper.map(e, s);
    }
  }

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      return await fetchProfile(uid);
    } on AppException {
      // Profile invalid/deactivated — don't leave a half-signed-in session.
      await _auth.signOut();
      rethrow;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Updates the signed-in user's own display name in their `users/{uid}`
  /// profile. Firestore rules restrict this to the caller's own document.
  Future<void> updateName({required String uid, required String name}) async {
    try {
      await _userRef(uid).update({
        UserFields.name: name,
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
