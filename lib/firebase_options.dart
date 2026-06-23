import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBvgUSmYJ8T9QB09Vc_htmMK0BtgpjpPHI',
    appId: '1:467878544533:web:aa8e961739b03f9981079c',
    messagingSenderId: '467878544533',
    projectId: 'ai-smart-life-assistant-a697a',
    authDomain: 'ai-smart-life-assistant-a697a.firebaseapp.com',
    storageBucket: 'ai-smart-life-assistant-a697a.firebasestorage.app',
    measurementId: 'G-1234567890',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXO6iaXla7ZNLj3-lff6DnD8ollrishHs',
    appId: '1:467878544533:android:08ede33cbff1e7ef81079c',
    messagingSenderId: '467878544533',
    projectId: 'ai-smart-life-assistant-a697a',
    storageBucket: 'ai-smart-life-assistant-a697a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvgUSmYJ8T9QB09Vc_htmMK0BtgpjpPHI',
    appId: '1:467878544533:ios:aa8e961739b03f9981079c',
    messagingSenderId: '467878544533',
    projectId: 'ai-smart-life-assistant-a697a',
    storageBucket: 'ai-smart-life-assistant-a697a.firebasestorage.app',
    iosBundleId: 'com.chaxu.aiSmartLifeAssistant',
    iosClientId: '467878544533-3j6c7rl91gfdq791lfgc06ln0g20rc8d.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBvgUSmYJ8T9QB09Vc_htmMK0BtgpjpPHI',
    appId: '1:467878544533:ios:aa8e961739b03f9981079c',
    messagingSenderId: '467878544533',
    projectId: 'ai-smart-life-assistant-a697a',
    storageBucket: 'ai-smart-life-assistant-a697a.firebasestorage.app',
    iosBundleId: 'com.chaxu.aiSmartLifeAssistant',
  );
}
