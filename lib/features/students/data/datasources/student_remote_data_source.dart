import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/person_id.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';
import '../models/student_model.dart';

class StudentRemoteDataSource {
  StudentRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.students);

  DocumentReference<Map<String, dynamic>> get _counterRef =>
      _firestore.collection(CounterDoc.collection).doc(CounterDoc.doc);

  Stream<List<StudentModel>> watchStudents() {
    return _col
        .orderBy(StudentFields.fullName)
        .snapshots()
        .map((snap) => snap.docs.map(StudentModel.fromDoc).toList())
        .handleError((Object e, StackTrace s) => throw ErrorMapper.map(e, s));
  }

  Future<StudentModel> getStudent(String studentId) async {
    try {
      final doc = await _col.doc(studentId).get();
      if (!doc.exists) {
        throw NotFoundException(appStrings.studentNotFound(studentId));
      }
      return StudentModel.fromDoc(doc);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<StudentModel> createStudent(StudentDraft draft) async {
    try {
      final studentId = await _firestore.runTransaction((tx) async {
        final counterSnap = await tx.get(_counterRef);
        final current =
            (counterSnap.data()?[CounterDoc.studentField] as int?) ?? 0;
        final next = current + 1;
        final id = PersonId.format(PersonType.student, next);

        tx.set(_counterRef, {
          CounterDoc.studentField: next,
        }, SetOptions(merge: true));
        tx.set(
          _col.doc(id),
          StudentModel.newData(
            studentId: id,
            fullName: draft.fullName,
            className: draft.className,
            parentId: draft.parentId,
          ),
        );
        return id;
      });
      return getStudent(studentId);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<StudentModel> updateStudent(Student student) async {
    try {
      await _col
          .doc(student.studentId)
          .update(StudentModel.updateData(student));
      return getStudent(student.studentId);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      await _col.doc(studentId).delete();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
