import 'package:clock_it/data/hours_store.dart';
import 'package:clock_it/data/timer_alerts.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingAlerts extends NoTimerAlerts {
  DateTime? end;

  @override
  Future<void> schedule(
          String goalId, DateTime at, String title, String body) async =>
      end = at;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final skew in [-60, 60]) {
    test('focus countdown survives a receiving clock skew of $skew minutes',
        () async {
      final db = FakeFirebaseFirestore();
      var firstNow = DateTime.now();
      var secondNow = firstNow.add(Duration(minutes: skew));
      final alerts = RecordingAlerts();
      final first = AppState(FirestoreHoursStore('u', db: db),
          clock: () => firstNow, alerts: alerts);
      final second =
          AppState(FirestoreHoursStore('u', db: db), clock: () => secondNow);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await first.load();
      await second.load();
      expect(first.timerOf('sfp'), isNull);
      first.startTimer('sfp', 15);
      expect(alerts.end!.difference(firstNow).inMilliseconds,
          closeTo(15 * 60000, 1000));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final timer = second.timerOf('sfp')!;
      expect(timer.remainingMs(second.now.millisecondsSinceEpoch),
          closeTo(15 * 60000, 1000));
      firstNow = firstNow.add(const Duration(minutes: 5));
      secondNow = secondNow.add(const Duration(minutes: 5));
      expect(timer.remainingMs(second.now.millisecondsSinceEpoch),
          closeTo(10 * 60000, 1000));
      second.refresh();
      expect(second.timerOf('sfp'), isNotNull);
      secondNow = secondNow.add(const Duration(minutes: 11));
      second.refresh();
      expect(second.timerOf('sfp'), isNull);
    });
  }

  for (final cachedOffset in [null, 3600000000]) {
    test('loads when calibration fails with cached offset $cachedOffset',
        () async {
      if (cachedOffset != null) {
        SharedPreferences.setMockInitialValues(
            {'clockit-clock-offset-u': cachedOffset});
      }
      final db = FakeFirebaseFirestore(securityRules: '''
      service cloud.firestore {
        match /databases/{database}/documents {
          match /users/{uid} { allow read, write: if true; }
        }
      }
    ''');
      final localNow = DateTime(2026, 10, 12, 10);
      final state =
          AppState(FirestoreHoursStore('u', db: db), clock: () => localNow);
      addTearDown(state.dispose);
      await state.load();
      expect(
          state.now, localNow.add(Duration(microseconds: cachedOffset ?? 0)));
      expect(state.timerOf('sfp'), isNull);
    });
  }

  test('successful calibration replaces the cached offset for this uid',
      () async {
    SharedPreferences.setMockInitialValues({
      'clockit-clock-offset-u': 3600000000,
      'clockit-clock-offset-other': 123,
    });
    final db = FakeFirebaseFirestore();
    final localNow = DateTime.now().add(const Duration(hours: 2));
    final state =
        AppState(FirestoreHoursStore('u', db: db), clock: () => localNow);
    addTearDown(state.dispose);
    await state.load();
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getInt('clockit-clock-offset-u'), closeTo(-7200000000, 1000000));
    expect(prefs.getInt('clockit-clock-offset-other'), 123);
    expect(state.now.difference(localNow).inMicroseconds,
        prefs.getInt('clockit-clock-offset-u'));
  });
}
