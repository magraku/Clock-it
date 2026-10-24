import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/accounts.dart';
import '../data/hours_store.dart';
import '../data/timer_alerts.dart';
import '../logic/time_math.dart';
import '../models/goals.dart';
import '../models/hours_data.dart';
import '../ui/strings.dart';
import '../ui/theme.dart';

/// The signed-in account's goals and hours. One instance per session.
class AppState extends ChangeNotifier {
  AppState(
    this._store, {
    this.account,
    DateTime Function()? clock,
    this.alerts = const NoTimerAlerts(),
  }) : _clock = clock ?? DateTime.now;

  final HoursStore _store;
  final Account? account;
  final TimerAlerts alerts;
  final DateTime Function() _clock;
  Timer? _ticker;
  StreamSubscription<UserData>? _sync;

  UserData _data = UserData.starter();
  UserData get data => _data;
  List<Goal> get goals => _data.goals;
  Goal get home => _data.home;

  /// [id]'s goal, or Home's if it was deleted (e.g. from another phone).
  Goal goal(String id) => _data.byId(id) ?? _data.home;

  DateTime get now => _clock();
  int get _nowMs => now.millisecondsSinceEpoch;

  bool isOpen(String goalId) => goal(goalId).hours.openSince != null;

  /// The month's hours, with a running timer's stretch counted today.
  MonthSummary summary(String goalId, DateTime month) {
    final s = summarizeMonth(goal(goalId).hours, month.year, month.month, now);
    final stretch = _timerStretchMinutes(goal(goalId));
    if (stretch > 0 && month.year == now.year && month.month == now.month) s.minutesByDay[now.day - 1] += stretch;
    return s;
  }

  /// Loads the account's goals. [adopt] (hours saved on this phone before
  /// accounts existed) seeds an account that has nothing yet.
  Future<void> load({UserData? adopt}) async {
    final saved = await _store.load();
    if (saved == null && adopt != null) {
      _data = adopt;
      _commit();
    } else {
      _data = saved ?? UserData.starter();
    }
    _sync ??= _store.changes().listen(_onRemote);
    _settleTimers();
    _syncTicker();
    notifyListeners();
  }

  /// Keeps whichever copy was saved last, like the web version.
  void _onRemote(UserData remote) {
    if (remote.updatedAt <= _data.updatedAt) return;
    _data = remote;
    _syncTicker();
    notifyListeners();
  }

  // ── Hours ────────────────────────────────────────────────────────────────

  /// Mark entry / mark exit.
  void punch(String goalId) {
    final hours = goal(goalId).hours;
    final open = hours.openSince;
    if (open != null) {
      _log(hours, open, _nowMs);
      hours.openSince = null;
    } else {
      hours.openSince = _nowMs;
    }
    _commit();
  }

  /// Minutes logged on [key], excluding a session still running.
  double savedMinutes(String goalId, String key) {
    final d = goal(goalId).hours.days[key];
    if (d == null) return 0;
    return d.manualMinutes + d.sessions.fold<double>(0, (a, s) => a + s.minutes);
  }

  /// Replaces the day's sessions with a single manual total, like the web version.
  /// Zero removes the day.
  void setDay(String goalId, String key, int minutes) {
    final days = goal(goalId).hours.days;
    if (minutes > 0) {
      days[key] = DayEntry(manualMinutes: minutes);
    } else {
      days.remove(key);
    }
    _commit();
  }

  void setGoalHours(String goalId, double hours) {
    if (hours <= 0) return;
    goal(goalId).hours.goalHours = hours;
    _commit();
  }

  /// Minutes on [goalId] from [from] (inclusive) to today, running session included.
  double minutesSince(String goalId, DateTime from) {
    final hours = goal(goalId).hours;
    final today = DateTime(now.year, now.month, now.day);
    var total = 0.0;
    for (var d = DateTime(from.year, from.month, from.day); !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
      total += dayMinutes(hours, dayKey(d), _nowMs);
    }
    return total + _timerStretchMinutes(goal(goalId));
  }

  /// The running timer stretch isn't logged until it pauses or ends.
  double _timerStretchMinutes(Goal g) {
    final since = g.timer?.runningSince;
    return since == null ? 0 : (_nowMs - since) / 60000;
  }

  static void _log(HoursData hours, int start, int end) {
    if (end <= start) return;
    hours.days.putIfAbsent(dayKeyOf(start), DayEntry.new).sessions.add(Session(start, end));
  }

  // ── Goals ────────────────────────────────────────────────────────────────

  Goal createGoal(String name, GoalColor color, double monthlyHours, {bool makeHome = false}) {
    final g = Goal(
      id: Goal.newId(),
      name: name.trim(),
      color: color,
      hours: HoursData(goalHours: monthlyHours > 0 ? monthlyHours : Goal.defaultHours),
    );
    _data.goals.add(g);
    if (makeHome) _data.home = g;
    _commit();
    return g;
  }

