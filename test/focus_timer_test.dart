import 'package:clock_it/data/focus_mode.dart';
import 'package:clock_it/models/goals.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:clock_it/ui/screens/goal_screen.dart';
import 'package:clock_it/ui/strings.dart';
import 'package:clock_it/ui/theme.dart';
import 'package:clock_it/ui/widgets/hourglass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/fonts.dart';

class ConfigurableFocusMode extends NoFocusMode {
  bool enabled = false;
  @override
  Future<FocusModeStatus> status() async =>
      FocusModeStatus(supported: true, granted: true, exact: true, enabled: enabled);
  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }
}

void main() {
  setUpAll(loadAppFonts);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('10-minute hourglass starts, pauses, resumes, and saves only focus time', (tester) async {
    var now = DateTime(2026, 11, 19, 12);
    final state = AppState(MemoryStore({}, 'u'), clock: () => now);
    await state.load();
    addTearDown(state.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        MaterialApp(theme: buildTheme(), home: Scaffold(body: GoalScreen(state: state, goalId: 'sfp'))));
    await settle(tester);
    await tester.tap(find.text(Str.minutesChip(10)));
    await settle(tester);
    expect(find.text('10:00'), findsOneWidget);
    await tester.tap(find.byType(Hourglass));
    await settle(tester);
    expect(state.timerOf('sfp')!.running, isTrue);
    expect(find.text(Str.focusRunning), findsOneWidget);
    now = now.add(const Duration(minutes: 2));
    state.refresh();
    await settle(tester);
    expect(find.text('08:00'), findsOneWidget);
    await tester.tap(find.byType(Hourglass));
    await settle(tester);
    expect(find.text(Str.resume), findsOneWidget);
    expect(state.timerOf('sfp')!.running, isFalse);
    now = now.add(const Duration(minutes: 3));
    state.refresh();
    await settle(tester);
    expect(find.text('08:00'), findsOneWidget);
    await tester.tap(find.text(Str.resume));
    now = now.add(const Duration(minutes: 1));
    state.refresh();
    await settle(tester);
    await tester.tap(find.byTooltip(Str.stop));
    await settle(tester);
    expect(state.timerOf('sfp'), isNull);
    expect(state.summary('sfp', now).total, 3);
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('small screen and large Spanish text scroll without overflow, including moon setup',
      (tester) async {
    Str.useLocale(const Locale('es'));
    addTearDown(() => Str.useLocale(const Locale('en')));
    final mode = ConfigurableFocusMode();
    final state = AppState(MemoryStore({}, 'u'), focusMode: mode);
    await state.load();
    addTearDown(state.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 568), textScaler: TextScaler.linear(1.3), disableAnimations: true),
            child: Scaffold(body: GoalScreen(state: state, goalId: 'sfp')))));
    await settle(tester);
    await tester.tap(find.byTooltip(Str.moonHint));
    await settle(tester);
    expect(find.text(Str.moonAuto), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(mode.enabled, isTrue);
    Navigator.of(tester.element(find.byType(Switch))).pop();
    await settle(tester);
    await tester.ensureVisible(find.text(Str.focusCalendar));
    await tester.tap(find.text(Str.focusCalendar));
    await settle(tester);
    await tester.ensureVisible(find.text(Str.ofGoal('0h', '140h')));
    expect(find.text(Str.ofGoal('0h', '140h')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion stops animation tickers but still shows time progress', (tester) async {
    var progress = 0.25;
    Widget glass() => MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SizedBox(
                width: 100,
                height: 146,
                child: Hourglass(style: HourglassStyle.line, progress: () => progress, running: true))));
    await tester.pumpWidget(glass());
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    progress = 0.5;
    await tester.pumpWidget(glass());
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
