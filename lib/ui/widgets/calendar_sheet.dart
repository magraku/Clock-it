import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../logic/time_math.dart';
import '../motion.dart';
import '../strings.dart';
import '../theme.dart';
import 'common.dart';

/// The wall calendar. Internal coordinates are pixels of
/// `assets/images/calendar_paper.png` (789 × 1174), scaled to the real size.
///
/// Changing month slides the page the way it was swiped and the paper swings
/// a little on its ring.
class CalendarSheet extends StatefulWidget {
  const CalendarSheet({
    super.key,
    required this.now,
    required this.summary,
    required this.onChangeMonth,
    required this.onToday,
    required this.onDayTap,
    required this.onGoalTap,
    required this.onMenuTap,
  });

  static const paperWidth = 789.0;

  final DateTime now;

  /// The month shown is the summary's.
  final MonthSummary summary;
  final ValueChanged<int> onChangeMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onGoalTap;
  final VoidCallback onMenuTap;

  @override
  State<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<CalendarSheet> with SingleTickerProviderStateMixin {
  late final _swing = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  /// +1 when moving to a later month, -1 to an earlier one.
  int _dir = 1;

  static DateTime _monthOf(MonthSummary s) => DateTime(s.year, s.month);

  @override
  void didUpdateWidget(CalendarSheet old) {
    super.didUpdateWidget(old);
    final from = _monthOf(old.summary), to = _monthOf(widget.summary);
    if (to != from) {
      _dir = to.isAfter(from) ? 1 : -1;
      if (!Motion.reduced(context)) _swing.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth / CalendarSheet.paperWidth;
      Widget at(double x, double y, double w, double h, Widget child) =>
          Positioned(left: x * s, top: y * s, width: w * s, height: h * s, child: child);

      final month = DateTime(summary.year, summary.month);
      return GestureDetector(
        // Swipe left/right to change month.
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() > 250) widget.onChangeMonth(v < 0 ? 1 : -1);
        },
        // Damped swing around the ring, against the direction of travel.
        child: AnimatedBuilder(
          animation: _swing,
          builder: (_, child) {
            final t = _swing.value;
            final angle = -_dir * 0.018 * math.sin(t * math.pi * 3) * math.pow(1 - t, 2);
            return Transform.rotate(angle: angle, alignment: Alignment.topCenter, child: child);
          },
          child: Stack(children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage(Assets.paper),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            at(706, 96, 66, 66, _RoundIcon(icon: Icons.more_horiz, label: Str.moreOptions, s: s, onTap: widget.onMenuTap)),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: Motion.standard,
                reverseDuration: const Duration(milliseconds: 200),
                transitionBuilder: (child, a) {
                  // Incoming page enters from the side we're heading to; the
                  // old one leaves toward the other side.
                  final incoming = child.key == ValueKey(month);
                  final from = Offset((incoming ? 0.06 : -0.06) * _dir, 0);
                  final curved = CurvedAnimation(parent: a, curve: Motion.enter, reverseCurve: Motion.exit);
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(curved), child: child),
                  );
                },
                child: Stack(
                  key: ValueKey(month),
                  children: [
                    at(18, 212, 384, 210, _Wordmark(month: month, onTap: widget.onToday)),
                    at(427, 209, 343, 216, _GoalCard(summary: summary, s: s, onTap: widget.onGoalTap)),
                    at(18, 444, 754, 120, _MonthStats(summary: summary, s: s, onNav: widget.onChangeMonth)),
                    at(18, 578, 754, 580, _Grid(now: widget.now, summary: summary, s: s, onDayTap: widget.onDayTap)),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

/// "JAN" — Anton, stretched to fill the box like the printed calendar.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.month, required this.onTap});

  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = Str.monthsShort[month.month - 1];
    return Semantics(
      label: '${Str.monthYear(month.year, month.month)}. ${Str.today}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(painter: _WordmarkPainter(label), size: Size.infinite),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter(this.text);

  final String text;

  // Anton metrics (units per em 2048): ascender 2409, cap height 1760.
  static const _ascent = 2409 / 2048;
  static const _cap = 1760 / 2048;

  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = size.height / _cap;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: Fonts.display,
          fontSize: fontSize,
          color: Palette.navy,
          letterSpacing: -fontSize * 0.01,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final sx = (size.width / tp.width).clamp(0.7, 1.45);
    canvas
      ..save()
      ..scale(sx, 1);
    tp.paint(canvas, Offset(0, -(_ascent - _cap) * fontSize));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) => old.text != text;
}

/// Green card: monthly goal and hours per day needed to reach it.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.summary, required this.s, required this.onTap});

  final MonthSummary summary;
  final double s;
  final VoidCallback onTap;

  String _need(int days) {
    final v = summary.needPerDay(days);
    return v == null ? '—' : fmtPerDay(v);
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, double size) {
      // Navy: the design's light text on green read at 1.6:1.
      final style = TextStyle(fontSize: size, color: Palette.navyDeep, height: 1.2);
      return Row(children: [
        // Shrinks rather than cutting the label off.
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: style, maxLines: 1),
          ),
        ),
        SizedBox(width: 8 * s),
        Text(value, style: style, maxLines: 1),
      ]);
    }

