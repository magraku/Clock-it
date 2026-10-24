import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/accounts.dart';
import 'data/demo_accounts.dart';
import 'data/hours_store.dart';
import 'data/timer_alerts.dart';
import 'firebase_options.dart';
import 'state/session.dart';
import 'ui/screens/intro_screens.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Str.useLocale(PlatformDispatcher.instance.locale);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(ClockItApp(services: kIsWeb ? _webServices() : await _firebaseServices()));
}

/// iPhone and Android: accounts and hours in Firebase.
Future<Services> _firebaseServices() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  return Services(
    accounts: FirebaseAccountService(onDelete: (a) => FirestoreHoursStore(a.uid).delete()),
    storeFor: (a) => FirestoreHoursStore(a.uid),
    legacy: LocalHoursStore(),
    alerts: LocalTimerAlerts(),
  );
}

/// Web (`flutter run -d chrome`), only for reviewing the design: no Firebase,
/// every account and its hours stay in this browser.
Services _webServices() => Services(
      accounts: DemoAccountService(),
      storeFor: (a) => LocalHoursStore(key: DemoAccountService.demoHoursKey(a)),
      legacy: LocalHoursStore(),
    );

class ClockItApp extends StatelessWidget {
  const ClockItApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Str.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Spanish or English, as the texts (Str); system pieces like the
      // text selection menu follow.
      locale: Locale(Str.spanish ? 'es' : 'en'),
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: SplashScreen(services: services),
    );
  }
}
