import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/app_language.dart';
import '../models/app_user.dart';
import '../service/auth_service.dart';
import '../service/access_service.dart';
import '../service/supabase_config.dart';
import '../service/notification_service.dart';
import '../service/presence_service.dart';

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
        title: Text(AppText.translate(language, 'support_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppText.translate(language, 'support_message')),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                await Clipboard.setData(const ClipboardData(text: blickNumber));
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(AppText.translate(language, 'number_copied'))),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text('${AppText.translate(language, 'blick_number')}: $blickNumber',
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
            child: Text(AppText.translate(language, 'close')),
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
            title: Text(AppText.translate(language, 'dashboard')),
            actions: [
              PresenceButton(languageController: languageController),
              FutureBuilder<bool>(
                future: AuthService.isCurrentOwner(),
                builder: (context, ownerSnapshot) {
                  if (ownerSnapshot.data != true) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: AppText.translate(language, 'owner_panel_title'),
                    onPressed: () => Navigator.pushNamed(context, '/owner-panel'),
                    icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                  );
                },
              ),
              IconButton(
                tooltip: AppText.translate(language, 'support_us'),
                onPressed: () => _showSupportDialog(context, language),
                icon: const Icon(Icons.volunteer_activism),
              ),
              NotificationBell(languageController: languageController),
              IconButton(
                tooltip: AppText.translate(language, 'settings'),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                icon: const Icon(Icons.settings),
              ),
              IconButton(
                tooltip: AppText.translate(language, 'stable_facebook'),
                onPressed: () => launchUrl(Uri.parse(stableFacebookUrl), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.facebook),
              ),
              IconButton(
                tooltip: AppText.translate(language, 'logout'),
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
                        SnackBar(content: Text('${AppText.translate(language, 'pending_users_notice')} ($pending)')),
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
                        AppText.translate(language, 'work_area'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (user != null)
                        Text(
                          '${AppText.translate(language, 'welcome')}, ${user.name}${user.stableName.isEmpty ? '' : ' · ${user.stableName}'}',
                          style: const TextStyle(color: Colors.white, fontSize: 17),
                        ),
                      if (user != null) const SizedBox(height: 8),
                      Text(
                        AppText.translate(language, 'choose_module'),
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
                          FutureBuilder<Uint8List?>(
                            future: _profilePhoto('owner'),
                            builder: (context, photoSnapshot) => _moduleCard(context, language, 'owner', 'owner_subtitle', Icons.person, Colors.blueGrey, '/owner', Alignment.bottomLeft, profilePhoto: photoSnapshot.data),
                          ),
                          FutureBuilder<Uint8List?>(
                            future: _firstAnimalPhoto(),
                            builder: (context, photoSnapshot) => _moduleCard(context, language, 'your_friends', 'horse_subtitle', null, Colors.teal, '/animals', Alignment.centerLeft, profilePhoto: photoSnapshot.data),
                          ),
                          _moduleCard(context, language, 'veterinarian', 'veterinarian_subtitle', Icons.medical_services, Colors.redAccent, '/veterinarian', Alignment.center),
                          _moduleCard(context, language, 'monitoring', 'monitoring_subtitle', Icons.monitor_heart, Colors.orange, '/monitoring', Alignment.centerRight),
                          _moduleCard(context, language, 'records', 'records_subtitle', Icons.assignment, Colors.indigo, '/records', Alignment.topCenter),
                          _moduleCard(context, language, 'care_plan', 'care_subtitle', Icons.medication, Colors.pink, '/care', Alignment.bottomRight),
                          _moduleCard(context, language, 'shared_care', 'shared_care_subtitle', Icons.calendar_month, Colors.cyan, '/shared-care', Alignment.topLeft),
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
    {Uint8List? profilePhoto}
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (route != null) {
            Navigator.pushNamed(context, route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppText.translate(language, 'in_development'))),
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
                    profilePhoto != null
                      ? CircleAvatar(radius: 20, backgroundImage: MemoryImage(profilePhoto))
                      : icon == null ? const Text('🐴', style: TextStyle(fontSize: 26)) : Icon(icon, color: color, size: 34),
                  const SizedBox(height: 4),
                  Text(
                    AppText.translate(language, titleKey),
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppText.translate(language, subtitleKey),
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

  Future<Uint8List?> _profilePhoto(String profileType) async {
    final key = await AccessService.scopedKey(profileType);
    final encoded = (await SharedPreferences.getInstance()).getString('${key}_photo');
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _firstAnimalPhoto() async {
    final key = await AccessService.scopedKey('animals');
    final encodedAnimals = (await SharedPreferences.getInstance()).getString(key);
    if (encodedAnimals == null || encodedAnimals.isEmpty) return null;
    try {
      final animals = jsonDecode(encodedAnimals) as List;
      final encodedPhoto = animals
          .cast<Map>()
          .map((animal) => '${animal['photo'] ?? ''}')
          .firstWhere((photo) => photo.isNotEmpty, orElse: () => '');
      return encodedPhoto.isEmpty ? null : base64Decode(encodedPhoto);
    } catch (_) {
      return null;
    }
  }

  Drawer _buildDrawer(BuildContext context, AppLanguage language) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(AppText.translate(language, 'admin_role')),
            accountEmail: const Text('Equi_Harmony_Monitor'),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
          ),
          ListTile(
            leading: const Text('🐴', style: TextStyle(fontSize: 22)),
            title: Text(AppText.translate(language, 'horses')),
            onTap: () => Navigator.pushNamed(context, '/horse'),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: Text(AppText.translate(language, 'veterinarian')),
            onTap: () => Navigator.pushNamed(context, '/veterinarian'),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: Text(AppText.translate(language, 'monitoring')),
            onTap: () => Navigator.pushNamed(context, '/monitoring'),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(AppText.translate(language, 'records')),
            onTap: () => Navigator.pushNamed(context, '/records'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppText.translate(language, 'owner')),
            onTap: () => Navigator.pushNamed(context, '/owner'),
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: Text(AppText.translate(language, 'care_plan')),
            onTap: () => Navigator.pushNamed(context, '/care'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(AppText.translate(language, 'report')),
            onTap: () => Navigator.pushNamed(context, '/report'),
          ),
          FutureBuilder<bool>(
            future: AuthService.isCurrentAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(AppText.translate(language, 'cctv')),
                onTap: () => Navigator.pushNamed(context, '/cctv'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppText.translate(language, 'settings')),
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
                    title: Text(AppText.translate(language, 'user_management')),
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
                title: Text(AppText.translate(language, 'chat')),
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
                title: Text(AppText.translate(language, 'feed')),
                onTap: () => Navigator.pushNamed(context, '/feed'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.facebook),
            title: Text(AppText.translate(language, 'stable_facebook')),
            onTap: () => launchUrl(Uri.parse(stableFacebookUrl), mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppText.translate(language, 'logout')),
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

class PresenceButton extends StatefulWidget {
  const PresenceButton({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<PresenceButton> createState() => _PresenceButtonState();
}

class _PresenceButtonState extends State<PresenceButton> {
  PresenceSession? session;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = await PresenceService.activeSession();
    if (mounted) setState(() { session = current; loading = false; });
  }

  Future<void> _toggle() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      if (session == null) {
        session = await PresenceService.checkIn();
      } else {
        await PresenceService.checkOut(session!.id);
        session = null;
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        final active = session != null;
        final time = active ? TimeOfDay.fromDateTime(session!.enteredAt).format(context) : '';
        return IconButton(
          tooltip: active
              ? '${AppText.translate(language, 'active_since')} $time'
              : AppText.translate(language, 'mark_active'),
          onPressed: _toggle,
          icon: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Badge(
                  isLabelVisible: active,
                  label: const SizedBox(width: 7, height: 7),
                  backgroundColor: Colors.green,
                  child: Icon(active ? Icons.login : Icons.logout, color: active ? Colors.green : null),
                ),
        );
      },
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
      if (postsReady) {
        final newIds = ids.difference(knownPostIds);
        unread += newIds.length;
        if (newIds.isNotEmpty) {
          final language = widget.languageController.language;
          NotificationService.show(
            AppText.translate(language, 'new_feed_notification_title'),
            AppText.translate(language, 'new_feed_notification_body'),
          );
        }
      }
      knownPostIds = ids;
      postsReady = true;
      if (mounted) setState(() {});
    });
    _messagesSubscription = SupabaseConfig.client.from('messages').stream(primaryKey: ['id']).listen((rows) {
      final ids = rows
          .where((row) => '${row['sender_email'] ?? ''}' != (user.email ?? ''))
          .map((row) => '${row['id']}')
          .toSet();
      if (messagesReady) {
        final newIds = ids.difference(knownMessageIds);
        unread += newIds.length;
        if (newIds.isNotEmpty) {
          final language = widget.languageController.language;
          NotificationService.show(
            AppText.translate(language, 'new_chat_notification_title'),
            AppText.translate(language, 'new_chat_notification_body'),
          );
        }
      }
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
        if (messagesReady) {
          final newIds = ids.difference(knownAssistantIds);
          unread += newIds.length;
          if (newIds.isNotEmpty) {
            final language = widget.languageController.language;
            NotificationService.show(
              AppText.translate(language, 'new_assistant_notification_title'),
              AppText.translate(language, 'new_assistant_notification_body'),
            );
          }
        }
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
            title: Text(AppText.translate(widget.languageController.language, 'notifications')),
            content: Text(AppText.translate(widget.languageController.language, 'notifications_empty')),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppText.translate(widget.languageController.language, 'close')),
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
