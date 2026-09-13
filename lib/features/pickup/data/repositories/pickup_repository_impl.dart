import '../../domain/entities/pickup_request.dart';
import '../../domain/repositories/pickup_repository.dart';
import '../datasources/pickup_remote_data_source.dart';

class PickupRepositoryImpl implements PickupRepository {
  PickupRepositoryImpl(this._remote);

  final PickupRemoteDataSource _remote;

  @override
  Stream<List<PickupRequest>> watchActive() => _remote.watchActive();

  @override
  Stream<PickupRequest?> watchActiveForStudent(String studentId) =>
      _remote.watchActiveForStudent(studentId);

  @override
  Stream<List<PickupRequest>> watchHistory({int limit = 100}) =>
      _remote.watchHistory(limit: limit);

  @override
  Future<void> requestPickup({
    required String studentId,
    required String studentName,
    String? className,
    required PickupRequester requester,
  }) => _remote.requestPickup(
    studentId: studentId,
    studentName: studentName,
    className: className,
    requester: requester,
  );

  @override
  Future<void> acknowledge({
    required String requestId,
    required PickupHandler handler,
  }) => _remote.acknowledge(requestId: requestId, handler: handler);

  @override
  Future<void> complete({
    required String requestId,
    required PickupHandler handler,
  }) => _remote.complete(requestId: requestId, handler: handler);

  @override
  Future<void> cancel({
    required String requestId,
    required String byUid,
    required bool isParent,
  }) => _remote.cancel(requestId: requestId, byUid: byUid, isParent: isParent);
}
