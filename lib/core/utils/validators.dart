import '../l10n/app_strings.dart';

/// Reusable field validators. Return `null` when valid, otherwise an error
/// string suitable for a `TextFormField`. Do not duplicate these in screens.
///
/// No [BuildContext] flows through these (they're plain functions handed to
/// `TextFormField.validator`). [required]'s default (no [message] passed)
/// stays the original hardcoded-English composition, untouched — the Login
/// page's own validator call relies on exactly that and is out of scope for
/// this app's localization, so it must never start following the app's
/// selected language. Every other call site should pass an already-localized
/// [message] (built from [appStrings] or `AppLocalizations.of(context)!`).
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? required(String? value, {String field = 'This field', String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? '$field is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final r = required(value, message: appStrings.validatorRequired(appStrings.fieldEmail));
    if (r != null) return r;
    if (!_email.hasMatch(value!.trim())) return appStrings.validatorInvalidEmail;
    return null;
  }

  static String? password(String? value, {int min = 6}) {
    final r = required(value, message: appStrings.validatorRequired(appStrings.fieldPassword));
    if (r != null) return r;
    if (value!.length < min) {
      return appStrings.validatorPasswordTooShort(min);
    }
    return null;
  }

  static String? phone(String? value) {
    final r = required(value, message: appStrings.validatorRequired(appStrings.fieldPhone));
    if (r != null) return r;
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value!.trim())) {
      return appStrings.validatorInvalidPhone;
    }
    return null;
  }

  /// Combines multiple validators, returning the first failure.
  static String? compose(String? value, List<String? Function(String?)> rules) {
    for (final rule in rules) {
      final result = rule(value);
      if (result != null) return result;
    }
    return null;
  }
}
