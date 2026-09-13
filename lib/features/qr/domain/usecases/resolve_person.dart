import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../workers/domain/repositories/worker_repository.dart';
import '../entities/resolved_person.dart';

/// Resolves a raw QR payload (e.g. `STU_00125`) to an existing person.
///
/// Rule 4: the QR must belong to an existing person — a missing record raises
/// [NotFoundException]; an unparseable payload raises [ValidationException].
class ResolvePerson {
  const ResolvePerson({
    required StudentRepository students,
    required WorkerRepository workers,
  }) : _students = students,
       _workers = workers;

  final StudentRepository _students;
  final WorkerRepository _workers;

  Future<ResolvedPerson> call(String rawPayload) async {
    final payload = rawPayload.trim().toUpperCase();
    if (payload.isEmpty) {
      throw const ValidationException('Empty QR code.');
    }

    final type = PersonType.fromQrCode(payload);
    if (type == null) {
      throw const ValidationException('Unrecognised QR code.');
    }

    switch (type) {
      case PersonType.student:
        final s = await _students.getStudent(payload);
        return ResolvedPerson(
          personId: s.studentId,
          personType: PersonType.student,
          displayName: s.fullName,
          subtitle: 'Class ${s.className}',
        );
      case PersonType.worker:
        final w = await _workers.getWorker(payload);
        return ResolvedPerson(
          personId: w.workerId,
          personType: PersonType.worker,
          displayName: w.fullName,
          subtitle: w.job,
        );
    }
  }
}
