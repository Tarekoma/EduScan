/// Centralised Firestore collection names. Never hard-code these strings.
abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String students = 'students';
  static const String workers = 'workers';
  static const String attendance = 'attendance';
  static const String pickupRequests = 'pickupRequests';

  /// Guard docs keyed by studentId — existence means an active pickup request
  /// exists for that student. Written/removed transactionally with the request.
  static const String pickupActive = 'pickupActive';
}

/// Centralised Firestore field names for documents that are queried or written
/// from more than one place.
abstract final class StudentFields {
  static const String studentId = 'studentId';
  static const String fullName = 'fullName';
  static const String className = 'className';
  static const String qrCodeId = 'qrCodeId';
  static const String parentId = 'parentId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

abstract final class WorkerFields {
  static const String workerId = 'workerId';
  static const String fullName = 'fullName';
  static const String job = 'job';
  static const String department = 'department';
  static const String phone = 'phone';
  static const String qrCodeId = 'qrCodeId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

abstract final class PickupFields {
  static const String requestId = 'requestId';
  static const String studentId = 'studentId';
  static const String parentId = 'parentId';
  static const String parentName = 'parentName';
  static const String studentName = 'studentName';
  static const String className = 'className';
  static const String status = 'status';
  static const String requestedAt = 'requestedAt';
  static const String acknowledgedAt = 'acknowledgedAt';
  static const String completedAt = 'completedAt';
  static const String cancelledAt = 'cancelledAt';
  static const String handledBy = 'handledBy';
}

abstract final class AttendanceFields {
  static const String personId = 'personId';
  static const String personType = 'personType';
  static const String date = 'date';
  static const String checkIn = 'checkIn';
  static const String checkOut = 'checkOut';
  static const String checkInRecordedBy = 'checkInRecordedBy';
  static const String checkInRecordedAt = 'checkInRecordedAt';
  static const String checkOutRecordedBy = 'checkOutRecordedBy';
  static const String checkOutRecordedAt = 'checkOutRecordedAt';
  static const String updatedBy = 'updatedBy';
  static const String updatedAt = 'updatedAt';

  /// Append-only log of manual corrections; historical audit is never erased.
  static const String corrections = 'corrections';
}

/// Sequential id counters: `metadata/counters { student, worker }`.
abstract final class CounterDoc {
  static const String collection = 'metadata';
  static const String doc = 'counters';
  static const String studentField = 'student';
  static const String workerField = 'worker';
}

abstract final class UserFields {
  static const String uid = 'uid';
  static const String name = 'name';
  static const String email = 'email';
  static const String role = 'role';
  static const String phone = 'phone';
  static const String isActive = 'isActive';
  static const String studentIds = 'studentIds';
  static const String createdAt = 'createdAt';
  static const String createdBy = 'createdBy';
}
