import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/app_language.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isSaving = false;
  bool hidePassword = true;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register(AppLanguage language) async {
    if (isSaving) return;
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.length < 6) {
      _message(AppText.translate(language, 'fill_required_fields'));
      return;
    }
    setState(() => isSaving = true);
    try {
      // El rol y la aprobación final los asigna el administrador/asistente desde su panel.
      final registrationError = await AuthService.registerUser(
        email: emailCtrl.text,
        password: passCtrl.text,
        name: nameCtrl.text,
        roles: const [],
        stableName: '',
        birthDate: DateTime(2000, 1, 1),
      );

      if (!mounted) return;
      if (registrationError != null) {
        setState(() => isSaving = false);
        await _showResult(
          AppText.translate(language, 'account_error_title'),
          '${AppText.translate(language, 'account_error_message_prefix')} $registrationError',
        );
        return;
      }
      final users = await AuthService.users();
      if (!mounted) return;
      final createdUser = users.firstWhere(
        (user) => user.email == emailCtrl.text.trim().toLowerCase(),
      );
      if (createdUser.isAdmin && createdUser.isApproved) {
        if (!mounted) return;
        await _showResult(AppText.translate(language, 'account_created_title'), AppText.translate(language, 'account_created_message'));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        return;
      }
      await AuthService.logout();
      setState(() => isSaving = false);
      await _showResult(
        AppText.translate(language, 'request_sent_title'),
        AppText.translate(language, 'request_sent_message'),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => isSaving = false);
      await _showResult(AppText.translate(language, 'account_error_title'), '${AppText.translate(language, 'account_error_message_prefix')} $error');
    }
  }

  Future<void> _showResult(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppText.translate(widget.languageController.language, 'accept')),
          ),
        ],
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(title: Text(AppText.translate(language, 'create_account'))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppText.translate(language, 'register_pending_notice'),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppText.translate(language, 'name'), border: const OutlineInputBorder())),
              const SizedBox(height: 14),
              TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: AppText.translate(language, 'email'), border: const OutlineInputBorder())),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: AppText.translate(language, 'password'),
                  helperText: AppText.translate(language, 'min_password_chars'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: AppText.translate(language, hidePassword ? 'show_password' : 'hide_password'),
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                    icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isSaving ? null : () => _register(language),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.how_to_reg),
                label: Text(isSaving ? AppText.translate(language, 'saving') : AppText.translate(language, 'submit_request')),
              ),
            ],
          ),
        );
      },
    );
  }
}
