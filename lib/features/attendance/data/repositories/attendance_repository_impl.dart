import '../../../../core/enums/person_type.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._remote);

  final AttendanceRemoteDataSource _remote;

  @override
  Future<AttendanceRecord?> getRecord({
    required String personId,
    required PersonType personType,
    required String date,
  }) =>
      _remote.getRecord(personId: personId, personType: personType, date: date);

  @override
  Stream<AttendanceRecord?> watchRecord({
    required String personId,
    required PersonType personType,
    required String date,
  }) => _remote.watchRecord(
    personId: personId,
    personType: personType,
    date: date,
  );

  @override
  Stream<List<AttendanceRecord>> watchByDate(String date) =>
      _remote.watchByDate(date);

  @override
  Future<List<AttendanceRecord>> getInRange({
    required String fromDate,
    required String toDate,
  }) => _remote.getInRange(fromDate: fromDate, toDate: toDate);

  @override
  Stream<List<AttendanceRecord>> watchByPerson({
    required String personId,
    required PersonType personType,
    int limit = 60,
  }) => _remote.watchByPerson(personId: personId, limit: limit);

  @override
  Future<AttendanceRecord> checkIn({
    required String personId,
    required PersonType personType,
    required String date,
    required AttendanceActor actor,
  }) => _remote.checkIn(
    personId: personId,
    personType: personType,
    date: date,
    actor: actor,
  );

  @override
  Future<AttendanceRecord> checkOut({
    required String personId,
    required PersonType personType,
    required String date,
    required AttendanceActor actor,
  }) => _remote.checkOut(
    personId: personId,
    personType: personType,
    date: date,
    actor: actor,
  );

  @override
  Future<AttendanceRecord> correct({
    required String recordId,
    required AttendanceCorrectionInput input,
    required AttendanceActor actor,
  }) => _remote.correct(recordId: recordId, input: input, actor: actor);
}