    return Pressable(
      onTap: onTap,
      semanticLabel: Str.monthlyGoal,
      child: Container(
        decoration: BoxDecoration(
          color: Palette.green.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(23 * s),
        ),
        padding: EdgeInsets.fromLTRB(28 * s, 30 * s, 28 * s, 16 * s),
        child: ShrinkToFit(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(Str.actualGoal, fmtHours(summary.goalMinutes), 31 * s),
              row(Str.monFri, _need(summary.weekdaysLeft), 34 * s),
              row(Str.everyday, _need(summary.daysLeft), 34 * s),
              SizedBox(height: 22 * s),
              Text(
                Str.daysLeft(summary.weekdaysLeft, summary.daysLeft),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24 * s,
                  color: Palette.navyDeep,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Month total, days with hours and average, between the month arrows.
class _MonthStats extends StatelessWidget {
  const _MonthStats({required this.summary, required this.s, required this.onNav});

  final MonthSummary summary;
  final double s;
  final ValueChanged<int> onNav;

  @override
  Widget build(BuildContext context) {
    final total = fmtHours(summary.total);
    return Row(children: [
      _RoundIcon(icon: Icons.chevron_left, label: Str.prevMonth, s: s, size: 72, onTap: () => onNav(-1)),
      Expanded(
        child: ShrinkToFit(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Str.monthTotal(total.isEmpty ? '0h' : total),
                style: TextStyle(
                  fontSize: 42 * s,
                  fontWeight: FontWeight.w700,
                  color: Palette.navy,
                  height: 1.1,
                ),
              ),
              Text(
                Str.daysWorked(summary.daysWithHours, fmtHours(summary.average)),
                style: TextStyle(
                  fontSize: 31 * s,
                  color: Palette.navy.withValues(alpha: 0.75),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
      _RoundIcon(icon: Icons.chevron_right, label: Str.nextMonth, s: s, size: 72, onTap: () => onNav(1)),
    ]);
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.s,
    required this.onTap,
    this.size = 66,
  });

  final IconData icon;
  final String label;
  final double s;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      focusRadius: size * s / 2,
      child: Container(
        width: size * s,
        height: size * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Palette.navy.withValues(alpha: 0.55), width: 2.4 * s),
        ),
        child: Icon(icon, color: Palette.navy, size: size * 0.66 * s),
      ),
    );
  }
}

/// Monday-first month grid. Days with hours are tinted orange (stronger with
/// more hours) and today is pink, as in the design.
///
/// When a month appears, the tinted days ripple in diagonally from the top
/// left corner.
class _Grid extends StatefulWidget {
  const _Grid({required this.now, required this.summary, required this.s, required this.onDayTap});

  final DateTime now;
  final MonthSummary summary;
  final double s;
  final ValueChanged<DateTime> onDayTap;

  static const _headerHeight = 42.0;

  static Color? tint(double minutes, bool today) {
    if (today) return Palette.pink.withValues(alpha: 0.75);
    if (minutes <= 0) return null;
    final h = minutes / 60;
    final a = h < 4
        ? 0.2
        : h < 7
            ? 0.45
            : h < 10
                ? 0.7
                : 1.0;
    return Palette.orange.withValues(alpha: a);
  }

  @override
  State<_Grid> createState() => _GridState();
}

class _GridState extends State<_Grid> with SingleTickerProviderStateMixin {
  late final _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _ripple.value = 1;
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  /// Cell [i]'s share of the ripple: 25 ms apart along the diagonals.
  Animation<double> _wave(int i) {
    final start = ((i % 7) + (i ~/ 7)) * 25 / 520;
    return CurvedAnimation(parent: _ripple, curve: Interval(start, math.min(1, start + 0.45), curve: Motion.pop));
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary, s = widget.s, onDayTap = widget.onDayTap;
    const headerHeight = _Grid._headerHeight;
    final y = summary.year, m = summary.month;
    final offset = DateTime(y, m).weekday - 1;
    final n = summary.minutesByDay.length;
    final rows = ((offset + n) / 7).ceil();
    final prevDays = daysInMonth(y, m - 1);
    final todayKey = dayKey(widget.now);

    return LayoutBuilder(builder: (context, c) {
      final colW = c.maxWidth / 7;
      final rowH = (c.maxHeight - headerHeight * s) / rows;
      final line = Palette.navy.withValues(alpha: 0.8);

      final cells = <Widget>[];
      for (var i = 0; i < rows * 7; i++) {
        final day = i - offset + 1;
        final left = (i % 7) * colW, top = headerHeight * s + (i ~/ 7) * rowH;
        final inMonth = day >= 1 && day <= n;
        Widget cell;
        if (!inMonth) {
          final shown = day < 1 ? prevDays + day : day - n;
          cell = ExcludeSemantics(
            child: Stack(children: [
              _DayNumber(day: shown, s: s, color: Palette.navy.withValues(alpha: 0.3)),
            ]),
          );
        } else {
          final date = DateTime(y, m, day);
          final minutes = summary.minutesByDay[day - 1];
          final today = dayKey(date) == todayKey;
          final color = _Grid.tint(minutes, today);
          final hours = fmtCell(minutes);
          cell = Pressable(
            semanticLabel: Str.dayHours(Str.fullDate(date), hours.isEmpty ? '' : fmtHours(minutes)),
            focusRadius: 8.5 * s,
            onTap: () => onDayTap(date),
            child: Stack(children: [
              if (color != null)
                Positioned.fill(
                  child: ScaleTransition(
                    scale: _wave(i),
                    child: AnimatedContainer(
                      duration: Motion.standard,
                      curve: Motion.ease,
                      margin: EdgeInsets.all(3 * s),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8.5 * s),
                      ),
                    ),
                  ),
                ),
              _DayNumber(day: day, s: s, color: Palette.navyDeep),
              if (hours.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 44 * s,
                  child: Text(
                    hours,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: (hours.length > 5 ? 30 : 34) * s,
                      color: today ? Palette.navyText : Palette.navyDeep,
                      height: 1,
                    ),
                  ),
                ),
            ]),
          );
        }
        cells.add(Positioned(left: left, top: top, width: colW, height: rowH, child: cell));
      }

      return Stack(children: [
        Positioned.fill(
          child:
              CustomPaint(painter: _GridPainter(rows: rows, header: headerHeight * s, color: line, stroke: 2.2 * s)),
        ),
        for (var i = 0; i < 7; i++)
          Positioned(
            left: i * colW,
            top: 0,
            width: colW,
            height: headerHeight * s,
            child: Center(child: Text(Str.weekdaysShort[i], style: outfit(22 * s, weight: 600))),
          ),
        ...cells,
      ]);
    });
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({required this.day, required this.s, required this.color});

  final int day;
  final double s;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 15 * s,
      top: 13 * s,
      child: Text('$day', style: outfit(26 * s, weight: 600, color: color)),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.rows, required this.header, required this.color, required this.stroke});

  final int rows;
  final double header;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    final colW = size.width / 7;
    final rowH = (size.height - header) / rows;
    canvas.drawRect(Offset.zero & size, p);
    canvas.drawLine(Offset(0, header), Offset(size.width, header), p);
    for (var r = 1; r < rows; r++) {
      final y = header + r * rowH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (var c = 1; c < 7; c++) {
      canvas.drawLine(Offset(c * colW, 0), Offset(c * colW, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.rows != rows || old.header != header || old.color != color || old.stroke != stroke;
}
