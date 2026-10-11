import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBFLKV01T-XGVmHEV6QlBRHkVcaHejs0hc',
    appId: '1:224732363568:web:placeholder',
    messagingSenderId: '224732363568',
    projectId: 'kurichya-matrimony',
    storageBucket: 'kurichya-matrimony.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFLKV01T-XGVmHEV6QlBRHkVcaHejs0hc',
    appId: '1:224732363568:android:c98056d0798d78038066f5',
    messagingSenderId: '224732363568',
    projectId: 'kurichya-matrimony',
    storageBucket: 'kurichya-matrimony.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBFLKV01T-XGVmHEV6QlBRHkVcaHejs0hc',
    appId: '1:224732363568:ios:placeholder',
    messagingSenderId: '224732363568',
    projectId: 'kurichya-matrimony',
    storageBucket: 'kurichya-matrimony.firebasestorage.app',
  );
}
