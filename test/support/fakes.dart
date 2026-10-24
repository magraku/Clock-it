import 'dart:async';

import 'package:clock_it/data/accounts.dart';
import 'package:clock_it/data/hours_store.dart';
import 'package:clock_it/models/goals.dart';
import 'package:clock_it/state/session.dart';
import 'package:clock_it/ui/strings.dart';

/// Accounts kept in memory, with the same rules as Firebase.
class FakeAccounts implements AccountService {
  final _users = <String, ({String uid, String password})>{};
  Account? current;

  @override
  Future<Account?> restore() async => current;

  @override
  Future<Account> logIn(String email, String password) async {
    final u = _users[email.trim()];
    if (u == null || u.password != password) throw AuthFailure(Str.authWrongCredentials);
    return current = Account(uid: u.uid, email: email.trim());
  }

  @override
  Future<Account> signUp(String email, String password) async {
    if (!email.contains('@')) throw AuthFailure(Str.authInvalidEmail);
    if (_users.containsKey(email.trim())) throw AuthFailure(Str.authEmailInUse);
    if (password.length < 6) throw AuthFailure(Str.authWeakPassword);
    _users[email.trim()] = (uid: 'uid-${_users.length}', password: password);
    return logIn(email, password);
  }

  @override
  Future<String> sendPasswordReset(String email) async => Str.resetSent;

  @override
  Future<void> logOut() async => current = null;

  @override
  Future<void> deleteAccount(String password) async {
    final email = current!.email;
    if (_users[email]!.password != password) throw AuthFailure(Str.authWrongCredentials);
    _users.remove(email);
    current = null;
  }
}

/// A "cloud" document per account, held in memory.
class MemoryStore extends HoursStore {
  MemoryStore(this.cloud, this.uid);

  final Map<String, Map<String, dynamic>> cloud;
  final String uid;
  final remote = StreamController<UserData>.broadcast();

  @override
  Future<UserData?> load() async => cloud[uid] == null ? null : UserData.fromJson(cloud[uid]!);

  @override
  Future<void> save(UserData data) async => cloud[uid] = data.toJson();

  @override
  Stream<UserData> changes() => remote.stream;
}

Services fakeServices(FakeAccounts accounts, Map<String, Map<String, dynamic>> cloud) => Services(
      accounts: accounts,
      storeFor: (a) => MemoryStore(cloud, a.uid),
      legacy: LocalHoursStore(),
    );
