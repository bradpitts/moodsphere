import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
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

    // Schedule daily notification
    await _notificationsPlugin.show(
      888,
      'Paint Your Mood Today 🎨',
      'Take a moment to reflect on your day and add a mood orb to your 3D Galaxy.',
      details,
    );
  }
}
