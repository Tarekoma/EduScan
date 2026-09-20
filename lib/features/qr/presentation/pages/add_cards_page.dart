import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/id_card_data.dart';
import '../widgets/qr_person_picker.dart';

/// Pick more people to add to a QR sheet that is already being previewed.
/// Pops with the newly chosen cards, or null if the user backs out.
class AddCardsPage extends StatelessWidget {
  const AddCardsPage({super.key, required this.excluded});

  /// `qrCodeId`s already on the sheet.
  final Set<String> excluded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.printQrAddTitle)),
      body: QrPersonPicker(
        excluded: excluded,
        confirmLabel: (l10n, count) => l10n.printQrAddSelected(count),
        onConfirm: (List<IdCardData> cards) => Navigator.of(context).pop(cards),
      ),
    );
  }
}
