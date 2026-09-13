import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/services/file_service.dart';
import '../../domain/excel_rows.dart';
import '../../domain/repositories/excel_repository.dart';

part 'excel_state.dart';

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
        state.copyWith(exporting: false, info: 'Exported ${file.filename}.'),
      );
    } catch (e, s) {
      emit(
        state.copyWith(exporting: false, error: ErrorMapper.map(e, s).message),
      );
    }
  }

  Future<void> pickStudentFile() => _pick(students: true);
  Future<void> pickAttendanceFile() => _pick(students: false);

  Future<void> _pick({required bool students}) async {
    emit(state.copyWith(clearMessages: true, clearPreview: true));
    try {
      final bytes = await _files.pickSpreadsheet();
      if (bytes == null) return;
      if (students) {
        emit(state.copyWith(studentPreview: _repo.parseStudents(bytes)));
      } else {
        emit(state.copyWith(attendancePreview: _repo.parseAttendance(bytes)));
      }
    } catch (e, s) {
      emit(state.copyWith(error: ErrorMapper.map(e, s).message));
    }
  }

  Future<void> confirmStudentImport() async {
    final preview = state.studentPreview;
    if (preview == null || preview.rows.isEmpty) return;
    await _runImport(() => _repo.importStudents(preview.rows), 'student');
  }

  Future<void> confirmAttendanceImport() async {
    final preview = state.attendancePreview;
    if (preview == null || preview.rows.isEmpty) return;
    await _runImport(() => _repo.importAttendance(preview.rows), 'attendance');
  }

  Future<void> _runImport(
    Future<ImportOutcome> Function() action,
    String label,
  ) async {
    emit(state.copyWith(importing: true, clearMessages: true));
    try {
      final outcome = await action();
      emit(
        state.copyWith(
          importing: false,
          info: 'Imported ${outcome.count} $label record(s).',
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
