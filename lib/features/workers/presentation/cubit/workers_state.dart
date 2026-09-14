part of 'workers_cubit.dart';

enum WorkersStatus { initial, loading, ready, error }

class WorkersState extends Equatable {
  const WorkersState({
    this.status = WorkersStatus.initial,
    this.all = const [],
    this.query = '',
    this.errorMessage,
    this.isMutating = false,
    this.actionError,
  });

  final WorkersStatus status;
  final List<Worker> all;
  final String query;
  final String? errorMessage;
  final bool isMutating;
  final String? actionError;

  List<Worker> get filtered {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((w) {
      return w.workerId.toLowerCase().contains(q) ||
          w.fullName.toLowerCase().contains(q) ||
          w.jobTitle.plainLabel.toLowerCase().contains(q) ||
          w.qrCodeId.toLowerCase().contains(q);
    }).toList();
  }

  bool get isEmpty => status == WorkersStatus.ready && all.isEmpty;

  WorkersState copyWith({
    WorkersStatus? status,
    List<Worker>? all,
    String? query,
    String? errorMessage,
    bool clearError = false,
    bool? isMutating,
    String? actionError,
    bool clearActionError = false,
  }) {
    return WorkersState(
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
