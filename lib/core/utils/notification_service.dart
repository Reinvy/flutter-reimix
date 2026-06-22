import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Singleton notification service shared across the entire app.
///
/// Call [NotificationService.instance.init()] once from the main shell,
/// then call helper methods anywhere in the app without reinitialising.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: iosSettings);
    await _plugin.initialize(settings);

    // Request notification permission at runtime (Android 13+ / iOS)
    if (Platform.isAndroid) {
      await Permission.notification.request();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    }
  }

  /// Shows "Sleep timer ended" notification.
  Future<void> showSleepTimerEnded() async {
    const androidDetails = AndroidNotificationDetails(
      'reimix_sleep_timer',
      'Sleep Timer',
      channelDescription: 'Notifies when the sleep timer ends',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(1, 'Reimix', 'Sleep timer ended', details);
  }

  /// Shows a download complete notification for [title].
  Future<void> showDownloadComplete(String title) async {
    const androidDetails = AndroidNotificationDetails(
      'reimix_downloads',
      'Downloads',
      channelDescription: 'Notifies when a song download completes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: false);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(2, 'Download Complete', title, details);
  }
}
