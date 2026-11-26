import 'package:clock_it/models/goals.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('timer ticks and remote snapshots do not enqueue repeated writes',
      (tester) async {
    final store = _CountingStore();
    final state = AppState(store, clock: () => DateTime(2026, 11, 19, 10));
    await state.load();
    expect(store.saves, 0);
    expect(store.listeners, 1);

    state.startTimer('sfp', 15);
    expect(store.saves, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(store.saves, 1);

    store.remote.add(UserData.starter()
      ..updatedAt = DateTime(2026, 11, 19, 11).millisecondsSinceEpoch);
    await tester.pump();
    expect(store.saves, 1);
    expect(store.listeners, 1);

    state.refresh();
    expect(store.saves, 1);
    state.dispose();
    await store.remote.close();
  });
}

class _CountingStore extends MemoryStore {
  _CountingStore() : super({}, 'test-user');

  int saves = 0;
  int listeners = 0;

  @override
  Future<void> save(UserData data) {
    saves++;
    return super.save(data);
  }

  @override
  Stream<UserData> changes() {
    listeners++;
    return super.changes();
  }
}
