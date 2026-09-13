import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../domain/entities/worker.dart';

class WorkerModel extends Worker {
  const WorkerModel({
    required super.workerId,
    required super.fullName,
    required super.job,
    required super.qrCodeId,
    super.department,
    super.phone,
    super.createdAt,
    super.updatedAt,
  });

  factory WorkerModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return WorkerModel(
      workerId: doc.id,
      fullName: (data[WorkerFields.fullName] as String?) ?? '',
      job: (data[WorkerFields.job] as String?) ?? '',
      qrCodeId: (data[WorkerFields.qrCodeId] as String?) ?? doc.id,
      department: data[WorkerFields.department] as String?,
      phone: data[WorkerFields.phone] as String?,
      createdAt: (data[WorkerFields.createdAt] as Timestamp?)?.toDate(),
      updatedAt: (data[WorkerFields.updatedAt] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> newData({
    required String workerId,
    required String fullName,
    required String job,
    String? department,
    String? phone,
  }) {
    return {
      WorkerFields.workerId: workerId,
      WorkerFields.fullName: fullName.trim(),
      WorkerFields.job: job.trim(),
      WorkerFields.qrCodeId: workerId,
      if (department != null && department.trim().isNotEmpty)
        WorkerFields.department: department.trim(),
      if (phone != null && phone.trim().isNotEmpty)
        WorkerFields.phone: phone.trim(),
      WorkerFields.createdAt: FieldValue.serverTimestamp(),
      WorkerFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> updateData(Worker worker) {
    return {
      WorkerFields.fullName: worker.fullName.trim(),
      WorkerFields.job: worker.job.trim(),
      WorkerFields.department: worker.department?.trim(),
      WorkerFields.phone: worker.phone?.trim(),
      WorkerFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }
}
