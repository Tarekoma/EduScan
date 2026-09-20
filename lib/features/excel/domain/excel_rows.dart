import '../../../core/enums/person_type.dart';
import '../../../core/enums/worker_job_title.dart';

/// One row of an attendance export.
class AttendanceExportRow {
  const AttendanceExportRow({
    required this.date,
    required this.personId,
    required this.name,
    required this.personType,
    required this.checkIn,
    required this.checkOut,
    required this.recordedBy,
    required this.recordedAt,
  });

  final String date;
  final String personId;
  final String name;
  final PersonType personType;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String recordedBy;
  final DateTime? recordedAt;
}

/// A registered person included in an attendance export even when they have
/// no record in the range (so an absence can be reported for them).
class AttendanceExportPerson {
  const AttendanceExportPerson({
    required this.personId,
    required this.name,
    required this.personType,
  });

  final String personId;
  final String name;
  final PersonType personType;
}

/// A parsed student row awaiting import.
class StudentImportRow {
  const StudentImportRow({required this.fullName, required this.className});

  final String fullName;
  final String className;

  Map<String, String> toJson() => {
    'fullName': fullName,
    'className': className,
  };
}

/// A parsed worker row awaiting import.
class WorkerImportRow {
  const WorkerImportRow({required this.fullName, required this.jobTitle});

  final String fullName;
  final WorkerJobTitle jobTitle;

  Map<String, String> toJson() => {
    'fullName': fullName,
    'jobTitle': jobTitle.value,
  };
}

/// A parsed historical attendance row awaiting import.
class AttendanceImportRow {
  const AttendanceImportRow({
    required this.date,
    required this.personId,
    required this.personType,
    this.checkIn,
    this.checkOut,
  });

  final String date;
  final String personId;
  final PersonType personType;

  /// `HH:mm` local time, or null.
  final String? checkIn;
  final String? checkOut;

  Map<String, String?> toJson() => {
    'date': date,
    'personId': personId,
    'personType': personType.value,
    'checkIn': checkIn,
    'checkOut': checkOut,
  };
}

class ImportOutcome {
  const ImportOutcome({required this.count, this.ids = const []});
  final int count;
  final List<String> ids;
}
