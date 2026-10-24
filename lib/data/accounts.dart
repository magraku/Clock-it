import 'package:firebase_auth/firebase_auth.dart';

import '../ui/strings.dart';

class Account {
  const Account({required this.uid, required this.email});

  final String uid;
  final String email;
}

/// A sign-in problem the user can act on; [message] is ready to show.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Who is using the app. Each account keeps its own hours.
abstract class AccountService {
  /// The account remembered from the last launch, if any.
  Future<Account?> restore();
  Future<Account> logIn(String email, String password);
  Future<Account> signUp(String email, String password);

  /// Returns the message to show the person.
  Future<String> sendPasswordReset(String email);
  Future<void> logOut();

  /// Asks for the password again, as a deleted account can't be undone.
  Future<void> deleteAccount(String password);
}

class FirebaseAccountService implements AccountService {
  FirebaseAccountService({FirebaseAuth? auth, this.onDelete}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Removes the account's data before the account itself is deleted.
  final Future<void> Function(Account)? onDelete;

  static Account _account(User u) => Account(uid: u.uid, email: u.email ?? '');

  @override
  Future<Account?> restore() async {
    final user = await _auth.authStateChanges().first;
    return user == null ? null : _account(user);
  }

  @override
  Future<Account> logIn(String email, String password) => _guard(() async {
        final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
        return _account(cred.user!);
      });

  @override
  Future<Account> signUp(String email, String password) => _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        return _account(cred.user!);
      });

  @override
  Future<String> sendPasswordReset(String email) => _guard(() async {
        await _auth.sendPasswordResetEmail(email: email.trim());
        return Str.resetSent;
      });

  @override
  Future<void> logOut() => _auth.signOut();

  @override
  Future<void> deleteAccount(String password) => _guard(() async {
        final user = _auth.currentUser;
        if (user == null) return;
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
        await onDelete?.call(_account(user));
        await user.delete();
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  static String _message(String code) => switch (code) {
        'invalid-email' => Str.authInvalidEmail,
        'user-not-found' || 'wrong-password' || 'invalid-credential' || 'INVALID_LOGIN_CREDENTIALS' =>
          Str.authWrongCredentials,
        'email-already-in-use' => Str.authEmailInUse,
        'weak-password' => Str.authWeakPassword,
        'user-disabled' => Str.authDisabled,
        'too-many-requests' => Str.authTooMany,
        'network-request-failed' => Str.authOffline,
        _ => Str.authGeneric,
      };
}
