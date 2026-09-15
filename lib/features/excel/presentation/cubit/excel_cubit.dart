import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/file_service.dart';
import '../../domain/excel_rows.dart';
import '../../domain/repositories/excel_repository.dart';

part 'excel_state.dart';

enum _ImportKind { students, workers, attendance }

class ExcelCubit extends Cubit<ExcelState> {
  ExcelCubit({
    required ExcelRepository repository,
    required FileService fileService,
  }) : _repo = repository,
       _files = fileService,
       super(const ExcelState());

  final ExcelRepository _repo;
  final FileService _files;

  Future<void> exportAttendance(DateTime from, DateTime to) async {
    emit(state.copyWith(exporting: true, clearMessages: true));
    try {
      final file = await _repo.exportAttendance(from: from, to: to);
      await _files.shareBytes(file.bytes, file.filename);
      emit(
        state.copyWith(
          exporting: false,
          info: appStrings.excelExportedFile(file.filename),
        ),
      );
    } catch (e, s) {
      emit(
        state.copyWith(exporting: false, error: ErrorMapper.map(e, s).message),
      );
    }
  }

  Future<void> pickStudentFile() => _pick(_ImportKind.students);
  Future<void> pickWorkerFile() => _pick(_ImportKind.workers);
  Future<void> pickAttendanceFile() => _pick(_ImportKind.attendance);

  Future<void> _pick(_ImportKind kind) async {
    emit(state.copyWith(clearMessages: true, clearPreview: true));
    try {
      final bytes = await _files.pickSpreadsheet();
      if (bytes == null) return;
      switch (kind) {
        case _ImportKind.students:
          emit(state.copyWith(studentPreview: _repo.parseStudents(bytes)));
        case _ImportKind.workers:
          emit(state.copyWith(workerPreview: _repo.parseWorkers(bytes)));
        case _ImportKind.attendance:
          emit(
            state.copyWith(attendancePreview: _repo.parseAttendance(bytes)),
          );
      }
    } catch (e, s) {
      emit(state.copyWith(error: ErrorMapper.map(e, s).message));
    }
  }

  Future<void> confirmStudentImport() async {
    final preview = state.studentPreview;
    if (preview == null || preview.rows.isEmpty) return;
    await _runImport(
      () => _repo.importStudents(preview.rows),
      appStrings.excelKindStudent,
    );
  }

  Future<void> confirmWorkerImport() async {
    final preview = state.workerPreview;
    if (preview == null || preview.rows.isEmpty) return;
    await _runImport(
      () => _repo.importWorkers(preview.rows),
      appStrings.excelKindWorker,
    );
  }

  Future<void> confirmAttendanceImport() async {
    final preview = state.attendancePreview;
    if (preview == null || preview.rows.isEmpty) return;
    await _runImport(
      () => _repo.importAttendance(preview.rows),
      appStrings.excelKindAttendance,
    );
  }

  Future<void> _runImport(
    Future<ImportOutcome> Function() action,
    String kind,
  ) async {
    emit(state.copyWith(importing: true, clearMessages: true));
    try {
      final outcome = await action();
      emit(
        state.copyWith(
          importing: false,
          info: appStrings.excelImportedRecords(outcome.count, kind),
          clearPreview: true,
        ),
      );
    } catch (e, s) {
      emit(
        state.copyWith(importing: false, error: ErrorMapper.map(e, s).message),
      );
    }
  }

  void clearPreview() =>
      emit(state.copyWith(clearPreview: true, clearMessages: true));
}
