import '../../../core/enums/person_type.dart';
import '../../attendance/domain/entities/attendance_record.dart';

/// Aggregate attendance figures for one day. Pure and unit-testable.
class DashboardStats {
  const DashboardStats({
    required this.totalStudents,
    required this.totalWorkers,
    required this.checkedIn,
    required this.checkedOut,
    required this.currentlyInside,
  });

  final int totalStudents;
  final int totalWorkers;
  final int checkedIn;
  final int checkedOut;
  final int currentlyInside;

  int get totalPeople => totalStudents + totalWorkers;

  /// People with no check-in for the day. Never negative.
  int get absent {
    final value = totalPeople - checkedIn;
    return value < 0 ? 0 : value;
  }

  static DashboardStats compute({
    required int totalStudents,
    required int totalWorkers,
    required List<AttendanceRecord> records,
    PersonType? typeFilter,
  }) {
    final filtered = typeFilter == null
        ? records
        : records.where((r) => r.personType == typeFilter).toList();

    var checkedIn = 0;
    var checkedOut = 0;
    var inside = 0;
    for (final r in filtered) {
      if (r.checkIn != null) checkedIn++;
      if (r.checkOut != null) checkedOut++;
      if (r.isInside) inside++;
    }

    final students = typeFilter == PersonType.worker ? 0 : totalStudents;
    final workers = typeFilter == PersonType.student ? 0 : totalWorkers;

    return DashboardStats(
      totalStudents: students,
      totalWorkers: workers,
      checkedIn: checkedIn,
      checkedOut: checkedOut,
      currentlyInside: inside,
    );
  }
}

/// A point on the "check-ins over time" chart: minutes-since-midnight → the
/// cumulative number of people checked in by that moment.
class CheckInPoint {
  const CheckInPoint(this.minutesOfDay, this.cumulative);
  final double minutesOfDay;
  final int cumulative;
}

abstract final class DashboardChart {
  /// Builds the cumulative check-in curve from real check-in timestamps.
  static List<CheckInPoint> cumulativeCheckIns(
    List<AttendanceRecord> records, {
    PersonType? typeFilter,
  }) {
    final times =
        records
            .where((r) => typeFilter == null || r.personType == typeFilter)
            .map((r) => r.checkIn)
            .whereType<DateTime>()
            .map((t) => t.toLocal())
            .toList()
          ..sort();

    if (times.isEmpty) return const [];

    final points = <CheckInPoint>[];
    for (var i = 0; i < times.length; i++) {
      final t = times[i];
      points.add(CheckInPoint(t.hour * 60.0 + t.minute, i + 1));
    }
    return points;
  }
}
