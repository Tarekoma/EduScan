import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/enums/person_type.dart';
import '../../../core/errors/app_exception.dart';
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
      throw const UnknownException(message: 'Could not build the workbook.');
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
      throw const ValidationException(
        'That file is not a valid .xlsx workbook.',
      );
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
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(v);
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
