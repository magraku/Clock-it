import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/time_math.dart';
import '../../models/goals.dart';
import '../../state/app_state.dart';
import '../sheets.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hourglass.dart';
import '../widgets/nav_bar.dart';
import '../widgets/wallpaper.dart';
import '../widgets/title_header.dart';

/// Design points (314 wide), 11 pt less than the artboard at the top.
const _width = 314.0;
const _presets = [15, 20, 30];
const _box = Rect.fromLTWH(25.1, 260.1, 271.5, 258);

/// A goal's screen ("STUDY HOURS"): title, focus timer presets, and a box
/// with the month's hours, or the hourglass once a time is picked. The
/// hourglass waits for Start, then turns over and the sand begins to fall.
class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key, required this.state, required this.goalId});

  final AppState state;
  final String goalId;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  /// Minutes picked but not started yet.
  int? _picked;
  late DateTime _month = DateTime(widget.state.now.year, widget.state.now.month);

  AppState get state => widget.state;

  void _pick(Goal goal, int minutes) {
    if (goal.timer != null) return; // one countdown at a time; Stop first
    HapticFeedback.selectionClick();
    setState(() => _picked = _picked == minutes ? null : minutes);
  }

  Future<void> _edit(Goal goal) async {
    await showGoalEditor(context, state, goal: goal);
    // Deleted from here: back to the list.
    if (mounted && state.data.byId(goal.id) == null) Navigator.of(context).maybePop();
  }

  void _startOrStop(Goal goal) {
    HapticFeedback.mediumImpact();
    final t = goal.timer;
    if (t == null) {
      state.startTimer(goal.id, _picked!);
    } else if (!t.running) {
      state.resumeTimer(goal.id);
    } else {
      state.stopTimer(goal.id);
    }
    setState(() => _picked = null);
  }

  @override
  Widget build(BuildContext context) {
    // The chosen wallpaper (Profile → Wallpaper) sits behind the timers.
    return ListenableBuilder(
      listenable: state,
      builder: (context, child) => WallpaperBackdrop(style: state.wallpaper, child: child!),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: NavBar.heightOf(context)),
          child: DesignCanvas(
            size: const Size(_width, 540),
            alignment: Alignment.topCenter,
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) {
                final goal = state.goal(widget.goalId);
                final timer = goal.timer;
                final showGlass = timer != null || _picked != null;
                return Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: TitleHeader(
                      text: goal.name.toUpperCase(),
                      color: goal.color.color,
                      onEdit: () => _edit(goal),
                    ),
                  ),
                  Positioned(
                    left: 25.1,
                    top: 124.8,
                    width: 271.5,
                    height: 120.9,
                    child: _Cronometer(
                      goal: goal,
                      selected: timer != null ? timer.totalMs ~/ 60000 : _picked,
                      onPick: (m) => _pick(goal, m),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: _box,
                    child: Container(
                      decoration: BoxDecoration(
                        color: goal.color.accent.withValues(alpha: Surface.alpha),
                        boxShadow: Surface.shadow,
                        borderRadius: BorderRadius.circular(12.8),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: showGlass
                            ? _GlassView(
                                key: const ValueKey('glass'),
                                state: state,
                                goal: goal,
                                picked: _picked,
                                onClose: () => setState(() => _picked = null),
                              )
                            : _MonthView(
                                key: const ValueKey('month'),
                                state: state,
                                goal: goal,
                                month: _month,
                                onChangeMonth: (d) => setState(() => _month = DateTime(_month.year, _month.month + d)),
                              ),
                      ),
                    ),
                  ),
                  if (showGlass)
                    Positioned(
                      left: _box.center.dx - 75,
                      top: _box.bottom - 17,
                      width: 150,
                      height: 34,
                      child: _BoxButton(
                        // While it runs, the time left shows on the button.
                        label: timer?.running ?? false
                            ? '${Str.stop} · ${_mmss(timer!.remainingMs(state.now.millisecondsSinceEpoch))}'
                            : Str.start,
                        semanticLabel: timer?.running ?? false ? Str.stop : Str.start,
                        color: timer?.running ?? false ? Palette.plum : Palette.turquoise,
                        onTap: () => _startOrStop(goal),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Cronometer extends StatelessWidget {
  const _Cronometer({required this.goal, required this.selected, required this.onPick});

  final Goal goal;
  final int? selected;
  final ValueChanged<int> onPick;

  // Chips grow left to right, as in the design.
  static const _chips = [
    Rect.fromLTWH(8.8, 62.2, 75.5, 47),
    Rect.fromLTWH(94, 53.1, 79, 56.9),
    Rect.fromLTWH(180.9, 42.7, 79, 67.3),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: goal.color.color.withValues(alpha: Surface.alpha),
        boxShadow: Surface.shadow,
        borderRadius: BorderRadius.circular(12.8),
      ),
      child: Stack(children: [
        Positioned(
          left: 11,
          top: 15,
          right: 11,
          child: Text(
            Str.timer,
            maxLines: 1,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Palette.ink, height: 1),
          ),
        ),
        for (var i = 0; i < _presets.length; i++)
          Positioned.fromRect(
            rect: _chips[i],
            child: _Chip(
              minutes: _presets[i],
              color: goal.color.accent,
              selected: selected == _presets[i],
              onTap: () => onPick(_presets[i]),
            ),
          ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.minutes, required this.color, required this.selected, required this.onTap});

  final int minutes;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: Str.minutesLong(minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 1 : 0.8),
          borderRadius: BorderRadius.circular(12.8),
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 9),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Str.minutesChip(minutes),
            maxLines: 1,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Palette.ink, height: 1),
          ),
        ),
      ),
    );
  }
}

