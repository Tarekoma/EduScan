import 'package:flutter/material.dart';

import '../../../../core/enums/pickup_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/pickup_request.dart';
import '../pickup_status_display.dart';

/// Reusable security-facing card for one pickup request.
class PickupRequestCard extends StatelessWidget {
  const PickupRequestCard({
    super.key,
    required this.request,
    required this.busy,
    required this.onAcknowledge,
    required this.onComplete,
    required this.onCancel,
    this.highlight = false,
  });

  final PickupRequest request;
  final bool busy;
  final VoidCallback onAcknowledge;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPending = request.status == PickupStatus.pending;
    return Card(
      color: highlight ? scheme.tertiaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.studentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: request.status.label,
                  tone: request.status.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [
                request.studentId,
                if (request.className != null) 'Class ${request.className}',
              ].join(' • '),
            ),
            Text('Parent: ${request.parentName}'),
            Text('Requested: ${TimeFormat.dateTime(request.requestedAt)}'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (isPending)
                  FilledButton.tonal(
                    onPressed: busy ? null : onAcknowledge,
                    child: const Text('Acknowledge'),
                  ),
                FilledButton(
                  onPressed: busy ? null : onComplete,
                  child: const Text('Mark completed'),
                ),
                TextButton(
                  onPressed: busy ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
