import 'package:clock_it/main.dart';
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
    await tester.tap(find.byIcon(Icons.more_horiz));
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
    expect(find.text(Str.signIn), findsOneWidget);

    // Ana creates an account and logs a session.
    await tester.tap(find.text(Str.signIn));
    await tester.pumpAndSettle();
    expect(find.text(Str.signUpTitle), findsOneWidget);
    await fillAccountSheet(tester, 'ana@mail.com', 'secret1', Str.createAccount);
    expect(find.text('140h'), findsWidgets); // empty month: everything left

    await tester.tap(find.text(Str.markEntry));
    await tester.pump();
    expect(find.text(Str.markExit), findsOneWidget);
    await tester.tap(find.text(Str.markExit));
    await tester.pump();
    expect(find.text(Str.markEntry), findsOneWidget);
    expect((cloud['uid-0']!['days'] as Map), hasLength(1));

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

/// Advances both the fake test clock (timers, animations) and real time
/// (asset and image decoding) until [finder] matches.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
