import 'package:flutter/material.dart';
import '../core/preferences/prefs_helper.dart';

class SettingsViewModel with ChangeNotifier {
  bool _isDarkMode = false;
  String _langCode = 'ru';

  bool get isDarkMode => _isDarkMode;
  String get langCode => _langCode;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isDarkMode = await PrefsHelper.getTheme();
    _langCode = await PrefsHelper.getLanguage();
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
}