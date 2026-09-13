import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_management/features/dashboard/domain/dashboard_stats.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceRecord _rec({
  required String id,
  required PersonType type,
  DateTime? checkIn,
  DateTime? checkOut,
}) {
  return AttendanceRecord(
    id: id,
    personId: id,
    personType: type,
    date: '2026-09-10',
    checkIn: checkIn,
    checkOut: checkOut,
  );
}

void main() {
  final d = DateTime(2026, 9, 10);

  final records = [
    _rec(
      id: 'STU_1',
      type: PersonType.student,
      checkIn: d.add(const Duration(hours: 7)),
    ),
    _rec(
      id: 'STU_2',
      type: PersonType.student,
      checkIn: d.add(const Duration(hours: 8)),
      checkOut: d.add(const Duration(hours: 14)),
    ),
    _rec(
      id: 'WRK_1',
      type: PersonType.worker,
      checkIn: d.add(const Duration(hours: 6, minutes: 30)),
    ),
  ];

  test('compute aggregates check-in / out / inside and absent', () {
    final stats = DashboardStats.compute(
      totalStudents: 5,
      totalWorkers: 2,
      records: records,
    );
    expect(stats.totalPeople, 7);
    expect(stats.checkedIn, 3);
    expect(stats.checkedOut, 1);
    expect(stats.currentlyInside, 2); // STU_1 and WRK_1
    expect(stats.absent, 4); // 7 total - 3 checked in
  });

  test('type filter scopes both totals and records', () {
    final stats = DashboardStats.compute(
      totalStudents: 5,
      totalWorkers: 2,
      records: records,
      typeFilter: PersonType.student,
    );
    expect(stats.totalPeople, 5);
    expect(stats.totalWorkers, 0);
    expect(stats.checkedIn, 2);
    expect(stats.currentlyInside, 1);
  });

  test('absent never goes negative', () {
    final stats = DashboardStats.compute(
      totalStudents: 1,
      totalWorkers: 0,
      records: [
        _rec(id: 'STU_1', type: PersonType.student, checkIn: d),
        _rec(id: 'STU_2', type: PersonType.student, checkIn: d),
      ],
    );
    expect(stats.absent, 0);
  });

  test('cumulative check-in chart is sorted and monotonic', () {
    final points = DashboardChart.cumulativeCheckIns(records);
    expect(points.map((p) => p.cumulative), [1, 2, 3]);
    // sorted by time: 06:30, 07:00, 08:00
    expect(points.first.minutesOfDay, 6 * 60 + 30);
    expect(points.last.minutesOfDay, 8 * 60);
  });

  test('empty records yield an empty chart', () {
    expect(DashboardChart.cumulativeCheckIns(const []), isEmpty);
  });
}
