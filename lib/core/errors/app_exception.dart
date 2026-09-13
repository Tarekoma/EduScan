/// Base class for every error thrown by the data and domain layers.
///
/// The [message] is safe to show to end users — raw Firebase messages must be
/// mapped to one of these before reaching the presentation layer.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException({
    String message = 'No internet connection.',
    Object? cause,
  }) : super(message, cause: cause);
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

class PermissionException extends AppException {
  const PermissionException({
    String message = 'You are not allowed to perform this action.',
    Object? cause,
  }) : super(message, cause: cause);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

/// Violation of a centralised business rule (e.g. duplicate check-in).
class BusinessRuleException extends AppException {
  const BusinessRuleException(super.message, {super.cause});
}

class UnknownException extends AppException {
  const UnknownException({
    String message = 'Something went wrong. Please try again.',
    Object? cause,
  }) : super(message, cause: cause);
}
