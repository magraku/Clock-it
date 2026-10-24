import 'package:flutter/material.dart';

import '../../models/goals.dart';
import '../../state/app_state.dart';
import '../../state/session.dart';
import '../motion.dart';
import '../sheets.dart';
import '../strings.dart';
import '../widgets/nav_bar.dart';
import 'calendar_screen.dart';
import 'goal_screen.dart';
import 'goals_screen.dart';
import 'intro_screens.dart';
import 'profile_screen.dart';

/// The signed-in app: Goals, Home and Profile with the bottom bar always
/// visible. Goals keeps its own stack (goal → its calendar) under the bar.
/// Switching tabs fades the new one in with a slight rise.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.services, required this.state});

  final Services services;

  /// The signed-in account's goals; this screen closes it when it goes away.
  final AppState state;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  AppState get state => widget.state;
  AppTab _tab = AppTab.home;
  final _goalsNav = GlobalKey<NavigatorState>();
  late final _switch = AnimationController(vsync: this, duration: Motion.standard, value: 1);
  late final _switchCurve = CurvedAnimation(parent: _switch, curve: Motion.enter);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _switch.dispose();
    state.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) state.refresh();
  }

  void _select(AppTab tab) {
    // Tapping Goals again goes back to the list.
    if (tab == _tab && tab == AppTab.goals) {
      _goalsNav.currentState?.popUntil((r) => r.isFirst);
    }
    if (tab != _tab && !Motion.reduced(context)) _switch.forward(from: 0);
    setState(() => _tab = tab);
  }

  /// The Home goal (the house on its card) lives on the Home tab; any other
  /// goal opens its own screen, with timers and its month.
  void _openGoal(Goal goal) {
    if (goal.id == state.home.id) {
      _select(AppTab.home);
      return;
    }
    _goalsNav.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => GoalScreen(state: state, goalId: goal.id),
    ));
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
        content: Text(Str.logOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(Str.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(Str.logOut)),
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

  Widget _page(AppTab tab, Widget child) => TickerMode(
        // Only the visible tab animates (the floating goals, the hourglass).
        enabled: _tab == tab,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _switchCurve,
            builder: (_, child) => Opacity(
              opacity: _switchCurve.value.clamp(0, 1),
              child: Transform.translate(offset: Offset(0, 10 * (1 - _switchCurve.value)), child: child),
            ),
            child: IndexedStack(
              index: _tab.index,
              children: [
                _page(
                  AppTab.goals,
                  NavigatorPopHandler(
                    onPopWithResult: (_) => _goalsNav.currentState?.maybePop(),
                    enabled: _tab == AppTab.goals,
                    child: Navigator(
                      key: _goalsNav,
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => GoalsScreen(state: state, onOpenGoal: _openGoal),
                      ),
                    ),
                  ),
                ),
                _page(AppTab.home, CalendarScreen(state: state)),
                _page(
                  AppTab.profile,
                  ProfileScreen(state: state, onLogOut: _logOut, onDeleteAccount: _deleteAccount),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: NavBar(current: _tab, onTap: _select),
        ),
      ]),
    );
  }
}
