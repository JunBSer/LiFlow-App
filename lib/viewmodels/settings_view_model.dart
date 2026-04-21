import 'dart:async';

import 'package:flutter/material.dart';
import '../core/preferences/prefs_helper.dart';
import '../core/services/notification_service.dart';

class SettingsViewModel with ChangeNotifier {
  bool _isDarkMode = false;
  String _langCode = 'ru';
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _disposed = false;

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
      try {
        await NotificationService.instance.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
      } catch (_) {
        _dailyReminderEnabled = false;
      }
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    unawaited(PrefsHelper.saveTheme(value));
    if (!_disposed) {
      notifyListeners();
    }
  }

  void setLanguage(String lang) {
    _langCode = lang;
    unawaited(PrefsHelper.saveLanguage(lang));
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> toggleDailyReminder(bool enabled) async {
    _dailyReminderEnabled = enabled;
    await PrefsHelper.saveReminderEnabled(enabled);

    if (enabled) {
      await NotificationService.instance.requestPermissionsIfNeeded();
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
    if (!_disposed) {
      notifyListeners();
    }
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
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
