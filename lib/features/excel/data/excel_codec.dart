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

  static const _staticHeaders = [
    'Name',
    'Person ID',
    'Person Type',
    'Recorded by',
  ];

  static final _headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.grey200,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  /// One row per person, one date per pair of `Check-in`/`Check-out` columns
  /// (merged header above them shows the date). [rows] is one entry per
  /// person-per-date; grouped here by [AttendanceExportRow.personId].
  /// [dates] (`yyyy-MM-dd`, sorted) is every day of the requested range —
  /// not just the ones with a record — so a day nobody was recorded on still
  /// gets its own (blank) column pair.
  Uint8List buildAttendanceWorkbook(
    List<AttendanceExportRow> rows, {
    required List<String> dates,
  }) {
    final book = Excel.createExcel();
    final sheet = book['Attendance'];
    book.setDefaultSheet('Attendance');
    if (book.sheets.containsKey('Sheet1')) book.delete('Sheet1');

    final byPerson = <String, List<AttendanceExportRow>>{};
    for (final r in rows) {
      (byPerson[r.personId] ??= []).add(r);
    }
    final personIds = byPerson.keys.toList()..sort();

    for (var c = 0; c < _staticHeaders.length; c++) {
      final top = CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0);
      sheet.updateCell(
        top,
        TextCellValue(_staticHeaders[c]),
        cellStyle: _headerStyle,
      );
      sheet.merge(top, CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1));
    }

    for (var i = 0; i < dates.length; i++) {
      final col = _staticHeaders.length + i * 2;
      final top = CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0);
      sheet.updateCell(top, TextCellValue(dates[i]), cellStyle: _headerStyle);
      sheet.merge(
        top,
        CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: 0),
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1),
        TextCellValue('Check-in'),
        cellStyle: _headerStyle,
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: 1),
        TextCellValue('Check-out'),
        cellStyle: _headerStyle,
      );
    }

    var rowIndex = 2;
    for (final personId in personIds) {
      final personRows = byPerson[personId]!
        ..sort((a, b) => a.date.compareTo(b.date));
      final byDate = {for (final r in personRows) r.date: r};
      final first = personRows.first;

      var recordedBy = '';
      for (final r in personRows) {
        if (r.recordedBy.isNotEmpty) recordedBy = r.recordedBy;
      }

      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        TextCellValue(first.name),
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        TextCellValue(personId),
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        TextCellValue(first.personType.value),
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        TextCellValue(recordedBy),
      );

      for (var i = 0; i < dates.length; i++) {
        final col = _staticHeaders.length + i * 2;
        final record = byDate[dates[i]];
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          TextCellValue(
            record?.checkIn == null
                ? ''
                : _time.format(record!.checkIn!.toLocal()),
          ),
        );
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: rowIndex),
          TextCellValue(
            record?.checkOut == null
                ? ''
                : _time.format(record!.checkOut!.toLocal()),
          ),
        );
      }
      rowIndex++;
    }

    sheet.setColumnWidth(0, 22);
    sheet.setColumnWidth(3, 20);

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
