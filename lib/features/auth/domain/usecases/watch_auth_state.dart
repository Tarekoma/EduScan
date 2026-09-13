import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Streams the current authenticated user (or `null`).
class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.watchCurrentUser();
}
