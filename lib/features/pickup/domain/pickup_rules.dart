import '../../../core/enums/pickup_status.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/app_strings.dart';

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
        appStrings.pickupCannotTransition(_plainLabel(from), _plainLabel(to)),
      );
    }
  }

  /// No [BuildContext] is available this deep in the domain layer — labels
  /// the raw [PickupStatus] with the current locale directly instead of
  /// leaking `.value` (a DB key like `'pending'`) into a user-facing message.
  static String _plainLabel(PickupStatus status) {
    final l10n = appStrings;
    return switch (status) {
      PickupStatus.pending => l10n.pickupStatusPending,
      PickupStatus.acknowledged => l10n.pickupStatusAcknowledged,
      PickupStatus.completed => l10n.pickupStatusCompleted,
      PickupStatus.cancelled => l10n.pickupStatusCancelled,
    };
  }
}
