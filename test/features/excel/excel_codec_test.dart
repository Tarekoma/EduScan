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

  test(
    'buildAttendanceWorkbook pivots one row per person, one Check-in/'
    'Check-out column pair per date',
    () {
      final bytes = codec.buildAttendanceWorkbook(
        [
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
          AttendanceExportRow(
            date: '2026-09-11',
            personId: 'STU_00001',
            name: 'Ahmed',
            personType: PersonType.student,
            checkIn: DateTime(2026, 9, 11, 7, 50),
            checkOut: DateTime(2026, 9, 11, 14, 5),
            recordedBy: '',
            recordedAt: DateTime(2026, 9, 11, 7, 50),
          ),
        ],
        // Requested range spans a third day with no record at all — it must
        // still get its own (blank) column pair, not just the dates that
        // happen to appear in `rows`.
        dates: const ['2026-09-10', '2026-09-11', '2026-09-12'],
        now: DateTime(2026, 9, 12, 10), // 09-12 still open: not absent
      );
      final book = Excel.decodeBytes(bytes);
      final sheet = book.tables['Attendance']!;
      String cell(int col, int row) =>
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value
              ?.toString() ??
          '';

      // Header: Name, Person ID, Person Type, Recorded by, then 3 dates x 2 cols.
      expect(cell(0, 0), 'Name');
      expect(cell(3, 0), 'Recorded by');
      expect(cell(4, 0), '2026-09-10');
      expect(cell(6, 0), '2026-09-11');
      expect(cell(8, 0), '2026-09-12');
      expect(cell(4, 1), 'Check-in');
      expect(cell(5, 1), 'Check-out');

      // One data row for Ahmed; "Recorded by" carries forward the last known
      // recorder when a later date's record has none of its own.
      expect(cell(0, 2), 'Ahmed');
      expect(cell(1, 2), 'STU_00001');
      expect(cell(3, 2), 'Sam');
      expect(cell(4, 2), '07:42:00');
      expect(cell(5, 2), ''); // no checkout on 09-10
      expect(cell(6, 2), '07:50:00');
      expect(cell(7, 2), '14:05:00');
      expect(cell(8, 2), ''); // no record at all on 09-12
      expect(cell(9, 2), '');
    },
  );

  test('absence: closed days without check-in are marked, open days are not', () {
    AttendanceExportRow row(String date, DateTime? i, DateTime? o) =>
        AttendanceExportRow(
          date: date,
          personId: 'STU_00001',
          name: 'Ahmed',
          personType: PersonType.student,
          checkIn: i,
          checkOut: o,
          recordedBy: '',
          recordedAt: i,
        );
    const roster = [
      AttendanceExportPerson(
        personId: 'STU_00002',
        name: 'Omar',
        personType: PersonType.student,
      ),
    ];
    Data at(Uint8List b, int col, int r) => Excel.decodeBytes(b)
        .tables['Attendance']!
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r));
    String v(Uint8List b, int col, int r) =>
        at(b, col, r).value?.toString() ?? '';

    final dates = ['2026-09-10', '2026-09-11', '2026-09-12'];
    final rows = [
      // 09-10: checked in, never checked out -> keep in, out stays empty.
      row('2026-09-10', DateTime(2026, 9, 10, 8), null),
      // 09-11: no check-in at all -> absent once closed.
      // 09-12: no record, "now" is before 18:00 -> not absent yet.
    ];
    final before = codec.buildAttendanceWorkbook(
      rows,
      dates: dates,
      roster: roster,
      now: DateTime(2026, 9, 12, 17, 59),
    );
    expect(v(before, 4, 2), '08:00:00');
    expect(v(before, 5, 2), ''); // in but no out: not absent
    expect(v(before, 6, 2), ExcelCodec.absentMarker);
    expect(v(before, 7, 2), ExcelCodec.absentMarker);
    expect(v(before, 8, 2), ''); // 17:59 -> still open
    expect(v(before, 9, 2), '');
    // Roster-only person (no records) is listed and absent on closed days.
    expect(v(before, 0, 3), 'Omar');
    expect(v(before, 4, 3), ExcelCodec.absentMarker);
    expect(v(before, 8, 3), '');

    final after = codec.buildAttendanceWorkbook(
      rows,
      dates: dates,
      roster: roster,
      now: DateTime(2026, 9, 12, 18),
    );
    expect(v(after, 8, 2), ExcelCodec.absentMarker);
    expect(v(after, 9, 2), ExcelCodec.absentMarker);
    expect(v(after, 5, 2), ''); // still not absent

    // Time cells are real Excel time values, not text.
    expect(at(after, 4, 2).value, isA<TimeCellValue>());
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

  test(
    'parseAttendance reads native Excel date/time cells, not just text',
    () {
      final book = Excel.createExcel();
      final sheet = book['Sheet1'];
      sheet.appendRow(
        ['Date', 'Person ID', 'Person Type', 'Check-in', 'Check-out']
            .map(TextCellValue.new)
            .toList(),
      );
      sheet.appendRow([
        DateCellValue(year: 2026, month: 9, day: 6),
        TextCellValue('WRK_00001'),
        TextCellValue('worker'),
        const TimeCellValue(hour: 8, minute: 15),
        const TimeCellValue(hour: 15, minute: 33),
      ]);
      final bytes = Uint8List.fromList(book.save()!);

      final parsed = codec.parseAttendance(bytes);
      expect(parsed.skipped, isEmpty);
      expect(parsed.rows.single.date, '2026-09-06');
      expect(parsed.rows.single.checkIn, '08:15');
      expect(parsed.rows.single.checkOut, '15:33');
    },
  );
}
