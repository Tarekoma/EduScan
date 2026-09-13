/// Lifecycle of a parent pickup request.
enum PickupStatus {
  pending('pending'),
  acknowledged('acknowledged'),
  completed('completed'),
  cancelled('cancelled');

  const PickupStatus(this.value);

  final String value;

  static PickupStatus fromValue(String? value) {
    return PickupStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown PickupStatus: $value'),
    );
  }

  /// An active request blocks the creation of another for the same student.
  bool get isActive =>
      this == PickupStatus.pending || this == PickupStatus.acknowledged;

  bool get isTerminal =>
      this == PickupStatus.completed || this == PickupStatus.cancelled;
}
