import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_config.dart';

class NotificationService {
  const NotificationService._();

  static const _enabledKey = 'notifications_enabled';
  static const _channelId = 'equiharmony_alerts_v2';
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
      playSound: true,
      enableVibration: true,
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
          playSound: true,
          enableVibration: true,
          ticker: 'Nuevo aviso',
        ),
      ),
    );
  }

  static Future<void> registerCurrentDevice() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await SupabaseConfig.client.from('device_tokens').upsert({
      'user_id': user.id,
      'token': token,
    }, onConflict: 'user_id,token');
  }

  static Future<void> notifyCareCompleted({required String taskId}) async {
    await SupabaseConfig.client.functions.invoke('send-care-notification', body: {'taskId': taskId});
  }
}