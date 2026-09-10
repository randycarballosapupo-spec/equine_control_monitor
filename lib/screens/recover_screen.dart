import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/app_language.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final emailCtrl = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final language = widget.languageController.language;
    setState(() => isSending = true);
    final sent = await AuthService.resetPassword(emailCtrl.text);
    if (!mounted) return;
    setState(() => isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppText.get(language, sent ? 'reset_link_sent' : 'email_not_found')),
      ),
    );
    if (sent) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(title: Text(AppText.get(language, 'reset_password'))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(AppText.get(language, 'reset_link_instructions')),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppText.get(language, 'email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isSending ? null : _sendResetLink,
                icon: const Icon(Icons.lock_reset),
                label: Text(AppText.get(language, 'reset_password')),
              ),
            ],
          ),
        );
      },
    );
  }
}
