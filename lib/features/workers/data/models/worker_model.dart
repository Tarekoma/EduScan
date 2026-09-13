import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/worker_job_title.dart';
import '../../domain/entities/worker.dart';

class WorkerModel extends Worker {
  const WorkerModel({
    required super.workerId,
    required super.fullName,
    required super.jobTitle,
    required super.qrCodeId,
    super.createdAt,
    super.updatedAt,
  });

  factory WorkerModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return WorkerModel(
      workerId: doc.id,
      fullName: (data[WorkerFields.fullName] as String?) ?? '',
      jobTitle: WorkerJobTitle.fromValue(
        data[WorkerFields.jobTitle] as String?,
      ),
      qrCodeId: (data[WorkerFields.qrCodeId] as String?) ?? doc.id,
      createdAt: (data[WorkerFields.createdAt] as Timestamp?)?.toDate(),
      updatedAt: (data[WorkerFields.updatedAt] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> newData({
    required String workerId,
    required String fullName,
    required WorkerJobTitle jobTitle,
  }) {
    return {
      WorkerFields.workerId: workerId,
      WorkerFields.fullName: fullName.trim(),
      WorkerFields.jobTitle: jobTitle.value,
      WorkerFields.qrCodeId: workerId,
      WorkerFields.createdAt: FieldValue.serverTimestamp(),
      WorkerFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> updateData(Worker worker) {
    return {
      WorkerFields.fullName: worker.fullName.trim(),
      WorkerFields.jobTitle: worker.jobTitle.value,
      WorkerFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }
}
