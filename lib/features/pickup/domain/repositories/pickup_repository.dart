import '../entities/pickup_request.dart';

/// Identifies the parent creating a request.
class PickupRequester {
  const PickupRequester({
    required this.parentId,
    required this.parentName,
    required this.linkedStudentIds,
  });

  final String parentId;
  final String parentName;
  final List<String> linkedStudentIds;
}

/// Identifies the security user handling a request.
class PickupHandler {
  const PickupHandler({required this.uid, required this.canHandle});

  final String uid;
  final bool canHandle;
}

abstract interface class PickupRepository {
  /// Active (pending / acknowledged) requests, newest first — for security.
  Stream<List<PickupRequest>> watchActive();

  /// The current active request for one student, or null — for the parent.
  Stream<PickupRequest?> watchActiveForStudent(String studentId);

  /// Completed / cancelled history, newest first — for manager / supervisor.
  Stream<List<PickupRequest>> watchHistory({int limit});

  /// Creates a pending request. Fails with [BusinessRuleException] when the
  /// student already has an active request, and [PermissionException] when the
  /// parent is not linked to the student.
  Future<void> requestPickup({
    required String studentId,
    required String studentName,
    String? className,
    required PickupRequester requester,
  });

  Future<void> acknowledge({
    required String requestId,
    required PickupHandler handler,
  });

  Future<void> complete({
    required String requestId,
    required PickupHandler handler,
  });

  /// Cancels an active request. The parent may cancel their own; security may
  /// cancel any.
  Future<void> cancel({
    required String requestId,
    required String byUid,
    required bool isParent,
  });
}
