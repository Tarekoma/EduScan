part of 'worker_attendance_history_cubit.dart';

enum WorkerAttendanceHistoryStatus { initial, loading, ready, error }

class WorkerAttendanceHistoryState extends Equatable {
  const WorkerAttendanceHistoryState({
    this.status = WorkerAttendanceHistoryStatus.initial,
    this.records = const [],
    this.range,
    this.errorMessage,
  });

  final WorkerAttendanceHistoryStatus status;

  /// Most-recent-first, capped server-side (see `watchByPerson`'s `limit`).
  final List<AttendanceRecord> records;
  final DateTimeRange? range;
  final String? errorMessage;

  /// [records] narrowed to [range] (inclusive, by calendar day), or all of
  /// [records] when no range is set.
  List<AttendanceRecord> get visibleRecords {
    final r = range;
    if (r == null) return records;
    final from = DateKey.of(r.start);
    final to = DateKey.of(r.end);
    return records
        .where((rec) => rec.date.compareTo(from) >= 0 && rec.date.compareTo(to) <= 0)
        .toList();
  }

  /// Days within [visibleRecords] the worker actually checked in. A simple,
  /// honest summary — there's no work-day calendar in the schema to derive
  /// an absence rate from, so this only counts what real records show.
  int get presentCount =>
      visibleRecords.where((r) => r.checkIn != null).length;

  WorkerAttendanceHistoryState copyWith({
    WorkerAttendanceHistoryStatus? status,
    List<AttendanceRecord>? records,
    DateTimeRange? range,
    bool clearRange = false,
    String? errorMessage,
  }) {
    return WorkerAttendanceHistoryState(
      status: status ?? this.status,
      records: records ?? this.records,
      range: clearRange ? null : (range ?? this.range),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, range, errorMessage];
}
