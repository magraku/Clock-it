import 'dart:async';

import 'package:clock_it/data/accounts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deletion waits for server data removal before deleting auth and cache',
      () async {
    final calls = <String>[];
    final acknowledged = Completer<void>();
    final accounts = FirebaseAccountService(
      auth: _Auth(_User(calls)),
      onDelete: (_) async {
        calls.add('delete document');
        await acknowledged.future;
      },
      afterDelete: () async => calls.add('flush'),
      onLogOut: () async => calls.add('clear and reload'),
    );
    final deletion = accounts.deleteAccount('password');
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['reauth', 'delete document']);
    acknowledged.complete();
    await deletion;
    expect(calls, [
      'reauth',
      'delete document',
      'delete auth',
      'flush',
      'clear and reload'
    ]);
  });

  test('failed document deletion preserves auth and does not clear cache',
      () async {
    final calls = <String>[];
    final accounts = FirebaseAccountService(
      auth: _Auth(_User(calls)),
      onDelete: (_) async =>
          throw TimeoutException('server did not acknowledge'),
      onLogOut: () async => calls.add('clear'),
    );
    await expectLater(
        accounts.deleteAccount('password'), throwsA(isA<TimeoutException>()));
    expect(calls, ['reauth']);
  });

  test('deletion with no signed-in user is a no-op', () async {
    final accounts = FirebaseAccountService(
      auth: _Auth(null),
      onDelete: (_) async => fail('no account to delete'),
      onLogOut: () async => fail('no cache cleanup without deletion'),
    );
    await accounts.deleteAccount('password');
  });
}

class _Auth implements FirebaseAuth {
  _Auth(this.currentUser);

  @override
  final User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  _User(this.calls);

  final List<String> calls;

  @override
  String get uid => 'test-user';

  @override
  String get email => 'test@example.com';

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    calls.add('reauth');
    return _Credential();
  }

  @override
  Future<void> delete() async => calls.add('delete auth');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
