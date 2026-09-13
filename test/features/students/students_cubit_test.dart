import 'dart:async';

import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/students/domain/entities/student.dart';
import 'package:attendance_management/features/students/domain/repositories/student_repository.dart';
import 'package:attendance_management/features/students/domain/usecases/student_usecases.dart';
import 'package:attendance_management/features/students/presentation/cubit/students_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake — exercises the real use cases (incl. validation).
class _FakeStudentRepository implements StudentRepository {
  final _controller = StreamController<List<Student>>.broadcast();
  final List<Student> _items = [];

  void emit() => _controller.add(List.unmodifiable(_items));

  @override
  Stream<List<Student>> watchStudents() => _controller.stream;

  @override
  Future<Student> createStudent(StudentDraft draft) async {
    final s = Student(
      studentId: 'STU_0000${_items.length + 1}',
      fullName: draft.fullName,
      className: draft.className,
      qrCodeId: 'STU_0000${_items.length + 1}',
    );
    _items.add(s);
    emit();
    return s;
  }

  @override
  Future<Student> updateStudent(Student student) async => student;

  @override
  Future<void> deleteStudent(String studentId) async {
    _items.removeWhere((s) => s.studentId == studentId);
    emit();
  }

  @override
  Future<Student> getStudent(String studentId) async =>
      _items.firstWhere((s) => s.studentId == studentId);
}

void main() {
  late _FakeStudentRepository repo;

  setUp(() => repo = _FakeStudentRepository());

  StudentsCubit build() => StudentsCubit(
    watchStudents: WatchStudents(repo),
    createStudent: CreateStudent(repo),
    updateStudent: UpdateStudent(repo),
    deleteStudent: DeleteStudent(repo),
  );

  blocTest<StudentsCubit, StudentsState>(
    'start() loads the stream into a ready state',
    build: build,
    act: (c) {
      c.start();
      repo._items.add(
        const Student(
          studentId: 'STU_00001',
          fullName: 'Ahmed',
          className: '5A',
          qrCodeId: 'STU_00001',
        ),
      );
      repo.emit();
    },
    skip: 1,
    expect: () => [
      isA<StudentsState>()
          .having((s) => s.status, 'status', StudentsStatus.ready)
          .having((s) => s.all.length, 'count', 1),
    ],
  );

  blocTest<StudentsCubit, StudentsState>(
    'create() with a blank name reports a validation error and does not throw',
    build: build,
    act: (c) => c.create(const StudentDraft(fullName: '  ', className: '5A')),
    expect: () => [
      isA<StudentsState>().having((s) => s.isMutating, 'mutating', true),
      isA<StudentsState>()
          .having((s) => s.isMutating, 'mutating', false)
          .having((s) => s.actionError, 'error', contains('Full name')),
    ],
  );

  test('CreateStudent use case throws ValidationException for blank class', () {
    expect(
      () => CreateStudent(repo)(
        const StudentDraft(fullName: 'Ahmed', className: ''),
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
