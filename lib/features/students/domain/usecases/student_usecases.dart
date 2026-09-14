import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../entities/student.dart';
import '../repositories/student_repository.dart';

class WatchStudents {
  const WatchStudents(this._repo);
  final StudentRepository _repo;
  Stream<List<Student>> call() => _repo.watchStudents();
}

class GetStudent {
  const GetStudent(this._repo);
  final StudentRepository _repo;
  Future<Student> call(String studentId) => _repo.getStudent(studentId);
}

class CreateStudent {
  const CreateStudent(this._repo);
  final StudentRepository _repo;

  Future<Student> call(StudentDraft draft) {
    _validate(draft.fullName, draft.className);
    return _repo.createStudent(draft);
  }
}

class UpdateStudent {
  const UpdateStudent(this._repo);
  final StudentRepository _repo;

  Future<Student> call(Student student) {
    _validate(student.fullName, student.className);
    return _repo.updateStudent(student);
  }
}

class DeleteStudent {
  const DeleteStudent(this._repo);
  final StudentRepository _repo;
  Future<void> call(String studentId) => _repo.deleteStudent(studentId);
}

void _validate(String fullName, String className) {
  final error =
      Validators.required(
        fullName,
        message: appStrings.validatorRequired(appStrings.fieldFullName),
      ) ??
      Validators.required(
        className,
        message: appStrings.validatorRequired(appStrings.fieldClass),
      );
  if (error != null) throw ValidationException(error);
}
