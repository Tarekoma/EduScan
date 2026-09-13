/// Reusable field validators. Return `null` when valid, otherwise an error
/// string suitable for a `TextFormField`. Do not duplicate these in screens.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    final r = required(value, field: 'Email');
    if (r != null) return r;
    if (!_email.hasMatch(value!.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value, {int min = 6}) {
    final r = required(value, field: 'Password');
    if (r != null) return r;
    if (value!.length < min) {
      return 'Password must be at least $min characters.';
    }
    return null;
  }

  static String? phone(String? value) {
    final r = required(value, field: 'Phone');
    if (r != null) return r;
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value!.trim())) {
      return 'Enter a valid phone number.';
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
