import 'dart:async';

import 'package:attendance_management/core/enums/user_role.dart';
import 'package:attendance_management/core/errors/app_exception.dart';
import 'package:attendance_management/features/auth/domain/entities/app_user.dart';
import 'package:attendance_management/features/auth/domain/usecases/sign_in.dart';
import 'package:attendance_management/features/auth/domain/usecases/sign_out.dart';
import 'package:attendance_management/features/auth/domain/usecases/update_name.dart';
import 'package:attendance_management/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:attendance_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignIn extends Mock implements SignIn {}

class _MockSignOut extends Mock implements SignOut {}

class _MockUpdateName extends Mock implements UpdateName {}

class _MockWatchAuthState extends Mock implements WatchAuthState {}

const _user = AppUser(
  uid: 'u1',
  name: 'Sam Security',
  email: 'sam@inst.test',
  role: UserRole.security,
  isActive: true,
);

void main() {
  late _MockSignIn signIn;
  late _MockSignOut signOut;
  late _MockUpdateName updateName;
  late _MockWatchAuthState watchAuthState;
  late StreamController<AppUser?> stream;

  setUp(() {
    signIn = _MockSignIn();
    signOut = _MockSignOut();
    updateName = _MockUpdateName();
    watchAuthState = _MockWatchAuthState();
    stream = StreamController<AppUser?>.broadcast();
    when(watchAuthState.call).thenAnswer((_) => stream.stream);
  });

  tearDown(() => stream.close());

  AuthCubit build() => AuthCubit(
    watchAuthState: watchAuthState,
    signIn: signIn,
    signOut: signOut,
    updateName: updateName,
  );

  blocTest<AuthCubit, AuthState>(
    'emits authenticated when the auth stream yields a user',
    build: build,
    act: (_) => stream.add(_user),
    expect: () => [
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.authenticated)
          .having((s) => s.user, 'user', _user),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'emits unauthenticated when the auth stream yields null',
    build: build,
    act: (_) => stream.add(null),
    expect: () => [
      isA<AuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.unauthenticated,
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'surfaces a user-safe error message on bad credentials',
    build: build,
    setUp: () {
      when(
        () => signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Incorrect email or password.'));
    },
    act: (c) => c.signIn(email: 'x@y.z', password: 'bad'),
    expect: () => [
      isA<AuthState>().having((s) => s.isSubmitting, 'submitting', true),
      isA<AuthState>()
          .having((s) => s.isSubmitting, 'submitting', false)
          .having(
            (s) => s.errorMessage,
            'error',
            'Incorrect email or password.',
          ),
    ],
  );
}
