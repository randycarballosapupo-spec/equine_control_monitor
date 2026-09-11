import 'package:flutter/material.dart';

import '../service/app_language.dart';
import '../service/auth_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    final language = widget.languageController.language;
    final password = passwordController.text.trim();
    if (password.length < 6 || password != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.translate(language, 'password_update_invalid'))),
      );
      return;
    }
    setState(() => saving = true);
    final updated = await AuthService.updatePassword(password);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.translate(language, updated ? 'password_updated' : 'password_update_error'))),
    );
    if (updated) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(title: Text(AppText.translate(language, 'reset_password'))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(AppText.translate(language, 'set_new_password')),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: AppText.translate(language, 'new_password'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: AppText.translate(language, 'confirm_password'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: const Icon(Icons.lock_reset),
                label: Text(AppText.translate(language, 'save')),
              ),
            ],
          ),
        );
      },
    );
  }
}