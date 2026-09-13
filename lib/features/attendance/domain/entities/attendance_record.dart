import 'package:equatable/equatable.dart';

import '../../../../core/enums/attendance_state.dart';
import '../../../../core/enums/person_type.dart';

/// One person's attendance for one calendar day.
///
/// The document id is deterministic — `{personType}_{personId}_{date}` — so
/// check-in is naturally idempotent and there is exactly one record per
/// person per day.
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.personId,
    required this.personType,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.checkInRecordedBy,
    this.checkInRecordedAt,
    this.checkOutRecordedBy,
    this.checkOutRecordedAt,
    this.updatedBy,
    this.updatedAt,
    this.corrections = const [],
  });

  final String id;
  final String personId;
  final PersonType personType;
  final String date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? checkInRecordedBy;
  final DateTime? checkInRecordedAt;
  final String? checkOutRecordedBy;
  final DateTime? checkOutRecordedAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final List<AttendanceCorrection> corrections;

  AttendanceState get state {
    if (checkIn == null) return AttendanceState.absent;
    if (checkOut == null) return AttendanceState.inside;
    return AttendanceState.left;
  }

  bool get isInside => state == AttendanceState.inside;

  @override
  List<Object?> get props => [
    id,
    personId,
    personType,
    date,
    checkIn,
    checkOut,
    checkInRecordedBy,
    checkInRecordedAt,
    checkOutRecordedBy,
    checkOutRecordedAt,
    updatedBy,
    updatedAt,
    corrections,
  ];
}

/// A single audited manual correction to a record.
class AttendanceCorrection extends Equatable {
  const AttendanceCorrection({
    required this.field,
    required this.previousValue,
    required this.newValue,
    required this.by,
    required this.at,
  });

  final String field;
  final String? previousValue;
  final String? newValue;
  final String by;
  final DateTime at;

  @override
  List<Object?> get props => [field, previousValue, newValue, by, at];
}
