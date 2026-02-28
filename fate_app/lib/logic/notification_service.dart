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
}
