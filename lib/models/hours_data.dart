/// Data model. The JSON shape is identical to the web version
/// (`reference/horas-sfp.html`), so backups move freely between both:
///
/// ```json
/// {"days": {"2026-10-01": {"m": 300, "s": [{"i": 1759300000000, "o": 1759310000000}]}},
///  "open": null, "ts": 1759310000000, "goal": 140}
/// ```
library;

class Session {
  const Session(this.start, this.end);

  /// Entry and exit, in milliseconds since epoch.
  final int start;
  final int end;

  double get minutes => (end - start) / 60000;

  Map<String, dynamic> toJson() => {'i': start, 'o': end};

  factory Session.fromJson(Map<String, dynamic> j) =>
      Session(_toInt(j['i']), _toInt(j['o']));
}

class DayEntry {
  DayEntry({this.manualMinutes = 0, List<Session>? sessions})
      : sessions = sessions ?? [];

  /// Minutes typed by hand (the `m` field).
  int manualMinutes;
  final List<Session> sessions;

  Map<String, dynamic> toJson() => {
        'm': manualMinutes,
        's': [for (final s in sessions) s.toJson()],
      };

  factory DayEntry.fromJson(Map<String, dynamic> j) => DayEntry(
        manualMinutes: _toInt(j['m']),
        sessions: [
          for (final s in (j['s'] as List? ?? const []))
            Session.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
      );
}

class HoursData {
  HoursData({
    Map<String, DayEntry>? days,
    this.openSince,
    this.updatedAt = 0,
    this.goalHours = defaultGoal,
  }) : days = days ?? {};

  static const double defaultGoal = 140;

  /// Keyed by local date, `yyyy-MM-dd`.
  final Map<String, DayEntry> days;

  /// Start of the running session (ms since epoch), or null.
  int? openSince;

  /// Last modification (ms). Used later to merge with the cloud.
  int updatedAt;

  double goalHours;

  Map<String, dynamic> toJson() => {
        'days': {for (final e in days.entries) e.key: e.value.toJson()},
        'open': openSince,
        'ts': updatedAt,
        'goal': goalHours,
      };

  /// Throws [FormatException] when [j] is not a valid backup.
  factory HoursData.fromJson(Map<String, dynamic> j) {
    final rawDays = j['days'];
    if (rawDays is! Map) throw const FormatException('Missing "days"');
    final goal = j['goal'];
    return HoursData(
      days: {
        for (final e in rawDays.entries)
          e.key as String:
              DayEntry.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
      openSince: j['open'] == null ? null : _toInt(j['open']),
      updatedAt: j['ts'] == null ? 0 : _toInt(j['ts']),
      goalHours: goal is num && goal > 0 ? goal.toDouble() : defaultGoal,
    );
  }
}

int _toInt(Object? v) => v is num ? v.round() : int.parse('$v');
