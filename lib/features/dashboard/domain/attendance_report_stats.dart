import '../../../core/utils/date_key.dart';
import '../../attendance/domain/entities/attendance_record.dart';
import '../../students/domain/entities/student.dart';

/// One row of the per-class breakdown.
class ClassAttendanceRow {
  const ClassAttendanceRow({
    required this.className,
    required this.studentCount,
    required this.presentCount,
    required this.absentCount,
    required this.attendanceRate,
  });

  final String className;
  final int studentCount;

  /// Count of present/absent student-days across the selected range.
  final int presentCount;
  final int absentCount;

  /// 0..1 fraction of possible attendances that happened — used only to size
  /// and colour the comparison bar, never shown to the user as a number.
  final double attendanceRate;
}

/// One point of the "attendance over time" chart: how many students of the
/// roster were present on that calendar day.
class DailyRatePoint {
  const DailyRatePoint({required this.date, required this.presentCount});

  final DateTime date;
  final int presentCount;
}

/// Aggregate student-attendance figures for a date range. Pure and
/// unit-testable; built entirely from real students + attendance records
/// already in Firestore — no invented data.
///
/// A student is counted "absent" on a day inside the range when they have no
/// attendance record with a check-in for that day (absence is the absence of
/// a record, matching how the rest of the app already treats it — see
/// [AttendanceRecord]/`AttendanceState.absent`).
class AttendanceReportStats {
  const AttendanceReportStats({
    required this.totalDays,
    required this.perClass,
    required this.dailyRates,
  });

  const AttendanceReportStats.empty()
    : totalDays = 0,
      perClass = const [],
      dailyRates = const [];

  final int totalDays;
  final List<ClassAttendanceRow> perClass;
  final List<DailyRatePoint> dailyRates;

  static AttendanceReportStats compute({
    required List<Student> students,
    required List<AttendanceRecord> studentRecords,
    required List<String> dateKeys,
  }) {
    if (students.isEmpty || dateKeys.isEmpty) {
      return const AttendanceReportStats.empty();
    }

    final presentDatesByStudent = <String, Set<String>>{};
    for (final r in studentRecords) {
      if (r.checkIn == null) continue;
      presentDatesByStudent.putIfAbsent(r.personId, () => {}).add(r.date);
    }

    final totalDays = dateKeys.length;

    final byClass = <String, List<Student>>{};
    for (final s in students) {
      byClass.putIfAbsent(s.className, () => []).add(s);
    }
    final perClass = byClass.entries.map((entry) {
      final classStudents = entry.value;
      final classPresent = classStudents.fold<int>(
        0,
        (sum, s) => sum + (presentDatesByStudent[s.studentId]?.length ?? 0),
      );
      final classPossible = classStudents.length * totalDays;
      final rate = classPossible == 0 ? 0.0 : classPresent / classPossible;
      return ClassAttendanceRow(
        className: entry.key,
        studentCount: classStudents.length,
        presentCount: classPresent,
        absentCount: classPossible - classPresent,
        attendanceRate: rate,
      );
    }).toList()..sort((a, b) => b.attendanceRate.compareTo(a.attendanceRate));

    final dailyRates = dateKeys.map((key) {
      final presentCount = presentDatesByStudent.values
          .where((dates) => dates.contains(key))
          .length;
      return DailyRatePoint(
        date: DateKey.parse(key),
        presentCount: presentCount,
      );
    }).toList();

    return AttendanceReportStats(
      totalDays: totalDays,
      perClass: perClass,
      dailyRates: dailyRates,
    );
  }

  /// All `yyyy-MM-dd` keys from [from] to [to], inclusive.
  static List<String> dateKeysInRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final keys = <String>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      keys.add(DateKey.of(d));
    }
    return keys;
  }
}
