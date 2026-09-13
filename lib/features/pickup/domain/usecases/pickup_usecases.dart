import '../../../../core/enums/attendance_state.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../attendance/domain/usecases/attendance_usecases.dart';
import '../entities/pickup_request.dart';
import '../repositories/pickup_repository.dart';

class WatchActivePickupRequests {
  const WatchActivePickupRequests(this._repo);
  final PickupRepository _repo;
  Stream<List<PickupRequest>> call() => _repo.watchActive();
}

class WatchStudentPickup {
  const WatchStudentPickup(this._repo);
  final PickupRepository _repo;
  Stream<PickupRequest?> call(String studentId) =>
      _repo.watchActiveForStudent(studentId);
}

class WatchPickupHistory {
  const WatchPickupHistory(this._repo);
  final PickupRepository _repo;
  Stream<List<PickupRequest>> call({int limit = 100}) =>
      _repo.watchHistory(limit: limit);
}

class RequestPickup {
  const RequestPickup(this._repo, this._getTodayRecord);
  final PickupRepository _repo;
  final GetTodayRecord _getTodayRecord;

  /// A pickup request may only be raised while the child is actually
  /// checked in — never for a child who hasn't arrived yet, and never for
  /// one who's already checked out and left for the day.
  Future<void> call({
    required String studentId,
    required String studentName,
    String? className,
    required PickupRequester requester,
  }) async {
    if (!requester.linkedStudentIds.contains(studentId)) {
      throw const PermissionException(
        message: 'You can only request pickup for your own child.',
      );
    }
    final record = await _getTodayRecord(
      personId: studentId,
      personType: PersonType.student,
    );
    switch (record?.state ?? AttendanceState.absent) {
      case AttendanceState.absent:
        throw const BusinessRuleException(
          'Your child has not checked in yet today.',
        );
      case AttendanceState.left:
        throw const BusinessRuleException(
          'Your child has already checked out for today.',
        );
      case AttendanceState.inside:
        break;
    }
    return _repo.requestPickup(
      studentId: studentId,
      studentName: studentName,
      className: className,
      requester: requester,
    );
  }
}

class AcknowledgePickup {
  const AcknowledgePickup(this._repo);
  final PickupRepository _repo;

  Future<void> call({
    required String requestId,
    required PickupHandler handler,
  }) {
    _assertHandler(handler);
    return _repo.acknowledge(requestId: requestId, handler: handler);
  }
}

class CompletePickup {
  const CompletePickup(this._repo);
  final PickupRepository _repo;

  Future<void> call({
    required String requestId,
    required PickupHandler handler,
  }) {
    _assertHandler(handler);
    return _repo.complete(requestId: requestId, handler: handler);
  }
}

class CancelPickup {
  const CancelPickup(this._repo);
  final PickupRepository _repo;

  Future<void> call({
    required String requestId,
    required String byUid,
    required bool isParent,
  }) => _repo.cancel(requestId: requestId, byUid: byUid, isParent: isParent);
}

void _assertHandler(PickupHandler handler) {
  if (!handler.canHandle) {
    throw const PermissionException(
      message: 'Only security may handle pickup requests.',
    );
  }
}
