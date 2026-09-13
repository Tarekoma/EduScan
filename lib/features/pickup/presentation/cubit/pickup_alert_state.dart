part of 'pickup_alert_cubit.dart';

class PickupAlertState extends Equatable {
  const PickupAlertState({
    this.pendingCount = 0,
    this.unseen = 0,
    this.lastNewRequest,
  });

  /// Current number of pending requests (for a badge).
  final int pendingCount;

  /// New pending requests not yet shown to the security user.
  final int unseen;

  /// The most recent newly-arrived request, for a banner.
  final PickupRequest? lastNewRequest;

  bool get hasUnseen => unseen > 0;

  PickupAlertState copyWith({
    int? pendingCount,
    int? unseen,
    PickupRequest? lastNewRequest,
    bool clearLastNew = false,
  }) {
    return PickupAlertState(
      pendingCount: pendingCount ?? this.pendingCount,
      unseen: unseen ?? this.unseen,
      lastNewRequest: clearLastNew
          ? null
          : (lastNewRequest ?? this.lastNewRequest),
    );
  }

  @override
  List<Object?> get props => [pendingCount, unseen, lastNewRequest];
}
