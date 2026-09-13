part of 'parent_dashboard_cubit.dart';

enum ParentStatus { initial, loading, ready, empty, error }

class ParentDashboardState extends Equatable {
  const ParentDashboardState({
    this.status = ParentStatus.initial,
    this.children = const [],
    this.selectedId,
    this.today,
    this.todayLoaded = false,
    this.history = const [],
    this.historyLoading = false,
    this.historyRange,
    this.errorMessage,
  });

  final ParentStatus status;
  final List<Student> children;
  final String? selectedId;
  final AttendanceRecord? today;
  final bool todayLoaded;
  final List<AttendanceRecord> history;
  final bool historyLoading;
  final DateTimeRange? historyRange;
  final String? errorMessage;

  Student? get selectedChild {
    for (final c in children) {
      if (c.studentId == selectedId) return c;
    }
    return null;
  }

  /// History filtered to [historyRange] (inclusive of both endpoints, by day).
  List<AttendanceRecord> get visibleHistory {
    final range = historyRange;
    if (range == null) return history;
    final from = DateKey.of(range.start);
    final to = DateKey.of(range.end);
    return history
        .where((r) => r.date.compareTo(from) >= 0 && r.date.compareTo(to) <= 0)
        .toList();
  }

  ParentDashboardState copyWith({
    ParentStatus? status,
    List<Student>? children,
    String? selectedId,
    AttendanceRecord? today,
    bool clearToday = false,
    bool? todayLoaded,
    List<AttendanceRecord>? history,
    bool? historyLoading,
    DateTimeRange? historyRange,
    bool clearRange = false,
    String? errorMessage,
  }) {
    return ParentDashboardState(
      status: status ?? this.status,
      children: children ?? this.children,
      selectedId: selectedId ?? this.selectedId,
      today: clearToday ? null : (today ?? this.today),
      todayLoaded: todayLoaded ?? this.todayLoaded,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
      historyRange: clearRange ? null : (historyRange ?? this.historyRange),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    children,
    selectedId,
    today,
    todayLoaded,
    history,
    historyLoading,
    historyRange,
    errorMessage,
  ];
}
