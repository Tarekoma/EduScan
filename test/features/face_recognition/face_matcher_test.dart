import 'package:attendance_management/core/enums/person_type.dart';
import 'package:attendance_management/features/face_recognition/domain/entities/enrolled_face.dart';
import 'package:attendance_management/features/face_recognition/domain/entities/face_embedding.dart';
import 'package:attendance_management/features/face_recognition/domain/face_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

EnrolledFace _face(String id, List<double> v) => EnrolledFace(
  personId: id,
  personType: PersonType.student,
  embedding: FaceEmbedding(v),
);

void main() {
  group('FaceEmbedding.similarity', () {
    test('identical vectors → 1.0', () {
      const e = FaceEmbedding([1, 2, 3, 4]);
      expect(e.similarity(e), closeTo(1.0, 1e-9));
    });

    test('orthogonal vectors → 0', () {
      expect(
        const FaceEmbedding([1, 0]).similarity(const FaceEmbedding([0, 1])),
        closeTo(0.0, 1e-9),
      );
    });

    test('dimension mismatch → -1', () {
      expect(
        const FaceEmbedding([1, 0]).similarity(const FaceEmbedding([1, 0, 0])),
        -1,
      );
    });
  });

  group('FaceMatcher.bestMatch', () {
    final enrolled = [
      _face('STU_00001', [1, 0, 0]),
      _face('STU_00002', [0, 1, 0]),
      _face('STU_00003', [0, 0, 1]),
    ];

    test('returns the closest above threshold', () {
      final m = FaceMatcher.bestMatch(
        const FaceEmbedding([0.95, 0.1, 0.05]),
        enrolled,
      );
      expect(m?.personId, 'STU_00001');
      expect(m!.confidence, greaterThan(FaceMatcher.defaultThreshold));
    });

    test('returns null when nothing is close enough', () {
      final m = FaceMatcher.bestMatch(
        const FaceEmbedding([0.4, 0.4, 0.4]),
        enrolled,
      );
      expect(m, isNull);
    });

    test('returns null when top two are within the margin (ambiguous)', () {
      final ambiguous = [
        _face('A', [1, 0.98, 0]),
        _face('B', [0.98, 1, 0]),
      ];
      final m = FaceMatcher.bestMatch(
        const FaceEmbedding([1, 1, 0]),
        ambiguous,
      );
      expect(m, isNull);
    });

    test('empty enrolment → null', () {
      expect(
        FaceMatcher.bestMatch(const FaceEmbedding([1, 0]), const []),
        isNull,
      );
    });
  });
}
