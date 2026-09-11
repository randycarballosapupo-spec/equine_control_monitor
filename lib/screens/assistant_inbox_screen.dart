import 'dart:async';
import 'package:flutter/material.dart';
import '../service/app_language.dart';
import '../service/assistant_service.dart';
import '../service/auth_service.dart';

class AssistantInboxScreen extends StatefulWidget {
  const AssistantInboxScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<AssistantInboxScreen> createState() => _AssistantInboxScreenState();
}

class _AssistantInboxScreenState extends State<AssistantInboxScreen> {
  List<AssistantMessage> messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? subscription;
  final replyController = TextEditingController();
  String? selectedEmail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!await AuthService.isCurrentOwner()) {
      if (mounted) Navigator.pop(context);
      return;
    }
    messages = await AssistantService.ownerMessages();
    subscription = AssistantService.subscribe().listen((rows) {
      if (!mounted) return;
      setState(() => messages = rows.map((row) => AssistantMessage.fromMap(row)).toList());
    });
    if (mounted) setState(() {});
  }

  Future<void> _reply() async {
    final text = replyController.text.trim();
    if (text.isEmpty || selectedEmail == null) return;
    final owner = await AuthService.currentUser();
    if (owner == null) return;
    await AssistantService.send(
      text: text,
      senderName: owner.name,
      senderEmail: owner.email,
      recipientEmail: selectedEmail,
    );
    replyController.clear();
  }

  @override
  void dispose() {
    subscription?.cancel();
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = messages.map((message) => message.senderEmail).where((email) => email != 'creator').toSet().toList();
    final selectedMessages = messages.where((message) =>
        message.senderEmail == selectedEmail || message.recipientEmail == selectedEmail).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes al asistente')),
      body: contacts.isEmpty
          ? const Center(child: Text('Aún no hay mensajes de usuarios.'))
          : Row(
        children: [
          SizedBox(
            width: 150,
            child: ListView(
              children: contacts.map((email) => ListTile(
                selected: email == selectedEmail,
                title: Text(email, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => setState(() => selectedEmail = email),
              )).toList(),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: selectedEmail == null
                      ? const Center(child: Text('Selecciona un contacto de la izquierda.'))
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: selectedMessages.length,
                    itemBuilder: (context, index) => Align(
                      alignment: selectedMessages[index].senderEmail == selectedEmail ? Alignment.centerLeft : Alignment.centerRight,
                      child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(selectedMessages[index].text))),
                    ),
                  ),
                ),
                if (selectedEmail != null)
                  SafeArea(
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: replyController, decoration: const InputDecoration(hintText: 'Responder'))),
                        IconButton(onPressed: _reply, icon: const Icon(Icons.send)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
