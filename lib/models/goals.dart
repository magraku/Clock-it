/// An account's goals ("SFP", "Study hours", ...), each with its own hours.
///
/// ```json
/// {"v": 2, "home": "sfp", "ts": 1759310000000,
///  "goals": [{"id": "sfp", "name": "SFP", "color": "orange",
///             "hours": {"days": {...}, "open": null, "goal": 140},
///             "timer": {"t": 1500000, "r": 1759310000000, "d": 0}}]}
/// ```
///
/// A single-tracker backup (the web version, or this app before goals)
/// reads as one "SFP" goal.
library;

import 'dart:math';

import 'hours_data.dart';

/// The four card colors. The names are what accounts store; since the plum
/// palette they paint turquoise, lavender, pink and butter (see theme.dart).
enum GoalColor { green, orange, pink, yellow }

/// A focus countdown ("Cronometer"). Each stretch it runs is logged as a
/// session of its goal when it pauses or ends, so the hours always add up.
class FocusTimer {
  FocusTimer({required this.totalMs, this.runningSince, this.doneMs = 0});

  /// Chosen length (15, 20 or 30 min).
  final int totalMs;

  /// Start of the current stretch (ms since epoch); null while paused.
  int? runningSince;

  /// Focus time from earlier stretches, already logged.
  int doneMs;

  bool get running => runningSince != null;

  int elapsedMs(int nowMs) => doneMs + (runningSince == null ? 0 : nowMs - runningSince!);
  int remainingMs(int nowMs) => max(0, totalMs - elapsedMs(nowMs));
  double progress(int nowMs) => (elapsedMs(nowMs) / totalMs).clamp(0.0, 1.0);

  /// When it reaches zero if left running.
  int? get endsAt => runningSince == null ? null : runningSince! + totalMs - doneMs;

  Map<String, dynamic> toJson() => {'t': totalMs, 'r': runningSince, 'd': doneMs};

  factory FocusTimer.fromJson(Map<String, dynamic> j) => FocusTimer(
        totalMs: (j['t'] as num).round(),
        runningSince: (j['r'] as num?)?.round(),
        doneMs: (j['d'] as num? ?? 0).round(),
      );
}

class Goal {
  Goal({
    required this.id,
    required this.name,
    this.color = GoalColor.green,
    HoursData? hours,
    this.timer,
  }) : hours = hours ?? HoursData(goalHours: defaultHours);

  /// Monthly target for a new goal; SFP keeps the original 140h.
  static const double defaultHours = 20;

  final String id;
  String name;
  GoalColor color;
  HoursData hours;
  FocusTimer? timer;

  static String newId() =>
      'g${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.name,
        'hours': hours.toJson(),
        'timer': timer?.toJson(),
      };

  factory Goal.fromJson(Map<String, dynamic> j) {
    final id = j['id'], name = j['name'], hours = j['hours'];
    if (id is! String || name is! String || hours is! Map) {
      throw const FormatException('Invalid goal');
    }
    final timer = j['timer'];
    return Goal(
      id: id,
      name: name,
      color: GoalColor.values.asNameMap()[j['color']] ?? GoalColor.green,
      hours: HoursData.fromJson(Map<String, dynamic>.from(hours)),
      timer: timer is Map ? FocusTimer.fromJson(Map<String, dynamic>.from(timer)) : null,
    );
  }
}

/// How the focus timer's hourglass is drawn.
enum HourglassStyle { classic, crystal, line, grains }

/// The focus screen's background (and the one to save for the lock screen):
/// the app's photo, or a painted wallpaper.
enum WallpaperStyle { photo, drop, dusk, meadow, pattern }

class UserData {
  UserData({
    required this.goals,
    required String homeId,
    this.updatedAt = 0,
    this.hourglass = HourglassStyle.classic,
    this.wallpaper = WallpaperStyle.photo,
  }) : _homeId = homeId {
    if (goals.isEmpty) throw const FormatException('An account needs at least one goal');
  }

  /// A new account: just SFP, the app's original purpose, on Home.
  factory UserData.starter({HoursData? sfp}) => UserData(
        goals: [Goal(id: 'sfp', name: 'SFP', color: GoalColor.orange, hours: sfp ?? HoursData())],
        homeId: 'sfp',
        updatedAt: sfp?.updatedAt ?? 0,
      );

  final List<Goal> goals;
  String _homeId;

  /// Last modification (ms); the newest copy wins when syncing.
  int updatedAt;

  HourglassStyle hourglass;
  WallpaperStyle wallpaper;

  /// The goal shown on the Home tab (the house on its card).
  Goal get home => byId(_homeId) ?? goals.first;
  set home(Goal g) => _homeId = g.id;

  Goal? byId(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'v': 2,
        'goals': [for (final g in goals) g.toJson()],
        'home': home.id,
        'ts': updatedAt,
        'glass': hourglass.name,
        'wall': wallpaper.name,
      };

  /// Reads this format or a single-tracker backup. Throws [FormatException]
  /// when [j] is neither.
  factory UserData.fromJson(Map<String, dynamic> j) {
    final goals = j['goals'];
    if (goals is List) {
      return UserData(
        goals: [for (final g in goals) Goal.fromJson(Map<String, dynamic>.from(g as Map))],
        homeId: j['home'] is String ? j['home'] as String : '',
        updatedAt: (j['ts'] as num? ?? 0).round(),
        hourglass: HourglassStyle.values.asNameMap()[j['glass']] ?? HourglassStyle.classic,
        wallpaper: WallpaperStyle.values.asNameMap()[j['wall']] ?? WallpaperStyle.photo,
      );
    }
    return UserData.starter(sfp: HoursData.fromJson(j));
  }
}
