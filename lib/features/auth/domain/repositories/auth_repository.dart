import '../entities/app_user.dart';

/// Contract for authentication and the current user's profile.
abstract interface class AuthRepository {
  /// Emits the signed-in [AppUser], or `null` when signed out / deactivated.
  /// Deactivated accounts are signed out automatically and emit `null`.
  Stream<AppUser?> watchCurrentUser();

  /// Signs in with email/password and returns the resolved profile.
  ///
  /// Throws [AuthException] for bad credentials, and a [PermissionException]
  /// wrapped as [AuthException] when the account exists but is deactivated or
  /// has no profile.
  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();
}