/// The hourglass, waiting for Start or running, with the styles to choose
/// from beside it.
class _GlassView extends StatelessWidget {
  const _GlassView({super.key, required this.state, required this.goal, required this.picked, required this.onClose});

  final AppState state;
  final Goal goal;
  final int? picked;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = goal.timer;
    final String label;
    if (t == null) {
      label = Str.readyToStart(picked ?? 0);
    } else {
      final left = Duration(milliseconds: t.remainingMs(state.now.millisecondsSinceEpoch));
      label = Str.timerSemantics('${left.inMinutes} min ${left.inSeconds % 60} s');
    }
    final sand = goal.color == GoalColor.yellow ? Palette.inkDeep : goal.color.color;
    return Stack(children: [
      Positioned(
        left: 0,
        right: 52,
        top: 16,
        bottom: 26,
        child: Semantics(
          label: label,
          child: Center(
            child: Hourglass(
              style: state.hourglass,
              sand: sand,
              progress: () => t?.progress(state.now.millisecondsSinceEpoch) ?? 0,
              running: t?.running ?? false,
              ready: t == null,
            ),
          ),
        ),
      ),
      // The styles, as small samples down the right side.
      Positioned(
        right: 10,
        top: t == null ? 40 : 14,
        bottom: 26,
        width: 38,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final style in HourglassStyle.values)
              _StyleOption(
                style: style,
                sand: sand,
                selected: style == state.hourglass,
                onTap: () => state.setHourglass(style),
              ),
          ],
        ),
      ),
      if (t == null)
        Positioned(
          right: 6,
          top: 6,
          child: Pressable(
            onTap: onClose,
            semanticLabel: Str.closeTimer,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.close, size: 22, color: Palette.ink),
            ),
          ),
        ),
    ]);
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({required this.style, required this.sand, required this.selected, required this.onTap});

  final HourglassStyle style;
  final Color sand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      focusRadius: 8,
      semanticLabel: Str.hourglassStyle(Str.hourglassNames[style.index]),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 44,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.75 : 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Palette.ink : Colors.transparent, width: 1.5),
        ),
        child: HourglassSwatch(style: style, sand: sand),
      ),
    );
  }
}

/// The goal's month, read only: each day's hours, which come from the
/// focus timers. Swipe or use the arrows to see other months.
class _MonthView extends StatelessWidget {
  const _MonthView({
    super.key,
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
                      style:
                          const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Palette.ink, height: 1.1),
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
      label: Str.dayHours(Str.fullDate(DateTime(month.year, month.month, day)), minutes > 0 ? fmtHours(minutes) : ''),
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
        decoration: BoxDecoration(
          color: minutes > 0 ? goal.color.color.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.35),
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
                    style:
                        const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Palette.inkDeep, height: 1)),
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

String _mmss(int ms) {
  final d = Duration(milliseconds: ms);
  return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _BoxButton extends StatelessWidget {
  const _BoxButton({required this.label, required this.color, required this.onTap, this.semanticLabel});

  final String label;
  final String? semanticLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.8),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: onColor(color),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
