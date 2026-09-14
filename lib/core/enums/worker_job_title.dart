/// Job-title classification for workers. Purely descriptive directory
/// information — unrelated to `users`/{uid}.role and grants no permissions.
enum WorkerJobTitle {
  teacher('teacher'),
  administrativeStaff('administrative_staff'),
  other('other');

  const WorkerJobTitle(this.value);

  /// Value persisted in Firestore (`workers/{id}.jobTitle`).
  final String value;

  /// Falls back to [other] for an unrecognised or missing value rather than
  /// throwing, so a worker document can never fail to load.
  static WorkerJobTitle fromValue(String? value) {
    return WorkerJobTitle.values.firstWhere(
      (t) => t.value == value,
      orElse: () => WorkerJobTitle.other,
    );
  }
}