  void updateGoal(String goalId, {String? name, GoalColor? color, double? monthlyHours, bool? makeHome}) {
    final g = _data.byId(goalId);
    if (g == null) return;
    if (name != null && name.trim().isNotEmpty) g.name = name.trim();
    if (color != null) g.color = color;
    if (monthlyHours != null && monthlyHours > 0) g.hours.goalHours = monthlyHours;
    if (makeHome == true) _data.home = g;
    _commit();
  }

  /// The last goal can't be deleted. Home moves to the first remaining one.
  bool deleteGoal(String goalId) {
    if (_data.goals.length < 2) return false;
    final wasHome = home.id == goalId;
    _data.goals.removeWhere((g) => g.id == goalId);
    if (wasHome) _data.home = _data.goals.first;
    alerts.cancel(goalId);
    _commit();
    return true;
  }

  // ── Focus timer ("Cronometer") ───────────────────────────────────────────

  HourglassStyle get hourglass => _data.hourglass;

  void setHourglass(HourglassStyle style) {
    _data.hourglass = style;
    _commit();
  }

  WallpaperStyle get wallpaper => _data.wallpaper;

  void setWallpaper(WallpaperStyle style) {
    _data.wallpaper = style;
    _commit();
  }

  FocusTimer? timerOf(String goalId) => goal(goalId).timer;

  /// Starts a [minutes] countdown, replacing (and logging) any current one.
  void startTimer(String goalId, int minutes) {
    final g = goal(goalId);
    _endTimer(g, _nowMs);
    g.timer = FocusTimer(totalMs: minutes * 60000, runningSince: _nowMs);
    _scheduleAlert(g);
    _commit();
  }

  void pauseTimer(String goalId) {
    final g = goal(goalId);
    final t = g.timer;
    final since = t?.runningSince;
    if (t == null || since == null) return;
    final end = _nowMs;
    _log(g.hours, since, end);
    t
      ..doneMs += end - since
      ..runningSince = null;
    alerts.cancel(g.id);
    _commit();
  }

  void resumeTimer(String goalId) {
    final g = goal(goalId);
    final t = g.timer;
    if (t == null || t.running) return;
    t.runningSince = _nowMs;
    _scheduleAlert(g);
    _commit();
  }

  /// Stops early; the focus time so far still counts.
  void stopTimer(String goalId) {
    final g = goal(goalId);
    if (g.timer == null) return;
    _endTimer(g, _nowMs);
    _commit();
  }

  /// Logs the running stretch (up to [atMs] or the timer's end) and clears it.
  void _endTimer(Goal g, int atMs) {
    final t = g.timer;
    if (t == null) return;
    final since = t.runningSince, ends = t.endsAt;
    if (since != null && ends != null) _log(g.hours, since, atMs < ends ? atMs : ends);
    g.timer = null;
    alerts.cancel(g.id);
  }

  /// Finishes timers that reached zero, also while the app was closed.
  bool _settleTimers() {
    var changed = false;
    for (final g in _data.goals) {
      final ends = g.timer?.endsAt;
      if (ends != null && _nowMs >= ends) {
        _endTimer(g, ends);
        changed = true;
      }
    }
    return changed;
  }

  void _scheduleAlert(Goal g) {
    final ends = g.timer?.endsAt;
    if (ends == null) return;
    alerts.schedule(
      g.id,
      DateTime.fromMillisecondsSinceEpoch(ends),
      Str.timerDoneTitle,
      Str.timerDoneBody(g.name, fmtHours(g.timer!.totalMs / 60000)),
    );
    alerts.showRunning(LiveTimer(
      goalId: g.id,
      goal: g.name,
      // As in the app: the goal's colour, or navy on a yellow goal.
      color: (g.color == GoalColor.yellow ? Palette.navyDeep : g.color.color).toARGB32() & 0xFFFFFF,
      start: DateTime.fromMillisecondsSinceEpoch(ends - g.timer!.totalMs),
      end: DateTime.fromMillisecondsSinceEpoch(ends),
    ));
  }

  // ── Backup ───────────────────────────────────────────────────────────────

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_data.toJson());

  /// Returns false (and changes nothing) when [text] is not a valid backup.
  /// A single-tracker backup (web version) replaces only Home's hours.
  bool importJson(String text) {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      if (j['goals'] is List) {
        _data = UserData.fromJson(j);
      } else {
        home.hours = HoursData.fromJson(j);
      }
    } on Object {
      return false;
    }
    _commit();
    return true;
  }

  /// Re-reads the clock, e.g. when the app returns to the foreground.
  void refresh() {
    if (_settleTimers()) {
      _commit();
    } else {
      notifyListeners();
    }
  }

  void _commit() {
    _data.updatedAt = _nowMs;
    _store.save(_data);
    _syncTicker();
    notifyListeners();
  }

  bool get _anythingRunning => _data.goals.any((g) => g.hours.openSince != null || (g.timer?.running ?? false));

  /// Ticks once per second only while a session or a timer is running.
  void _syncTicker() {
    if (_anythingRunning && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_settleTimers()) {
          _commit();
        } else {
          notifyListeners();
        }
      });
    } else if (!_anythingRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sync?.cancel();
    super.dispose();
  }
}
