import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../domain/entities/student.dart';

class StudentModel extends Student {
  const StudentModel({
    required super.studentId,
    required super.fullName,
    required super.className,
    required super.qrCodeId,
    super.parentId,
    super.createdAt,
    super.updatedAt,
  });

  factory StudentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return StudentModel(
      studentId: doc.id,
      fullName: (data[StudentFields.fullName] as String?) ?? '',
      className: (data[StudentFields.className] as String?) ?? '',
      qrCodeId: (data[StudentFields.qrCodeId] as String?) ?? doc.id,
      parentId: data[StudentFields.parentId] as String?,
      createdAt: (data[StudentFields.createdAt] as Timestamp?)?.toDate(),
      updatedAt: (data[StudentFields.updatedAt] as Timestamp?)?.toDate(),
    );
  }

  /// Payload for create. Timestamps are set with server values by the caller.
  static Map<String, dynamic> newData({
    required String studentId,
    required String fullName,
    required String className,
    String? parentId,
  }) {
    return {
      StudentFields.studentId: studentId,
      StudentFields.fullName: fullName.trim(),
      StudentFields.className: className.trim(),
      StudentFields.qrCodeId: studentId,
      if (parentId != null) StudentFields.parentId: parentId,
      StudentFields.createdAt: FieldValue.serverTimestamp(),
      StudentFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> updateData(Student student) {
    return {
      StudentFields.fullName: student.fullName.trim(),
      StudentFields.className: student.className.trim(),
      if (student.parentId != null) StudentFields.parentId: student.parentId,
      StudentFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }
}
