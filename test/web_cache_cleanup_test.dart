import 'dart:async';

import 'package:clock_it/data/web_cache_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mode in ['complete', 'error', 'pending']) {
    test('clears cache before reloading when writes are $mode', () async {
      final calls = <String>[];
      await clearWebCache(
        waitForPendingWrites: () async {
          calls.add('wait');
          if (mode == 'error') throw StateError('offline');
          if (mode == 'pending') await Completer<void>().future;
        },
        terminate: () async => calls.add('terminate'),
        clearPersistence: () async => calls.add('clear'),
        reload: () => calls.add('reload'),
        timeout: const Duration(milliseconds: 1),
      );
      expect(calls, ['wait', 'terminate', 'clear', 'reload']);
    });
  }

  test('does not reload as if cleanup succeeded when clearing fails', () async {
    var reloaded = false;
    await expectLater(
        clearWebCache(
          waitForPendingWrites: () async {},
          terminate: () async {},
          clearPersistence: () async =>
              throw StateError('another tab holds cache'),
          reload: () => reloaded = true,
        ),
        throwsStateError);
    expect(reloaded, isFalse);
  });
}
