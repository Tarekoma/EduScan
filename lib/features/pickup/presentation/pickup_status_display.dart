import '../../../core/enums/pickup_status.dart';
import '../../../core/widgets/status_badge.dart';

extension PickupStatusDisplay on PickupStatus {
  String get label => switch (this) {
    PickupStatus.pending => 'Pending',
    PickupStatus.acknowledged => 'Acknowledged',
    PickupStatus.completed => 'Completed',
    PickupStatus.cancelled => 'Cancelled',
  };

  BadgeTone get tone => switch (this) {
    PickupStatus.pending => BadgeTone.warning,
    PickupStatus.acknowledged => BadgeTone.info,
    PickupStatus.completed => BadgeTone.positive,
    PickupStatus.cancelled => BadgeTone.neutral,
  };
}
