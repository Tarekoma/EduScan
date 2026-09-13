part of 'security_pickup_cubit.dart';

enum PickupQueueStatus { initial, loading, ready, error }

class SecurityPickupState extends Equatable {
  const SecurityPickupState({
    this.status = PickupQueueStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.isMutating = false,
    this.actionError,
  });

  final PickupQueueStatus status;
  final List<PickupRequest> requests;
  final String? errorMessage;
  final bool isMutating;
  final String? actionError;

  List<PickupRequest> get pending =>
      requests.where((r) => r.status == PickupStatus.pending).toList();

  SecurityPickupState copyWith({
    PickupQueueStatus? status,
    List<PickupRequest>? requests,
    String? errorMessage,
    bool clearError = false,
    bool? isMutating,
    String? actionError,
    bool clearActionError = false,
  }) {
    return SecurityPickupState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isMutating: isMutating ?? this.isMutating,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    status,
    requests,
    errorMessage,
    isMutating,
    actionError,
  ];
}
