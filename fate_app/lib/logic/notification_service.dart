import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  static Future<void> showAnalysisNotification(
    double casScore, {
    String? insight,
  }) async {
    String title = 'FATE Analysis Complete';
    String body =
        'Your current Contextual Attention Score is ${casScore.toStringAsFixed(0)}.';
    if (insight != null && insight.isNotEmpty) {
      body += ' $insight';
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fate_analysis_channel',
          'Analysis Updates',
          channelDescription: 'Notifications for new CAS analysis results',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Alert notification when an unknown device is detected nearby.
  /// Uses alarm-level importance with sound + vibration.
  static Future<void> showUnknownDeviceAlert(
    String deviceName,
    double? distance,
  ) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fate_attention_alert_channel',
          'Attention Alerts',
          channelDescription:
              'Alerts when unknown devices may affect your attention score',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
          color: const Color(0xFFFF3B30),
          colorized: true,
          category: AndroidNotificationCategory.alarm,
          styleInformation: const BigTextStyleInformation(''),
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 9000 + DateTime.now().millisecond,
      title: '⚠️ Unknown Device Detected',
      body:
          '"$deviceName" is ${distance != null ? "~${distance.toStringAsFixed(1)}m away" : "nearby"}. Unregistered devices near you decrease your attention score.',
      notificationDetails: details,
    );
  }
}
