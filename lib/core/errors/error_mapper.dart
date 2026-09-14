import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';
import '../l10n/app_strings.dart';

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
    final l10n = appStrings;
    final message = switch (e.code) {
      'invalid-email' => l10n.errorInvalidEmail,
      'user-disabled' => l10n.errorAccountDeactivated,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => l10n.errorIncorrectCredentials,
      'too-many-requests' => l10n.errorTooManyAttempts,
      'network-request-failed' => l10n.errorNoInternet,
      'email-already-in-use' => l10n.errorEmailInUse,
      'weak-password' => l10n.errorWeakPassword,
      _ => l10n.errorAuthFailed,
    };
    if (e.code == 'network-request-failed') {
      return NetworkException(cause: e);
    }
    return AuthException(message, cause: e);
  }

  static AppException _mapFirebase(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => PermissionException(),
      'not-found' => NotFoundException(appStrings.errorDataNotFound),
      'unavailable' || 'deadline-exceeded' => NetworkException(cause: e),
      _ => UnknownException(cause: e),
    };
  }
}
