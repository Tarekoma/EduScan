part of 'excel_cubit.dart';

class ExcelState extends Equatable {
  const ExcelState({
    this.exportingType,
    this.importing = false,
    this.studentPreview,
    this.workerPreview,
    this.attendancePreview,
    this.info,
    this.error,
  });

  /// Which export (students or workers) is currently running, if any.
  final PersonType? exportingType;
  final bool importing;
  final ParsedSheet<StudentImportRow>? studentPreview;
  final ParsedSheet<WorkerImportRow>? workerPreview;
  final ParsedSheet<AttendanceImportRow>? attendancePreview;
  final String? info;
  final String? error;

  bool get exporting => exportingType != null;
  bool get busy => exporting || importing;

  ExcelState copyWith({
    PersonType? exportingType,
    bool clearExporting = false,
    bool? importing,
    ParsedSheet<StudentImportRow>? studentPreview,
    ParsedSheet<WorkerImportRow>? workerPreview,
    ParsedSheet<AttendanceImportRow>? attendancePreview,
    bool clearPreview = false,
    String? info,
    String? error,
    bool clearMessages = false,
  }) {
    return ExcelState(
      exportingType: clearExporting
          ? null
          : (exportingType ?? this.exportingType),
      importing: importing ?? this.importing,
      studentPreview: clearPreview
          ? null
          : (studentPreview ?? this.studentPreview),
      workerPreview: clearPreview
          ? null
          : (workerPreview ?? this.workerPreview),
      attendancePreview: clearPreview
          ? null
          : (attendancePreview ?? this.attendancePreview),
      info: clearMessages ? null : (info ?? this.info),
      error: clearMessages ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    exportingType,
    importing,
    studentPreview?.rows.length,
    studentPreview?.skipped.length,
    workerPreview?.rows.length,
    workerPreview?.skipped.length,
    attendancePreview?.rows.length,
    attendancePreview?.skipped.length,
    info,
    error,
  ];
}
