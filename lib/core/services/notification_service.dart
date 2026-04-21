import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 101;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? _androidPlugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );

    _androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimeZone));
    } catch (_) {
      final fallback = _ianaFromKnownTimeZoneName(DateTime.now().timeZoneName);
      if (fallback != null) {
        tz.setLocalLocation(tz.getLocation(fallback));
        return;
      }
      tz.setLocalLocation(tz.UTC);
    }
  }

  String? _ianaFromKnownTimeZoneName(String rawName) {
    final normalized = rawName.trim().toUpperCase();
    const mapped = <String, String>{
      'UTC': 'UTC',
      'GMT': 'UTC',
      'MSK': 'Europe/Moscow',
      'EET': 'Europe/Athens',
      'EEST': 'Europe/Athens',
      'CET': 'Europe/Paris',
      'CEST': 'Europe/Paris',
      'WET': 'Europe/Lisbon',
      'WEST': 'Europe/Lisbon',
    };

    if (mapped.containsKey(normalized)) return mapped[normalized];

    final offsetMatch = RegExp(
      r'^(?:UTC|GMT)?\s*([+-])(\d{1,2})(?::?(\d{2}))?$',
    ).firstMatch(normalized);
    if (offsetMatch == null) return null;

    final sign = offsetMatch.group(1)!;
    final hours = int.tryParse(offsetMatch.group(2)!) ?? 0;
    final minutes = int.tryParse(offsetMatch.group(3) ?? '0') ?? 0;
    if (minutes != 0) return null;

    if (sign == '+' && hours == 3) return 'Europe/Moscow';
    if (sign == '+' && hours == 2) return 'Europe/Athens';
    if (sign == '+' && hours == 1) return 'Europe/Paris';
    if (sign == '-' && hours == 0) return 'UTC';

    return null;
  }

  Future<void> requestPermissionsIfNeeded() async {
    if (!_initialized) await initialize();
    try {
      await _androidPlugin?.requestNotificationsPermission();
      await _androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final canExact = await _androidPlugin?.canScheduleExactNotifications();
    if (canExact == true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await initialize();

    await requestPermissionsIfNeeded();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final scheduleMode = await _resolveScheduleMode();

    await _scheduleAt(
      id: _dailyReminderId,
      title: 'LiFlow Reminder',
      body: 'Take a minute and log your mood today.',
      scheduledDate: scheduled,
      preferredMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    if (!_initialized) await initialize();

    await _plugin.cancel(id: _dailyReminderId);
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_mood_reminder',
      'Daily Mood Reminder',
      channelDescription: 'Scheduled reminders to add a mood entry.',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required AndroidScheduleMode preferredMode,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails,
        androidScheduleMode: preferredMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } on PlatformException {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }
  }
}
