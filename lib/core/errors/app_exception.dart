import '../l10n/app_strings.dart';

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
  NetworkException({String? message, Object? cause})
    : super(message ?? appStrings.errorNoInternet, cause: cause);
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

class PermissionException extends AppException {
  PermissionException({String? message, Object? cause})
    : super(message ?? appStrings.errorNotAllowed, cause: cause);
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
  UnknownException({String? message, Object? cause})
    : super(message ?? appStrings.errorSomethingWentWrong, cause: cause);
}
