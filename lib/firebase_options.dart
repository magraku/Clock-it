// Firebase project clock-it-83703. Same values as android/app/google-services.json
// and ios/Runner/GoogleService-Info.plist; regenerate with `flutterfire configure`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
        TargetPlatform.android => android,
        TargetPlatform.iOS => ios,
        _ => throw UnsupportedError('Clock it only runs on iPhone and Android.'),
      };

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-lKxETg8sRrraJqgZBuhzr3yrKfDo2VY',
    appId: '1:44992129967:android:010491c18298875140dd5a',
    messagingSenderId: '44992129967',
    projectId: 'clock-it-83703',
    storageBucket: 'clock-it-83703.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHDhgGK53WQZ0yR3tF1DCw296dBMBDbKc',
    appId: '1:44992129967:ios:1d9a27e2b995ae5040dd5a',
    messagingSenderId: '44992129967',
    projectId: 'clock-it-83703',
    storageBucket: 'clock-it-83703.firebasestorage.app',
    iosBundleId: 'com.mariagracia.clockIt',
  );
}
