import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../service/auth_service.dart';
import '../service/access_service.dart';
import '../service/app_language.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> users = [];
  List<String> chatMembers = [];
  String? currentEmail;
  bool currentIsPrimary = false;
  bool currentIsOwner = false;
  bool loading = true;
  final Map<String, Set<String>> _pendingRoleSelections = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final isAdmin = await AuthService.isCurrentAdmin();
    final isOwner = await AuthService.isCurrentOwner();
    if (!isAdmin && !isOwner) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final values = await AuthService.users();
    final members = await AccessService.chatMembers();
    final current = await AuthService.currentUser();
    if (!mounted) return;
    setState(() {
      users = values;
      chatMembers = members;
      currentEmail = current?.email;
      currentIsPrimary = current?.isPrimary ?? false;
      currentIsOwner = current?.isOwner ?? false;
      loading = false;
    });
  }

  Future<void> _update(AppUser user, String status) async {
    await AuthService.updateUserStatus(user.email, status);
    await _loadUsers();
  }

  Future<void> _approveWithRoles(AppUser user) async {
    final language = widget.languageController.language;
    final roles = _pendingRoleSelections[user.email] ?? <String>{};
    if (roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.get(language, 'select_roles_required'))),
      );
      return;
    }
    await AuthService.approveUserWithRoles(user.email, roles.toList());
    _pendingRoleSelections.remove(user.email);
    await _loadUsers();
  }

  Future<void> _transferPrimaryAdmin(AppUser user) async {
    final language = widget.languageController.language;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppText.get(language, 'transfer_primary_title')),
        content: Text('${AppText.get(language, 'transfer_primary_confirm_prefix')} ${user.name}${AppText.get(language, 'transfer_primary_confirm_suffix')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppText.get(language, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppText.get(language, 'transfer_primary_action'))),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await AuthService.transferPrimaryAdmin(user.email);
    if (!mounted) return;
    await _loadUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.get(language, success ? 'transfer_primary_success' : 'transfer_primary_error'))),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    final language = widget.languageController.language;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppText.get(language, 'delete_account')),
        content: Text('${AppText.get(language, 'delete_account_confirm_prefix')} ${user.name}${AppText.get(language, 'delete_account_confirm_suffix')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppText.get(language, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppText.get(language, 'delete_account'))),
        ],
      ),
    );
    if (confirmed != true) return;
    final isSelf = user.email == currentEmail;
    final deleted = await AuthService.deleteUser(user.email);
    if (!mounted) return;
    if (deleted && isSelf) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      return;
    }
    await _loadUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.get(language, deleted ? 'account_deleted' : 'account_delete_error'))),
    );
  }

  Future<void> _addAdministrator() async {
    final language = widget.languageController.language;
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final stable = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.get(language, 'add_administrator')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: InputDecoration(labelText: AppText.get(language, 'name'))),
              TextField(controller: email, decoration: InputDecoration(labelText: AppText.get(language, 'email'))),
              TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: '${AppText.get(language, 'password')} (${AppText.get(language, 'min_password_chars')})')),
              TextField(controller: stable, decoration: InputDecoration(labelText: AppText.get(language, 'stable_label'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppText.get(language, 'cancel'))),
          FilledButton(
            onPressed: () async {
              final added = name.text.trim().isNotEmpty &&
                  password.text.trim().length >= 6 &&
                  await AuthService.addAdministrator(
                    email: email.text,
                    password: password.text,
                    name: name.text,
                    stableName: stable.text,
                  );
              if (!context.mounted) return;
              Navigator.pop(context, added);
            },
            child: Text(AppText.get(language, 'add')),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
    password.dispose();
    stable.dispose();
    if (!mounted) return;
    await _loadUsers();
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.get(language, result ? 'administrator_added' : 'administrator_add_error'))),
      );
    }
  }

  Future<void> _createUser() async {
    final language = widget.languageController.language;
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final stable = TextEditingController();
    final roles = <String>{};
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppText.get(language, 'create_user')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: InputDecoration(labelText: AppText.get(language, 'name'))),
                TextField(controller: email, decoration: InputDecoration(labelText: AppText.get(language, 'email'))),
                TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: '${AppText.get(language, 'password')} (${AppText.get(language, 'min_password_chars')})')),
                TextField(controller: stable, decoration: InputDecoration(labelText: AppText.get(language, 'stable_label'))),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(AppText.get(language, 'select_roles'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...{
                  'admin': AppText.get(language, 'role_admin'),
                  'owner': AppText.get(language, 'role_owner'),
                  'veterinarian': AppText.get(language, 'role_veterinarian'),
                }.entries.map((entry) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: roles.contains(entry.key),
                      title: Text(entry.value),
                      onChanged: (checked) => setDialogState(() {
                        if (checked == true) {
                          roles.add(entry.key);
                        } else {
                          roles.remove(entry.key);
                        }
                      }),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppText.get(language, 'cancel'))),
            FilledButton(
              onPressed: () async {
                final added = name.text.trim().isNotEmpty &&
                    password.text.trim().length >= 6 &&
                    roles.isNotEmpty &&
                    await AuthService.createUser(
                      email: email.text,
                      password: password.text,
                      name: name.text,
                      stableName: stable.text,
                      roles: roles.toList(),
                    );
                if (!context.mounted) return;
                Navigator.pop(context, added);
              },
              child: Text(AppText.get(language, 'add')),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    password.dispose();
    stable.dispose();
    if (!mounted) return;
    await _loadUsers();
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.get(language, result ? 'user_created' : 'user_create_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppText.get(language, 'validate_users')),
            actions: [
              if (currentIsOwner)
                IconButton(
                  tooltip: AppText.get(language, 'create_user'),
                  onPressed: _createUser,
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              if (currentIsPrimary || currentIsOwner)
                IconButton(
                  tooltip: AppText.get(language, 'add_administrator'),
                  onPressed: _addAdministrator,
                  icon: const Icon(Icons.admin_panel_settings),
                ),
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
                  ? Center(child: Text(AppText.get(language, 'no_users')))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isPending = user.status == 'pending';
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(user.name),
                                    subtitle: Text('${user.email}\n${AppText.get(language, 'status_label')}: ${user.status}'),
                                ),
                                Text('${AppText.get(language, 'roles_label')}: ${user.roles.join(', ')}'),
                                if (user.stableName.isNotEmpty) Text('${AppText.get(language, 'stable_label')}: ${user.stableName}'),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(AppText.get(language, 'chat_room_access')),
                                  value: chatMembers.contains(user.email),
                                  onChanged: user.isApproved
                                      ? (enabled) async {
                                          await AccessService.setChatAccess(user.email, enabled);
                                          await _loadUsers();
                                        }
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                if (isPending) ...[
                                  Text(AppText.get(language, 'select_roles'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ...{
                                    'admin': AppText.get(language, 'role_admin'),
                                    'owner': AppText.get(language, 'role_owner'),
                                    'veterinarian': AppText.get(language, 'role_veterinarian'),
                                  }.entries.map((entry) {
                                    final selected = _pendingRoleSelections[user.email] ?? <String>{};
                                    return CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      value: selected.contains(entry.key),
                                      title: Text(entry.value),
                                      onChanged: (checked) => setState(() {
                                        final set = _pendingRoleSelections.putIfAbsent(user.email, () => <String>{});
                                        if (checked == true) {
                                          set.add(entry.key);
                                        } else {
                                          set.remove(entry.key);
                                        }
                                      }),
                                    );
                                  }),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _update(user, 'rejected'),
                                          icon: const Icon(Icons.close),
                                          label: Text(AppText.get(language, 'reject'), overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () => _approveWithRoles(user),
                                          icon: const Icon(Icons.check),
                                          label: Text(AppText.get(language, 'approve'), overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if ((currentIsPrimary || currentIsOwner) && user.isAdmin && user.isApproved && user.email != currentEmail)
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: () => _transferPrimaryAdmin(user),
                                      icon: const Icon(Icons.swap_horiz),
                                      label: Text(
                                        AppText.get(language, 'transfer_primary_action'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () => _deleteUser(user),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    label: Text(
                                      AppText.get(language, 'delete_account'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
