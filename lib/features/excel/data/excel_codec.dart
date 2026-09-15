import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/enums/person_type.dart';
import '../../../core/enums/worker_job_title.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/app_strings.dart';
import '../domain/excel_rows.dart';
import '../domain/repositories/excel_repository.dart';

/// Pure Excel (de)serialisation. No Firebase, no IO — just bytes ⇄ rows.
class ExcelCodec {
  static final _time = DateFormat('HH:mm');

  static const _attendanceHeaders = [
    'Date',
    'Person ID',
    'Name',
    'Person Type',
    'Check-in',
    'Check-out',
    'Recorded by',
    'Recorded at',
  ];

  Uint8List buildAttendanceWorkbook(List<AttendanceExportRow> rows) {
    final book = Excel.createExcel();
    final sheet = book['Attendance'];
    book.setDefaultSheet('Attendance');
    if (book.sheets.containsKey('Sheet1')) book.delete('Sheet1');

    sheet.appendRow(_attendanceHeaders.map(TextCellValue.new).toList());
    for (final r in rows) {
      sheet.appendRow([
        TextCellValue(r.date),
        TextCellValue(r.personId),
        TextCellValue(r.name),
        TextCellValue(r.personType.value),
        TextCellValue(
          r.checkIn == null ? '' : _time.format(r.checkIn!.toLocal()),
        ),
        TextCellValue(
          r.checkOut == null ? '' : _time.format(r.checkOut!.toLocal()),
        ),
        TextCellValue(r.recordedBy),
        TextCellValue(
          r.recordedAt == null
              ? ''
              : DateFormat('yyyy-MM-dd HH:mm').format(r.recordedAt!.toLocal()),
        ),
      ]);
    }

    final bytes = book.save();
    if (bytes == null) {
      throw UnknownException(message: appStrings.excelCouldNotBuildWorkbook);
    }
    return Uint8List.fromList(bytes);
  }

  /// Reads the first sheet as a list of `header → value` maps (lower-cased,
  /// trimmed headers). Skips fully empty rows.
  List<Map<String, String>> _readSheet(Uint8List bytes) {
    final Excel book;
    try {
      book = Excel.decodeBytes(bytes);
    } catch (_) {
      throw ValidationException(appStrings.excelInvalidWorkbook);
    }
    if (book.tables.isEmpty) return const [];
    final table = book.tables.values.first;
    if (table.rows.isEmpty) return const [];

    String cell(Data? d) => (d?.value?.toString() ?? '').trim();

    final headers = table.rows.first.map((d) => cell(d).toLowerCase()).toList();
    final result = <Map<String, String>>[];
    for (final row in table.rows.skip(1)) {
      final values = [
        for (var i = 0; i < headers.length; i++)
          cell(i < row.length ? row[i] : null),
      ];
      if (values.every((v) => v.isEmpty)) continue;
      result.add({
        for (var i = 0; i < headers.length; i++) headers[i]: values[i],
      });
    }
    return result;
  }

  ParsedSheet<StudentImportRow> parseStudents(Uint8List bytes) {
    final rows = <StudentImportRow>[];
    final skipped = <int>[];
    var line = 1;
    for (final m in _readSheet(bytes)) {
      line++;
      final name = m['fullname'] ?? m['name'] ?? '';
      final className = m['classname'] ?? m['class'] ?? '';
      if (name.isEmpty || className.isEmpty) {
        skipped.add(line);
        continue;
      }
      rows.add(StudentImportRow(fullName: name, className: className));
    }
    return ParsedSheet(rows: rows, skipped: skipped);
  }

  ParsedSheet<WorkerImportRow> parseWorkers(Uint8List bytes) {
    final rows = <WorkerImportRow>[];
    final skipped = <int>[];
    var line = 1;
    for (final m in _readSheet(bytes)) {
      line++;
      final name = m['fullname'] ?? m['name'] ?? '';
      final jobTitleRaw = m['jobtitle'] ?? m['job title'] ?? '';
      if (name.isEmpty || jobTitleRaw.isEmpty) {
        skipped.add(line);
        continue;
      }
      rows.add(
        WorkerImportRow(
          fullName: name,
          jobTitle: WorkerJobTitle.fromValue(jobTitleRaw.trim().toLowerCase()),
        ),
      );
    }
    return ParsedSheet(rows: rows, skipped: skipped);
  }

  ParsedSheet<AttendanceImportRow> parseAttendance(Uint8List bytes) {
    final rows = <AttendanceImportRow>[];
    final skipped = <int>[];
    var line = 1;
    for (final m in _readSheet(bytes)) {
      line++;
      final date = _normaliseDate(m['date'] ?? '');
      final personId = (m['person id'] ?? m['personid'] ?? '').toUpperCase();
      final typeRaw = (m['person type'] ?? m['persontype'] ?? '').toLowerCase();
      final type = _personTypeOf(typeRaw, personId);
      if (date == null || personId.isEmpty || type == null) {
        skipped.add(line);
        continue;
      }
      rows.add(
        AttendanceImportRow(
          date: date,
          personId: personId,
          personType: type,
          checkIn: _normaliseTime(m['check-in'] ?? m['checkin'] ?? ''),
          checkOut: _normaliseTime(m['check-out'] ?? m['checkout'] ?? ''),
        ),
      );
    }
    return ParsedSheet(rows: rows, skipped: skipped);
  }

  static String? _normaliseDate(String raw) {
    final v = raw.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return v;
    // A real Excel date cell (not text) round-trips as an ISO-8601 instant,
    // e.g. "2026-09-06T00:00:00.000Z" — the calendar date is its first 10
    // characters regardless of the time-of-day/offset suffix.
    if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(v)) return v.substring(0, 10);
    for (final f in ['d/M/yyyy', 'M/d/yyyy', 'dd-MM-yyyy']) {
      try {
        return DateFormat('yyyy-MM-dd').format(DateFormat(f).parseStrict(v));
      } catch (_) {
        // try next
      }
    }
    return null;
  }

  static String? _normaliseTime(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    // A real Excel date+time cell round-trips as an ISO-8601 instant, e.g.
    // "2026-09-06T08:15:00.000Z" — the time-of-day is right after the "T".
    final isoMatch = RegExp(
      r'^\d{4}-\d{2}-\d{2}T(\d{1,2}):(\d{2})',
    ).firstMatch(v);
    final m = isoMatch ?? RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(v);
    if (m == null) return null;
    return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
  }

  static PersonType? _personTypeOf(String raw, String personId) {
    if (raw == 'student' || personId.startsWith('STU')) {
      return PersonType.student;
    }
    if (raw == 'worker' || personId.startsWith('WRK')) return PersonType.worker;
    return null;
  }
}
