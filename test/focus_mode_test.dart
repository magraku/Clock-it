import 'dart:convert';

import 'package:clock_it/data/focus_mode.dart';
import 'package:clock_it/models/goals.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

class RecordingFocusMode extends NoFocusMode {
  List<int> ends = [];
  @override
  Future<void> sync(List<int> endsAt) async {
    ends = endsAt;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('focus mode tracks all running timers, never paused or stopped ones', () async {
    var now = DateTime(2026, 11, 19, 12);
    final mode = RecordingFocusMode();
    final state = AppState(MemoryStore({}, 'u'), clock: () => now, focusMode: mode);
    await state.load();
    final other = state.createGoal('Study', GoalColor.pink, 20);
    state.startTimer('sfp', 10);
    final firstEnd = now.add(const Duration(minutes: 10)).millisecondsSinceEpoch;
    expect(mode.ends, [firstEnd]);
    state.startTimer(other.id, 15);
    expect(mode.ends, [firstEnd, now.add(const Duration(minutes: 15)).millisecondsSinceEpoch]);
    now = now.add(const Duration(minutes: 2));
    state.pauseTimer('sfp');
    expect(mode.ends, [state.timerOf(other.id)!.endsAt]);
    state.stopTimer(other.id);
    expect(mode.ends, isEmpty);
    state.resumeTimer('sfp');
    expect(mode.ends, [state.timerOf('sfp')!.endsAt]);
    now = now.add(const Duration(minutes: 10));
    state.refresh();
    expect(mode.ends, isEmpty);
    expect(state.timerOf('sfp'), isNull);
    state.dispose();
  });

  test('load restores mode; import, remote changes, deletion and sign-out reconcile it', () async {
    final now = DateTime(2026, 11, 19, 12);
    final mode = RecordingFocusMode();
    final store = MemoryStore({}, 'u');
    var state = AppState(store, clock: () => now, focusMode: mode);
    await state.load();
    final other = state.createGoal('Study', GoalColor.green, 20);
    state.startTimer(other.id, 15);
    state.dispose();
    expect(mode.ends, isEmpty);
    state = AppState(store, clock: () => now, focusMode: mode);
    await state.load();
    expect(mode.ends, isNotEmpty);
    state.deleteGoal(other.id);
    expect(mode.ends, isEmpty);
    state.startTimer('sfp', 10);
    final remote = UserData.starter()..updatedAt = now.millisecondsSinceEpoch + 1;
    store.remote.add(remote);
    await Future<void>.delayed(Duration.zero);
    expect(mode.ends, isEmpty);
    state.startTimer('sfp', 10);
    expect(state.importJson(jsonEncode(UserData.starter().toJson())), isTrue);
    expect(mode.ends, isEmpty);
    state.dispose();
  });

  test('Android bridge exposes permissions and synchronizes deadlines', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('clockit/focus');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      if (call.method == 'status') {
        return {'supported': true, 'enabled': true, 'granted': true, 'exact': false, 'active': false};
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    const mode = LocalFocusMode();
    expect((await mode.status()).ready, isFalse);
    await mode.requestAccess();
    await mode.setEnabled(true);
    await mode.sync([123, 456]);
    expect(calls.map((c) => c.method), ['status', 'requestAccess', 'enable', 'sync']);
    expect(calls.last.arguments, [123, 456]);
  });

  test('missing native support does not break the timer', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const mode = LocalFocusMode();
    expect((await mode.status()).supported, isFalse);
    await mode.sync([123]);
    await mode.setEnabled(true);
    await mode.requestAccess();
  });
}
