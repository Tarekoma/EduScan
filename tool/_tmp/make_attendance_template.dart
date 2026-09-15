import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  final book = Excel.createExcel();
  final sheet = book['Attendance'];
  book.setDefaultSheet('Attendance');
  if (book.sheets.containsKey('Sheet1')) book.delete('Sheet1');

  sheet.appendRow([
    TextCellValue('Date'),
    TextCellValue('Person ID'),
    TextCellValue('Person Type'),
    TextCellValue('Check-in'),
    TextCellValue('Check-out'),
  ]);

  sheet.appendRow([
    TextCellValue('2026-09-15'),
    TextCellValue('WRK_00001'),
    TextCellValue('worker'),
    TextCellValue('08:30'),
    TextCellValue('16:00'),
  ]);
  sheet.appendRow([
    TextCellValue('2026-09-15'),
    TextCellValue('WRK_00002'),
    TextCellValue('worker'),
    TextCellValue('09:00'),
    TextCellValue('15:45'),
  ]);
  sheet.appendRow([
    TextCellValue('2026-09-16'),
    TextCellValue('WRK_00001'),
    TextCellValue('worker'),
    TextCellValue('08:15'),
    TextCellValue(''),
  ]);

  final bytes = book.save();
  File('attendance_template.xlsx').writeAsBytesSync(bytes!);
  stdout.writeln('written');
}
