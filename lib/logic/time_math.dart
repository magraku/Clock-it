import '../models/hours_data.dart';

String _pad(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` in local time.
String dayKey(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

String dayKeyOf(int ms) => dayKey(DateTime.fromMillisecondsSinceEpoch(ms));

/// "09:05"
String clockTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${_pad(d.hour)}:${_pad(d.minute)}';
}

/// "01:23:45"
String stopwatch(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${_pad(s ~/ 3600)}:${_pad(s ~/ 60 % 60)}:${_pad(s % 60)}';
}

/// Splits minutes into whole hours and rounded minutes (59.6 → 1h, not 0h60).
(int, int) _split(double minutes) {
  var h = minutes ~/ 60;
  var m = (minutes % 60).round();
  if (m == 60) {
    h++;
    m = 0;
  }
  return (h, m);
}

/// "5h30m", "5h05m", "5h", "45m"; empty for zero.
String fmtHours(double minutes) {
  final (h, m) = _split(minutes);
  if (h == 0 && m == 0) return '';
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h${_pad(m)}m';
}

/// Compact form used inside calendar cells: "2h29’", "24h", "45’".
String fmtCell(double minutes) {
  final (h, m) = _split(minutes);
  if (h == 0 && m == 0) return '';
  if (h == 0) return '$m’';
  return m == 0 ? '${h}h' : '${h}h${_pad(m)}’';
}

/// Goal card form: "7h30min", "6h", "45min".
String fmtPerDay(double minutes) {
  final (h, m) = _split(minutes);
  if (h == 0 && m == 0) return '0h';
  if (h == 0) return '${m}min';
  return m == 0 ? '${h}h' : '${h}h${_pad(m)}min';
}

/// Accepts 5h, 5h30m, 5h30, 5h30min, 45m, 45min, 5:30, 5.5 and 5,5.
/// Returns minutes, or null when the text is not understood.
int? parseDuration(String input) {
  final t = input.trim().toLowerCase().replaceAll(',', '.').replaceAll('’', 'm');
  RegExpMatch? m;
  if ((m = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(t)) != null) {
    return int.parse(m!.group(1)!) * 60 + int.parse(m.group(2)!);
  }
  if ((m = RegExp(r'^(\d+(?:\.\d+)?)\s*h(?:\s*(\d+)\s*(?:m|min)?)?$').firstMatch(t)) != null) {
    return (double.parse(m!.group(1)!) * 60).round() + int.parse(m.group(2) ?? '0');
  }
  if ((m = RegExp(r'^(\d+)\s*(?:m|min)$').firstMatch(t)) != null) {
    return int.parse(m!.group(1)!);
  }
  if (RegExp(r'^\d+(\.\d+)?$').hasMatch(t)) {
    return (double.parse(t) * 60).round();
  }
  return null;
}

/// Minutes logged on [key], counting the running session if it started that day.
double dayMinutes(HoursData data, String key, int nowMs) {
  final d = data.days[key];
  var total = d == null ? 0.0 : d.manualMinutes.toDouble();
  if (d != null) {
    for (final s in d.sessions) {
      total += s.minutes;
    }
  }
  final open = data.openSince;
  if (open != null && dayKeyOf(open) == key) total += (nowMs - open) / 60000;
  return total;
}

class MonthSummary {
  const MonthSummary({
    required this.year,
    required this.month,
    required this.minutesByDay,
    required this.goalMinutes,
    required this.daysLeft,
    required this.weekdaysLeft,
  });

  final int year;
  final int month;

  /// Index 0 is day 1.
  final List<double> minutesByDay;
  final double goalMinutes;

  /// Days left in the month counting today (all / Monday–Friday only).
  final int daysLeft;
  final int weekdaysLeft;

  double get total => minutesByDay.fold(0, (a, b) => a + b);
  int get daysWithHours => minutesByDay.where((m) => m > 0).length;
  double get average => daysWithHours == 0 ? 0 : total / daysWithHours;
  double get remaining => (goalMinutes - total).clamp(0, double.infinity);
  double get progress => goalMinutes <= 0 ? 1 : (total / goalMinutes).clamp(0, 1);
  bool get goalReached => remaining == 0;

  /// Minutes per day needed over [days] days; null when no days are left.
  double? needPerDay(int days) {
    if (goalReached) return 0;
    return days == 0 ? null : remaining / days;
  }
}

MonthSummary summarizeMonth(HoursData data, int year, int month, DateTime now) {
  final n = daysInMonth(year, month);
  final nowMs = now.millisecondsSinceEpoch;
  final minutes = [
    for (var d = 1; d <= n; d++) dayMinutes(data, dayKey(DateTime(year, month, d)), nowMs),
  ];

  // First day still ahead: today in the current month, day 1 for future months,
  // and none for past months.
  final int from;
  if (year == now.year && month == now.month) {
    from = now.day;
  } else if (DateTime(year, month).isAfter(now)) {
    from = 1;
  } else {
    from = n + 1;
  }
  var all = 0, weekdays = 0;
  for (var d = from; d <= n; d++) {
    all++;
    if (DateTime(year, month, d).weekday <= DateTime.friday) weekdays++;
  }

  return MonthSummary(
    year: year,
    month: month,
    minutesByDay: minutes,
    goalMinutes: data.goalHours * 60,
    daysLeft: all,
    weekdaysLeft: weekdays,
  );
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
