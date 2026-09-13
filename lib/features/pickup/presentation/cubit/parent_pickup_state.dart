part of 'parent_pickup_cubit.dart';

enum ParentPickupStatus { initial, loading, ready }

class ParentPickupState extends Equatable {
  const ParentPickupState({
    this.status = ParentPickupStatus.initial,
    this.active,
    this.childState = AttendanceState.absent,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final ParentPickupStatus status;
  final PickupRequest? active;

  /// The child's today attendance state. A pickup request may only be sent
  /// while this is [AttendanceState.inside].
  final AttendanceState childState;
  final bool isSubmitting;
  final String? errorMessage;

  ParentPickupState copyWith({
    ParentPickupStatus? status,
    PickupRequest? active,
    bool clearActive = false,
    AttendanceState? childState,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ParentPickupState(
      status: status ?? this.status,
      active: clearActive ? null : (active ?? this.active),
      childState: childState ?? this.childState,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, active, childState, isSubmitting, errorMessage];
}
