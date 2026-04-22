import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static const String _themeKey = 'isDarkMode';
  static const String _langKey = 'languageCode';
  static const String _reminderEnabledKey = 'dailyReminderEnabled';
  static const String _reminderHourKey = 'dailyReminderHour';
  static const String _reminderMinuteKey = 'dailyReminderMinute';
  static String? _userScope;

  static void setUserScope(String? userId) {
    _userScope = userId;
  }

  static String _key(String base) {
    final scope = _userScope;
    if (scope == null || scope.isEmpty) return base;
    return '${base}_$scope';
  }

  static Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_themeKey), isDark);
  }

  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(_themeKey)) ?? false;
  }

  static Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_langKey), langCode);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(_langKey)) ?? 'ru';
  }

  static Future<void> saveReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_reminderEnabledKey), enabled);
  }

  static Future<bool> getReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(_reminderEnabledKey)) ?? false;
  }

  static Future<void> saveReminderTime({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(_reminderHourKey), hour);
    await prefs.setInt(_key(_reminderMinuteKey), minute);
  }

  static Future<(int, int)> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_key(_reminderHourKey)) ?? 20;
    final minute = prefs.getInt(_key(_reminderMinuteKey)) ?? 0;
    return (hour, minute);
  }
}
