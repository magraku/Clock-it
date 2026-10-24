import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../ui/strings.dart';

/// A running focus timer, for the lock screen.
class LiveTimer {
  const LiveTimer({required this.goalId, required this.goal, required this.color, required this.start, required this.end});

  final String goalId;
  final String goal;

  /// The sand's colour, 0xRRGGBB.
  final int color;

  /// When the sand would have started (pauses left out) and when it runs out.
  final DateTime start;
  final DateTime end;
}

/// Tells the person when a focus timer ends, even with the app closed, and
/// keeps the countdown on the lock screen while it runs.
abstract class TimerAlerts {
  Future<void> schedule(String goalId, DateTime at, String title, String body);

  /// The hourglass and countdown on the lock screen (a Live Activity on
  /// iPhone, an ongoing notification on Android).
  Future<void> showRunning(LiveTimer timer);

  /// Removes both the alert and the lock-screen countdown.
  Future<void> cancel(String goalId);
}

/// For the web demo and tests.
class NoTimerAlerts implements TimerAlerts {
  const NoTimerAlerts();

  @override
  Future<void> schedule(String goalId, DateTime at, String title, String body) async {}

  @override
  Future<void> showRunning(LiveTimer timer) async {}

  @override
  Future<void> cancel(String goalId) async {}
}

class LocalTimerAlerts implements TimerAlerts {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'focus_timer',
      'Focus timer',
      channelDescription: 'When a focus timer ends',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
  );

  /// Asks for permission the first time a timer starts, not at launch.
  Future<void> _init() => _ready ??= () async {
        tzdata.initializeTimeZones();
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          ),
        );
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }();

  static const _live = MethodChannel('clockit/live');

  static int _id(String goalId) => goalId.hashCode & 0x7fffffff;

  /// The ongoing countdown has its own id, beside the "time's up" alert.
  static int _runningId(String goalId) => _id(goalId) ^ 0x40000000;

  @override
  Future<void> showRunning(LiveTimer t) async {
    try {
      if (Platform.isIOS) {
        await _live.invokeMethod('show', {
          'id': t.goalId,
          'goal': t.goal,
          'color': t.color,
          'start': t.start.millisecondsSinceEpoch.toDouble(),
          'end': t.end.millisecondsSinceEpoch.toDouble(),
        });
      } else if (Platform.isAndroid) {
        await _init();
        final left = t.end.difference(DateTime.now());
        if (left <= Duration.zero) return;
        await _plugin.show(
          id: _runningId(t.goalId),
          title: t.goal,
          body: Str.focusTimeLeft,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'focus_running',
              'Running focus timer',
              channelDescription: 'The countdown while a focus timer runs',
              importance: Importance.low,
              priority: Priority.low,
              ongoing: true,
              autoCancel: false,
              onlyAlertOnce: true,
              silent: true,
              category: AndroidNotificationCategory.progress,
              visibility: NotificationVisibility.public,
              color: Color(0xFF000000 | t.color),
              // Android counts down by itself, with the app closed too.
              when: t.end.millisecondsSinceEpoch,
              usesChronometer: true,
              chronometerCountDown: true,
              showWhen: true,
              timeoutAfter: left.inMilliseconds,
            ),
          ),
        );
      }
    } on Object {
      // No permission or not supported: the timer still works in the app.
    }
  }

  @override
  Future<void> schedule(String goalId, DateTime at, String title, String body) async {
    try {
      await _init();
      await _plugin.zonedSchedule(
        id: _id(goalId),
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } on Object {
      // No permission or no notifications: the timer still works in the app.
    }
  }

  @override
  Future<void> cancel(String goalId) async {
    try {
      await _init();
      await _plugin.cancel(id: _id(goalId));
      await _plugin.cancel(id: _runningId(goalId));
      if (Platform.isIOS) await _live.invokeMethod('end', {'id': goalId});
    } on Object {
      // Nothing scheduled.
    }
  }
}
