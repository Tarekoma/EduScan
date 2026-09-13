import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/usecases/student_usecases.dart';

part 'students_state.dart';

class StudentsCubit extends Cubit<StudentsState> {
  StudentsCubit({
    required WatchStudents watchStudents,
    required CreateStudent createStudent,
    required UpdateStudent updateStudent,
    required DeleteStudent deleteStudent,
  }) : _watchStudents = watchStudents,
       _createStudent = createStudent,
       _updateStudent = updateStudent,
       _deleteStudent = deleteStudent,
       super(const StudentsState());

  final WatchStudents _watchStudents;
  final CreateStudent _createStudent;
  final UpdateStudent _updateStudent;
  final DeleteStudent _deleteStudent;

  StreamSubscription<List<Student>>? _subscription;

  void start() {
    if (_subscription != null) return;
    emit(state.copyWith(status: StudentsStatus.loading));
    _subscription = _watchStudents().listen(
      (students) => emit(
        state.copyWith(
          status: StudentsStatus.ready,
          all: students,
          clearError: true,
        ),
      ),
      onError: (Object e, StackTrace s) => emit(
        state.copyWith(
          status: StudentsStatus.error,
          errorMessage: ErrorMapper.map(e, s).message,
        ),
      ),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  void filterByClass(String? className) => emit(
    state.copyWith(classFilter: className, clearClassFilter: className == null),
  );

  Future<bool> create(StudentDraft draft) =>
      _mutate(() => _createStudent(draft));

  Future<bool> update(Student student) =>
      _mutate(() => _updateStudent(student));

  Future<bool> delete(String studentId) =>
      _mutate(() => _deleteStudent(studentId));

  Future<bool> _mutate(Future<void> Function() action) async {
    emit(state.copyWith(isMutating: true, clearActionError: true));
    try {
      await action();
      emit(state.copyWith(isMutating: false));
      return true;
    } catch (e, s) {
      emit(
        state.copyWith(
          isMutating: false,
          actionError: ErrorMapper.map(e, s).message,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
