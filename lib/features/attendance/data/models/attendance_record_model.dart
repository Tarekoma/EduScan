import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/person_type.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.personId,
    required super.personType,
    required super.date,
    super.checkIn,
    super.checkOut,
    super.checkInRecordedBy,
    super.checkInRecordedAt,
    super.checkOutRecordedBy,
    super.checkOutRecordedAt,
    super.updatedBy,
    super.updatedAt,
    super.corrections,
  });

  /// Deterministic document id: `{personType}_{personId}_{date}`.
  static String buildId({
    required String personId,
    required PersonType personType,
    required String date,
  }) => '${personType.value}_${personId}_$date';

  factory AttendanceRecordModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return AttendanceRecordModel(
      id: doc.id,
      personId: (data[AttendanceFields.personId] as String?) ?? '',
      personType: PersonType.fromValue(
        data[AttendanceFields.personType] as String?,
      ),
      date: (data[AttendanceFields.date] as String?) ?? '',
      checkIn: (data[AttendanceFields.checkIn] as Timestamp?)?.toDate(),
      checkOut: (data[AttendanceFields.checkOut] as Timestamp?)?.toDate(),
      checkInRecordedBy: data[AttendanceFields.checkInRecordedBy] as String?,
      checkInRecordedAt:
          (data[AttendanceFields.checkInRecordedAt] as Timestamp?)?.toDate(),
      checkOutRecordedBy: data[AttendanceFields.checkOutRecordedBy] as String?,
      checkOutRecordedAt:
          (data[AttendanceFields.checkOutRecordedAt] as Timestamp?)?.toDate(),
      updatedBy: data[AttendanceFields.updatedBy] as String?,
      updatedAt: (data[AttendanceFields.updatedAt] as Timestamp?)?.toDate(),
      corrections: ((data[AttendanceFields.corrections] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_correctionFromMap)
          .toList(),
    );
  }

  static AttendanceCorrection _correctionFromMap(Map<String, dynamic> m) {
    return AttendanceCorrection(
      field: (m['field'] as String?) ?? '',
      previousValue: m['previousValue'] as String?,
      newValue: m['newValue'] as String?,
      by: (m['by'] as String?) ?? '',
      at:
          (m['at'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static Map<String, dynamic> correctionToMap(AttendanceCorrection c) {
    return {
      'field': c.field,
      'previousValue': c.previousValue,
      'newValue': c.newValue,
      'by': c.by,
      'at': Timestamp.fromDate(c.at),
    };
  }
}
