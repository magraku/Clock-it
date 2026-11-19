import 'package:clock_it/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('web options use the shared Firebase project and auth domain', () {
    expect(DefaultFirebaseOptions.web.projectId,
        DefaultFirebaseOptions.android.projectId);
    expect(DefaultFirebaseOptions.web.storageBucket,
        DefaultFirebaseOptions.android.storageBucket);
    expect(DefaultFirebaseOptions.web.messagingSenderId,
        DefaultFirebaseOptions.android.messagingSenderId);
    expect(DefaultFirebaseOptions.web.authDomain,
        'clock-it-83703.firebaseapp.com');
    expect(DefaultFirebaseOptions.web.apiKey, isNotEmpty);
    expect(DefaultFirebaseOptions.web.appId, isNotEmpty);
  });

  test('current platform selects web before the host platform', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(
          DefaultFirebaseOptions.currentPlatform,
          kIsWeb
              ? DefaultFirebaseOptions.web
              : platform == TargetPlatform.android
                  ? DefaultFirebaseOptions.android
                  : DefaultFirebaseOptions.ios);
    }
  });

  test('unsupported native platforms reject Firebase initialization', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    if (kIsWeb) {
      expect(
          DefaultFirebaseOptions.currentPlatform, DefaultFirebaseOptions.web);
    } else {
      expect(
          () => DefaultFirebaseOptions.currentPlatform, throwsUnsupportedError);
    }
  });
}
