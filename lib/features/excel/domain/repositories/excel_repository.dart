import 'dart:typed_data';

import '../../../../core/enums/person_type.dart';
import '../excel_rows.dart';

class SpreadsheetFile {
  const SpreadsheetFile(this.bytes, this.filename);
  final Uint8List bytes;
  final String filename;
}

class ParsedSheet<T> {
  const ParsedSheet({required this.rows, required this.skipped});
  final List<T> rows;

  /// 1-based source row numbers that could not be parsed.
  final List<int> skipped;
}

abstract interface class ExcelRepository {
  /// Builds an attendance workbook for `[from, to]` (both inclusive), limited
  /// to [personType], resolving person and recorder names.
  Future<SpreadsheetFile> exportAttendance({
    required DateTime from,
    required DateTime to,
    required PersonType personType,
  });

  ParsedSheet<StudentImportRow> parseStudents(Uint8List bytes);

  ParsedSheet<WorkerImportRow> parseWorkers(Uint8List bytes);

  ParsedSheet<AttendanceImportRow> parseAttendance(Uint8List bytes);

  /// Bulk-creates students with sequential ids (manager only). Returns how many
  /// were written.
  Future<ImportOutcome> importStudents(List<StudentImportRow> rows);

  /// Bulk-creates workers with sequential ids (manager only). Returns how many
  /// were written.
  Future<ImportOutcome> importWorkers(List<WorkerImportRow> rows);

  Future<ImportOutcome> importAttendance(List<AttendanceImportRow> rows);
}
