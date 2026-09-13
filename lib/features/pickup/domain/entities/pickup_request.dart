import 'package:equatable/equatable.dart';

import '../../../../core/enums/pickup_status.dart';

/// A parent's request to collect their child, and its lifecycle timestamps.
class PickupRequest extends Equatable {
  const PickupRequest({
    required this.requestId,
    required this.studentId,
    required this.parentId,
    required this.parentName,
    required this.studentName,
    required this.status,
    this.className,
    this.requestedAt,
    this.acknowledgedAt,
    this.completedAt,
    this.cancelledAt,
    this.handledBy,
  });

  final String requestId;
  final String studentId;
  final String parentId;
  final String parentName;
  final String studentName;
  final PickupStatus status;
  final String? className;
  final DateTime? requestedAt;
  final DateTime? acknowledgedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? handledBy;

  bool get isActive => status.isActive;

  @override
  List<Object?> get props => [
    requestId,
    studentId,
    parentId,
    parentName,
    studentName,
    status,
    className,
    requestedAt,
    acknowledgedAt,
    completedAt,
    cancelledAt,
    handledBy,
  ];
}
