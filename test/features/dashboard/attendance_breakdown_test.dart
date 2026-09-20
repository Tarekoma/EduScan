import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/core/enums/worker_job_title.dart';
import 'package:attendance_management/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_management/features/dashboard/domain/attendance_breakdown.dart';
import 'package:attendance_management/features/dashboard/domain/dashboard_stats.dart';
import 'package:attendance_management/features/students/domain/entities/student.dart';
import 'package:attendance_management/features/workers/domain/entities/worker.dart';
import 'package:flutter_test/flutter_test.dart';

Student _student(String id, String name, String cls) =>
    Student(studentId: id, fullName: name, className: cls, qrCodeId: id);

Worker _worker(String id, String name) => Worker(
  workerId: id,
  fullName: name,
  jobTitle: WorkerJobTitle.teacher,
  qrCodeId: id,
);

AttendanceRecord _rec(
  String id,
  PersonType type, {
  DateTime? checkIn,
  DateTime? checkOut,
}) => AttendanceRecord(
  id: id,
  personId: id,
  personType: type,
  date: '2026-09-10',
  checkIn: checkIn,
  checkOut: checkOut,
);

void main() {
  final d = DateTime(2026, 9, 10);
  final students = [
    _student('STU_1', 'Ali', '5A'), // inside
    _student('STU_2', 'Bassem', '5A'), // left
    _student('STU_3', 'Carla', '6B'), // absent
  ];
  final workers = [
    _worker('WRK_1', 'Dina'), // inside
    _worker('WRK_2', 'Emad'), // absent
  ];
  final records = [
    _rec('STU_1', PersonType.student, checkIn: d.add(const Duration(hours: 7))),
    _rec(
      'STU_2',
      PersonType.student,
      checkIn: d.add(const Duration(hours: 8)),
      checkOut: d.add(const Duration(hours: 14)),
    ),
    _rec('WRK_1', PersonType.worker, checkIn: d.add(const Duration(hours: 6))),
  ];

  List<BreakdownEntry> of(AttendanceCategory c, {PersonType? filter}) =>
      AttendanceBreakdown.compute(
        category: c,
        students: students,
        workers: workers,
        records: records,
        typeFilter: filter,
      );

  List<String> ids(List<BreakdownEntry> e) => e.map((x) => x.personId).toList();

  test('checked in lists everyone with a check-in, most recent first', () {
    expect(ids(of(AttendanceCategory.checkedIn)), ['STU_2', 'STU_1', 'WRK_1']);
  });

  test('checked out lists only people with a check-out, at that time', () {
    final out = of(AttendanceCategory.checkedOut);
    expect(ids(out), ['STU_2']);
    expect(out.single.time, d.add(const Duration(hours: 14)));
  });

  test('currently inside excludes people who already left', () {
    expect(ids(of(AttendanceCategory.currentlyInside)), ['STU_1', 'WRK_1']);
  });

  test('absent lists roster people with no check-in, by name', () {
    final absent = of(AttendanceCategory.absent);
    expect(ids(absent), ['STU_3', 'WRK_2']);
    expect(absent.every((e) => e.time == null), isTrue);
  });

  test('entries carry class (students) and job title (workers)', () {
    final all = of(AttendanceCategory.checkedIn);
    final student = all.firstWhere((e) => e.personId == 'STU_1');
    final worker = all.firstWhere((e) => e.personId == 'WRK_1');
    expect(student.className, '5A');
    expect(student.jobTitle, isNull);
    expect(worker.jobTitle, WorkerJobTitle.teacher);
    expect(worker.className, isNull);
  });

  test('type filter scopes every category', () {
    expect(ids(of(AttendanceCategory.absent, filter: PersonType.student)), [
      'STU_3',
    ]);
    expect(ids(of(AttendanceCategory.checkedIn, filter: PersonType.worker)), [
      'WRK_1',
    ]);
  });

  test('list lengths match the dashboard card counts', () {
    for (final filter in [null, PersonType.student, PersonType.worker]) {
      final stats = DashboardStats.compute(
        totalStudents: students.length,
        totalWorkers: workers.length,
        records: records,
        typeFilter: filter,
      );
      expect(
        of(AttendanceCategory.checkedIn, filter: filter).length,
        stats.checkedIn,
      );
      expect(
        of(AttendanceCategory.checkedOut, filter: filter).length,
        stats.checkedOut,
      );
      expect(
        of(AttendanceCategory.currentlyInside, filter: filter).length,
        stats.currentlyInside,
      );
      expect(
        of(AttendanceCategory.absent, filter: filter).length,
        stats.absent,
      );
    }
  });

  test('a record whose person was deleted falls back to the id', () {
    final orphan = AttendanceBreakdown.compute(
      category: AttendanceCategory.checkedIn,
      students: const [],
      workers: const [],
      records: [_rec('STU_9', PersonType.student, checkIn: d)],
    );
    expect(orphan.single.name, 'STU_9');
  });
}
