import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/date_key.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

void _assertAuthorised(AttendanceActor actor) {
  if (!actor.canRecord) {
    throw PermissionException(
      message: appStrings.attendanceOnlySecurityCanRecord,
    );
  }
}

/// Checks a person in for today. Business rules (Rule 1) are enforced
/// transactionally in the repository; this use case owns authorisation
/// (Rule 9) and input shaping.
class CheckInUseCase {
  const CheckInUseCase(this._repo);
  final AttendanceRepository _repo;

  Future<AttendanceRecord> call({
    required String personId,
    required PersonType personType,
    required AttendanceActor actor,
    DateTime? now,
  }) {
    _assertAuthorised(actor);
    return _repo.checkIn(
      personId: personId,
      personType: personType,
      date: DateKey.of(now ?? DateTime.now()),
      actor: actor,
    );
  }
}

/// Checks a person out for today (Rules 2 & 3 enforced in the repository).
class CheckOutUseCase {
  const CheckOutUseCase(this._repo);
  final AttendanceRepository _repo;

  Future<AttendanceRecord> call({
    required String personId,
    required PersonType personType,
    required AttendanceActor actor,
    DateTime? now,
  }) {
    _assertAuthorised(actor);
    return _repo.checkOut(
      personId: personId,
      personType: personType,
      date: DateKey.of(now ?? DateTime.now()),
      actor: actor,
    );
  }
}

/// Corrects an existing record's times, preserving audit history (Rule 12).
class UpdateAttendanceUseCase {
  const UpdateAttendanceUseCase(this._repo);
  final AttendanceRepository _repo;

  Future<AttendanceRecord> call({
    required String recordId,
    required AttendanceCorrectionInput input,
    required AttendanceActor actor,
  }) {
    _assertAuthorised(actor);
    if (input.checkIn == null && input.checkOut == null) {
      throw ValidationException(appStrings.validationNothingToChange);
    }
    if (input.checkIn != null &&
        input.checkOut != null &&
        input.checkOut!.isBefore(input.checkIn!)) {
      throw ValidationException(appStrings.validationCheckOutBeforeCheckIn);
    }
    return _repo.correct(recordId: recordId, input: input, actor: actor);
  }
}

class WatchAttendanceByDate {
  const WatchAttendanceByDate(this._repo);
  final AttendanceRepository _repo;
  Stream<List<AttendanceRecord>> call([DateTime? day]) =>
      _repo.watchByDate(DateKey.of(day ?? DateTime.now()));
}

class WatchPersonAttendance {
  const WatchPersonAttendance(this._repo);
  final AttendanceRepository _repo;
  Stream<List<AttendanceRecord>> call({
    required String personId,
    required PersonType personType,
    int limit = 60,
  }) => _repo.watchByPerson(
    personId: personId,
    personType: personType,
    limit: limit,
  );
}

class GetTodayRecord {
  const GetTodayRecord(this._repo);
  final AttendanceRepository _repo;
  Future<AttendanceRecord?> call({
    required String personId,
    required PersonType personType,
    DateTime? day,
  }) => _repo.getRecord(
    personId: personId,
    personType: personType,
    date: DateKey.of(day ?? DateTime.now()),
  );
}

class WatchTodayRecord {
  const WatchTodayRecord(this._repo);
  final AttendanceRepository _repo;
  Stream<AttendanceRecord?> call({
    required String personId,
    required PersonType personType,
    DateTime? day,
  }) => _repo.watchRecord(
    personId: personId,
    personType: personType,
    date: DateKey.of(day ?? DateTime.now()),
  );
}
