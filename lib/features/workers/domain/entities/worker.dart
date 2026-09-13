import 'package:equatable/equatable.dart';

import '../../../../core/enums/worker_job_title.dart';

/// A worker whose attendance is tracked. [workerId] and [qrCodeId] are both
/// unique. [jobTitle] is directory information only — independent of
/// `users`/{uid}.role and unrelated to authentication permissions.
class Worker extends Equatable {
  const Worker({
    required this.workerId,
    required this.fullName,
    required this.jobTitle,
    required this.qrCodeId,
    this.createdAt,
    this.updatedAt,
  });

  final String workerId;
  final String fullName;
  final WorkerJobTitle jobTitle;
  final String qrCodeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Worker copyWith({String? fullName, WorkerJobTitle? jobTitle}) {
    return Worker(
      workerId: workerId,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      qrCodeId: qrCodeId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    workerId,
    fullName,
    jobTitle,
    qrCodeId,
    createdAt,
    updatedAt,
  ];
}
