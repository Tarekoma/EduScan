import 'package:equatable/equatable.dart';

import '../../../../core/enums/person_type.dart';

/// The outcome of resolving a scanned QR payload to a real person.
class ResolvedPerson extends Equatable {
  const ResolvedPerson({
    required this.personId,
    required this.personType,
    required this.displayName,
    this.subtitle,
  });

  final String personId;
  final PersonType personType;
  final String displayName;

  /// Class (student) or job title (worker), for confirmation UI.
  final String? subtitle;

  @override
  List<Object?> get props => [personId, personType, displayName, subtitle];
}
