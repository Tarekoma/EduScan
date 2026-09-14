import 'package:flutter/widgets.dart';

import '../../../core/enums/pickup_status.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';

extension PickupStatusDisplay on PickupStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      PickupStatus.pending => l10n.pickupStatusPending,
      PickupStatus.acknowledged => l10n.pickupStatusAcknowledged,
      PickupStatus.completed => l10n.pickupStatusCompleted,
      PickupStatus.cancelled => l10n.pickupStatusCancelled,
    };
  }

  BadgeTone get tone => switch (this) {
    PickupStatus.pending => BadgeTone.warning,
    PickupStatus.acknowledged => BadgeTone.info,
    PickupStatus.completed => BadgeTone.positive,
    PickupStatus.cancelled => BadgeTone.neutral,
  };
}
