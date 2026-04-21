import 'package:flutter/material.dart';

class AppLoc extends InheritedWidget {
  final String lang;

  const AppLoc({super.key, required this.lang, required super.child});

  static AppLoc? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLoc>();

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
      'unknown_author': 'Unknown author',
      'search_hint': 'Search by text, category, or keywords',
      'category': 'Category',
      'all_categories': 'All categories',
      'sort': 'Sort',
      'newest_first': 'Newest first',
      'oldest_first': 'Oldest first',
      'reason_az': 'Reason A-Z',
      'reason_za': 'Reason Z-A',
      'date_range': 'Date range',
      'clear_filters': 'Clear filters',
      'daily_reminder': 'Daily reminder',
      'daily_reminder_subtitle': 'Show a scheduled notification each day',
      'reminder_time': 'Reminder time',
      'total': 'Total',
      'this_week': 'This week',
      'top_category': 'Top category',
      'select_image': 'Select image',
      'keywords_hint': 'Keywords (comma separated)',
      'delete_entry_title': 'Delete entry',
      'delete_entry_message': 'This action cannot be undone.',
      'cancel': 'Cancel',
      'streak': 'Streak',
      'today_status': 'Today',
      'logged_today': 'Logged',
      'not_logged_today': 'Not yet',
      'mood_balance': 'Mood balance',
      'random_entry': 'Random entry',
      'add_today_entry': 'Add today entry',
      'history': 'History',
      'open_history': 'Open history',
      'quick_actions': 'Quick actions',
    },
    'ru': {
      'app_name': 'LiFlow',
      'tracker_feat':
          '\u0422\u0440\u0435\u043A\u0435\u0440 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F',
      'settings': '\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438',
      'dark_mode':
          '\u0422\u0435\u043C\u043D\u0430\u044F \u0442\u0435\u043C\u0430',
      'language': '\u042F\u0437\u044B\u043A',
      'add_entry':
          '\u041A\u0430\u043A \u0432\u044B \u0441\u0435\u0431\u044F \u0447\u0443\u0432\u0441\u0442\u0432\u0443\u0435\u0442\u0435?',
      'reason':
          '\u041F\u0440\u0438\u0447\u0438\u043D\u0430 / \u0417\u0430\u043C\u0435\u0442\u043A\u0438',
      'save': '\u0421\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u044C',
      'delete': '\u0423\u0434\u0430\u043B\u0438\u0442\u044C',
      'edit': '\u0418\u0437\u043C\u0435\u043D\u0438\u0442\u044C',
      'no_data':
          '\u041F\u043E\u043A\u0430 \u043D\u0435\u0442 \u0437\u0430\u043F\u0438\u0441\u0435\u0439. \u0414\u043E\u0431\u0430\u0432\u044C\u0442\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435!',
      'loading': '\u0417\u0430\u0433\u0440\u0443\u0437\u043A\u0430...',
      'unknown_author':
          '\u041D\u0435\u0438\u0437\u0432\u0435\u0441\u0442\u043D\u044B\u0439 \u0430\u0432\u0442\u043E\u0440',
      'search_hint':
          '\u041F\u043E\u0438\u0441\u043A \u043F\u043E \u0442\u0435\u043A\u0441\u0442\u0443, \u043A\u0430\u0442\u0435\u0433\u043E\u0440\u0438\u0438 \u0438\u043B\u0438 \u043A\u043B\u044E\u0447\u0435\u0432\u044B\u043C \u0441\u043B\u043E\u0432\u0430\u043C',
      'category': '\u041A\u0430\u0442\u0435\u0433\u043E\u0440\u0438\u044F',
      'all_categories':
          '\u0412\u0441\u0435 \u043A\u0430\u0442\u0435\u0433\u043E\u0440\u0438\u0438',
      'sort': '\u0421\u043E\u0440\u0442\u0438\u0440\u043E\u0432\u043A\u0430',
      'newest_first':
          '\u0421\u043D\u0430\u0447\u0430\u043B\u0430 \u043D\u043E\u0432\u044B\u0435',
      'oldest_first':
          '\u0421\u043D\u0430\u0447\u0430\u043B\u0430 \u0441\u0442\u0430\u0440\u044B\u0435',
      'reason_az': '\u041F\u0440\u0438\u0447\u0438\u043D\u0430 \u0410-\u042F',
      'reason_za': '\u041F\u0440\u0438\u0447\u0438\u043D\u0430 \u042F-\u0410',
      'date_range':
          '\u0414\u0438\u0430\u043F\u0430\u0437\u043E\u043D \u0434\u0430\u0442',
      'clear_filters':
          '\u0421\u0431\u0440\u043E\u0441\u0438\u0442\u044C \u0444\u0438\u043B\u044C\u0442\u0440\u044B',
      'daily_reminder':
          '\u0415\u0436\u0435\u0434\u043D\u0435\u0432\u043D\u043E\u0435 \u043D\u0430\u043F\u043E\u043C\u0438\u043D\u0430\u043D\u0438\u0435',
      'daily_reminder_subtitle':
          '\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0443\u0432\u0435\u0434\u043E\u043C\u043B\u0435\u043D\u0438\u0435 \u043F\u043E \u0440\u0430\u0441\u043F\u0438\u0441\u0430\u043D\u0438\u044E \u043A\u0430\u0436\u0434\u044B\u0439 \u0434\u0435\u043D\u044C',
      'reminder_time':
          '\u0412\u0440\u0435\u043C\u044F \u043D\u0430\u043F\u043E\u043C\u0438\u043D\u0430\u043D\u0438\u044F',
      'total': '\u0412\u0441\u0435\u0433\u043E',
      'this_week': '\u0417\u0430 \u043D\u0435\u0434\u0435\u043B\u044E',
      'top_category':
          '\u0422\u043E\u043F-\u043A\u0430\u0442\u0435\u0433\u043E\u0440\u0438\u044F',
      'select_image':
          '\u0412\u044B\u0431\u0440\u0430\u0442\u044C \u0438\u0437\u043E\u0431\u0440\u0430\u0436\u0435\u043D\u0438\u0435',
      'keywords_hint':
          '\u041A\u043B\u044E\u0447\u0435\u0432\u044B\u0435 \u0441\u043B\u043E\u0432\u0430 (\u0447\u0435\u0440\u0435\u0437 \u0437\u0430\u043F\u044F\u0442\u0443\u044E)',
      'delete_entry_title':
          '\u0423\u0434\u0430\u043B\u0438\u0442\u044C \u0437\u0430\u043F\u0438\u0441\u044C',
      'delete_entry_message':
          '\u042D\u0442\u043E \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0435 \u043D\u0435\u043B\u044C\u0437\u044F \u043E\u0442\u043C\u0435\u043D\u0438\u0442\u044C.',
      'cancel': '\u041E\u0442\u043C\u0435\u043D\u0430',
      'streak': '\u0421\u0442\u0440\u0438\u043A',
      'today_status': '\u0421\u0435\u0433\u043E\u0434\u043D\u044F',
      'logged_today':
          '\u0415\u0441\u0442\u044C \u0437\u0430\u043F\u0438\u0441\u044C',
      'not_logged_today': '\u0415\u0449\u0435 \u043D\u0435\u0442',
      'mood_balance':
          '\u0411\u0430\u043B\u0430\u043D\u0441 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F',
      'random_entry':
          '\u0421\u043B\u0443\u0447\u0430\u0439\u043D\u0430\u044F \u0437\u0430\u043F\u0438\u0441\u044C',
      'add_today_entry':
          '\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u0437\u0430\u043F\u0438\u0441\u044C \u0437\u0430 \u0441\u0435\u0433\u043E\u0434\u043D\u044F',
      'history': '\u0418\u0441\u0442\u043E\u0440\u0438\u044F',
      'open_history':
          '\u041E\u0442\u043A\u0440\u044B\u0442\u044C \u0438\u0441\u0442\u043E\u0440\u0438\u044E',
      'quick_actions':
          '\u0411\u044B\u0441\u0442\u0440\u044B\u0435 \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u044F',
    },
  };
}

extension ContextExtension on BuildContext {
  String loc(String key) => AppLoc.of(this)?.get(key) ?? key;
}
