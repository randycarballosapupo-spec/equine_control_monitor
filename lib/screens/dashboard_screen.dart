import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/app_language.dart';
import '../models/app_user.dart';
import '../service/auth_service.dart';
import '../service/access_service.dart';
import '../service/supabase_config.dart';
import '../service/notification_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  static const blickNumber = '726829335';
  static const stableFacebookUrl =
      'https://www.facebook.com/photo/?fbid=122106458702977371&set=a.122106269954977371';
  static bool _pendingNoticeShown = false;

  void _showSupportDialog(BuildContext context, AppLanguage language) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppText.get(language, 'support_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppText.get(language, 'support_message')),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                await Clipboard.setData(const ClipboardData(text: blickNumber));
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(AppText.get(language, 'number_copied'))),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text('${AppText.get(language, 'blick_number')}: $blickNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 18),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppText.get(language, 'close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        final language = languageController.language;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppText.get(language, 'dashboard')),
            actions: [
              FutureBuilder<bool>(
                future: AuthService.isCurrentOwner(),
                builder: (context, ownerSnapshot) {
                  if (ownerSnapshot.data != true) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: AppText.get(language, 'owner_panel_title'),
                    onPressed: () => Navigator.pushNamed(context, '/owner-panel'),
                    icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                  );
                },
              ),
              IconButton(
                tooltip: AppText.get(language, 'support_us'),
                onPressed: () => _showSupportDialog(context, language),
                icon: const Icon(Icons.volunteer_activism),
              ),
              NotificationBell(languageController: languageController),
              IconButton(
                tooltip: AppText.get(language, 'settings'),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                icon: const Icon(Icons.settings),
              ),
              IconButton(
                tooltip: AppText.get(language, 'stable_facebook'),
                onPressed: () => launchUrl(Uri.parse(stableFacebookUrl), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.facebook),
              ),
              IconButton(
                tooltip: AppText.get(language, 'logout'),
                onPressed: () async {
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: _buildDrawer(context, language),
          body: FutureBuilder<AppUser?>(
            future: AuthService.currentUser(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user?.isAdmin == true && !_pendingNoticeShown) {
                AuthService.pendingUsersCount().then((pending) {
                  if (pending > 0 && !_pendingNoticeShown && context.mounted) {
                    _pendingNoticeShown = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${AppText.get(language, 'pending_users_notice')} ($pending)')),
                      );
                    });
                  }
                });
              }
              return Stack(
                fit: StackFit.expand,
                children: [
              Image.asset('assets/images/caballos_fondo.jpg', fit: BoxFit.cover),
              Container(color: Colors.black.withValues(alpha: 0.48)),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppText.get(language, 'work_area'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (user != null)
                        Text(
                          '${AppText.get(language, 'welcome')}, ${user.name}${user.stableName.isEmpty ? '' : ' · ${user.stableName}'}',
                          style: const TextStyle(color: Colors.white, fontSize: 17),
                        ),
                      if (user != null) const SizedBox(height: 8),
                      Text(
                        AppText.get(language, 'choose_module'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.9,
                        children: [
                          _moduleCard(context, language, 'your_friends', 'horse_subtitle', null, Colors.teal, '/animals', Alignment.centerLeft),
                          _moduleCard(context, language, 'veterinarian', 'veterinarian_subtitle', Icons.medical_services, Colors.redAccent, '/veterinarian', Alignment.center),
                          _moduleCard(context, language, 'monitoring', 'monitoring_subtitle', Icons.monitor_heart, Colors.orange, '/monitoring', Alignment.centerRight),
                          _moduleCard(context, language, 'records', 'records_subtitle', Icons.assignment, Colors.indigo, '/records', Alignment.topCenter),
                          _moduleCard(context, language, 'owner', 'owner_subtitle', Icons.person, Colors.blueGrey, '/owner', Alignment.bottomLeft),
                          _moduleCard(context, language, 'care_plan', 'care_subtitle', Icons.medication, Colors.pink, '/care', Alignment.bottomRight),
                          _moduleCard(context, language, 'report', 'report_subtitle', Icons.picture_as_pdf, Colors.deepPurple, '/report', Alignment.center),
                          if (user?.isAdmin == true)
                            _moduleCard(context, language, 'cctv', 'cctv_subtitle', Icons.videocam, Colors.black87, '/cctv', Alignment.centerRight),
                          if (user?.isAdmin == true)
                            FutureBuilder<int>(
                              future: AuthService.pendingUsersCount(),
                              builder: (context, pendingSnapshot) {
                                final pending = pendingSnapshot.data ?? 0;
                                return Stack(
                                  children: [
                                    _moduleCard(context, language, 'user_management', 'user_management_subtitle', Icons.verified_user, Colors.green, '/user-management', Alignment.topRight),
                                    if (pending > 0)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: CircleAvatar(
                                          radius: 11,
                                          backgroundColor: Colors.red,
                                          child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          FutureBuilder<bool>(
                            future: AccessService.canUseChat(),
                            builder: (context, chatSnapshot) {
                              if (chatSnapshot.data != true) return const SizedBox.shrink();
                              return _moduleCard(context, language, 'chat', 'chat_subtitle', Icons.chat, Colors.blue, '/chat', Alignment.bottomCenter);
                            },
                          ),
                          FutureBuilder<bool>(
                            future: AccessService.canUseChat(),
                            builder: (context, feedSnapshot) {
                              if (feedSnapshot.data != true) return const SizedBox.shrink();
                              return _moduleCard(context, language, 'feed', 'feed_subtitle', Icons.dynamic_feed, Colors.purple, '/feed', Alignment.center);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _moduleCard(
    BuildContext context,
    AppLanguage language,
    String titleKey,
    String subtitleKey,
    IconData? icon,
    Color color,
    String? route,
    Alignment imageAlignment,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (route != null) {
            Navigator.pushNamed(context, route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppText.get(language, 'in_development'))),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/caballos_fondo.jpg',
              fit: BoxFit.cover,
              alignment: imageAlignment,
              color: color.withValues(alpha: 0.42),
              colorBlendMode: BlendMode.modulate,
            ),
            Container(color: Colors.white.withValues(alpha: 0.72)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon == null ? const Text('🐴', style: TextStyle(fontSize: 26)) : Icon(icon, color: color, size: 34),
                  const SizedBox(height: 4),
                  Text(
                    AppText.get(language, titleKey),
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppText.get(language, subtitleKey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, AppLanguage language) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(AppText.get(language, 'admin_role')),
            accountEmail: const Text('Equi_Harmony_Monitor'),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
          ),
          ListTile(
            leading: const Text('🐴', style: TextStyle(fontSize: 22)),
            title: Text(AppText.get(language, 'horses')),
            onTap: () => Navigator.pushNamed(context, '/horse'),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: Text(AppText.get(language, 'veterinarian')),
            onTap: () => Navigator.pushNamed(context, '/veterinarian'),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: Text(AppText.get(language, 'monitoring')),
            onTap: () => Navigator.pushNamed(context, '/monitoring'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(AppText.get(language, 'records')),
            onTap: () => Navigator.pushNamed(context, '/records'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppText.get(language, 'owner')),
            onTap: () => Navigator.pushNamed(context, '/owner'),
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: Text(AppText.get(language, 'care_plan')),
            onTap: () => Navigator.pushNamed(context, '/care'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(AppText.get(language, 'report')),
            onTap: () => Navigator.pushNamed(context, '/report'),
          ),
          FutureBuilder<bool>(
            future: AuthService.isCurrentAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(AppText.get(language, 'cctv')),
                onTap: () => Navigator.pushNamed(context, '/cctv'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppText.get(language, 'settings')),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          FutureBuilder<bool>(
            future: AuthService.isCurrentAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return FutureBuilder<int>(
                future: AuthService.pendingUsersCount(),
                builder: (context, pendingSnapshot) {
                  final pending = pendingSnapshot.data ?? 0;
                  return ListTile(
                    leading: const Icon(Icons.verified_user),
                    title: Text(AppText.get(language, 'user_management')),
                    trailing: pending > 0
                        ? CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.red,
                            child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        : null,
                    onTap: () => Navigator.pushNamed(context, '/user-management'),
                  );
                },
              );
            },
          ),
          FutureBuilder<bool>(
            future: AccessService.canUseChat(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.chat),
                title: Text(AppText.get(language, 'chat')),
                onTap: () => Navigator.pushNamed(context, '/chat'),
              );
            },
          ),
          FutureBuilder<bool>(
            future: AccessService.canUseChat(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.dynamic_feed),
                title: Text(AppText.get(language, 'feed')),
                onTap: () => Navigator.pushNamed(context, '/feed'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.facebook),
            title: Text(AppText.get(language, 'stable_facebook')),
            onTap: () => launchUrl(Uri.parse(stableFacebookUrl), mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppText.get(language, 'logout')),
            onTap: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  StreamSubscription<List<Map<String, dynamic>>>? _postsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _assistantSubscription;
  Set<String> knownPostIds = {};
  Set<String> knownMessageIds = {};
  Set<String> knownAssistantIds = {};
  bool postsReady = false;
  bool messagesReady = false;
  int unread = 0;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  Future<void> _subscribe() async {
    notificationsEnabled = await NotificationService.isEnabled();
    if (!notificationsEnabled) {
      if (mounted) setState(() {});
      return;
    }
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final isOwner = await AuthService.isCurrentOwner();
    _postsSubscription = SupabaseConfig.client.from('posts').stream(primaryKey: ['id']).listen((rows) {
      final ids = rows.map((row) => '${row['id']}').toSet();
      if (postsReady) unread += ids.difference(knownPostIds).length;
      knownPostIds = ids;
      postsReady = true;
      if (mounted) setState(() {});
    });
    _messagesSubscription = SupabaseConfig.client.from('messages').stream(primaryKey: ['id']).listen((rows) {
      final ids = rows
          .where((row) => '${row['sender_email'] ?? ''}' != (user.email ?? ''))
          .map((row) => '${row['id']}')
          .toSet();
      if (messagesReady) unread += ids.difference(knownMessageIds).length;
      knownMessageIds = ids;
      messagesReady = true;
      if (mounted) setState(() {});
    });
    if (isOwner) {
      _assistantSubscription = SupabaseConfig.client.from('assistant_messages').stream(primaryKey: ['id']).listen((rows) {
        final ids = rows
            .where((row) => '${row['sender_email'] ?? ''}' != (user.email ?? ''))
            .map((row) => '${row['id']}')
            .toSet();
        if (messagesReady) unread += ids.difference(knownAssistantIds).length;
        knownAssistantIds = ids;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _assistantSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        setState(() => unread = 0);
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppText.get(widget.languageController.language, 'notifications')),
            content: Text(AppText.get(widget.languageController.language, 'notifications_empty')),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppText.get(widget.languageController.language, 'close')),
              ),
            ],
          ),
        );
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(notificationsEnabled ? Icons.notifications_outlined : Icons.notifications_off_outlined),
      ),
    );
  }
}
