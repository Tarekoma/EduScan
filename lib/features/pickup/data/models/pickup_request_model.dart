import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/pickup_status.dart';
import '../../domain/entities/pickup_request.dart';

class PickupRequestModel extends PickupRequest {
  const PickupRequestModel({
    required super.requestId,
    required super.studentId,
    required super.parentId,
    required super.parentName,
    required super.studentName,
    required super.status,
    super.className,
    super.requestedAt,
    super.acknowledgedAt,
    super.completedAt,
    super.cancelledAt,
    super.handledBy,
  });

  factory PickupRequestModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return PickupRequestModel(
      requestId: doc.id,
      studentId: (data[PickupFields.studentId] as String?) ?? '',
      parentId: (data[PickupFields.parentId] as String?) ?? '',
      parentName: (data[PickupFields.parentName] as String?) ?? '',
      studentName: (data[PickupFields.studentName] as String?) ?? '',
      status: PickupStatus.fromValue(data[PickupFields.status] as String?),
      className: data[PickupFields.className] as String?,
      requestedAt: (data[PickupFields.requestedAt] as Timestamp?)?.toDate(),
      acknowledgedAt: (data[PickupFields.acknowledgedAt] as Timestamp?)
          ?.toDate(),
      completedAt: (data[PickupFields.completedAt] as Timestamp?)?.toDate(),
      cancelledAt: (data[PickupFields.cancelledAt] as Timestamp?)?.toDate(),
      handledBy: data[PickupFields.handledBy] as String?,
    );
  }

  static Map<String, dynamic> newData({
    required String requestId,
    required String studentId,
    required String studentName,
    String? className,
    required String parentId,
    required String parentName,
  }) {
    return {
      PickupFields.requestId: requestId,
      PickupFields.studentId: studentId,
      PickupFields.studentName: studentName,
      if (className != null && className.isNotEmpty)
        PickupFields.className: className,
      PickupFields.parentId: parentId,
      PickupFields.parentName: parentName,
      PickupFields.status: PickupStatus.pending.value,
      PickupFields.requestedAt: FieldValue.serverTimestamp(),
    };
  }
}
