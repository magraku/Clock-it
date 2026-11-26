import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/time_math.dart';
import '../../models/goals.dart';
import '../../state/app_state.dart';
import '../sheets.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/focus_timer_panel.dart';
import '../widgets/focus_mode_sheet.dart';
import '../widgets/nav_bar.dart';
import '../widgets/wallpaper.dart';
import '../widgets/title_header.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key, required this.state, required this.goalId});
  final AppState state;
  final String goalId;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  int _picked = 15;
  late DateTime _month = DateTime(widget.state.now.year, widget.state.now.month);
  AppState get state => widget.state;

  Future<void> _edit(Goal goal) async {
    await showGoalEditor(context, state, goal: goal);
    if (mounted && state.data.byId(goal.id) == null) Navigator.of(context).maybePop();
  }

  void _toggle(Goal goal) {
    HapticFeedback.mediumImpact();
    final timer = goal.timer;
    if (timer == null) {
      state.startTimer(goal.id, _picked);
    } else if (timer.running) {
      state.pauseTimer(goal.id);
    } else {
      state.resumeTimer(goal.id);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final goal = state.goal(widget.goalId);
          return WallpaperBackdrop(
            style: state.wallpaper,
            child: ColoredBox(
                color: Palette.ink.withValues(alpha: 0.65),
                child: SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, NavBar.heightOf(context) + 24),
                      child: Center(
                          child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Center(
                              child: TitleHeader(
                                  text: goal.name.toUpperCase(),
                                  color: goal.color.color,
                                  width: MediaQuery.sizeOf(context).width.clamp(0, 440) - 40,
                                  onEdit: () => _edit(goal))),
                          FocusTimerPanel(
                              state: state,
                              goal: goal,
                              minutes: _picked,
                              onPick: (m) {
                                HapticFeedback.selectionClick();
                                setState(() => _picked = m);
                              },
                              onToggle: () => _toggle(goal),
                              onStop: () => state.stopTimer(goal.id),
                              onMoon: () => showFocusModeSheet(context, state)),
                          const SizedBox(height: 24),
                          ExpansionTile(
                            title: Text(Str.focusCalendar,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            textColor: Palette.ink,
                            collapsedTextColor: Palette.ink,
                            iconColor: Palette.ink,
                            collapsedIconColor: Palette.ink,
                            backgroundColor: Palette.cream,
                            collapsedBackgroundColor: Palette.cream,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            children: [
                              SizedBox(
                                  height: 260,
                                  child: _MonthView(
                                    state: state,
                                    goal: goal,
                                    month: _month,
                                    onChangeMonth: (d) =>
                                        setState(() => _month = DateTime(_month.year, _month.month + d)),
                                  ))
                            ],
                          ),
                        ]),
                      )),
                    ))),
          );
        },
      );
}

/// The goal's month, read only: each day's hours, which come from the
/// focus timers. Swipe or use the arrows to see other months.
class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.state,
    required this.goal,
    required this.month,
    required this.onChangeMonth,
  });

  final AppState state;
  final Goal goal;
  final DateTime month;
  final ValueChanged<int> onChangeMonth;

  @override
  Widget build(BuildContext context) {
    final sum = state.summary(goal.id, month);
    final now = state.now;
    String h(double m) => fmtHours(m).isEmpty ? '0h' : fmtHours(m);
    final first = DateTime(month.year, month.month);
    final lead = first.weekday - 1;
    final days = sum.minutesByDay.length;
    final rows = ((lead + days) / 7).ceil();

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() > 250) onChangeMonth(v < 0 ? 1 : -1);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(children: [
          SizedBox(
            height: 34,
            child: Row(children: [
              _Arrow(icon: Icons.chevron_left, label: Str.prevMonth, onTap: () => onChangeMonth(-1)),
              Expanded(
                child: ShrinkToFit(
                  alignment: Alignment.center,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      Str.monthYear(month.year, month.month).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Palette.ink, height: 1.1),
                    ),
                    Text(
                      Str.ofGoal(h(sum.total), fmtHours(sum.goalMinutes)),
                      style: const TextStyle(fontSize: 12, color: Palette.ink, height: 1.2),
                    ),
                  ]),
                ),
              ),
              _Arrow(icon: Icons.chevron_right, label: Str.nextMonth, onTap: () => onChangeMonth(1)),
            ]),
          ),
          const SizedBox(height: 4),
          Row(children: [
            for (final w in Str.weekdaysShort)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(w,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Palette.ink)),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Expanded(
            child: Column(children: [
              for (var r = 0; r < rows; r++)
                Expanded(
                  child: Row(children: [
                    for (var c = 0; c < 7; c++) Expanded(child: _cell(r * 7 + c - lead + 1, days, sum, now)),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _cell(int day, int days, MonthSummary sum, DateTime now) {
    if (day < 1 || day > days) return const SizedBox();
    final minutes = sum.minutesByDay[day - 1];
    final hours = fmtCell(minutes);
    final today = now.year == month.year && now.month == month.month && now.day == day;
    return Semantics(
      container: true,
      label: Str.dayHours(
          Str.fullDate(DateTime(month.year, month.month, day)), minutes > 0 ? fmtHours(minutes) : ''),
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
        decoration: BoxDecoration(
          color:
              minutes > 0 ? goal.color.color.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(5),
          border: today ? Border.all(color: Palette.ink, width: 1.4) : null,
        ),
        child: Stack(children: [
          Align(
            alignment: Alignment.topLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$day', style: const TextStyle(fontSize: 11, color: Palette.ink, height: 1)),
            ),
          ),
          if (hours.isNotEmpty)
            Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(hours,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Palette.inkDeep, height: 1)),
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
        child: SizedBox(width: 34, height: 34, child: Icon(icon, color: Palette.ink, size: 24)),
      );
}
