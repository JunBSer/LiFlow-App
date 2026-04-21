import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/mood_view_model.dart';
import 'viewmodels/quote_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'views/screens/splash_screen.dart';
import 'core/localization/localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  runApp(const MyApp());

  unawaited(_bootstrapServices());
}

Future<void> _bootstrapServices() async {
  try {
    await FirebaseService.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {}

  try {
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => MoodViewModel()),
        ChangeNotifierProvider(create: (_) => QuoteViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          return AppLoc(
            lang: settings.langCode,
            child: MaterialApp(
              title: 'LiFlow',
              theme: ThemeData(
                colorSchemeSeed: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              debugShowCheckedModeBanner: false,
              darkTheme: ThemeData(
                colorSchemeSeed: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
