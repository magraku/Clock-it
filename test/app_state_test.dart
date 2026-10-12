import 'dart:convert';

import 'package:clock_it/models/hours_data.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  test('keeps whichever copy was saved last', () async {
    final store = MemoryStore({}, 'u');
    final state = AppState(store, clock: () => DateTime(2026, 10, 12, 10));
    await state.load();
    state.setGoal(120); // saved at 10:00

    store.remote.add(HoursData(goalHours: 100, updatedAt: 1)); // older: ignored
    await Future<void>.delayed(Duration.zero);
    expect(state.data.goalHours, 120);

    store.remote.add(HoursData(goalHours: 90, updatedAt: DateTime(2026, 10, 12, 11).millisecondsSinceEpoch));
    await Future<void>.delayed(Duration.zero);
    expect(state.data.goalHours, 90);
    state.dispose();
  });

  test('a new account takes over the hours saved on this phone, only once', () async {
    const old = {'days': {'2026-10-01': {'m': 300, 's': []}}, 'open': null, 'ts': 5, 'goal': 140};
    SharedPreferences.setMockInitialValues({'sfp-v1': jsonEncode(old)});
    final accounts = FakeAccounts();
    final cloud = <String, Map<String, dynamic>>{};
    final services = fakeServices(accounts, cloud);

    final ana = await services.open(await accounts.signUp('ana@mail.com', 'secret1'), isNew: true);
    expect(ana.data.days['2026-10-01']!.manualMinutes, 300);
    expect(cloud['uid-0'], isNotNull);

    final bea = await services.open(await accounts.signUp('bea@mail.com', 'secret2'), isNew: true);
    expect(bea.data.days, isEmpty);
    ana.dispose();
    bea.dispose();
  });
}
