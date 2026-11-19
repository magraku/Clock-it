import 'dart:async';

import 'package:clock_it/data/accounts.dart';
import 'package:clock_it/data/web_cache_cleanup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mode in ['complete', 'error', 'pending']) {
    test('clears cache before reloading when writes are $mode', () async {
      final calls = <String>[];
      final accounts = FirebaseAccountService(
        auth: _Auth(calls),
        beforeLogOut: () => flushWebWrites(
          waitForPendingWrites: () async {
            calls.add('wait');
            if (mode == 'error') throw StateError('offline');
            if (mode == 'pending') await Completer<void>().future;
          },
          timeout: const Duration(milliseconds: 1),
        ),
        onLogOut: () => clearWebCache(
          terminate: () async => calls.add('terminate'),
          clearPersistence: () async => calls.add('clear'),
          reload: () => calls.add('reload'),
        ),
      );
      await accounts.logOut();
      expect(calls, ['wait', 'signOut', 'terminate', 'clear', 'reload']);
    });
  }

  test('does not reload as if cleanup succeeded when clearing fails', () async {
    var reloaded = false;
    await expectLater(
        clearWebCache(
          terminate: () async {},
          clearPersistence: () async =>
              throw StateError('another tab holds cache'),
          reload: () => reloaded = true,
        ),
        throwsStateError);
    expect(reloaded, isFalse);
  });
}

class _Auth implements FirebaseAuth {
  _Auth(this.calls);

  final List<String> calls;

  @override
  Future<void> signOut() async => calls.add('signOut');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
