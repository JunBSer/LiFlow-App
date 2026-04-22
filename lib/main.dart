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
import 'core/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  try {
    await FirebaseService.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {}

  try {
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {}

  final settingsViewModel = await SettingsViewModel.bootstrapForUser(
    AuthService.instance.currentUser?.uid,
  );

  runApp(MyApp(settingsViewModel: settingsViewModel));
}

class MyApp extends StatelessWidget {
  final SettingsViewModel settingsViewModel;

  const MyApp({super.key, required this.settingsViewModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsViewModel>.value(
          value: settingsViewModel,
        ),
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
