import 'dart:typed_data';

import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/features/excel/data/excel_codec.dart';
import 'package:attendance_management/features/excel/domain/excel_rows.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _sheet(List<List<String>> rows) {
  final book = Excel.createExcel();
  final sheet = book['Sheet1'];
  for (final r in rows) {
    sheet.appendRow(r.map(TextCellValue.new).toList());
  }
  return Uint8List.fromList(book.save()!);
}

void main() {
  final codec = ExcelCodec();

  test('buildAttendanceWorkbook writes a header row and data', () {
    final bytes = codec.buildAttendanceWorkbook([
      AttendanceExportRow(
        date: '2026-09-10',
        personId: 'STU_00001',
        name: 'Ahmed',
        personType: PersonType.student,
        checkIn: DateTime(2026, 9, 10, 7, 42),
        checkOut: null,
        recordedBy: 'Sam',
        recordedAt: DateTime(2026, 9, 10, 7, 42),
      ),
    ]);
    final book = Excel.decodeBytes(bytes);
    final rows = book.tables['Attendance']!.rows;
    expect(rows.first.first!.value.toString(), 'Date');
    expect(rows[1][1]!.value.toString(), 'STU_00001');
    expect(rows[1][4]!.value.toString(), '07:42');
  });

  test('parseStudents reads headers case-insensitively and reports skips', () {
    final bytes = _sheet([
      ['FullName', 'ClassName'],
      ['Ahmed Mohamed', '5A'],
      ['', '5B'], // skipped: no name
      ['Sara Ali', '6C'],
    ]);
    final parsed = codec.parseStudents(bytes);
    expect(parsed.rows.map((r) => r.fullName), ['Ahmed Mohamed', 'Sara Ali']);
    expect(parsed.skipped, [3]);
  });

  test('parseAttendance normalises dates/times and infers type from id', () {
    final bytes = _sheet([
      ['Date', 'Person ID', 'Person Type', 'Check-in', 'Check-out'],
      ['2026-09-10', 'stu_00001', '', '7:42', '14:05'],
      ['10/09/2026', 'WRK_00002', 'worker', '08:00', ''],
      ['bad', 'STU_9', 'student', '', ''], // skipped: bad date
    ]);
    final parsed = codec.parseAttendance(bytes);
    expect(parsed.rows.length, 2);
    expect(parsed.rows[0].personId, 'STU_00001');
    expect(parsed.rows[0].personType, PersonType.student);
    expect(parsed.rows[0].checkIn, '07:42');
    expect(parsed.rows[1].date, '2026-09-10');
    expect(parsed.rows[1].personType, PersonType.worker);
    expect(parsed.skipped, [4]);
  });
}
