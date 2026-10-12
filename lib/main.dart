import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/accounts.dart';
import 'data/hours_store.dart';
import 'firebase_options.dart';
import 'state/session.dart';
import 'ui/screens/intro_screens.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ClockItApp(
    services: Services(
      accounts: FirebaseAccountService(onDelete: (a) => FirestoreHoursStore(a.uid).delete()),
      storeFor: (a) => FirestoreHoursStore(a.uid),
      legacy: LocalHoursStore(),
    ),
  ));
}

class ClockItApp extends StatelessWidget {
  const ClockItApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Str.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: SplashScreen(services: services),
    );
  }
}
