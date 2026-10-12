import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/time_math.dart';
import '../../state/app_state.dart';
import '../../state/session.dart';
import '../sheets.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/calendar_sheet.dart';
import '../widgets/common.dart';
import 'intro_screens.dart';

/// Artboard of the main screen, in points (design's third screen).
const _homeSize = Size(292.6, 604);
const _contentWidth = 269.3;
const _contentLeft = (292.6 - _contentWidth) / 2;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services, required this.state});

  final Services services;

  /// The signed-in account's hours; this screen closes it when it goes away.
  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.dispose();
    super.dispose();
  }

  void _toWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(WelcomeScreen(services: widget.services)),
      (_) => false,
    );
  }

  Future<void> _logOut() async {
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        content: const Text(Str.logOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(Str.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text(Str.logOut)),
        ],
      ),
    );
    if (ok != true) return;
    await widget.services.accounts.logOut();
    if (mounted) _toWelcome();
  }

  Future<void> _deleteAccount() async {
    if (await showDeleteAccountSheet(context, widget.services.accounts) && mounted) _toWelcome();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) state.refresh();
  }

  void _punch() {
    HapticFeedback.mediumImpact();
    state.punch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Backdrop(
        image: Assets.bgMain,
        child: SafeArea(
          child: DesignCanvas(
            size: _homeSize,
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) {
                final summary = state.summary;
                return Stack(children: [
                  Positioned(
                    left: _contentLeft,
                    top: 10,
                    width: _contentWidth,
                    height: 53.4,
                    child: _PunchButton(state: state, onTap: _punch),
                  ),
                  Positioned(
                    left: _contentLeft,
                    top: 73.8,
                    width: _contentWidth,
                    height: 104.8,
                    child: _HoursLeftCard(summary: summary),
                  ),
                  Positioned(
                    left: (292.6 - 278.8) / 2,
                    top: 185.4,
                    width: 278.8,
                    height: 414.8,
                    child: CalendarSheet(
                      state: state,
                      summary: summary,
                      onDayTap: (date) => showDaySheet(context, state, date),
                      onGoalTap: () => showGoalSheet(context, state),
                      onMenuTap: () => showMenuSheet(
                        context,
                        state,
                        onLogOut: _logOut,
                        onDeleteAccount: _deleteAccount,
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

class _PunchButton extends StatelessWidget {
  const _PunchButton({required this.state, required this.onTap});

  final AppState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = state.data.openSince;
    if (open == null) {
      return DesignButton(
        label: Str.markEntry,
        color: Palette.green.withValues(alpha: 0.8),
        radius: 12.8,
        fontWeight: FontWeight.w600,
        onTap: onTap,
      );
    }
    final elapsed = state.now.difference(DateTime.fromMillisecondsSinceEpoch(open));
    return DesignButton(
      label: Str.markExit,
      color: Palette.pink.withValues(alpha: 0.85),
      radius: 12.8,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      subtitle: Str.inSince(clockTime(open), stopwatch(elapsed)),
      onTap: onTap,
    );
  }
}

class _HoursLeftCard extends StatelessWidget {
  const _HoursLeftCard({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.yellow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12.8),
      ),
      child: Stack(children: [
        const Positioned(
          left: 11.9,
          top: 11.1,
          child: Text(
            Str.hoursLeft,
            style: TextStyle(fontSize: 15, color: Palette.navyText, height: 1),
          ),
        ),
        Positioned(
          left: 7.7,
          top: 30.4,
          right: 8,
          child: Text(
            summary.goalReached ? Str.goalReached : fmtHours(summary.remaining),
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
        Positioned(
          left: 6.5,
          right: 6.5,
          top: 70.3,
          height: 28,
          child: _ProgressBar(summary: summary),
        ),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.summary});

  final MonthSummary summary;

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
          TweenAnimationBuilder<double>(
            tween: Tween(end: summary.progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, p, __) => Container(
              width: p == 0 ? 0 : (c.maxWidth * p).clamp(radius * 2, c.maxWidth),
              decoration: BoxDecoration(
                color: Palette.green.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(children: [
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: summary.progress >= 0.14 ? Colors.white : Palette.navy,
                ),
              ),
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
