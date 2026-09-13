import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/attendance_rules.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_record_model.dart';

class AttendanceRemoteDataSource {
  AttendanceRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.attendance);

  Future<AttendanceRecordModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? AttendanceRecordModel.fromDoc(doc) : null;
  }

  Future<AttendanceRecordModel?> getRecord({
    required String personId,
    required PersonType personType,
    required String date,
  }) {
    return getById(
      AttendanceRecordModel.buildId(
        personId: personId,
        personType: personType,
        date: date,
      ),
    ).catchError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Stream<AttendanceRecord?> watchRecord({
    required String personId,
    required PersonType personType,
    required String date,
  }) {
    final id = AttendanceRecordModel.buildId(
      personId: personId,
      personType: personType,
      date: date,
    );
    return _col
        .doc(id)
        .snapshots()
        .map((doc) {
          return doc.exists ? AttendanceRecordModel.fromDoc(doc) : null;
        })
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Future<List<AttendanceRecord>> getInRange({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final snap = await _col
          .where(AttendanceFields.date, isGreaterThanOrEqualTo: fromDate)
          .where(AttendanceFields.date, isLessThanOrEqualTo: toDate)
          .orderBy(AttendanceFields.date)
          .get();
      return snap.docs.map(AttendanceRecordModel.fromDoc).toList();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Stream<List<AttendanceRecord>> watchByDate(String date) {
    return _col
        .where(AttendanceFields.date, isEqualTo: date)
        .orderBy(AttendanceFields.checkIn)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceRecordModel.fromDoc).toList())
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Stream<List<AttendanceRecord>> watchByPerson({
    required String personId,
    required int limit,
  }) {
    // personId is globally unique (STU_/WRK_ prefix), so no personType filter
    // is needed here.
    return _col
        .where(AttendanceFields.personId, isEqualTo: personId)
        .orderBy(AttendanceFields.date, descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceRecordModel.fromDoc).toList())
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Future<AttendanceRecordModel> checkIn({
    required String personId,
    required PersonType personType,
    required String date,
    required AttendanceActor actor,
  }) async {
    final id = AttendanceRecordModel.buildId(
      personId: personId,
      personType: personType,
      date: date,
    );
    final ref = _col.doc(id);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final current = snap.exists
            ? AttendanceRecordModel.fromDoc(snap)
            : null;
        AttendanceRules.assertCanCheckIn(current);
        tx.set(ref, {
          AttendanceFields.personId: personId,
          AttendanceFields.personType: personType.value,
          AttendanceFields.date: date,
          AttendanceFields.checkIn: FieldValue.serverTimestamp(),
          AttendanceFields.checkInRecordedBy: actor.uid,
          AttendanceFields.checkInRecordedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      return (await getById(id))!;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<AttendanceRecordModel> checkOut({
    required String personId,
    required PersonType personType,
    required String date,
    required AttendanceActor actor,
  }) async {
    final id = AttendanceRecordModel.buildId(
      personId: personId,
      personType: personType,
      date: date,
    );
    final ref = _col.doc(id);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final current = snap.exists
            ? AttendanceRecordModel.fromDoc(snap)
            : null;
        AttendanceRules.assertCanCheckOut(current);
        tx.update(ref, {
          AttendanceFields.checkOut: FieldValue.serverTimestamp(),
          AttendanceFields.checkOutRecordedBy: actor.uid,
          AttendanceFields.checkOutRecordedAt: FieldValue.serverTimestamp(),
        });
      });
      return (await getById(id))!;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<AttendanceRecordModel> correct({
    required String recordId,
    required AttendanceCorrectionInput input,
    required AttendanceActor actor,
  }) async {
    final ref = _col.doc(recordId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw NotFoundException('Attendance record "$recordId" not found.');
        }
        final current = AttendanceRecordModel.fromDoc(snap);
        final now = DateTime.now();
        final updates = <String, dynamic>{};
        final newCorrections = <AttendanceCorrection>[];

        void applyChange(String field, DateTime? oldValue, DateTime? newValue) {
          if (newValue == null || newValue == oldValue) return;
          updates[field] = Timestamp.fromDate(newValue);
          newCorrections.add(
            AttendanceCorrection(
              field: field,
              previousValue: oldValue?.toIso8601String(),
              newValue: newValue.toIso8601String(),
              by: actor.uid,
              at: now,
            ),
          );
        }

        applyChange(AttendanceFields.checkIn, current.checkIn, input.checkIn);
        applyChange(
          AttendanceFields.checkOut,
          current.checkOut,
          input.checkOut,
        );

        if (updates.isEmpty) {
          throw const ValidationException('Nothing to change.');
        }

        updates[AttendanceFields.updatedBy] = actor.uid;
        updates[AttendanceFields.updatedAt] = FieldValue.serverTimestamp();
        updates[AttendanceFields.corrections] = FieldValue.arrayUnion(
          newCorrections.map(AttendanceRecordModel.correctionToMap).toList(),
        );

        tx.update(ref, updates);
      });
      return (await getById(recordId))!;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
