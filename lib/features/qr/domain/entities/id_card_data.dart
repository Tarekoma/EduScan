import 'package:equatable/equatable.dart';

/// Everything printed on one ID card. [qrValue] is the person's existing
/// `qrCodeId` — the card never encodes anything else.
class IdCardData extends Equatable {
  const IdCardData({
    required this.personId,
    required this.fullName,
    required this.qrValue,
    required this.typeLabel,
    this.detail,
  });

  /// Human-readable ID printed under the name (e.g. `STU_00144`).
  final String personId;
  final String fullName;
  final String qrValue;

  /// Localized category shown in the card header (e.g. "STUDENT").
  final String typeLabel;

  /// Class or job title, when available.
  final String? detail;

  @override
  List<Object?> get props => [personId, fullName, qrValue, typeLabel, detail];
}
