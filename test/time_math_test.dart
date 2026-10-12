import 'dart:convert';

import 'package:clock_it/logic/time_math.dart';
import 'package:clock_it/models/hours_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDuration', () {
    test('accepts every documented format', () {
      expect(parseDuration('5h'), 300);
      expect(parseDuration('5h30m'), 330);
      expect(parseDuration('5h30'), 330);
      expect(parseDuration('5h 30min'), 330);
      expect(parseDuration('45m'), 45);
      expect(parseDuration('45min'), 45);
      expect(parseDuration('5:30'), 330);
      expect(parseDuration('5.5'), 330);
      expect(parseDuration('5,5'), 330);
      expect(parseDuration(' 5H30M '), 330);
      expect(parseDuration('2h29’'), 149);
    });

    test('rejects garbage', () {
      expect(parseDuration('abc'), isNull);
      expect(parseDuration('5x'), isNull);
      expect(parseDuration(''), isNull);
    });
  });

  group('formatting', () {
    test('fmtHours', () {
      expect(fmtHours(0), '');
      expect(fmtHours(45), '45m');
      expect(fmtHours(300), '5h');
      expect(fmtHours(305), '5h05m');
      expect(fmtHours(3615), '60h15m');
      expect(fmtHours(59.6), '1h'); // rounds up instead of "0h60m"
    });

    test('fmtCell and fmtPerDay match the design', () {
      expect(fmtCell(149), '2h29’');
      expect(fmtCell(24 * 60), '24h');
      expect(fmtCell(30), '30’');
      expect(fmtPerDay(450), '7h30min');
      expect(fmtPerDay(330), '5h30min');
      expect(fmtPerDay(0), '0h');
    });
  });

  group('summarizeMonth', () {
    final data = HoursData(days: {
      '2026-10-01': DayEntry(manualMinutes: 300),
      '2026-10-02': DayEntry(sessions: [
        Session(DateTime(2026, 10, 2, 9).millisecondsSinceEpoch,
            DateTime(2026, 10, 2, 12, 30).millisecondsSinceEpoch),
      ]),
    });
    // Monday, October 12 2026.
    final now = DateTime(2026, 10, 12, 10);

    test('totals, days with hours and average', () {
      final s = summarizeMonth(data, 2026, 10, now);
      expect(s.total, 510);
      expect(s.daysWithHours, 2);
      expect(s.average, 255);
      expect(s.remaining, 140 * 60 - 510);
    });

    test('days left count today; weekdays exclude weekends', () {
      final s = summarizeMonth(data, 2026, 10, now);
      expect(s.daysLeft, 20); // 12..31
      expect(s.weekdaysLeft, 15); // Oct 12-16, 19-23, 26-30
      expect(s.needPerDay(s.weekdaysLeft), (140 * 60 - 510) / 15);
    });

    test('past months have no days left, future months all of them', () {
      expect(summarizeMonth(data, 2026, 9, now).daysLeft, 0);
      expect(summarizeMonth(data, 2026, 9, now).needPerDay(0), isNull);
      expect(summarizeMonth(data, 2026, 11, now).daysLeft, 30);
    });

    test('a running session counts toward its day', () {
      final open = HoursData(openSince: DateTime(2026, 10, 12, 8).millisecondsSinceEpoch);
      expect(dayMinutes(open, '2026-10-12', now.millisecondsSinceEpoch), 120);
    });
  });

  test('JSON round-trips and reads web-version backups', () {
    const web = '{"days":{"2026-10-01":{"m":300,"s":[]},"2026-10-02":{"m":0,'
        '"s":[{"i":1759395600000,"o":1759408200000}]}},"open":null,"ts":1759408200000,"goal":120}';
    final data = HoursData.fromJson(jsonDecode(web) as Map<String, dynamic>);
    expect(data.goalHours, 120);
    expect(data.days['2026-10-01']!.manualMinutes, 300);
    expect(data.days['2026-10-02']!.sessions.single.minutes, 210);

    final again = HoursData.fromJson(jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>);
    expect(jsonEncode(again.toJson()), jsonEncode(data.toJson()));
  });

  test('a backup without goal falls back to 140h; without days it is rejected', () {
    expect(HoursData.fromJson({'days': {}}).goalHours, 140);
    expect(() => HoursData.fromJson({'foo': 1}), throwsFormatException);
  });
}
