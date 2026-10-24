import 'package:shared_preferences/shared_preferences.dart';

import '../ui/strings.dart';
import 'accounts.dart';

/// Accounts kept in this browser, for reviewing the design on the web
/// without Firebase. Any password is accepted and none is stored: this only
/// keeps each test account's hours apart, it doesn't protect them.
class DemoAccountService implements AccountService {
  static const _emailsKey = 'clockit-demo-accounts';
  static const _currentKey = 'clockit-demo-current';

  static Account _account(String email) => Account(uid: 'demo-$email', email: email);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<Account?> restore() async {
    final email = (await _prefs).getString(_currentKey);
    return email == null ? null : _account(email);
  }

  @override
  Future<Account> logIn(String email, String password) async {
    final e = _check(email, password);
    final prefs = await _prefs;
    if (!(prefs.getStringList(_emailsKey) ?? const []).contains(e)) {
      throw AuthFailure(Str.authWrongCredentials);
    }
    await prefs.setString(_currentKey, e);
    return _account(e);
  }

  @override
  Future<Account> signUp(String email, String password) async {
    final e = _check(email, password);
    final prefs = await _prefs;
    final emails = prefs.getStringList(_emailsKey) ?? [];
    if (emails.contains(e)) throw AuthFailure(Str.authEmailInUse);
    await prefs.setStringList(_emailsKey, [...emails, e]);
    await prefs.setString(_currentKey, e);
    return _account(e);
  }

  @override
  Future<String> sendPasswordReset(String email) async => Str.demoReset;

  @override
  Future<void> logOut() async => (await _prefs).remove(_currentKey);

  @override
  Future<void> deleteAccount(String password) async {
    final prefs = await _prefs;
    final email = prefs.getString(_currentKey);
    if (email == null) return;
    await prefs.setStringList(
      _emailsKey,
      [...?prefs.getStringList(_emailsKey)]..remove(email),
    );
    await prefs.remove(demoHoursKey(_account(email)));
    await prefs.remove(_currentKey);
  }

  /// Where [account]'s hours are kept (see `LocalHoursStore`).
  static String demoHoursKey(Account account) => 'clockit-demo-hours-${account.uid}';

  static String _check(String email, String password) {
    final e = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) throw AuthFailure(Str.authInvalidEmail);
    if (password.length < 6) throw AuthFailure(Str.authWeakPassword);
    return e;
  }
}
