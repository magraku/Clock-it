import 'dart:async';

import 'package:clock_it/data/accounts.dart';
import 'package:clock_it/data/hours_store.dart';
import 'package:clock_it/models/hours_data.dart';
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
    if (u == null || u.password != password) throw const AuthFailure(Str.authWrongCredentials);
    return current = Account(uid: u.uid, email: email.trim());
  }

  @override
  Future<Account> signUp(String email, String password) async {
    if (!email.contains('@')) throw const AuthFailure(Str.authInvalidEmail);
    if (_users.containsKey(email.trim())) throw const AuthFailure(Str.authEmailInUse);
    if (password.length < 6) throw const AuthFailure(Str.authWeakPassword);
    _users[email.trim()] = (uid: 'uid-${_users.length}', password: password);
    return logIn(email, password);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> logOut() async => current = null;

  @override
  Future<void> deleteAccount(String password) async {
    final email = current!.email;
    if (_users[email]!.password != password) throw const AuthFailure(Str.authWrongCredentials);
    _users.remove(email);
    current = null;
  }
}

/// A "cloud" document per account, held in memory.
class MemoryStore extends HoursStore {
  MemoryStore(this.cloud, this.uid);

  final Map<String, Map<String, dynamic>> cloud;
  final String uid;
  final remote = StreamController<HoursData>.broadcast();

  @override
  Future<HoursData?> load() async => cloud[uid] == null ? null : HoursData.fromJson(cloud[uid]!);

  @override
  Future<void> save(HoursData data) async => cloud[uid] = data.toJson();

  @override
  Stream<HoursData> changes() => remote.stream;
}

Services fakeServices(FakeAccounts accounts, Map<String, Map<String, dynamic>> cloud) => Services(
      accounts: accounts,
      storeFor: (a) => MemoryStore(cloud, a.uid),
      legacy: LocalHoursStore(),
    );
