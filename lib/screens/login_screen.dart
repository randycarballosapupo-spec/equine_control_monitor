import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/app_language.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    AuthService.rememberedEmail().then((email) {
      if (mounted && email.isNotEmpty) setState(() => emailCtrl.text = email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFFF3F2EE)),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/equi_harmony_logo.png',
                        height: 220,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppText.get(language, 'welcome_message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF2E4D2E),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: emailCtrl,
                        style: const TextStyle(color: Color(0xFF2E4D2E)),
                        decoration: InputDecoration(
                          labelText: AppText.get(language, 'email'),
                          labelStyle: const TextStyle(color: Color(0xFF2E4D2E)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passCtrl,
                        obscureText: hidePassword,
                        style: const TextStyle(color: Color(0xFF2E4D2E)),
                        decoration: InputDecoration(
                          labelText: AppText.get(language, 'password'),
                          labelStyle: const TextStyle(color: Color(0xFF2E4D2E)),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            tooltip: AppText.get(language, hidePassword ? 'show_password' : 'hide_password'),
                            onPressed: () => setState(() => hidePassword = !hidePassword),
                            icon: Icon(
                              hidePassword ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF2E4D2E),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E4D2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          final ok = await AuthService.login(
                            emailCtrl.text.trim(),
                            passCtrl.text.trim(),
                          );

                          if (!context.mounted) return;
                          if (ok) {
                            await AuthService.rememberEmail(emailCtrl.text);
                            await widget.languageController.loadForCurrentUser();
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/dashboard');
                          } else {
                            final reasonKey = await AuthService.loginFailureReason(
                              emailCtrl.text,
                              passCtrl.text,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppText.get(language, reasonKey))),
                            );
                          }
                        },
                        child: Text(
                          AppText.get(language, 'login').toUpperCase(),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/assistant-contact'),
                          icon: const Icon(Icons.support_agent),
                          label: const Text('Atención al usuario'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB8860B),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/admin-login'),
                            icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF2E4D2E)),
                            label: Text(
                              AppText.get(language, 'admin_access').toUpperCase(),
                              style: const TextStyle(color: Color(0xFF2E4D2E)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              AppText.get(language, 'create_account').toUpperCase(),
                              style: const TextStyle(color: Color(0xFF2E4D2E)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/recover');
                            },
                            child: Text(
                              AppText.get(language, 'forgot_password').toUpperCase(),
                              style: const TextStyle(color: Color(0xFF2E4D2E)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}