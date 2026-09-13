import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../errors/error_mapper.dart';

/// Creates Firebase Auth accounts for other people without disturbing the
/// signed-in manager's session.
///
/// `createUserWithEmailAndPassword` signs the *current* app in as the new user.
/// To avoid logging the manager out, provisioning runs on a throwaway secondary
/// [FirebaseApp]: the account is created there, that app signs out and is
/// deleted, and the manager's session on the default app is untouched.
///
/// The Admin-SDK abilities the old Cloud Functions had (disabling or deleting
/// another user's Auth record) are not available to a client. Deactivation is
/// therefore a Firestore `isActive: false` flag only — which Security Rules
/// already treat as "no privileges" — and deleting an account removes its
/// `users/{uid}` profile but leaves the orphaned Auth record for a manager to
/// clear from the Firebase console.
class UserProvisioner {
  /// Creates an Auth account and returns its uid. Throws an [AppException]
  /// (e.g. `email-already-in-use`, `weak-password`) via [ErrorMapper].
  Future<String> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final app = await Firebase.initializeApp(
      name: 'provisioner-${DateTime.now().microsecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final auth = FirebaseAuth.instanceFor(app: app);
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(displayName);
      final uid = user.uid;
      await auth.signOut();
      return uid;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    } finally {
      await app.delete();
    }
  }
}
