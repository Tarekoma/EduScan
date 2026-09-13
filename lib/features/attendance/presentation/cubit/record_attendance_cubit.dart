import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../qr/domain/entities/resolved_person.dart';
import '../../../qr/domain/usecases/resolve_person.dart';
import '../../domain/attendance_rules.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/attendance_usecases.dart';

part 'record_attendance_state.dart';

/// Drives a single check-in / check-out submission for the security user.
/// Both entry points (manual id, QR scan) resolve the person against
/// Firestore before writing anything — Rule 4: an attendance record may only
/// exist for a real student/worker.
class RecordAttendanceCubit extends Cubit<RecordAttendanceState> {
  RecordAttendanceCubit({
    required AuthCubit authCubit,
    required GetTodayRecord getTodayRecord,
    required CheckInUseCase checkIn,
    required CheckOutUseCase checkOut,
    required ResolvePerson resolvePerson,
  }) : _authCubit = authCubit,
       _getTodayRecord = getTodayRecord,
       _checkIn = checkIn,
       _checkOut = checkOut,
       _resolvePerson = resolvePerson,
       super(const RecordAttendanceState());

  final AuthCubit _authCubit;
  final GetTodayRecord _getTodayRecord;
  final CheckInUseCase _checkIn;
  final CheckOutUseCase _checkOut;
  final ResolvePerson _resolvePerson;

  AttendanceActor? _actor() {
    final user = _authCubit.state.user;
    if (user == null) return null;
    return AttendanceActor(uid: user.uid, canRecord: user.canRecordAttendance);
  }

  /// Records attendance for a manually-typed id. [personId] is resolved
  /// against the students/workers collections first (Rule 4) — the same
  /// check the QR flow does — so a well-formatted but non-existent id (or one
  /// that's since been deleted) is rejected instead of silently creating an
  /// attendance record for nobody. When [action] is null the correct action
  /// is derived from the person's current day state (scan-and-toggle).
  Future<void> submit({
    required String personId,
    AttendanceAction? action,
  }) async {
    final actor = _actor();
    if (actor == null || !actor.canRecord) {
      emit(state.failure('Only security may record attendance.'));
      return;
    }

    emit(const RecordAttendanceState(status: RecordStatus.submitting));
    try {
      final person = await _resolvePerson(personId);
      await _recordFor(person: person, actor: actor, action: action);
    } on AppException catch (e) {
      emit(state.failure(e.message));
    } catch (e, s) {
      emit(state.failure(ErrorMapper.map(e, s).message));
    }
  }

  /// Resolves a scanned QR payload to a person (Rule 4), then records
  /// attendance for them. [scanKey] deduplicates rapid repeat detections of the
  /// same code from the camera stream.
  Future<void> submitScanned(
    String rawPayload, {
    AttendanceAction? action,
    String? scanKey,
  }) async {
    if (state.status == RecordStatus.submitting) return;
    if (scanKey != null && scanKey == _lastScanKey) return;
    _lastScanKey = scanKey;

    final actor = _actor();
    if (actor == null || !actor.canRecord) {
      emit(state.failure('Only security may record attendance.'));
      return;
    }

    emit(const RecordAttendanceState(status: RecordStatus.submitting));
    try {
      final person = await _resolvePerson(rawPayload);
      await _recordFor(person: person, actor: actor, action: action);
    } on AppException catch (e) {
      emit(state.failure(e.message));
    } catch (e, s) {
      emit(state.failure(ErrorMapper.map(e, s).message));
    }
  }

  /// Shared by [submit] and [submitScanned] once the person is known to
  /// exist: checks today's state (Rules 1–3) and applies the check-in/out.
  Future<void> _recordFor({
    required ResolvedPerson person,
    required AttendanceActor actor,
    AttendanceAction? action,
  }) async {
    final current = await _getTodayRecord(
      personId: person.personId,
      personType: person.personType,
    );
    final effective = action ?? AttendanceRules.nextAction(current);
    final record = switch (effective) {
      AttendanceAction.checkIn => await _checkIn(
        personId: person.personId,
        personType: person.personType,
        actor: actor,
      ),
      AttendanceAction.checkOut => await _checkOut(
        personId: person.personId,
        personType: person.personType,
        actor: actor,
      ),
    };
    emit(
      RecordAttendanceState(
        status: RecordStatus.success,
        record: record,
        action: effective,
      ),
    );
  }

  String? _lastScanKey;

  void reset() {
    _lastScanKey = null;
    emit(const RecordAttendanceState());
  }
}
