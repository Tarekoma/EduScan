import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_remote_data_source.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl(this._remote);

  final StudentRemoteDataSource _remote;

  @override
  Stream<List<Student>> watchStudents() => _remote.watchStudents();

  @override
  Future<Student> getStudent(String studentId) => _remote.getStudent(studentId);

  @override
  Future<Student> createStudent(StudentDraft draft) =>
      _remote.createStudent(draft);

  @override
  Future<Student> updateStudent(Student student) =>
      _remote.updateStudent(student);

  @override
  Future<void> deleteStudent(String studentId) =>
      _remote.deleteStudent(studentId);
}
