import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/accounts.dart';
import 'data/demo_accounts.dart';
import 'data/hours_store.dart';
import 'data/timer_alerts.dart';
import 'data/web_cache_cleanup.dart';
import 'data/reload_stub.dart' if (dart.library.js_interop) 'data/reload_web.dart';
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
  runApp(ClockItApp(services: const bool.fromEnvironment('CLOCKIT_DEMO')
      ? _demoServices()
      : await _firebaseServices()));
}

/// Accounts and hours shared across web, iPhone and Android.
Future<Services> _firebaseServices() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  }
  return Services(
    accounts: FirebaseAccountService(
      onDelete: (a) => FirestoreHoursStore(a.uid).delete(),
      beforeLogOut: kIsWeb ? () => flushWebWrites(
        waitForPendingWrites: FirebaseFirestore.instance.waitForPendingWrites,
      ) : null,
      afterDelete: kIsWeb ? () => flushWebWrites(
        waitForPendingWrites: FirebaseFirestore.instance.waitForPendingWrites,
      ) : null,
      onLogOut: kIsWeb ? () {
        final db = FirebaseFirestore.instance;
        return clearWebCache(
          terminate: db.terminate,
          clearPersistence: db.clearPersistence,
          reload: reloadPage,
        );
      } : null,
    ),
    storeFor: (a) => FirestoreHoursStore(a.uid),
    legacy: LocalHoursStore(),
    alerts: kIsWeb ? const NoTimerAlerts() : LocalTimerAlerts(),
  );
}

/// Design review without Firebase: accounts and hours stay on this device.
Services _demoServices() => Services(
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
