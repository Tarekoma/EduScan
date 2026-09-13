# Face recognition (optional fallback)

Used only when a person has no QR code. It is **fully isolated**: the core
attendance workflow does not depend on it, and enabling it does not change the
check-in / check-out flow — a recognised face is turned into a `personId` and
run through the **same** `CheckInUseCase` / `CheckOutUseCase` as QR.

## What ships today

- `FaceEmbedding` — descriptor value type + cosine similarity.
- `FaceMatcher` — real 1:N matching (threshold + margin against 2nd-best).
- `FaceEnrollmentRemoteDataSource` — stores **embeddings only** in
  `faceEnrollments/{personType}_{personId}` (never raw images; children's
  biometric data is sensitive). Security-only per `firestore.rules`.
- `RecordAttendanceByFace` — identify → existing attendance use cases.
- `FaceAttendanceCubit` / `FaceAttendancePage` — wired and gated by
  `AppConfig.faceRecognitionEnabled` (default `false`).
- `UnavailableFaceRecognizer` — the default `FaceRecognizer` binding, so the
  app builds with no ML dependencies.

## To enable it

1. Add deps: `google_mlkit_face_detection`, `tflite_flutter`, `camera`.
2. Drop a MobileFaceNet-style model at `assets/models/facenet.tflite` and
   register it in `pubspec.yaml`.
3. Implement `FaceRecognizer`:
   - detect the primary face with ML Kit,
   - crop + align + resize to the model's input (commonly 112×112),
   - normalise, run the interpreter, return the output vector as a
     `FaceEmbedding`.
4. In `face_recognition_injection.dart`, register your implementation instead of
   `UnavailableFaceRecognizer`.
5. Add a camera preview to `FaceAttendancePage` that feeds frames to
   `FaceAttendanceCubit.submitFrame`, and an enrolment screen that calls
   `EnrollFace`.
6. Flip `AppConfig.faceRecognitionEnabled` to `true`.

Nothing else in the app needs to change.
