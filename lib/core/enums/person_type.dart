/// A person whose attendance is tracked.
enum PersonType {
  student('student', 'STU'),
  worker('worker', 'WRK');

  const PersonType(this.value, this.qrPrefix);

  /// Value persisted in Firestore (`attendance/{id}.personType`).
  final String value;

  /// Prefix used in QR identifiers, e.g. `STU_00125`.
  final String qrPrefix;

  static PersonType fromValue(String? value) {
    return PersonType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown PersonType: $value'),
    );
  }

  /// Resolves the [PersonType] encoded in a QR identifier such as `STU_00125`.
  /// Returns `null` when the prefix is not recognised.
  static PersonType? fromQrCode(String raw) {
    final prefix = raw.split('_').first.toUpperCase();
    for (final type in PersonType.values) {
      if (type.qrPrefix == prefix) return type;
    }
    return null;
  }
}
