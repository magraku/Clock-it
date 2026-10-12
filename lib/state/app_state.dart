import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/accounts.dart';
import '../data/hours_store.dart';
import '../logic/time_math.dart';
import '../models/hours_data.dart';

/// The signed-in account's hours. One instance per session.
class AppState extends ChangeNotifier {
  AppState(this._store, {this.account, DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _viewMonth = DateTime(now.year, now.month);
  }

  final HoursStore _store;
  final Account? account;
  final DateTime Function() _clock;
  Timer? _ticker;
  StreamSubscription<HoursData>? _sync;

  HoursData _data = HoursData();
  HoursData get data => _data;

  late DateTime _viewMonth;
  DateTime get viewMonth => _viewMonth;

  DateTime get now => _clock();
  bool get isOpen => _data.openSince != null;

  bool get viewingCurrentMonth {
    final n = now;
    return _viewMonth.year == n.year && _viewMonth.month == n.month;
  }

  MonthSummary get summary => summarizeMonth(_data, _viewMonth.year, _viewMonth.month, now);

  /// Loads the account's hours. [adopt] (hours saved on this phone before
  /// accounts existed) seeds an account that has none yet.
  Future<void> load({HoursData? adopt}) async {
    final saved = await _store.load();
    if (saved == null && adopt != null) {
      _data = adopt;
      _commit();
    } else {
      _data = saved ?? HoursData();
    }
    _sync ??= _store.changes().listen(_onRemote);
    _syncTicker();
    notifyListeners();
  }

  /// Keeps whichever copy was saved last, like the web version.
  void _onRemote(HoursData remote) {
    if (remote.updatedAt <= _data.updatedAt) return;
    _data = remote;
    _syncTicker();
    notifyListeners();
  }

  /// Mark entry / mark exit.
  void punch() {
    final nowMs = now.millisecondsSinceEpoch;
    final open = _data.openSince;
    if (open != null) {
      _data.days.putIfAbsent(dayKeyOf(open), DayEntry.new).sessions.add(Session(open, nowMs));
      _data.openSince = null;
    } else {
      _data.openSince = nowMs;
    }
    _commit();
  }

  /// Minutes logged on [key], excluding a session still running.
  double savedMinutes(String key) {
    final d = _data.days[key];
    if (d == null) return 0;
    return d.manualMinutes + d.sessions.fold<double>(0, (a, s) => a + s.minutes);
  }

  /// Replaces the day's sessions with a single manual total, like the web version.
  /// Zero removes the day.
  void setDay(String key, int minutes) {
    if (minutes > 0) {
      _data.days[key] = DayEntry(manualMinutes: minutes);
    } else {
      _data.days.remove(key);
    }
    _commit();
  }

  void setGoal(double hours) {
    if (hours <= 0) return;
    _data.goalHours = hours;
    _commit();
  }

  void changeMonth(int delta) {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    notifyListeners();
  }

  void goToToday() {
    final n = now;
    _viewMonth = DateTime(n.year, n.month);
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_data.toJson());

  /// Returns false (and changes nothing) when [text] is not a valid backup.
  bool importJson(String text) {
    try {
      _data = HoursData.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } on Object {
      return false;
    }
    _commit();
    return true;
  }

  /// Re-reads the clock, e.g. when the app returns to the foreground.
  void refresh() => notifyListeners();

  void _commit() {
    _data.updatedAt = now.millisecondsSinceEpoch;
    _store.save(_data);
    _syncTicker();
    notifyListeners();
  }

  /// Ticks once per second only while a session is running.
  void _syncTicker() {
    if (isOpen && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    } else if (!isOpen) {
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
