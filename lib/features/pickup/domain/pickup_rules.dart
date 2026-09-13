import '../../../core/enums/pickup_status.dart';
import '../../../core/errors/app_exception.dart';

/// Centralised pickup status-transition rules (spec Pickup rules 4, 5, 7).
abstract final class PickupRules {
  static const Map<PickupStatus, Set<PickupStatus>> _allowed = {
    PickupStatus.pending: {PickupStatus.acknowledged, PickupStatus.cancelled},
    PickupStatus.acknowledged: {PickupStatus.completed, PickupStatus.cancelled},
    PickupStatus.completed: {},
    PickupStatus.cancelled: {},
  };

  static bool canTransition(PickupStatus from, PickupStatus to) =>
      _allowed[from]?.contains(to) ?? false;

  static void assertTransition(PickupStatus from, PickupStatus to) {
    if (!canTransition(from, to)) {
      throw BusinessRuleException(
        'Cannot change a ${from.value} pickup request to ${to.value}.',
      );
    }
  }
}
