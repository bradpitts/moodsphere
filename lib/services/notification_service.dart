import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> scheduleDailyReminder(bool enable) async {
    if (!enable) {
      await _notificationsPlugin.cancelAll();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_mood_channel',
      'Daily Mood Reminders',
      channelDescription: 'Reminds you to log your daily mood in MoodSphere',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Schedule for 8:00 PM every day
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8 PM
      0,
    );

    final initialDelay = scheduledTime.isAfter(now)
        ? scheduledTime.difference(now)
        : scheduledTime.add(const Duration(days: 1)).difference(now);

    await _notificationsPlugin.zonedSchedule(
      888,
      'Paint Your Mood Today 🎨',
      'Take a moment to reflect on your day and add a mood orb to your 3D Galaxy.',
      scheduledTime,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }
}