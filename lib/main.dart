import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/hours_store.dart';
import 'state/app_state.dart';
import 'ui/screens/intro_screens.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

void main() {
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
  runApp(ClockItApp(state: AppState(LocalHoursStore())));
}

class ClockItApp extends StatelessWidget {
  const ClockItApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Str.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: SplashScreen(state: state),
    );
  }
}
