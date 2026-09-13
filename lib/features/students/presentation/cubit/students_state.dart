part of 'students_cubit.dart';

enum StudentsStatus { initial, loading, ready, error }

class StudentsState extends Equatable {
  const StudentsState({
    this.status = StudentsStatus.initial,
    this.all = const [],
    this.query = '',
    this.classFilter,
    this.errorMessage,
    this.isMutating = false,
    this.actionError,
  });

  final StudentsStatus status;
  final List<Student> all;
  final String query;
  final String? classFilter;
  final String? errorMessage;
  final bool isMutating;
  final String? actionError;

  /// Distinct class names actually present in the roster, for the class
  /// filter dropdown — never a hardcoded list.
  List<String> get classNames =>
      all.map((s) => s.className).toSet().toList()..sort();

  /// Students matching the current search query (id, name, class or QR id)
  /// and the selected class filter, if any.
  List<Student> get filtered {
    var result = all;
    if (classFilter != null) {
      result = result.where((s) => s.className == classFilter).toList();
    }
    if (query.isEmpty) return result;
    final q = query.toLowerCase();
    return result.where((s) {
      return s.studentId.toLowerCase().contains(q) ||
          s.fullName.toLowerCase().contains(q) ||
          s.className.toLowerCase().contains(q) ||
          s.qrCodeId.toLowerCase().contains(q);
    }).toList();
  }

  bool get isEmpty => status == StudentsStatus.ready && all.isEmpty;

  StudentsState copyWith({
    StudentsStatus? status,
    List<Student>? all,
    String? query,
    String? classFilter,
    bool clearClassFilter = false,
    String? errorMessage,
    bool clearError = false,
    bool? isMutating,
    String? actionError,
    bool clearActionError = false,
  }) {
    return StudentsState(
      status: status ?? this.status,
      all: all ?? this.all,
      query: query ?? this.query,
      classFilter: clearClassFilter ? null : (classFilter ?? this.classFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isMutating: isMutating ?? this.isMutating,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    status,
    all,
    query,
    classFilter,
    errorMessage,
    isMutating,
    actionError,
  ];
}
