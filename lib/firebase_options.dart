import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4qo9LaRLqB2sKb1QSVs6p864MR48-RbI',
    appId: '1:263477722960:android:9dea418d4cc87976557655',
    messagingSenderId: '263477722960',
    projectId: 'spartan-space-16b26',
    storageBucket: 'spartan-space-16b26.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBQlC_isrQyXHx7Us1syZEINNCRd5nywSo',
    appId: '1:263477722960:ios:137c766a5acf13f7557655',
    messagingSenderId: '263477722960',
    projectId: 'spartan-space-16b26',
    storageBucket: 'spartan-space-16b26.firebasestorage.app',
    iosBundleId: 'com.example.cmpe137StudySpace',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBQlC_isrQyXHx7Us1syZEINNCRd5nywSo',
    appId: '1:263477722960:ios:137c766a5acf13f7557655',
    messagingSenderId: '263477722960',
    projectId: 'spartan-space-16b26',
    storageBucket: 'spartan-space-16b26.firebasestorage.app',
    iosBundleId: 'com.example.cmpe137StudySpace',
  );
}