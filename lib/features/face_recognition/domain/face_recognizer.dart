import 'dart:typed_data';

import 'entities/face_embedding.dart';

/// A single captured frame handed to the recognizer.
class FaceImageInput {
  const FaceImageInput({
    required this.bytes,
    required this.width,
    required this.height,
    this.rotationDegrees = 0,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int rotationDegrees;
}

/// Produces a [FaceEmbedding] from a captured frame.
///
/// This is the model plug-in point. The default binding is
/// [UnavailableFaceRecognizer]; a real implementation (e.g. MobileFaceNet via
/// `tflite_flutter`, fed by `google_mlkit_face_detection` for the crop) is
/// registered instead when a model asset ships — see
/// `features/face_recognition/README.md`.
abstract interface class FaceRecognizer {
  /// Whether a working model is configured on this build.
  bool get isAvailable;

  /// Detects the primary face, crops/aligns it, and returns its embedding.
  /// Throws [FaceRecognitionUnavailable] when no model is configured, and
  /// [NoFaceDetected] when the frame has no usable face.
  Future<FaceEmbedding> extract(FaceImageInput input);
}

class FaceRecognitionUnavailable implements Exception {
  const FaceRecognitionUnavailable([
    this.message = 'Face recognition is not enabled on this build.',
  ]);
  final String message;
}

class NoFaceDetected implements Exception {
  const NoFaceDetected([this.message = 'No face detected. Try again.']);
  final String message;
}

/// Default binding — keeps the feature fully isolated and the app buildable
/// without ML dependencies. Swapped for a real recognizer when a model ships.
class UnavailableFaceRecognizer implements FaceRecognizer {
  const UnavailableFaceRecognizer();

  @override
  bool get isAvailable => false;

  @override
  Future<FaceEmbedding> extract(FaceImageInput input) async =>
      throw const FaceRecognitionUnavailable();
}
