import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../service/auth_service.dart';
import '../service/app_language.dart';

/// Exclusive maintenance panel for the app creator/owner account.
/// Unlike the regular admin screen, this bypasses every normal restriction:
/// the owner can approve, reject, promote, or delete ANY account, including
/// the primary administrator.
class OwnerPanelScreen extends StatefulWidget {
  const OwnerPanelScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<OwnerPanelScreen> createState() => _OwnerPanelScreenState();
}

class _OwnerPanelScreenState extends State<OwnerPanelScreen> {
  List<AppUser> users = [];
  bool loading = true;
  bool authorized = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isOwner = await AuthService.isCurrentOwner();
    if (!isOwner) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final values = await AuthService.users();
    if (!mounted) return;
    setState(() {
      users = values;
      authorized = true;
      loading = false;
    });
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
    await AuthService.deleteUser(user.email);
    await _load();
  }

  Future<void> _toggleApproval(AppUser user) async {
    await AuthService.updateUserStatus(user.email, user.isApproved ? 'rejected' : 'approved');
    await _load();
  }

  Future<void> _makePrimary(AppUser user) async {
    await AuthService.transferPrimaryAdmin(user.email);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black87,
            title: Text(AppText.get(language, 'owner_panel_title')),
            actions: [
              IconButton(
                tooltip: 'Mensajes al asistente',
                onPressed: () => Navigator.pushNamed(context, '/assistant-inbox'),
                icon: const Icon(Icons.support_agent),
              ),
            ],
          ),
          body: !authorized
              ? const SizedBox.shrink()
              : loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: user.isOwner
                                        ? Colors.amber
                                        : user.isPrimary
                                            ? Colors.deepPurple
                                            : null,
                                    child: Icon(user.isOwner ? Icons.workspace_premium : Icons.person),
                                  ),
                                  title: Text(user.name),
                                  subtitle: Text('${user.email}\n${AppText.get(language, 'status_label')}: ${user.status} · ${AppText.get(language, 'roles_label')}: ${user.roles.join(', ')}'),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _toggleApproval(user),
                                      icon: Icon(user.isApproved ? Icons.block : Icons.check),
                                      label: Text(
                                        AppText.get(language, user.isApproved ? 'reject' : 'approve'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isAdmin && !user.isPrimary)
                                      OutlinedButton.icon(
                                        onPressed: () => _makePrimary(user),
                                        icon: const Icon(Icons.swap_horiz),
                                        label: Text(
                                          AppText.get(language, 'transfer_primary_action'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    TextButton.icon(
                                      onPressed: () => _deleteUser(user),
                                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                                      label: Text(
                                        AppText.get(language, 'delete_account'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
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
