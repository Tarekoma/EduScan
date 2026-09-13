import '../../../../core/enums/person_type.dart';
import '../entities/enrolled_face.dart';
import '../entities/face_embedding.dart';

/// Stores and retrieves face embeddings. Implementations must never persist raw
/// images — only the numeric descriptor.
abstract interface class FaceEnrollmentRepository {
  Future<List<EnrolledFace>> loadAll();

  Future<EnrolledFace?> forPerson(String personId);

  Future<void> enroll({
    required String personId,
    required PersonType personType,
    required FaceEmbedding embedding,
    required String enrolledBy,
  });

  Future<void> remove(String personId);
}
