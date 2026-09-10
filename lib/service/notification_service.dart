import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  const NotificationService._();

  static const _enabledKey = 'notifications_enabled';
  static const _channelId = 'equiharmony_alerts';
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      'Equi Harmony avisos',
      description: 'Mensajes y publicaciones nuevas',
      importance: Importance.max,
    ));
    FirebaseMessaging.onMessage.listen((message) {
      show(message.notification?.title ?? 'Equi Harmony', message.notification?.body ?? 'Nuevo aviso');
    });
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      await FirebaseMessaging.instance.getToken();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } else {
      await FirebaseMessaging.instance.deleteToken();
    }
  }

  static Future<void> show(String title, String body) async {
    if (!await isEnabled()) return;
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Equi Harmony avisos',
          channelDescription: 'Mensajes y publicaciones nuevas',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Nuevo aviso',
        ),
      ),
    );
  }
}