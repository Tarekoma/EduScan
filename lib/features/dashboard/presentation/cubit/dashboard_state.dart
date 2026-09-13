part of 'dashboard_cubit.dart';

enum DashboardStatus { initial, loading, ready, error }

enum DashboardReportStatus { initial, loading, ready, error }

/// One row in the recent-activity list, with names already resolved.
class ActivityItem extends Equatable {
  const ActivityItem({
    required this.personId,
    required this.personName,
    required this.personType,
    required this.checkIn,
    required this.checkOut,
    required this.recordedBy,
    required this.lastActivity,
  });

  final String personId;
  final String personName;
  final PersonType personType;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String recordedBy;
  final DateTime lastActivity;

  @override
  List<Object?> get props => [
    personId,
    personName,
    personType,
    checkIn,
    checkOut,
    recordedBy,
  ];
}

class DashboardState extends Equatable {
  DashboardState({
    required this.date,
    required this.reportFrom,
    required this.reportTo,
    this.status = DashboardStatus.initial,
    this.students = const [],
    this.workers = const [],
    this.records = const [],
    this.recorderNames = const {},
    this.typeFilter,
    this.attendanceLoading = false,
    this.errorMessage,
    this.reportRecords = const [],
    this.reportStatus = DashboardReportStatus.initial,
    this.reportErrorMessage,
  });

  final DateTime date;
  final DashboardStatus status;
  final List<Student> students;
  final List<Worker> workers;
  final List<AttendanceRecord> records;
  final Map<String, String> recorderNames;
  final PersonType? typeFilter;
  final bool attendanceLoading;
  final String? errorMessage;

  /// Date range + one-shot fetch backing the report section (rate-over-time
  /// chart, class comparison, detailed table). Independent from [date]/[records]
  /// above, which drive the live single-day "recent activity" feed.
  final DateTime reportFrom;
  final DateTime reportTo;
  final List<AttendanceRecord> reportRecords;
  final DashboardReportStatus reportStatus;
  final String? reportErrorMessage;

  DashboardStats get stats => DashboardStats.compute(
    totalStudents: students.length,
    totalWorkers: workers.length,
    records: records,
    typeFilter: typeFilter,
  );

  List<CheckInPoint> get chart =>
      DashboardChart.cumulativeCheckIns(records, typeFilter: typeFilter);

  AttendanceReportStats get report => AttendanceReportStats.compute(
    students: students,
    studentRecords: reportRecords
        .where((r) => r.personType == PersonType.student)
        .toList(),
    dateKeys: AttendanceReportStats.dateKeysInRange(reportFrom, reportTo),
  );

  late final Map<String, String> _personNames = {
    for (final s in students) s.studentId: s.fullName,
    for (final w in workers) w.workerId: w.fullName,
  };

  List<ActivityItem> get activity {
    final items =
        records
            .where((r) => typeFilter == null || r.personType == typeFilter)
            .map((r) {
              final last = [r.checkOut, r.checkIn, r.updatedAt]
                  .whereType<DateTime>()
                  .fold<DateTime?>(
                    null,
                    (a, b) => a == null || b.isAfter(a) ? b : a,
                  );
              return ActivityItem(
                personId: r.personId,
                personName: _personNames[r.personId] ?? r.personId,
                personType: r.personType,
                checkIn: r.checkIn,
                checkOut: r.checkOut,
                recordedBy:
                    recorderNames[r.checkOutRecordedBy ??
                        r.checkInRecordedBy ??
                        r.updatedBy] ??
                    '—',
                lastActivity: last ?? DateTime.fromMillisecondsSinceEpoch(0),
              );
            })
            .toList()
          ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return items;
  }

  DashboardState copyWith({
    DateTime? date,
    DashboardStatus? status,
    List<Student>? students,
    List<Worker>? workers,
    List<AttendanceRecord>? records,
    Map<String, String>? recorderNames,
    PersonType? typeFilter,
    bool clearTypeFilter = false,
    bool? attendanceLoading,
    String? errorMessage,
    DateTime? reportFrom,
    DateTime? reportTo,
    List<AttendanceRecord>? reportRecords,
    DashboardReportStatus? reportStatus,
    String? reportErrorMessage,
  }) {
    return DashboardState(
      date: date ?? this.date,
      status: status ?? this.status,
      students: students ?? this.students,
      workers: workers ?? this.workers,
      records: records ?? this.records,
      recorderNames: recorderNames ?? this.recorderNames,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      attendanceLoading: attendanceLoading ?? this.attendanceLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      reportFrom: reportFrom ?? this.reportFrom,
      reportTo: reportTo ?? this.reportTo,
      reportRecords: reportRecords ?? this.reportRecords,
      reportStatus: reportStatus ?? this.reportStatus,
      reportErrorMessage: reportErrorMessage ?? this.reportErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    date,
    status,
    students,
    workers,
    records,
    recorderNames,
    typeFilter,
    attendanceLoading,
    errorMessage,
    reportFrom,
    reportTo,
    reportRecords,
    reportStatus,
    reportErrorMessage,
  ];
}
