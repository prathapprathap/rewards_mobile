import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Handles FCM token registration, permission requests, and showing
/// notifications while the app is in the foreground.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'default_channel',
    'General Notifications',
    description: 'Reward updates, offers, and announcements.',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> init({required int? userId}) async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Permissions (iOS + Android 13+)
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Local notifications setup (foreground display)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Foreground messages — render with local notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = message.notification;
        if (notif == null) return;
        _localNotifications.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: message.data['action_url'] ?? '',
        );
      });

      // Token registration
      if (userId != null) {
        final token = await _messaging.getToken();
        if (token != null) {
          await ApiService().registerFcmToken(userId, token);
        }
        _messaging.onTokenRefresh.listen((newToken) {
          ApiService().registerFcmToken(userId, newToken);
        });
      }
    } catch (e) {
      debugPrint('FcmService init error: $e');
    }
  }
}
