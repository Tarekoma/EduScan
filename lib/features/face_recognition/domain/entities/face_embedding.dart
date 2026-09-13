import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// A numeric face descriptor produced by a recognition model (e.g. a 128- or
/// 512-dimensional MobileFaceNet embedding). Never a raw image — biometric
/// data for children is sensitive, so only the vector is stored/compared.
class FaceEmbedding extends Equatable {
  const FaceEmbedding(this.values);

  final List<double> values;

  int get dimension => values.length;

  /// L2-normalised copy, so cosine similarity reduces to a dot product.
  FaceEmbedding get normalized {
    var norm = 0.0;
    for (final v in values) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return this;
    return FaceEmbedding([for (final v in values) v / norm]);
  }

  /// Cosine similarity in [-1, 1]; higher means more alike.
  double similarity(FaceEmbedding other) {
    if (dimension != other.dimension || dimension == 0) return -1;
    final a = normalized.values;
    final b = other.normalized.values;
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot.clamp(-1.0, 1.0);
  }

  @override
  List<Object?> get props => [values];
}
