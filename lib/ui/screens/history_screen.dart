import 'package:flutter/material.dart';

import '../../logic/time_math.dart';
import '../../models/goals.dart';
import '../../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/title_header.dart';

/// Every clock-in of a month, by goal: for each day, the exact times of
/// entry and exit (or a timer's start and end) and the day's total. Opened
/// from Profile; read only. Unlike the design-canvas screens it is a plain
/// scrolling list, so it follows the phone's text size all the way.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  AppState get state => widget.state;
  late String _goalId = state.home.id;
  late DateTime _month = DateTime(state.now.year, state.now.month);

  void _changeMonth(int d) => setState(() => _month = DateTime(_month.year, _month.month + d));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Backdrop(
        child: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final goal = state.goal(_goalId);
              final sum = state.summary(goal.id, _month);
              final total = fmtHours(sum.total);
              return CustomScrollView(slivers: [
                SliverToBoxAdapter(child: _Header(onBack: () => Navigator.of(context).maybePop())),
                SliverToBoxAdapter(
                  child: _GoalPicker(
                    goals: state.goals,
                    selected: goal.id,
                    onPick: (id) => setState(() => _goalId = id),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    // On the cream card, not the busy background: readable.
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: Palette.cream.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12.8),
                    ),
                    child: Row(children: [
                      _Arrow(icon: Icons.chevron_left, label: Str.prevMonth, onTap: () => _changeMonth(-1)),
                      Expanded(
                        child: Column(children: [
                          Text(
                            Str.monthYear(_month.year, _month.month).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Palette.ink),
                          ),
                          Text(
                            Str.ofGoal(total.isEmpty ? '0h' : total, fmtHours(sum.goalMinutes)),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Palette.ink),
                          ),
                        ]),
                      ),
                      _Arrow(icon: Icons.chevron_right, label: Str.nextMonth, onTap: () => _changeMonth(1)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
                  sliver: SliverToBoxAdapter(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Palette.cream.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12.8),
                      ),
                      child: Column(children: [
                        for (var day = 1; day <= sum.minutesByDay.length; day++) ...[
                          if (day > 1)
                            const Divider(height: 1, thickness: 1, indent: 14, endIndent: 14, color: Color(0x1A32466C)),
                          _DayRow(
                            date: DateTime(_month.year, _month.month, day),
                            minutes: sum.minutesByDay[day - 1],
                            spans: _spans(goal, DateTime(_month.year, _month.month, day)),
                            today: _isToday(day),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  bool _isToday(int day) {
    final n = state.now;
    return n.year == _month.year && n.month == _month.month && n.day == day;
  }

  /// The day's entries and exits, oldest first, with whatever is still
  /// running (a clock-in or a timer) ending "now", and hours typed by hand.
  List<String> _spans(Goal goal, DateTime date) {
    final key = dayKey(date);
    final entry = goal.hours.days[key];
    final out = <String>[
      for (final s in [...?entry?.sessions]..sort((a, b) => a.start.compareTo(b.start)))
        '${clockTime(s.start)}–${clockTime(s.end)}',
    ];
    for (final since in [goal.hours.openSince, goal.timer?.runningSince]) {
      if (since != null && dayKeyOf(since) == key) out.add('${clockTime(since)}–${Str.now}');
    }
    final manual = entry?.manualMinutes ?? 0;
    if (manual > 0) out.add(Str.byHand(fmtHours(manual.toDouble())));
    return out;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth / 314;
      return SizedBox(
        height: TitleHeader.maxLogo * s,
        child: Stack(children: [
          // The title with the logo, as on the other screens.
          // Clear of the back button.
          Positioned.fill(
            left: 48,
            right: 8,
            child: FittedBox(
              alignment: Alignment.topCenter,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: TitleHeader(text: Str.history.toUpperCase(), color: Palette.butter),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Pressable(
                onTap: onBack,
                semanticLabel: Str.back,
                focusRadius: 22,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  // Straight on the background, which is dark here and there.
                  child: Icon(Icons.arrow_back_ios_new, color: Palette.cream, size: 22),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

/// One chip per goal, in the goal's colour; the chosen one is outlined.
class _GoalPicker extends StatelessWidget {
  const _GoalPicker({required this.goals, required this.selected, required this.onPick});

  final List<Goal> goals;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Pressable(
              onTap: () => onPick(g.id),
              selected: g.id == selected,
              semanticLabel: Str.goalOption(g.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: g.color.color.withValues(alpha: g.id == selected ? 1 : 0.6),
                  borderRadius: BorderRadius.circular(12.8),
                  border: Border.all(color: g.id == selected ? Palette.ink : Colors.transparent, width: 2),
                ),
                child: Text(
                  g.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: g.id == selected ? FontWeight.w700 : FontWeight.w600,
                    color: Palette.ink,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.date, required this.minutes, required this.spans, required this.today});

  final DateTime date;
  final double minutes;
  final List<String> spans;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final hours = fmtHours(minutes);
    const ink = Palette.ink;
    return Semantics(
      container: true,
      label: [Str.fullDate(date), if (hours.isNotEmpty) hours, ...spans].join(', '),
      excludeSemantics: true,
      child: Container(
        color: today ? Palette.rose.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 34,
            child: Text(Str.weekdaysShort[date.weekday - 1], style: const TextStyle(fontSize: 13, color: ink)),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '${date.day}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
            ),
          ),
          Expanded(
            child: spans.isEmpty
                ? const SizedBox()
                : Text(
                    spans.join('  ·  '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Palette.ink,
                      height: 1.35,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
          if (hours.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                hours,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Palette.ink),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: label,
        focusRadius: 22,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Palette.ink, size: 28)),
      );
}
