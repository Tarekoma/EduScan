import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums/person_type.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/entities/enrolled_face.dart';
import '../domain/entities/face_embedding.dart';
import '../domain/repositories/face_enrollment_repository.dart';

class FaceEnrollmentRemoteDataSource implements FaceEnrollmentRepository {
  FaceEnrollmentRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'faceEnrollments';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  String _docId(PersonType type, String personId) => '${type.value}_$personId';

  EnrolledFace _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return EnrolledFace(
      personId: data['personId'] as String,
      personType: PersonType.fromValue(data['personType'] as String?),
      embedding: FaceEmbedding(
        ((data['embedding'] as List?) ?? const [])
            .map((v) => (v as num).toDouble())
            .toList(),
      ),
    );
  }

  @override
  Future<List<EnrolledFace>> loadAll() async {
    try {
      final snap = await _col.get();
      return snap.docs
          .where((d) => d.data().containsKey('embedding'))
          .map(_fromDoc)
          .toList();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<EnrolledFace?> forPerson(String personId) async {
    try {
      final snap = await _col
          .where('personId', isEqualTo: personId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return _fromDoc(snap.docs.first);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> enroll({
    required String personId,
    required PersonType personType,
    required FaceEmbedding embedding,
    required String enrolledBy,
  }) async {
    try {
      await _col.doc(_docId(personType, personId)).set({
        'personId': personId,
        'personType': personType.value,
        // Only the numeric descriptor — never a raw image.
        'embedding': embedding.normalized.values,
        'dimension': embedding.dimension,
        'enrolledBy': enrolledBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> remove(String personId) async {
    try {
      final existing = await forPerson(personId);
      if (existing == null) return;
      await _col.doc(_docId(existing.personType, personId)).delete();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
