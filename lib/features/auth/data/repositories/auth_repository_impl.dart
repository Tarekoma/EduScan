import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _remote.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        return await _remote.fetchProfile(firebaseUser.uid);
      } on AppException catch (e) {
        // ignore: avoid_print
        print('WATCH USER -> forcing sign-out due to: ${e.message}');
        // Missing or deactivated profile: force a clean signed-out state.
        await _remote.signOut();
        return null;
      }
    });
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _remote.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() => _remote.signOut();
}
