import '../entities/student.dart';

/// Draft data for creating a student. The id and qrCodeId are generated
/// server-side (sequential counter), not supplied by the caller.
class StudentDraft {
  const StudentDraft({
    required this.fullName,
    required this.className,
    this.parentId,
  });

  final String fullName;
  final String className;
  final String? parentId;
}

abstract interface class StudentRepository {
  Stream<List<Student>> watchStudents();

  Future<Student> getStudent(String studentId);

  /// Creates a student with a freshly allocated unique id. Returns the created
  /// record.
  Future<Student> createStudent(StudentDraft draft);

  Future<Student> updateStudent(Student student);

  Future<void> deleteStudent(String studentId);
}
