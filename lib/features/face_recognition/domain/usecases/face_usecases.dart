import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../attendance/domain/attendance_rules.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../attendance/domain/usecases/attendance_usecases.dart';
import '../entities/enrolled_face.dart';
import '../face_matcher.dart';
import '../face_recognizer.dart';
import '../repositories/face_enrollment_repository.dart';

/// Extracts an embedding from a frame and enrolls it for a person.
class EnrollFace {
  const EnrollFace(this._recognizer, this._repo);

  final FaceRecognizer _recognizer;
  final FaceEnrollmentRepository _repo;

  Future<void> call({
    required String personId,
    required PersonType personType,
    required FaceImageInput frame,
    required String enrolledBy,
  }) async {
    _assertAvailable();
    final embedding = await _recognizer.extract(frame);
    await _repo.enroll(
      personId: personId,
      personType: personType,
      embedding: embedding,
      enrolledBy: enrolledBy,
    );
  }

  void _assertAvailable() {
    if (!_recognizer.isAvailable) {
      throw const BusinessRuleException(
        'Face recognition is not enabled on this build.',
      );
    }
  }
}

/// Identifies the person in a frame. Returns null when no confident match.
class IdentifyByFace {
  const IdentifyByFace(this._recognizer, this._repo);

  final FaceRecognizer _recognizer;
  final FaceEnrollmentRepository _repo;

  Future<FaceMatch?> call(FaceImageInput frame) async {
    if (!_recognizer.isAvailable) {
      throw const BusinessRuleException(
        'Face recognition is not enabled on this build.',
      );
    }
    final probe = await _recognizer.extract(frame);
    final enrolled = await _repo.loadAll();
    return FaceMatcher.bestMatch(probe, enrolled);
  }
}

/// The fallback attendance flow: identify a face, then run the SAME check-in /
/// check-out use cases as the QR path — no separate attendance system.
class RecordAttendanceByFace {
  const RecordAttendanceByFace({
    required IdentifyByFace identify,
    required GetTodayRecord getTodayRecord,
    required CheckInUseCase checkIn,
    required CheckOutUseCase checkOut,
  }) : _identify = identify,
       _getToday = getTodayRecord,
       _checkIn = checkIn,
       _checkOut = checkOut;

  final IdentifyByFace _identify;
  final GetTodayRecord _getToday;
  final CheckInUseCase _checkIn;
  final CheckOutUseCase _checkOut;

  Future<FaceAttendanceResult> call({
    required FaceImageInput frame,
    required AttendanceActor actor,
    AttendanceAction? action,
  }) async {
    final match = await _identify(frame);
    if (match == null) {
      throw const NotFoundException(
        'Face not recognised. Use the QR code instead.',
      );
    }

    final current = await _getToday(
      personId: match.personId,
      personType: match.personType,
    );
    final effective = action ?? AttendanceRules.nextAction(current);
    final record = switch (effective) {
      AttendanceAction.checkIn => await _checkIn(
        personId: match.personId,
        personType: match.personType,
        actor: actor,
      ),
      AttendanceAction.checkOut => await _checkOut(
        personId: match.personId,
        personType: match.personType,
        actor: actor,
      ),
    };
    return FaceAttendanceResult(
      match: match,
      record: record,
      action: effective,
    );
  }
}

class FaceAttendanceResult {
  const FaceAttendanceResult({
    required this.match,
    required this.record,
    required this.action,
  });

  final FaceMatch match;
  final AttendanceRecord record;
  final AttendanceAction action;
}

class LoadEnrolledFaces {
  const LoadEnrolledFaces(this._repo);
  final FaceEnrollmentRepository _repo;
  Future<List<EnrolledFace>> call() => _repo.loadAll();
}
