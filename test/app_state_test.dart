import 'dart:convert';

import 'package:clock_it/data/timer_alerts.dart';
import 'package:clock_it/models/goals.dart';
import 'package:clock_it/models/hours_data.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

/// A clock the test moves by hand.
class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

class RecordingAlerts implements TimerAlerts {
  final scheduled = <String, DateTime>{};

  @override
  Future<void> schedule(String goalId, DateTime at, String title, String body) async => scheduled[goalId] = at;

  final live = <String, LiveTimer>{};

  @override
  Future<void> showRunning(LiveTimer timer) async => live[timer.goalId] = timer;

  @override
  Future<void> cancel(String goalId) async {
    scheduled.remove(goalId);
    live.remove(goalId);
  }
}

void main() {
  late FakeClock clock;
  late MemoryStore store;
  late RecordingAlerts alerts;
  late AppState state;

  setUp(() async {
    clock = FakeClock(DateTime(2026, 10, 12, 10));
    store = MemoryStore({}, 'u');
    alerts = RecordingAlerts();
    state = AppState(store, clock: clock.call, alerts: alerts);
    await state.load();
  });

  tearDown(() => state.dispose());

  test('a new account starts with SFP on Home', () {
    expect(state.goals.single.name, 'SFP');
    expect(state.home.hours.goalHours, 140);
  });

  test('the chosen wallpaper is saved with the account; unknown ones fall back', () {
    expect(state.wallpaper, WallpaperStyle.photo);
    state.setWallpaper(WallpaperStyle.dusk);
    final saved = UserData.fromJson(jsonDecode(jsonEncode(state.data.toJson())) as Map<String, dynamic>);
    expect(saved.wallpaper, WallpaperStyle.dusk);
    expect(UserData.fromJson({...state.data.toJson(), 'wall': 'neon'}).wallpaper, WallpaperStyle.photo);
  });

  test('keeps whichever copy was saved last', () async {
    state.setGoalHours('sfp', 120); // saved at 10:00

    final older = UserData.starter(sfp: HoursData(goalHours: 100))..updatedAt = 1;
    store.remote.add(older);
    await Future<void>.delayed(Duration.zero);
    expect(state.home.hours.goalHours, 120);

    final newer = UserData.starter(sfp: HoursData(goalHours: 90))
      ..updatedAt = DateTime(2026, 10, 12, 11).millisecondsSinceEpoch;
    store.remote.add(newer);
    await Future<void>.delayed(Duration.zero);
    expect(state.home.hours.goalHours, 90);
  });

  test('each goal keeps its own hours; Home can move and the last goal stays', () {
    final study = state.createGoal('Study hours', GoalColor.green, 30);
    state.punch(study.id);
    clock.advance(const Duration(hours: 2));
    state.punch(study.id);

    expect(state.minutesSince(study.id, clock.now), 120);
    expect(state.minutesSince('sfp', clock.now), 0);
    expect(state.home.id, 'sfp');

    state.updateGoal(study.id, makeHome: true);
    expect(state.home.id, study.id);

    expect(state.deleteGoal(study.id), isTrue);
    expect(state.home.id, 'sfp'); // Home moves to what's left
    expect(state.deleteGoal('sfp'), isFalse);
    expect(state.goals, hasLength(1));
  });

  test('a timer logs its focus time when it ends, alerts once, and can pause', () {
    state.startTimer('sfp', 15);
    expect(alerts.scheduled['sfp'], clock.now.add(const Duration(minutes: 15)));
    expect(alerts.live['sfp']!.start, clock.now); // on the lock screen too
    expect(alerts.live['sfp']!.end, clock.now.add(const Duration(minutes: 15)));

    clock.advance(const Duration(minutes: 5));
    state.pauseTimer('sfp');
    expect(alerts.scheduled, isEmpty);
    expect(alerts.live, isEmpty);
    expect(state.minutesSince('sfp', clock.now), 5);

    clock.advance(const Duration(hours: 1)); // paused: nothing counts
    state.resumeTimer('sfp');
    expect(state.timerOf('sfp')!.remainingMs(clock.now.millisecondsSinceEpoch), 10 * 60000);
    // The sand picks up where it stopped: a third has fallen.
    expect(alerts.live['sfp']!.start, clock.now.subtract(const Duration(minutes: 5)));

    // The app was closed past the end: it settles on return, logging only up to the end.
    clock.advance(const Duration(hours: 3));
    state.refresh();
    expect(state.timerOf('sfp'), isNull);
    expect(state.minutesSince('sfp', DateTime(2026, 10, 12)), 15);
    expect(state.home.hours.days['2026-10-12']!.sessions, hasLength(2));
  });

  test('stopping early keeps the time so far', () {
    state.startTimer('sfp', 30);
    clock.advance(const Duration(minutes: 12));
    state.stopTimer('sfp');
    expect(state.timerOf('sfp'), isNull);
    expect(state.minutesSince('sfp', clock.now), 12);
  });

  test('old single-tracker data and web backups become the SFP goal', () {
    const web = '{"days":{"2026-10-01":{"m":300,"s":[]}},"open":null,"ts":5,"goal":120}';
    final data = UserData.fromJson(jsonDecode(web) as Map<String, dynamic>);
    expect(data.home.name, 'SFP');
    expect(data.home.hours.goalHours, 120);
    expect(data.updatedAt, 5);

    final study = state.createGoal('Study', GoalColor.pink, 10);
    expect(state.importJson(web), isTrue); // only Home's hours change
    expect(state.home.hours.days['2026-10-01']!.manualMinutes, 300);
    expect(state.goal(study.id).name, 'Study');

    final again = UserData.fromJson(jsonDecode(state.exportJson()) as Map<String, dynamic>);
    expect(again.goals.map((g) => g.name), ['SFP', 'Study']);
    expect(state.importJson('{"nope":1}'), isFalse);
  });

  test('a new account takes over the hours saved on this phone, only once', () async {
    const old = {'days': {'2026-10-01': {'m': 300, 's': []}}, 'open': null, 'ts': 5, 'goal': 140};
    SharedPreferences.setMockInitialValues({'sfp-v1': jsonEncode(old)});
    final accounts = FakeAccounts();
    final cloud = <String, Map<String, dynamic>>{};
    final services = fakeServices(accounts, cloud);

    final ana = await services.open(await accounts.signUp('ana@mail.com', 'secret1'), isNew: true);
    expect(ana.home.hours.days['2026-10-01']!.manualMinutes, 300);
    expect(cloud['uid-0'], isNotNull);

    final bea = await services.open(await accounts.signUp('bea@mail.com', 'secret2'), isNew: true);
    expect(bea.home.hours.days, isEmpty);
    ana.dispose();
    bea.dispose();
  });
}
