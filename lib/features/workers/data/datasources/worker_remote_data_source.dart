import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/person_id.dart';
import '../../domain/entities/worker.dart';
import '../../domain/repositories/worker_repository.dart';
import '../models/worker_model.dart';

class WorkerRemoteDataSource {
  WorkerRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.workers);

  DocumentReference<Map<String, dynamic>> get _counterRef =>
      _firestore.collection(CounterDoc.collection).doc(CounterDoc.doc);

  Stream<List<WorkerModel>> watchWorkers() {
    return _col
        .orderBy(WorkerFields.fullName)
        .snapshots()
        .map((snap) => snap.docs.map(WorkerModel.fromDoc).toList())
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Future<WorkerModel> getWorker(String workerId) async {
    try {
      final doc = await _col.doc(workerId).get();
      if (!doc.exists) {
        throw NotFoundException('Worker "$workerId" was not found.');
      }
      return WorkerModel.fromDoc(doc);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<WorkerModel> createWorker(WorkerDraft draft) async {
    try {
      final workerId = await _firestore.runTransaction((tx) async {
        final counterSnap = await tx.get(_counterRef);
        final current =
            (counterSnap.data()?[CounterDoc.workerField] as int?) ?? 0;
        final next = current + 1;
        final id = PersonId.format(PersonType.worker, next);

        tx.set(_counterRef, {
          CounterDoc.workerField: next,
        }, SetOptions(merge: true));
        tx.set(
          _col.doc(id),
          WorkerModel.newData(
            workerId: id,
            fullName: draft.fullName,
            job: draft.job,
            department: draft.department,
            phone: draft.phone,
          ),
        );
        return id;
      });
      return getWorker(workerId);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<WorkerModel> updateWorker(Worker worker) async {
    try {
      await _col.doc(worker.workerId).update(WorkerModel.updateData(worker));
      return getWorker(worker.workerId);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> deleteWorker(String workerId) async {
    try {
      await _col.doc(workerId).delete();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
