import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';

/// Reusable QR card for a student or worker. The [value] is the person's
/// `qrCodeId` only — never personal data.
class PersonQrView extends StatelessWidget {
  const PersonQrView({
    super.key,
    required this.value,
    required this.title,
    this.subtitle,
    this.size = 240,
  });

  final String value;
  final String title;
  final String? subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: QrImageView(
                data: value,
                version: QrVersions.auto,
                size: size,
                gapless: false,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              value,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
