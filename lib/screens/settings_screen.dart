import 'package:flutter/material.dart';
import '../service/app_language.dart';
import '../service/auth_service.dart';
import '../service/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  static const languages = {
    AppLanguage.pl: 'Polski',
    AppLanguage.es: 'Español',
    AppLanguage.de: 'Deutsch',
    AppLanguage.nl: 'Nederlands',
    AppLanguage.fr: 'Français',
    AppLanguage.en: 'English',
    AppLanguage.pt: 'Português',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        final language = languageController.language;
        return Scaffold(
          appBar: AppBar(title: Text(AppText.translate(language, 'settings'))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.translate, size: 56, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                AppText.translate(language, 'language'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppLanguage>(
                initialValue: language,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: languages.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) languageController.setLanguage(value);
                },
              ),
              const SizedBox(height: 32),
              FutureBuilder<bool>(
                future: NotificationService.isEnabled(),
                builder: (context, snapshot) {
                  var enabled = snapshot.data ?? true;
                  return StatefulBuilder(
                    builder: (context, setSwitchState) => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: Text(AppText.translate(language, 'notifications')),
                    value: enabled,
                    onChanged: (value) async {
                      enabled = value;
                      setSwitchState(() {});
                      await NotificationService.setEnabled(value);
                    },
                    ),
                  );
                },
              ),
              const Divider(),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.support_agent),
                label: Text(AppText.translate(language, 'user_support')),
                onPressed: () => Navigator.pushNamed(context, '/assistant-contact'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(AppText.translate(language, 'delete_local_account')),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(AppText.translate(language, 'delete_account')),
                      content: Text(AppText.translate(language, 'delete_account_warning')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppText.translate(language, 'cancel'))),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppText.translate(language, 'delete'))),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  await AuthService.deleteCurrentUser();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
              ),
              const SizedBox(height: 8),
              Text(AppText.translate(language, 'password_privacy_note'), style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
