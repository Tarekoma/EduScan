import '../../../../core/enums/person_type.dart';
import '../entities/attendance_record.dart';

/// Who is performing an attendance operation. Carried for audit and for the
/// client-side authorisation check (server rules remain authoritative).
class AttendanceActor {
  const AttendanceActor({required this.uid, required this.canRecord});

  final String uid;

  /// `UserRole.security` only.
  final bool canRecord;
}

/// A requested change to check-in / check-out times during a correction.
class AttendanceCorrectionInput {
  const AttendanceCorrectionInput({this.checkIn, this.checkOut});

  final DateTime? checkIn;
  final DateTime? checkOut;
}

abstract interface class AttendanceRepository {
  Future<AttendanceRecord?> getRecord({
    required String personId,
    required PersonType personType,
    required String date,
  });

  Stream<AttendanceRecord?> watchRecord({
    required String personId,
    required PersonType personType,
    required String date,
  });

  Stream<List<AttendanceRecord>> watchByDate(String date);

  /// One-shot fetch of all records with `date` in `[fromDate, toDate]`
  /// (both `yyyy-MM-dd`). Used for reporting / export.
  Future<List<AttendanceRecord>> getInRange({
    required String fromDate,
    required String toDate,
  });

  Stream<List<AttendanceRecord>> watchByPerson({
    required String personId,
    required PersonType personType,
    int limit,
  });

  /// Atomically checks in the person for [date], enforcing the business rules
  /// inside a transaction. Returns the resulting record.
  Future<AttendanceRecord> checkIn({
    required String personId,
    required PersonType personType,
    required String date,
    required AttendanceActor actor,
  });

  Future<AttendanceRecord> checkOut({
    required String personId,
    required PersonType personType,
    required String date,
    required AttendanceActor actor,
  });

  /// Corrects check-in / check-out times, appending an audit entry and never
  /// erasing the original recorded-by / recorded-at values.
  Future<AttendanceRecord> correct({
    required String recordId,
    required AttendanceCorrectionInput input,
    required AttendanceActor actor,
  });
}
