import 'package:equatable/equatable.dart';

import '../../../../core/enums/person_type.dart';
import 'face_embedding.dart';

/// A person's stored face descriptor.
class EnrolledFace extends Equatable {
  const EnrolledFace({
    required this.personId,
    required this.personType,
    required this.embedding,
  });

  final String personId;
  final PersonType personType;
  final FaceEmbedding embedding;

  @override
  List<Object?> get props => [personId, personType, embedding];
}

/// The result of identifying a probe face against the enrolled set.
class FaceMatch extends Equatable {
  const FaceMatch({
    required this.personId,
    required this.personType,
    required this.confidence,
  });

  final String personId;
  final PersonType personType;

  /// Cosine similarity of the winning match, in [-1, 1].
  final double confidence;

  @override
  List<Object?> get props => [personId, personType, confidence];
}
