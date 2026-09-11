import 'dart:async';
import 'package:flutter/material.dart';
import '../service/app_language.dart';
import '../service/assistant_service.dart';
import '../service/auth_service.dart';

class AssistantContactScreen extends StatefulWidget {
  const AssistantContactScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<AssistantContactScreen> createState() => _AssistantContactScreenState();
}

class _AssistantContactScreenState extends State<AssistantContactScreen> {
  final messageController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  List<AssistantMessage> messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? subscription;
  String senderName = '';
  String senderEmail = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.currentUser();
      if (user?.isOwner == true) {
        if (mounted) Navigator.pushReplacementNamed(context, '/assistant-inbox');
        return;
      }
      senderName = user?.name ?? '';
      senderEmail = user?.email ?? '';
      if (senderEmail.isNotEmpty) {
        messages = await AssistantService.messages(email: senderEmail);
        subscription = AssistantService.subscribe().listen((rows) async {
          if (!mounted) return;
          setState(() {
            messages = rows
                .map((row) => AssistantMessage.fromMap(row))
                .where((message) => message.senderEmail == senderEmail || message.recipientEmail == senderEmail)
                .toList();
          });
        });
      }
    } catch (_) {
      // Si falla la carga (ej. red lenta), se muestra la pantalla vacía en vez de quedar cargando para siempre.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _send() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    if (senderEmail.isEmpty) {
      senderName = nameController.text.trim();
      senderEmail = emailController.text.trim().toLowerCase();
      if (senderName.isEmpty || !senderEmail.contains('@')) return;
    }
    await AssistantService.send(
      text: text,
      senderName: senderName,
      senderEmail: senderEmail,
      recipientEmail: 'creator',
    );
    messageController.clear();
  }

  @override
  void dispose() {
    subscription?.cancel();
    messageController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atención al usuario')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(child: Text('Escribe a Atención al usuario.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return Align(
                              alignment: message.senderEmail == senderEmail ? Alignment.centerRight : Alignment.centerLeft,
                              child: Card(
                                color: message.senderEmail == senderEmail ? Colors.teal.shade50 : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(message.text),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (senderEmail.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Correo'))),
                      ],
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: messageController, decoration: const InputDecoration(hintText: 'Escribe tu mensaje'))),
                        IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
