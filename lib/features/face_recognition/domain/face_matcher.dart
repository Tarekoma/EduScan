import 'entities/enrolled_face.dart';
import 'entities/face_embedding.dart';

/// Pure 1:N matching of a probe embedding against the enrolled set.
/// This is real recognition maths (cosine similarity + threshold), independent
/// of whichever model produced the embeddings.
abstract final class FaceMatcher {
  /// Rejects matches below this cosine similarity. Tune per model.
  static const double defaultThreshold = 0.68;

  /// Minimum gap between the best and second-best match to accept the best one
  /// — guards against two similar-looking people.
  static const double defaultMargin = 0.05;

  static FaceMatch? bestMatch(
    FaceEmbedding probe,
    List<EnrolledFace> enrolled, {
    double threshold = defaultThreshold,
    double margin = defaultMargin,
  }) {
    if (enrolled.isEmpty) return null;

    var bestScore = -2.0;
    var secondScore = -2.0;
    EnrolledFace? best;
    for (final face in enrolled) {
      final score = probe.similarity(face.embedding);
      if (score > bestScore) {
        secondScore = bestScore;
        bestScore = score;
        best = face;
      } else if (score > secondScore) {
        secondScore = score;
      }
    }

    if (best == null || bestScore < threshold) return null;
    if (enrolled.length > 1 && (bestScore - secondScore) < margin) return null;

    return FaceMatch(
      personId: best.personId,
      personType: best.personType,
      confidence: bestScore,
    );
  }
}
