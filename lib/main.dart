import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/mood_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'views/screens/splash_screen.dart';
import 'core/localization/localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await FirebaseService.initialize();
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => MoodViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
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
    );
  }
}
