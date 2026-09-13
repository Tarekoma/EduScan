import '../enums/person_type.dart';

/// Builds and parses the human-readable identifiers used for students and
/// workers, e.g. `STU_00125`, `WRK_00015`. The same value is used as the
/// Firestore document id, the `qrCodeId`, and the QR payload.
abstract final class PersonId {
  static const int _padWidth = 5;

  static String format(PersonType type, int sequence) {
    return '${type.qrPrefix}_${sequence.toString().padLeft(_padWidth, '0')}';
  }

  /// Returns the numeric part of an id, or `null` when malformed.
  static int? sequenceOf(String id) {
    final parts = id.split('_');
    if (parts.length != 2) return null;
    return int.tryParse(parts[1]);
  }

  static bool isValid(String id, PersonType type) {
    final parts = id.split('_');
    return parts.length == 2 &&
        parts[0].toUpperCase() == type.qrPrefix &&
        int.tryParse(parts[1]) != null;
  }
}
