import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/app_language.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (loading) return;
    setState(() => loading = true);
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final valid = await AuthService.login(email, password);
      if (valid) {
        final user = await AuthService.currentUser();
        if (user != null && user.isAdmin) {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          return;
        }
        await AuthService.logout();
      }
    } catch (_) {
      // Fall through to the generic error message below.
    }

    if (!mounted) return;
    final language = widget.languageController.language;
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.get(language, 'invalid_admin_credentials'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(title: Text(AppText.get(language, 'admin_access'))),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.admin_panel_settings, size: 72, color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                AppText.get(language, 'admin_only_access'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppText.get(language, 'admin_email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: AppText.get(language, 'password'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                    icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: loading ? null : _login,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(loading ? AppText.get(language, 'checking') : AppText.get(language, 'enter_as_admin')),
              ),
            ],
          ),
        );
      },
    );
  }
}

