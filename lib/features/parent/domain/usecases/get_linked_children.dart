import '../../../students/domain/entities/student.dart';
import '../../../students/domain/repositories/student_repository.dart';

/// Loads the [Student] records a parent is linked to. A parent may not list the
/// students collection, so each linked id is fetched individually — the rules
/// permit this only for their own children.
class GetLinkedChildren {
  const GetLinkedChildren(this._students);

  final StudentRepository _students;

  Future<List<Student>> call(List<String> studentIds) async {
    final results = await Future.wait(
      studentIds.map(_students.getStudent),
      eagerError: false,
    );
    results.sort((a, b) => a.fullName.compareTo(b.fullName));
    return results;
  }
}
