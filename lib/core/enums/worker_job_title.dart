/// Job-title classification for workers. Purely descriptive directory
/// information — unrelated to `users`/{uid}.role and grants no permissions.
enum WorkerJobTitle {
  teacher('teacher', 'Teacher'),
  administrativeStaff('administrative_staff', 'Administrative Staff'),
  other('other', 'Other');

  const WorkerJobTitle(this.value, this.label);

  /// Value persisted in Firestore (`workers/{id}.jobTitle`).
  final String value;

  /// Display label shown in the UI.
  final String label;

  /// Falls back to [other] for an unrecognised or missing value rather than
  /// throwing, so a worker document can never fail to load.
  static WorkerJobTitle fromValue(String? value) {
    return WorkerJobTitle.values.firstWhere(
      (t) => t.value == value,
      orElse: () => WorkerJobTitle.other,
    );
  }
}
