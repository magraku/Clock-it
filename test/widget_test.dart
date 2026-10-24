import 'package:clock_it/main.dart';
import 'package:clock_it/models/goals.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:clock_it/ui/screens/history_screen.dart';
import 'package:clock_it/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';
import 'support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeAccounts accounts;
  late Map<String, Map<String, dynamic>> cloud;

  setUp(() {
    accounts = FakeAccounts();
    cloud = {};
  });

  Future<void> start(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ClockItApp(services: fakeServices(accounts, cloud)));
    // Splash waits ~1.3 s, then fades to the next screen.
    await pumpUntilFound(tester, find.text(Str.logIn));
  }

  Future<void> fillAccountSheet(WidgetTester tester, String email, String password, String button) async {
    await tester.enterText(find.widgetWithText(TextField, Str.email), email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text(button).last);
    await pumpUntilFound(tester, find.text(Str.markEntry));
    await tester.pumpAndSettle();
  }

  Future<void> logOut(WidgetTester tester) async {
    await tester.tap(find.text(Str.tabProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Str.logOut));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Str.logOut).last); // confirm
    await pumpUntilFound(tester, find.text(Str.logIn));
    await tester.pumpAndSettle();
  }

  testWidgets('each account keeps its own hours', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await start(tester);
    expect(find.text(Str.signUp), findsOneWidget);

    // Ana creates an account and logs a session.
    await tester.tap(find.text(Str.signUp));
    await tester.pumpAndSettle();
    expect(find.text(Str.signUpTitle), findsOneWidget);
    await fillAccountSheet(tester, 'ana@mail.com', 'secret1', Str.createAccount);
    expect(find.text('140h'), findsWidgets); // empty month: everything left

    // Each tap swaps the label with a short roll; let it finish.
    await tester.tap(find.text(Str.markEntry));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(Str.markExit), findsOneWidget);
    await tester.tap(find.text(Str.markExit));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(Str.markEntry), findsOneWidget);
    expect(homeDays(cloud['uid-0']!), hasLength(1));

    await logOut(tester);

    // Bea creates her own account: it starts empty.
    await tester.tap(find.text(Str.logIn));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Str.noAccount));
    await tester.pumpAndSettle();
    await fillAccountSheet(tester, 'bea@mail.com', 'secret2', Str.createAccount);
    expect(cloud['uid-1'], isNull);
    await logOut(tester);

    // A wrong password is refused.
    await tester.tap(find.text(Str.logIn));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, Str.email), 'ana@mail.com');
    await tester.enterText(find.byType(TextField).last, 'nope!!');
    await tester.tap(find.text(Str.logIn).last);
    await tester.pumpAndSettle();
    expect(find.text(Str.authWrongCredentials), findsOneWidget);

    // Ana logs back in and finds her hours.
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.text(Str.logIn).last);
    await pumpUntilFound(tester, find.text(Str.markEntry));
    await tester.pumpAndSettle();
    expect(find.text(Str.markEntry), findsOneWidget);
    expect(accounts.current?.email, 'ana@mail.com');
  });

  testWidgets('goals: create one, run its timer, see it on the Goals screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await accounts.signUp('ana@mail.com', 'secret1');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ClockItApp(services: fakeServices(accounts, cloud)));
    await pumpUntilFound(tester, find.text(Str.markEntry));

    // The cards keep floating, so these pumps never "settle".
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.text(Str.tabGoals));
    await settle();
    expect(find.text('SFP'), findsOneWidget);

    await tester.tap(find.text(Str.createGoal));
    await settle();
    await tester.enterText(find.widgetWithText(TextField, Str.goalNameHint), 'Study hours');
    await tester.tap(find.text(Str.create));
    await settle();
    await settle();

    // It opens the new goal's screen.
    expect(find.text('STUDY HOURS'), findsOneWidget);
    expect(find.text(Str.timer), findsOneWidget);
    // Its month, read only, until a time is picked.
    final monthLine = find.text(Str.ofGoal('0h', '20h'));
    expect(monthLine, findsOneWidget);

    await tester.tap(find.text(Str.minutesChip(15)));
    await settle();
    expect(monthLine, findsNothing);
    expect(find.text(Str.start), findsOneWidget);
    expect(cloud['uid-0']!['goals'][1]['timer'], isNull); // waits for Start

    await tester.tap(find.bySemanticsLabel(Str.hourglassStyle(Str.hourglassNames[2])));
    await settle();
    expect(cloud['uid-0']!['glass'], 'line');

    await tester.tap(find.text(Str.start));
    await settle();
    // The time left shows on the button (real clock: 15:00 or just under).
    expect(find.textContaining(RegExp('^${Str.stop} · 1[45]:[0-5][0-9]\$')), findsOneWidget);
    expect(cloud['uid-0']!['goals'][1]['timer'], isNotNull);

    await tester.tap(find.textContaining(Str.stop));
    await settle();
    expect(monthLine, findsOneWidget);

    // Back on the list (tap the tab again), both goals are there.
    await tester.tap(find.text(Str.tabGoals));
    await settle();
    expect(find.text('STUDY\nHOURS'), findsOneWidget);
    expect(find.text('SFP'), findsOneWidget);
    expect((cloud['uid-0']!['goals'] as List), hasLength(2));

    // The Home goal (the house) opens the Home tab, not a goal screen.
    await tester.tap(find.text('SFP'));
    await settle();
    expect(find.text(Str.markEntry).hitTestable(), findsOneWidget);
    expect(find.text(Str.timer), findsNothing);

    // Leave the floating screen so the test can end.
    await tester.tap(find.text(Str.tabProfile));
    await settle();
    expect(find.text('ana@mail.com'), findsOneWidget);
  });

  testWidgets('History lists each day\'s exact entries and exits, by goal', (tester) async {
    var now = DateTime(2026, 10, 7, 13, 27);
    final state = AppState(MemoryStore({}, 'u'), clock: () => now);
    await state.load();
    final gym = state.createGoal('Gym', GoalColor.pink, 10);
    state.punch('sfp'); // in at 13:27
    now = DateTime(2026, 10, 7, 20, 24);
    state.punch('sfp'); // out at 20:24
    now = DateTime(2026, 10, 7, 20, 44);
    state.punch('sfp'); // in again, still running
    now = DateTime(2026, 10, 7, 21, 0);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: HistoryScreen(state: state)));
    await tester.pump();

    expect(find.text(Str.history.toUpperCase()), findsOneWidget);
    expect(find.text('13:27–20:24  ·  20:44–${Str.now}'), findsOneWidget);
    expect(find.text('7h13m'), findsOneWidget); // 6h57m done + 16m running

    // Another goal has its own days.
    await tester.tap(find.text('GYM'));
    await tester.pump();
    expect(find.textContaining('13:27'), findsNothing);
    expect(gym.hours.days, isEmpty);
    state.dispose();
  });

  testWidgets('a remembered account skips the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await accounts.signUp('ana@mail.com', 'secret1');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ClockItApp(services: fakeServices(accounts, cloud)));
    await pumpUntilFound(tester, find.text(Str.markEntry));
    expect(find.text(Str.markEntry), findsOneWidget);
    expect(find.text(Str.logIn), findsNothing);
  });
}

List<dynamic> homeDays(Map<String, dynamic> doc) {
  final goals = (doc['goals'] as List).cast<Map<String, dynamic>>();
  final home = goals.firstWhere((g) => g['id'] == doc['home']);
  return ((home['hours'] as Map)['days'] as Map).values.toList();
}

/// Advances both the fake test clock (timers, animations) and real time
/// (asset and image decoding) until [finder] matches.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
