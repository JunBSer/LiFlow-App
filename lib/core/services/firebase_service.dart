import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static bool _isReady = false;

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
      _isReady = true;
      return;
    } catch (_) {}

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
      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
  }
}
