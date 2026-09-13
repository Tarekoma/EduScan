import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

/// Converts any thrown object into a typed, user-safe [AppException].
///
/// This is the single place where raw Firebase errors are translated. Data
/// sources should call [ErrorMapper.map] in their `catch` blocks so the rest of
/// the app only ever deals with [AppException]s.
abstract final class ErrorMapper {
  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) return _mapAuth(error);
    if (error is FirebaseException) return _mapFirebase(error);

    return UnknownException(cause: error);
  }

  static AppException _mapAuth(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'The email address is not valid.',
      'user-disabled' => 'This account has been deactivated.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Incorrect email or password.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'No internet connection.',
      'email-already-in-use' => 'An account already exists for that email.',
      'weak-password' => 'The password is too weak.',
      _ => 'Authentication failed. Please try again.',
    };
    if (e.code == 'network-request-failed') {
      return NetworkException(cause: e);
    }
    return AuthException(message, cause: e);
  }

  static AppException _mapFirebase(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const PermissionException(),
      'not-found' => const NotFoundException(
        'The requested data was not found.',
      ),
      'unavailable' || 'deadline-exceeded' => NetworkException(cause: e),
      _ => UnknownException(cause: e),
    };
  }
}
