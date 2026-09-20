import 'package:equatable/equatable.dart';

import '../../../core/enums/person_type.dart';
import '../../../core/enums/worker_job_title.dart';
import '../../attendance/domain/entities/attendance_record.dart';
import '../../students/domain/entities/student.dart';
import '../../workers/domain/entities/worker.dart';

/// The four dashboard summary cards that can be drilled into.
enum AttendanceCategory { checkedIn, checkedOut, absent, currentlyInside }

/// One person listed under an [AttendanceCategory], with the display facts
/// already resolved from the roster.
class BreakdownEntry extends Equatable {
  const BreakdownEntry({
    required this.personId,
    required this.name,
    required this.personType,
    this.className,
    this.jobTitle,
    this.time,
  });

  final String personId;
  final String name;
  final PersonType personType;

  /// Students only.
  final String? className;

  /// Workers only (teacher / administrative staff / other).
  final WorkerJobTitle? jobTitle;

  /// The check-in or check-out time that put the person in this category;
  /// null for [AttendanceCategory.absent].
  final DateTime? time;

  @override
  List<Object?> get props => [
    personId,
    name,
    personType,
    className,
    jobTitle,
    time,
  ];
}

/// Works out *who* is behind each dashboard count, from the same live
/// students / workers / attendance data the counts are built from — nothing
/// is stored or duplicated. Pure and unit-testable.
///
/// Category rules match [DashboardStats.compute]: a person is "checked in"
/// when their record has a check-in, "checked out" when it has a check-out,
/// "currently inside" when checked in but not out, and "absent" when the
/// roster person has no check-in for the day.
abstract final class AttendanceBreakdown {
  static List<BreakdownEntry> compute({
    required AttendanceCategory category,
    required List<Student> students,
    required List<Worker> workers,
    required List<AttendanceRecord> records,
    PersonType? typeFilter,
  }) {
    final scoped = typeFilter == null
        ? records
        : records.where((r) => r.personType == typeFilter).toList();

    final studentsById = {for (final s in students) s.studentId: s};
    final workersById = {for (final w in workers) w.workerId: w};

    BreakdownEntry entryFor(AttendanceRecord r, DateTime? time) {
      final student = studentsById[r.personId];
      final worker = workersById[r.personId];
      return BreakdownEntry(
        personId: r.personId,
        // A record can outlive its person; fall back to the id, as the
        // recent-activity list does.
        name: student?.fullName ?? worker?.fullName ?? r.personId,
        personType: r.personType,
        className: student?.className,
        jobTitle: worker?.jobTitle,
        time: time,
      );
    }

    if (category == AttendanceCategory.absent) {
      final present = {
        for (final r in scoped)
          if (r.checkIn != null) r.personId,
      };
      return [
        if (typeFilter != PersonType.worker)
          for (final s in students)
            if (!present.contains(s.studentId))
              BreakdownEntry(
                personId: s.studentId,
                name: s.fullName,
                personType: PersonType.student,
                className: s.className,
              ),
        if (typeFilter != PersonType.student)
          for (final w in workers)
            if (!present.contains(w.workerId))
              BreakdownEntry(
                personId: w.workerId,
                name: w.fullName,
                personType: PersonType.worker,
                jobTitle: w.jobTitle,
              ),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final entries = <BreakdownEntry>[
      for (final r in scoped)
        if (switch (category) {
          AttendanceCategory.checkedIn => r.checkIn != null,
          AttendanceCategory.checkedOut => r.checkOut != null,
          AttendanceCategory.currentlyInside => r.isInside,
          AttendanceCategory.absent => false,
        })
          entryFor(
            r,
            category == AttendanceCategory.checkedOut ? r.checkOut : r.checkIn,
          ),
    ];
    // Most recent first.
    entries.sort((a, b) => b.time!.compareTo(a.time!));
    return entries;
  }
}
