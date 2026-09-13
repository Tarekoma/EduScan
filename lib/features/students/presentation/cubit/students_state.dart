part of 'students_cubit.dart';

enum StudentsStatus { initial, loading, ready, error }

class StudentsState extends Equatable {
  const StudentsState({
    this.status = StudentsStatus.initial,
    this.all = const [],
    this.query = '',
    this.errorMessage,
    this.isMutating = false,
    this.actionError,
  });

  final StudentsStatus status;
  final List<Student> all;
  final String query;
  final String? errorMessage;
  final bool isMutating;
  final String? actionError;

  /// Students matching the current search query (id, name, class or QR id).
  List<Student> get filtered {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((s) {
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
    errorMessage,
    isMutating,
    actionError,
  ];
}
