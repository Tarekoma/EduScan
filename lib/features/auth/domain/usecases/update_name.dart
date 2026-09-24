import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

/// Updates the signed-in user's own display name.
class UpdateName {
  const UpdateName(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String uid, required String name}) {
    final error = Validators.required(
      name,
      message: appStrings.validatorRequired(appStrings.fieldName),
    );
    if (error != null) throw ValidationException(error);
    return _repository.updateName(uid: uid, name: name.trim());
  }
}
