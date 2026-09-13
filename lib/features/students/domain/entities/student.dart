import 'package:equatable/equatable.dart';

/// A student whose attendance is tracked. [studentId] and [qrCodeId] are both
/// unique; the QR payload carries only [qrCodeId] — never personal data.
class Student extends Equatable {
  const Student({
    required this.studentId,
    required this.fullName,
    required this.className,
    required this.qrCodeId,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  final String studentId;
  final String fullName;
  final String className;
  final String qrCodeId;

  /// Linked parent's uid, if any. The authoritative link is `users/{parentId}.
  /// studentIds` — this is a convenience back-reference.
  final String? parentId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Student copyWith({String? fullName, String? className, String? parentId}) {
    return Student(
      studentId: studentId,
      fullName: fullName ?? this.fullName,
      className: className ?? this.className,
      qrCodeId: qrCodeId,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    fullName,
    className,
    qrCodeId,
    parentId,
    createdAt,
    updatedAt,
  ];
}
