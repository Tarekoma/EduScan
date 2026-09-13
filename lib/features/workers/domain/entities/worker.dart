import 'package:equatable/equatable.dart';

/// A worker (teacher / staff) whose attendance is tracked. [workerId] and
/// [qrCodeId] are both unique. [phone] is shown only to authorised internal
/// users (e.g. security contacting a teacher during pickup).
class Worker extends Equatable {
  const Worker({
    required this.workerId,
    required this.fullName,
    required this.job,
    required this.qrCodeId,
    this.department,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  final String workerId;
  final String fullName;
  final String job;
  final String qrCodeId;
  final String? department;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Worker copyWith({
    String? fullName,
    String? job,
    String? department,
    String? phone,
  }) {
    return Worker(
      workerId: workerId,
      fullName: fullName ?? this.fullName,
      job: job ?? this.job,
      qrCodeId: qrCodeId,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    workerId,
    fullName,
    job,
    qrCodeId,
    department,
    phone,
    createdAt,
    updatedAt,
  ];
}
