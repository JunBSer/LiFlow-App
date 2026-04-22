import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import '../../firebase_options.dart';

class FirebaseService {
  static bool _isReady = false;
  static bool _isAppCheckActivated = false;

  static bool get isReady => _isReady;

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      _isReady = true;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _activateAppCheckIfNeeded();
      _isReady = true;
      return;
    } catch (e, st) {
      developer.log(
        'Firebase init with default options failed: $e',
        name: 'FirebaseService',
        stackTrace: st,
      );
    }

    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final appId = dotenv.env['FIREBASE_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];

    if ([
      apiKey,
      appId,
      messagingSenderId,
      projectId,
    ].any((value) => value == null || value.isEmpty)) {
      _isReady = false;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey!,
          appId: appId!,
          messagingSenderId: messagingSenderId!,
          projectId: projectId!,
          storageBucket: storageBucket,
        ),
      );
      await _activateAppCheckIfNeeded();
      _isReady = true;
    } catch (e, st) {
      developer.log(
        'Firebase init with dotenv options failed: $e',
        name: 'FirebaseService',
        stackTrace: st,
      );
      _isReady = false;
    }
  }

  static Future<void> _activateAppCheckIfNeeded() async {
    if (_isAppCheckActivated) return;
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      _isAppCheckActivated = true;
    } catch (e, st) {
      developer.log(
        'Firebase App Check activation failed: $e',
        name: 'FirebaseService',
        stackTrace: st,
      );
    }
  }
}
