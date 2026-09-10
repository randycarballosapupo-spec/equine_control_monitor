import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'service/app_language.dart';
import 'service/supabase_config.dart';
import 'service/notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/recover_screen.dart';
import 'screens/profile_form_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/records_screen.dart';
import 'screens/care_plan_screen.dart';
import 'screens/report_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/cctv_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/owner_panel_screen.dart';
import 'screens/assistant_contact_screen.dart';
import 'screens/assistant_inbox_screen.dart';
import 'screens/animals_screen.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  if (await NotificationService.isEnabled()) {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  }
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('Firebase Messaging token: $token');
  await SupabaseConfig.initialize();
  runApp(const EquineApp());
}

class EquineApp extends StatefulWidget {
  const EquineApp({super.key});

  @override
  State<EquineApp> createState() => _EquineAppState();
}

class _EquineAppState extends State<EquineApp> {
  final languageController = AppLanguageController();

  @override
  void initState() {
    super.initState();
    languageController.load();
  }

  @override
  void dispose() {
    languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) => MaterialApp(
        title: 'Equi_Harmony_Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(languageController: languageController),
          '/': (context) => LoginScreen(languageController: languageController),
          '/register': (context) => RegisterScreen(languageController: languageController),
          '/recover': (context) => RecoverScreen(languageController: languageController),
          '/dashboard': (context) => DashboardScreen(
                languageController: languageController,
              ),
          '/settings': (context) => SettingsScreen(
                languageController: languageController,
              ),
          '/horse': (context) => ProfileFormScreen(
                languageController: languageController,
                isHorse: true,
              ),
          '/animals': (context) => AnimalsScreen(languageController: languageController),
          '/veterinarian': (context) => ProfileFormScreen(
                languageController: languageController,
                isHorse: false,
              ),
          '/monitoring': (context) => MonitoringScreen(
                languageController: languageController,
              ),
          '/records': (context) => RecordsScreen(
                languageController: languageController,
              ),
          '/owner': (context) => ProfileFormScreen(
                languageController: languageController,
                isHorse: false,
                isOwner: true,
              ),
          '/care': (context) => CarePlanScreen(
                languageController: languageController,
              ),
          '/report': (context) => ReportScreen(
                languageController: languageController,
              ),
          '/user-management': (context) => UserManagementScreen(languageController: languageController),
          '/chat': (context) => ChatScreen(languageController: languageController),
          '/admin-login': (context) => AdminLoginScreen(languageController: languageController),
          '/cctv': (context) => CctvScreen(languageController: languageController),
          '/feed': (context) => FeedScreen(languageController: languageController),
          '/owner-panel': (context) => OwnerPanelScreen(languageController: languageController),
          '/assistant-contact': (context) => AssistantContactScreen(languageController: languageController),
          '/assistant-inbox': (context) => AssistantInboxScreen(languageController: languageController),
        },
      ),
    );
  }
}