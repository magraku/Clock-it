import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/time_math.dart';
import '../../models/goals.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../sheets.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/calendar_sheet.dart';
import '../widgets/common.dart';
import '../widgets/nav_bar.dart';

/// Main screen of the design, in points: 314 wide like the artboard, down
/// to the bottom of the calendar (12 pt less at the top, for the status bar).
const _size = Size(314, 612);
const _contentWidth = 269.3;
const _contentLeft = (314 - _contentWidth) / 2;

/// Mark entry, hours left and the wall calendar of one goal. The Home tab
/// shows the Home goal ([goalId] null); other goals open it from their screen.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.state, this.goalId});

  final AppState state;
  final String? goalId;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  AppState get state => widget.state;
  Goal get goal => widget.goalId == null ? state.home : state.goal(widget.goalId!);

  late DateTime _month = DateTime(state.now.year, state.now.month);

  void _changeMonth(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _today() => setState(() => _month = DateTime(state.now.year, state.now.month));

  void _punch() {
    HapticFeedback.mediumImpact();
    state.punch(goal.id);
  }

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      image: Assets.bgMain,
      child: SafeArea(
        bottom: false,
        child: Padding(
          // The whole calendar stays above the bar, so no day is hidden.
          padding: EdgeInsets.only(bottom: NavBar.heightOf(context)),
          child: DesignCanvas(
            size: _size,
            alignment: Alignment.topCenter,
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) {
                final g = goal;
                final summary = state.summary(g.id, _month);
                return Stack(children: [
                  Positioned(
                    left: _contentLeft,
                    top: 6,
                    width: _contentWidth,
                    height: 70,
                    child: Entrance(child: _PunchButton(state: state, goal: g, onTap: _punch)),
                  ),
                  Positioned(
                    left: _contentLeft,
                    top: 84,
                    width: _contentWidth,
                    height: 104.8,
                    child: Entrance(
                      delay: const Duration(milliseconds: 70),
                      child: _HoursLeftCard(
                        summary: summary,
                        label: g.id == state.home.id ? Str.hoursLeft : Str.hoursLeftFor(g.name),
                        live: g.hours.openSince != null,
                      ),
                    ),
                  ),
                  Positioned(
                    left: (314 - 278.8) / 2,
                    top: 195,
                    width: 278.8,
                    height: 414.8,
                    child: Entrance(
                      delay: const Duration(milliseconds: 140),
                      offset: 22,
                      child: CalendarSheet(
                        now: state.now,
                        summary: summary,
                        onChangeMonth: _changeMonth,
                        onToday: _today,
                        onDayTap: (date) => showDaySheet(context, state, g.id, date),
                        onGoalTap: () => showGoalSheet(context, state, g.id, _month),
                        onMenuTap: () => showMenuSheet(context, state, g.id, month: _month, onToday: _today),
                      ),
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

/// Mark entry / Mark exit: big, with what's happening underneath. While in,
/// it turns dark red and shows the entry time and a running stopwatch
/// ("Entered at 13:44 · 00:56:56"), like the design's reference.
class _PunchButton extends StatelessWidget {
  const _PunchButton({required this.state, required this.goal, required this.onTap});

  final AppState state;
  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = goal.hours.openSince;
    final inside = open != null;
    final String title, detail;
    if (inside) {
      title = Str.markExit;
      detail = Str.inSince(clockTime(open), stopwatch(state.now.difference(DateTime.fromMillisecondsSinceEpoch(open))));
    } else {
      final today = fmtHours(state.minutesSince(goal.id, state.now));
      title = Str.markEntry;
      detail = Str.todaySoFar(today.isEmpty ? '0h' : today);
    }
    // Dark red under white text (5.4:1); green under navy (4.7:1).
    final color = inside ? Palette.coral : Palette.green;
    final ink = onColor(color);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $detail',
      child: AnimatedContainer(
        duration: Motion.standard,
        curve: Motion.ease,
        decoration: BoxDecoration(
          color: color.withValues(alpha: inside ? 1 : 0.85),
          borderRadius: BorderRadius.circular(12.8),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ShrinkToFit(
          alignment: Alignment.center,
          // A new title rolls up into place; the old one drops away.
          child: AnimatedSwitcher(
            duration: Motion.standard,
            reverseDuration: Motion.quick,
            switchInCurve: Motion.enter,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
            child: Column(key: ValueKey(inside), mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (inside) ...[_LiveDot(color: ink), const SizedBox(width: 9)],
                Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: ink, height: 1.1),
                ),
              ]),
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: ink,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Breathing dot beside "Mark exit": the clock is running.
class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Loop(
      active: true,
      period: const Duration(milliseconds: 1600),
      builder: (_, t) {
        final p = Loop.pulse(t);
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.65 + 0.35 * p),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45 * p), blurRadius: 2 + 6 * p, spreadRadius: 3 * p)],
          ),
        );
      },
    );
  }
}

class _HoursLeftCard extends StatelessWidget {
  const _HoursLeftCard({required this.summary, required this.label, required this.live});

  final MonthSummary summary;
  final String label;

  /// A session is running: the bar shimmers.
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.yellow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12.8),
      ),
      child: Stack(children: [
        Positioned(
          left: 11.9,
          top: 11.1,
          right: 10,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: Palette.navyText, height: 1),
          ),
        ),
        Positioned(
          left: 7.7,
          top: 30.4,
          right: 8,
          // The number counts toward its new value; reaching the goal pops in.
          child: AnimatedSwitcher(
            duration: Motion.slow,
            switchInCurve: Motion.pop,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(a), alignment: Alignment.centerLeft, child: child),
            ),
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.centerLeft, children: [...previous, if (current != null) current]),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(summary.goalReached),
              tween: Tween(end: summary.remaining),
              duration: Motion.slow,
              curve: Motion.ease,
              builder: (_, minutes, __) => Text(
                summary.goalReached ? Str.goalReached : fmtHours(minutes),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 37,
                  fontWeight: FontWeight.w700,
                  color: Palette.navy,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 6.5,
          right: 6.5,
          top: 70.3,
          height: 28,
          child: _ProgressBar(summary: summary, live: live),
        ),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.summary, required this.live});

  final MonthSummary summary;
  final bool live;

  @override
  Widget build(BuildContext context) {
    const radius = 8.6;
    final pct = (summary.progress * 100).floor();
    final done = fmtHours(summary.total);
    final goal = fmtHours(summary.goalMinutes);
    return Semantics(
      label: Str.ofGoal(done.isEmpty ? '0h' : done, goal),
      value: '$pct%',
      child: LayoutBuilder(builder: (context, c) {
        return Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.track.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          // Fills from empty on arrival; the percentage counts along with it.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: summary.progress),
            duration: const Duration(milliseconds: 900),
            curve: Motion.ease,
            builder: (_, p, __) => Stack(children: [
              Container(
                width: p == 0 ? 0 : (c.maxWidth * p).clamp(radius * 2, c.maxWidth),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Palette.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: _Sheen(active: live),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${(p * 100).floor()}%',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Palette.navy,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(children: [
              const Spacer(),
              Text(
                Str.ofGoal(done.isEmpty ? '0h' : done, goal),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Palette.navy,
                ),
              ),
            ]),
          ),
        ]);
      }),
    );
  }
}

/// Soft highlight sweeping across the bar while hours are being counted.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Loop(
      active: active,
      period: const Duration(milliseconds: 2200),
      builder: (_, t) {
        if (!active) return const SizedBox.expand();
        final x = -1.6 + 3.2 * Motion.ease.transform(t);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(x - 0.6, 0),
              end: Alignment(x + 0.6, 0),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
