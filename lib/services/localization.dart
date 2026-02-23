import 'package:flutter/material.dart';

class AppLoc extends InheritedWidget {
  final String lang;
  const AppLoc({super.key, required this.lang, required super.child});

  static AppLoc? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppLoc>();

  @override
  bool updateShouldNotify(AppLoc oldWidget) => lang != oldWidget.lang;

  String get(String key) => _localizedValues[lang]?[key] ?? key;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'LiFlow',
      'tracker_feat': 'Mood Tracker',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'add_entry': 'How do you feel?',
      'reason': 'Reason / Notes',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'no_data': 'No entries yet. Add your mood!',
      'loading': 'Loading...',
    },
    'ru': {
      'app_name': 'LiFlow',
      'tracker_feat': 'Трекер настроения',
      'settings': 'Настройки',
      'dark_mode': 'Темная тема',
      'language': 'Язык',
      'add_entry': 'Как вы себя чувствуете?',
      'reason': 'Причина / Заметки',
      'save': 'Сохранить',
      'delete': 'Удалить',
      'edit': 'Изменить',
      'no_data': 'Пока нет записей. Добавьте настроение!',
      'loading': 'Загрузка...',
    }
  };
}

extension ContextExtension on BuildContext {
  String loc(String key) => AppLoc.of(this)?.get(key) ?? key;
}