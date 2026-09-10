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
  final stableCtrl = TextEditingController();
  DateTime? birthDate;
  final selectedRoles = <String>{};
  bool isSaving = false;
  bool hidePassword = true;
  bool hasPrimaryAdmin = true;

  @override
  void initState() {
    super.initState();
    AuthService.hasPrimaryAdmin().then((value) {
      if (mounted) setState(() => hasPrimaryAdmin = value);
    });
  }

  Map<String, String> _roleOptions(AppLanguage language) => {
        if (!hasPrimaryAdmin) 'admin': AppText.get(language, 'role_admin'),
        'owner': AppText.get(language, 'role_owner'),
        'veterinarian': AppText.get(language, 'role_veterinarian'),
      };

  bool _isAdult(DateTime date) {
    final today = DateTime.now();
    var age = today.year - date.year;
    if (today.month < date.month || (today.month == date.month && today.day < date.day)) age--;
    return age >= 18;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    stableCtrl.dispose();
    super.dispose();
  }

  Future<void> _register(AppLanguage language) async {
    if (isSaving) return;
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.length < 6 ||
        birthDate == null ||
        selectedRoles.isEmpty) {
      _message(AppText.get(language, 'fill_required_fields'));
      return;
    }
    if (!_isAdult(birthDate!)) {
      _message(AppText.get(language, 'age_restriction'));
      return;
    }
    setState(() => isSaving = true);
    try {
      final registrationError = await AuthService.registerUser(
        email: emailCtrl.text,
        password: passCtrl.text,
        name: nameCtrl.text,
        roles: selectedRoles.toList(),
        stableName: stableCtrl.text,
        birthDate: birthDate!,
      );

      if (!mounted) return;
      if (registrationError != null) {
        setState(() => isSaving = false);
        await _showResult(
          AppText.get(language, 'account_error_title'),
          '${AppText.get(language, 'account_error_message_prefix')} $registrationError',
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
        await _showResult(AppText.get(language, 'account_created_title'), AppText.get(language, 'account_created_message'));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        return;
      }
      await AuthService.logout();
      setState(() => isSaving = false);
      await _showResult(
        AppText.get(language, 'request_sent_title'),
        AppText.get(language, 'request_sent_message'),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => isSaving = false);
      await _showResult(AppText.get(language, 'account_error_title'), '${AppText.get(language, 'account_error_message_prefix')} $error');
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
            child: Text(AppText.get(widget.languageController.language, 'accept')),
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
        final roleOptions = _roleOptions(language);
        return Scaffold(
          appBar: AppBar(title: Text(AppText.get(language, 'create_account'))),
          body: Form(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppText.get(language, 'name'), border: const OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: AppText.get(language, 'email'), border: const OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: AppText.get(language, 'password'),
                    helperText: AppText.get(language, 'min_password_chars'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: AppText.get(language, hidePassword ? 'show_password' : 'hide_password'),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                      icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_outlined),
                  title: Text(AppText.get(language, 'birth_date')),
                  subtitle: Text(
                    birthDate == null
                        ? AppText.get(language, 'birth_date_required')
                        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDate: birthDate ?? DateTime(DateTime.now().year - 18),
                    );
                    if (selected != null) setState(() => birthDate = selected);
                  },
                ),
                const SizedBox(height: 4),
                TextField(controller: stableCtrl, decoration: InputDecoration(labelText: AppText.get(language, 'stable_name_optional'), border: const OutlineInputBorder())),
                const SizedBox(height: 20),
                Text(AppText.get(language, 'select_roles'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ...roleOptions.entries.map((entry) => CheckboxListTile(
                      value: selectedRoles.contains(entry.key),
                      title: Text(entry.value),
                      onChanged: (selected) => setState(() {
                        if (selected == true) {
                          selectedRoles.add(entry.key);
                        } else {
                          selectedRoles.remove(entry.key);
                        }
                      }),
                    )),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: isSaving ? null : () => _register(language),
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.how_to_reg),
                  label: Text(isSaving ? AppText.get(language, 'saving') : AppText.get(language, 'submit_request')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
