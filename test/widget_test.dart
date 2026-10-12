import 'package:clock_it/data/hours_store.dart';
import 'package:clock_it/main.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:clock_it/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('splash → welcome → home, then mark entry and exit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = AppState(LocalHoursStore());
    await tester.pumpWidget(ClockItApp(state: state));

    // Splash waits ~1.3 s, then fades to the welcome screen.
    await pumpUntilFound(tester, find.text(Str.logIn));
    expect(find.text(Str.logIn), findsOneWidget);
    expect(find.text(Str.signIn), findsOneWidget);

    await tester.tap(find.text(Str.logIn));
    await pumpUntilFound(tester, find.text(Str.markEntry));
    await tester.pumpAndSettle();
    expect(find.text(Str.markEntry), findsOneWidget);
    expect(find.text(Str.hoursLeft), findsOneWidget);
    expect(find.text('140h'), findsWidgets); // empty month: everything left

    await tester.tap(find.text(Str.markEntry));
    await tester.pump();
    expect(find.text(Str.markExit), findsOneWidget);
    expect(state.isOpen, isTrue);

    await tester.tap(find.text(Str.markExit));
    await tester.pump();
    expect(find.text(Str.markEntry), findsOneWidget);
    expect(state.isOpen, isFalse);
    expect(state.data.days.values.single.sessions, hasLength(1));

    // Second launch skips the welcome screen.
    expect(await LocalHoursStore().hasSeenWelcome(), isTrue);
  });
}

/// Advances both the fake test clock (timers, animations) and real time
/// (asset and image decoding) until [finder] matches.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
