import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/enums/person_type.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/utils/person_id.dart';
import '../../attendance/data/models/attendance_record_model.dart';
import '../../attendance/domain/entities/attendance_record.dart';
import '../../attendance/domain/repositories/attendance_repository.dart';
import '../../students/data/models/student_model.dart';
import '../../students/domain/repositories/student_repository.dart';
import '../../user_management/domain/usecases/user_admin_usecases.dart';
import '../../workers/data/models/worker_model.dart';
import '../../workers/domain/repositories/worker_repository.dart';
import '../domain/excel_rows.dart';
import '../domain/repositories/excel_repository.dart';
import 'excel_codec.dart';

/// Chunk size for a Firestore [WriteBatch] (hard limit is 500 operations).
const int _batchLimit = 450;

class ExcelRepositoryImpl implements ExcelRepository {
  ExcelRepositoryImpl({
    required ExcelCodec codec,
    required AttendanceRepository attendance,
    required StudentRepository students,
    required WorkerRepository workers,
    required WatchUsersByRole watchUsersByRole,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _codec = codec,
       _attendance = attendance,
       _students = students,
       _workers = workers,
       _watchSecurity = watchUsersByRole,
       _firestore = firestore,
       _auth = auth;

  final ExcelCodec _codec;
  final AttendanceRepository _attendance;
  final StudentRepository _students;
  final WorkerRepository _workers;
  final WatchUsersByRole _watchSecurity;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<SpreadsheetFile> exportAttendance({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await _attendance.getInRange(
      fromDate: DateKey.of(from),
      toDate: DateKey.of(to),
    );
    final students = await _students.watchStudents().first;
    final workers = await _workers.watchWorkers().first;
    final security = await _watchSecurity(UserRole.security).first;

    final names = <String, String>{
      for (final s in students) s.studentId: s.fullName,
      for (final w in workers) w.workerId: w.fullName,
    };
    final recorders = {for (final u in security) u.uid: u.name};

    String recorder(AttendanceRecord r) {
      final uid = r.checkOutRecordedBy ?? r.checkInRecordedBy ?? r.updatedBy;
      return uid == null ? '' : (recorders[uid] ?? uid);
    }

    final rows = records
        .map(
          (r) => AttendanceExportRow(
            date: r.date,
            personId: r.personId,
            name: names[r.personId] ?? r.personId,
            personType: r.personType,
            checkIn: r.checkIn,
            checkOut: r.checkOut,
            recordedBy: recorder(r),
            recordedAt: r.checkInRecordedAt ?? r.updatedAt,
          ),
        )
        .toList();

    final bytes = _codec.buildAttendanceWorkbook(rows);
    final stamp = DateFormat('yyyyMMdd').format(from);
    final stamp2 = DateFormat('yyyyMMdd').format(to);
    return SpreadsheetFile(bytes, 'attendance_${stamp}_$stamp2.xlsx');
  }

  @override
  ParsedSheet<StudentImportRow> parseStudents(Uint8List bytes) =>
      _codec.parseStudents(bytes);

  @override
  ParsedSheet<WorkerImportRow> parseWorkers(Uint8List bytes) =>
      _codec.parseWorkers(bytes);

  @override
  ParsedSheet<AttendanceImportRow> parseAttendance(Uint8List bytes) =>
      _codec.parseAttendance(bytes);

  String get _managerUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw AuthException(appStrings.errorPleaseSignInAgain);
    return uid;
  }

  /// Creates students in bulk with sequential ids. A single transaction reserves
  /// the id range on `metadata/counters`; the documents are then written in
  /// [WriteBatch] chunks.
  @override
  Future<ImportOutcome> importStudents(List<StudentImportRow> rows) async {
    if (rows.isEmpty) return const ImportOutcome(count: 0);
    try {
      final counterRef = _firestore
          .collection(CounterDoc.collection)
          .doc(CounterDoc.doc);
      final studentsCol = _firestore.collection(FirestoreCollections.students);

      final startAfter = await _firestore.runTransaction<int>((tx) async {
        final snap = await tx.get(counterRef);
        final current = (snap.data()?[CounterDoc.studentField] as int?) ?? 0;
        tx.set(counterRef, {
          CounterDoc.studentField: current + rows.length,
        }, SetOptions(merge: true));
        return current;
      });

      final ids = <String>[];
      for (var i = 0; i < rows.length; i += _batchLimit) {
        final batch = _firestore.batch();
        final slice = rows.skip(i).take(_batchLimit).toList();
        for (var j = 0; j < slice.length; j++) {
          final id = PersonId.format(PersonType.student, startAfter + i + j + 1);
          ids.add(id);
          batch.set(
            studentsCol.doc(id),
            StudentModel.newData(
              studentId: id,
              fullName: slice[j].fullName,
              className: slice[j].className,
            ),
          );
        }
        await batch.commit();
      }
      return ImportOutcome(count: ids.length, ids: ids);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Creates workers in bulk with sequential ids. A single transaction reserves
  /// the id range on `metadata/counters`; the documents are then written in
  /// [WriteBatch] chunks.
  @override
  Future<ImportOutcome> importWorkers(List<WorkerImportRow> rows) async {
    if (rows.isEmpty) return const ImportOutcome(count: 0);
    try {
      final counterRef = _firestore
          .collection(CounterDoc.collection)
          .doc(CounterDoc.doc);
      final workersCol = _firestore.collection(FirestoreCollections.workers);

      final startAfter = await _firestore.runTransaction<int>((tx) async {
        final snap = await tx.get(counterRef);
        final current = (snap.data()?[CounterDoc.workerField] as int?) ?? 0;
        tx.set(counterRef, {
          CounterDoc.workerField: current + rows.length,
        }, SetOptions(merge: true));
        return current;
      });

      final ids = <String>[];
      for (var i = 0; i < rows.length; i += _batchLimit) {
        final batch = _firestore.batch();
        final slice = rows.skip(i).take(_batchLimit).toList();
        for (var j = 0; j < slice.length; j++) {
          final id = PersonId.format(PersonType.worker, startAfter + i + j + 1);
          ids.add(id);
          batch.set(
            workersCol.doc(id),
            WorkerModel.newData(
              workerId: id,
              fullName: slice[j].fullName,
              jobTitle: slice[j].jobTitle,
            ),
          );
        }
        await batch.commit();
      }
      return ImportOutcome(count: ids.length, ids: ids);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Imports historical attendance rows with explicit check-in / check-out
  /// times, written in [WriteBatch] chunks. Requires a manager session
  /// (Security Rules allow manager writes to `attendance` for migration).
  @override
  Future<ImportOutcome> importAttendance(List<AttendanceImportRow> rows) async {
    if (rows.isEmpty) return const ImportOutcome(count: 0);
    try {
      final by = _managerUid;
      final col = _firestore.collection(FirestoreCollections.attendance);
      var written = 0;

      for (var i = 0; i < rows.length; i += _batchLimit) {
        final batch = _firestore.batch();
        for (final row in rows.skip(i).take(_batchLimit)) {
          final personId = row.personId.trim().toUpperCase();
          final checkIn = _timestampOrNull(row.date, row.checkIn);
          final checkOut = _timestampOrNull(row.date, row.checkOut);
          if (checkIn == null && checkOut != null) {
            throw ValidationException(
              appStrings.excelCheckoutWithoutCheckin(personId, row.date),
            );
          }

          final data = <String, dynamic>{
            AttendanceFields.personId: personId,
            AttendanceFields.personType: row.personType.value,
            AttendanceFields.date: row.date,
            AttendanceFields.updatedBy: by,
            AttendanceFields.updatedAt: FieldValue.serverTimestamp(),
          };
          if (checkIn != null) {
            data[AttendanceFields.checkIn] = checkIn;
            data[AttendanceFields.checkInRecordedBy] = by;
            data[AttendanceFields.checkInRecordedAt] = checkIn;
          }
          if (checkOut != null) {
            data[AttendanceFields.checkOut] = checkOut;
            data[AttendanceFields.checkOutRecordedBy] = by;
            data[AttendanceFields.checkOutRecordedAt] = checkOut;
          }

          final id = AttendanceRecordModel.buildId(
            personId: personId,
            personType: row.personType,
            date: row.date,
          );
          batch.set(col.doc(id), data, SetOptions(merge: true));
          written++;
        }
        await batch.commit();
      }
      return ImportOutcome(count: written);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Parses `HH:mm` on [dateKey] (`yyyy-MM-dd`) into a [Timestamp], or null when
  /// the time is blank.
  Timestamp? _timestampOrNull(String dateKey, String? hhmm) {
    if (hhmm == null || hhmm.trim().isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm.trim());
    if (m == null) {
      throw ValidationException(appStrings.excelBadTime(hhmm));
    }
    final parsed = DateTime.tryParse(
      '${dateKey}T${m.group(1)!.padLeft(2, '0')}:${m.group(2)}:00',
    );
    if (parsed == null) {
      throw ValidationException(appStrings.excelBadDateTime(dateKey, hhmm));
    }
    return Timestamp.fromDate(parsed);
  }
}
