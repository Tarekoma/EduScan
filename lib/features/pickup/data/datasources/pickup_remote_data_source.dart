import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/pickup_status.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/pickup_rules.dart';
import '../../domain/repositories/pickup_repository.dart';
import '../models/pickup_request_model.dart';

class PickupRemoteDataSource {
  PickupRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.pickupRequests);

  CollectionReference<Map<String, dynamic>> get _activeCol =>
      _firestore.collection(FirestoreCollections.pickupActive);

  static const _activeValues = ['pending', 'acknowledged'];
  static const _terminalValues = ['completed', 'cancelled'];

  Stream<List<PickupRequest>> watchActive() {
    return _col
        .where(PickupFields.status, whereIn: _activeValues)
        .orderBy(PickupFields.requestedAt, descending: true)
        .snapshots()
        .map<List<PickupRequest>>(
          (s) => s.docs.map(PickupRequestModel.fromDoc).toList(),
        )
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Stream<List<PickupRequest>> watchHistory({int limit = 100}) {
    return _col
        .where(PickupFields.status, whereIn: _terminalValues)
        .orderBy(PickupFields.requestedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map<List<PickupRequest>>(
          (s) => s.docs.map(PickupRequestModel.fromDoc).toList(),
        )
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Stream<PickupRequest?> watchActiveForStudent(String studentId) {
    return _activeCol
        .doc(studentId)
        .snapshots()
        .asyncExpand((ptr) {
          final requestId = ptr.data()?[PickupFields.requestId] as String?;
          if (!ptr.exists || requestId == null) {
            return Stream<PickupRequest?>.value(null);
          }
          return _col
              .doc(requestId)
              .snapshots()
              .map((d) => d.exists ? PickupRequestModel.fromDoc(d) : null);
        })
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Future<void> requestPickup({
    required String studentId,
    required String studentName,
    String? className,
    required PickupRequester requester,
  }) async {
    try {
      final activeRef = _activeCol.doc(studentId);
      final reqRef = _col.doc();
      await _firestore.runTransaction((tx) async {
        final ptr = await tx.get(activeRef);
        if (ptr.exists) {
          throw const BusinessRuleException(
            'There is already an active pickup request for this child.',
          );
        }
        tx.set(
          reqRef,
          PickupRequestModel.newData(
            requestId: reqRef.id,
            studentId: studentId,
            studentName: studentName,
            className: className,
            parentId: requester.parentId,
            parentName: requester.parentName,
          ),
        );
        tx.set(activeRef, {
          PickupFields.requestId: reqRef.id,
          PickupFields.studentId: studentId,
          PickupFields.parentId: requester.parentId,
          PickupFields.requestedAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> _transition(
    String requestId,
    PickupStatus to,
    Map<String, dynamic> extra, {
    bool removeActivePointer = false,
    String? requireParentId,
  }) async {
    try {
      final reqRef = _col.doc(requestId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(reqRef);
        if (!snap.exists) {
          throw NotFoundException('Pickup request "$requestId" not found.');
        }
        final current = PickupRequestModel.fromDoc(snap);
        if (requireParentId != null && current.parentId != requireParentId) {
          throw const PermissionException(
            message: 'You can only cancel your own pickup request.',
          );
        }
        PickupRules.assertTransition(current.status, to);
        tx.update(reqRef, {PickupFields.status: to.value, ...extra});
        if (removeActivePointer) {
          tx.delete(_activeCol.doc(current.studentId));
        }
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> acknowledge({
    required String requestId,
    required PickupHandler handler,
  }) => _transition(requestId, PickupStatus.acknowledged, {
    PickupFields.acknowledgedAt: FieldValue.serverTimestamp(),
    PickupFields.handledBy: handler.uid,
  });

  Future<void> complete({
    required String requestId,
    required PickupHandler handler,
  }) => _transition(requestId, PickupStatus.completed, {
    PickupFields.completedAt: FieldValue.serverTimestamp(),
    PickupFields.handledBy: handler.uid,
  }, removeActivePointer: true);

  Future<void> cancel({
    required String requestId,
    required String byUid,
    required bool isParent,
  }) => _transition(
    requestId,
    PickupStatus.cancelled,
    {PickupFields.cancelledAt: FieldValue.serverTimestamp()},
    removeActivePointer: true,
    requireParentId: isParent ? byUid : null,
  );
}
