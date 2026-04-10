import 'package:flutter/material.dart';
import '../core/preferences/prefs_helper.dart';
import '../core/services/notification_service.dart';

class SettingsViewModel with ChangeNotifier {
  bool _isDarkMode = false;
  String _langCode = 'ru';
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  bool get isDarkMode => _isDarkMode;
  String get langCode => _langCode;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isDarkMode = await PrefsHelper.getTheme();
    _langCode = await PrefsHelper.getLanguage();
    _dailyReminderEnabled = await PrefsHelper.getReminderEnabled();
    final (hour, minute) = await PrefsHelper.getReminderTime();
    _reminderTime = TimeOfDay(hour: hour, minute: minute);

    if (_dailyReminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    }

    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    PrefsHelper.saveTheme(value);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _langCode = lang;
    PrefsHelper.saveLanguage(lang);
    notifyListeners();
  }

  Future<void> toggleDailyReminder(bool enabled) async {
    _dailyReminderEnabled = enabled;
    await PrefsHelper.saveReminderEnabled(enabled);

    if (enabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await PrefsHelper.saveReminderTime(hour: time.hour, minute: time.minute);

    if (_dailyReminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    }
    notifyListeners();
  }
}
