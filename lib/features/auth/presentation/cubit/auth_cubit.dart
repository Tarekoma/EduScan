import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/watch_auth_state.dart';

part 'auth_state.dart';

/// Owns the app-wide authentication state. Created once, above the router.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required WatchAuthState watchAuthState,
    required SignIn signIn,
    required SignOut signOut,
  }) : _watchAuthState = watchAuthState,
       _signIn = signIn,
       _signOut = signOut,
       super(const AuthState()) {
    _subscription = _watchAuthState().listen(
      _onUserChanged,
      onError: (_) => _onUserChanged(null),
    );
  }

  final WatchAuthState _watchAuthState;
  final SignIn _signIn;
  final SignOut _signOut;
  late final StreamSubscription<AppUser?> _subscription;

  void _onUserChanged(AppUser? user) {
    if (user == null) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          clearError: true,
        ),
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _signIn(email: email, password: password);
      // Success: the auth stream drives the transition to `authenticated`.
    } catch (e, s) {
      // ignore: avoid_print
      print('SIGN-IN ERROR: $e\n$s');
      final failure = ErrorMapper.map(e, s);
      emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
    }
  }

  Future<void> signOut() => _signOut();

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
