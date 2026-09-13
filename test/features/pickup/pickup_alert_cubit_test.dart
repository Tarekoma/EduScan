import 'dart:async';

import 'package:attendance_management/core/enums/pickup_status.dart';
import 'package:attendance_management/core/enums/user_role.dart';
import 'package:attendance_management/features/auth/domain/entities/app_user.dart';
import 'package:attendance_management/features/auth/domain/usecases/sign_in.dart';
import 'package:attendance_management/features/auth/domain/usecases/sign_out.dart';
import 'package:attendance_management/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:attendance_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:attendance_management/features/pickup/data/pickup_alert_player.dart';
import 'package:attendance_management/features/pickup/domain/entities/pickup_request.dart';
import 'package:attendance_management/features/pickup/domain/repositories/pickup_repository.dart';
import 'package:attendance_management/features/pickup/domain/usecases/pickup_usecases.dart';
import 'package:attendance_management/features/pickup/presentation/cubit/pickup_alert_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchAuth extends Mock implements WatchAuthState {}

class _CountingPlayer implements PickupAlertPlayer {
  int plays = 0;
  @override
  Future<void> playAlert() async => plays++;
  @override
  Future<void> dispose() async {}
}

class _FakePickupRepo implements PickupRepository {
  final controller = StreamController<List<PickupRequest>>.broadcast();
  @override
  Stream<List<PickupRequest>> watchActive() => controller.stream;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

PickupRequest _req(String id, PickupStatus status) => PickupRequest(
  requestId: id,
  studentId: 'STU_00001',
  parentId: 'p1',
  parentName: 'Parent',
  studentName: 'Child',
  status: status,
);

void main() {
  late _MockWatchAuth watchAuth;
  late StreamController<AppUser?> authStream;
  late AuthCubit authCubit;
  late _FakePickupRepo repo;
  late _CountingPlayer player;

  setUp(() {
    watchAuth = _MockWatchAuth();
    authStream = StreamController<AppUser?>.broadcast();
    when(watchAuth.call).thenAnswer((_) => authStream.stream);
    authCubit = AuthCubit(
      watchAuthState: watchAuth,
      signIn: _MockSignInStub(),
      signOut: _MockSignOutStub(),
    );
    repo = _FakePickupRepo();
    player = _CountingPlayer();
  });

  tearDown(() async {
    await authStream.close();
    await authCubit.close();
    await repo.controller.close();
  });

  Future<PickupAlertCubit> securityAlertCubit() async {
    authStream.add(
      const AppUser(
        uid: 's1',
        name: 'Security',
        email: 's@x.com',
        role: UserRole.security,
        isActive: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final cubit = PickupAlertCubit(
      authCubit: authCubit,
      watchActive: WatchActivePickupRequests(repo),
      player: player,
    );
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  test(
    'first snapshot primes silently — no sound for existing requests',
    () async {
      final cubit = await securityAlertCubit();
      repo.controller.add([_req('r1', PickupStatus.pending)]);
      await Future<void>.delayed(Duration.zero);
      expect(player.plays, 0);
      expect(cubit.state.pendingCount, 1);
      await cubit.close();
    },
  );

  test('sounds once for a genuinely new pending request', () async {
    final cubit = await securityAlertCubit();
    repo.controller.add([]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([_req('r1', PickupStatus.pending)]);
    await Future<void>.delayed(Duration.zero);
    expect(player.plays, 1);
    expect(cubit.state.unseen, 1);
    await cubit.close();
  });

  test('re-emitting the same request does not replay the sound', () async {
    final cubit = await securityAlertCubit();
    repo.controller.add([]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([_req('r1', PickupStatus.pending)]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([_req('r1', PickupStatus.pending)]);
    repo.controller.add([_req('r1', PickupStatus.pending)]);
    await Future<void>.delayed(Duration.zero);
    expect(player.plays, 1);
    await cubit.close();
  });

  test(
    'acknowledging (pending -> acknowledged) does not replay the sound',
    () async {
      final cubit = await securityAlertCubit();
      repo.controller.add([]);
      await Future<void>.delayed(Duration.zero);
      repo.controller.add([_req('r1', PickupStatus.pending)]);
      await Future<void>.delayed(Duration.zero);
      repo.controller.add([_req('r1', PickupStatus.acknowledged)]);
      await Future<void>.delayed(Duration.zero);
      expect(player.plays, 1);
      await cubit.close();
    },
  );

  test('a second distinct request sounds again', () async {
    final cubit = await securityAlertCubit();
    repo.controller.add([]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([_req('r1', PickupStatus.pending)]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([
      _req('r1', PickupStatus.acknowledged),
      _req('r2', PickupStatus.pending),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(player.plays, 2);
    await cubit.close();
  });
}

class _MockSignInStub implements SignIn {
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _MockSignOutStub implements SignOut {
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
