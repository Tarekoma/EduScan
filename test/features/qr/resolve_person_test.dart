import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/core/enums/worker_job_title.dart';
import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/qr/domain/usecases/resolve_person.dart';
import 'package:attendance_management/features/students/domain/entities/student.dart';
import 'package:attendance_management/features/students/domain/repositories/student_repository.dart';
import 'package:attendance_management/features/workers/domain/entities/worker.dart';
import 'package:attendance_management/features/workers/domain/repositories/worker_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Students implements StudentRepository {
  @override
  Future<Student> getStudent(String id) async {
    if (id != 'STU_00125') throw NotFoundException('nope');
    return const Student(
      studentId: 'STU_00125',
      fullName: 'Ahmed Mohamed',
      className: '5A',
      qrCodeId: 'STU_00125',
    );
  }

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Workers implements WorkerRepository {
  @override
  Future<Worker> getWorker(String id) async {
    if (id != 'WRK_00015') throw NotFoundException('nope');
    return const Worker(
      workerId: 'WRK_00015',
      fullName: 'Mr Teacher',
      jobTitle: WorkerJobTitle.teacher,
      qrCodeId: 'WRK_00015',
    );
  }

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  final resolve = ResolvePerson(students: _Students(), workers: _Workers());

  test('resolves a student QR', () async {
    final r = await resolve('stu_00125');
    expect(r.personType, PersonType.student);
    expect(r.personId, 'STU_00125');
    expect(r.displayName, 'Ahmed Mohamed');
  });

  test('resolves a worker QR', () async {
    final r = await resolve('WRK_00015');
    expect(r.personType, PersonType.worker);
    expect(r.personId, 'WRK_00015');
  });

  test('Rule 4: unknown student id throws NotFoundException', () {
    expect(() => resolve('STU_99999'), throwsA(isA<NotFoundException>()));
  });

  test('unparseable payload throws ValidationException', () {
    expect(() => resolve('hello'), throwsA(isA<ValidationException>()));
    expect(() => resolve(''), throwsA(isA<ValidationException>()));
  });
}
