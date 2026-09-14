import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/person_qr_view.dart';

/// Displays a single person's QR code full-screen for viewing or printing.
class PersonQrPage extends StatelessWidget {
  const PersonQrPage({
    super.key,
    required this.value,
    required this.title,
    this.subtitle,
  });

  final String value;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.qrCodeTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: PersonQrView(value: value, title: title, subtitle: subtitle),
          ),
        ),
      ),
    );
  }
}
