import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/chat_message.dart';
import '../models/app_user.dart';
import '../service/access_service.dart';
import '../service/auth_service.dart';
import '../service/chat_service.dart';
import '../service/app_language.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  List<ChatMessage> messages = [];
  bool allowed = false;
  bool isRecording = false;
  bool canModerate = false;
  String? currentEmail;
  String? privateRecipientEmail;
  ChatMessage? replyToMessage;
  List<AppUser> availableUsers = [];
  StreamSubscription<List<Map<String, dynamic>>>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    allowed = await AccessService.canUseChat();
    final current = await AuthService.currentUser();
    currentEmail = current?.email;
    canModerate = current?.isAdmin == true || current?.isOwner == true;
    availableUsers = await AuthService.users();
    if (!allowed) {
      if (mounted) setState(() {});
      return;
    }

    try {
      final remoteMessages = await ChatService.fetchMessages();
      if (mounted) {
        setState(() => messages = remoteMessages);
        if (currentEmail != null) await ChatService.markRead(remoteMessages, currentEmail!);
      }
    } catch (_) {
      if (mounted) {
        setState(() => messages = const []);
      }
    }

    _chatSubscription ??= ChatService.subscribe().listen((rows) {
      if (!mounted) return;
      final nextMessages = rows
          .map((row) => ChatMessage.fromMap(row))
          .where((message) => message.recipientEmail == null ||
            message.senderEmail.toLowerCase() == currentEmail?.toLowerCase() ||
            message.recipientEmail!.toLowerCase() == currentEmail?.toLowerCase())
          .toList();
      setState(() => messages = nextMessages);
    });

    if (mounted) setState(() {});
  }

  Future<void> _send({String? attachment, String? attachmentType}) async {
    final text = messageController.text.trim();
    if (text.isEmpty && attachment == null) return;

    try {
      await ChatService.sendMessage(
        text: text,
        attachmentUrl: attachment,
        attachmentType: attachmentType,
        recipientEmail: privateRecipientEmail,
        replyTo: replyToMessage,
      );
      messageController.clear();
      replyToMessage = null;
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      final language = widget.languageController.language;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppText.translate(language, 'send_message_error')} $error')),
      );
    }
  }

  Future<void> _choosePrivateRecipient(AppLanguage language) async {
    final recipient = await showModalBottomSheet<AppUser>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(AppText.translate(language, 'chat_community')),
              leading: const Icon(Icons.groups),
              onTap: () => Navigator.pop(sheetContext),
            ),
            ...availableUsers
                .where((user) => user.email != currentEmail)
                .map((user) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      onTap: () => Navigator.pop(sheetContext, user),
                    )),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => privateRecipientEmail = recipient?.email);
  }

  Future<void> _deleteMessage(ChatMessage message, AppLanguage language) async {
    final isOwn = message.senderEmail.toLowerCase() == currentEmail?.toLowerCase();
    if (!isOwn && !canModerate) return;
    await ChatService.deleteMessage(message.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppText.translate(language, 'message_deleted'))));
  }

  void _replyTo(ChatMessage message) {
    setState(() {
      replyToMessage = message;
      privateRecipientEmail = message.senderEmail.toLowerCase() == currentEmail?.toLowerCase() ? privateRecipientEmail : message.senderEmail;
    });
  }

  Future<void> _forward(ChatMessage message, AppLanguage language) async {
    await _choosePrivateRecipient(language);
    if (privateRecipientEmail == null) return;
    await ChatService.sendMessage(
      text: '${AppText.translate(language, 'forwarded')}: ${message.text}',
      attachmentUrl: message.attachmentUrl,
      attachmentType: message.attachmentType,
      recipientEmail: privateRecipientEmail,
    );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles(type: FileType.media);
    if (result.isEmpty) return;
    final file = result.first;
    final extension = file.extension?.toLowerCase() ?? '';
    final type = ['mp4', 'mov', 'avi', 'webm'].contains(extension) ? 'video' : 'image';
    await _send(attachment: file.path ?? file.name, attachmentType: type);
  }

  Future<void> _toggleRecording() async {
    if (isRecording) {
      final path = await recorder.stop();
      if (mounted) setState(() => isRecording = false);
      if (path != null) await _send(attachment: path, attachmentType: 'voice');
      return;
    }
    if (!await recorder.hasPermission()) return;
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await recorder.start(const RecordConfig(), path: path);
    if (mounted) setState(() => isRecording = true);
  }

  Future<void> _playVoice(String path) async {
    await player.stop();
    await player.play(DeviceFileSource(path));
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    messageController.dispose();
    recorder.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        if (!allowed) {
          return Scaffold(
            appBar: AppBar(title: Text(AppText.translate(language, 'chat'))),
            body: Center(child: Text(AppText.translate(language, 'chat_access_required'))),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              privateRecipientEmail == null
                  ? AppText.translate(language, 'chat_community')
                  : '${AppText.translate(language, 'private_message')} ${privateRecipientEmail!}',
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: AppText.translate(language, 'private_message'),
                onPressed: () => _choosePrivateRecipient(language),
                icon: const Icon(Icons.person_search),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final attachment = message.attachmentUrl ?? '';
                    final own = message.senderEmail.toLowerCase() == currentEmail?.toLowerCase();
                    return GestureDetector(
                      onLongPress: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (sheetContext) => SafeArea(child: Wrap(children: [
                          ListTile(leading: const Icon(Icons.reply), title: Text(AppText.translate(language, 'reply')), onTap: () { Navigator.pop(sheetContext); _replyTo(message); }),
                          ListTile(leading: const Icon(Icons.forward), title: Text(AppText.translate(language, 'forward')), onTap: () { Navigator.pop(sheetContext); _forward(message, language); }),
                          if (own || canModerate) ListTile(leading: const Icon(Icons.delete_outline), title: Text(AppText.translate(language, 'delete')), onTap: () { Navigator.pop(sheetContext); _deleteMessage(message, language); }),
                        ])),
                      ),
                      child: Align(
                      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 330),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                        decoration: BoxDecoration(color: own ? Colors.teal.shade50 : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: GestureDetector(
                          onTap: () {
                            final matches = availableUsers.where((user) => user.email == message.senderEmail).toList();
                            final target = matches.isEmpty ? null : matches.first;
                            if (target != null) setState(() => privateRecipientEmail = target.email);
                          },
                          child: Text(message.senderName),
                        )),
                        if (own) Text(message.readAt != null ? '✓✓' : message.deliveredAt != null ? '✓✓' : '✓', style: TextStyle(color: message.readAt != null ? Colors.orange : Colors.grey)),
                        if (own || canModerate)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (value) { if (value == 'delete') _deleteMessage(message, language); },
                            itemBuilder: (context) => [PopupMenuItem(value: 'delete', child: Text(AppText.translate(language, 'delete')))],
                          ),
                          ]),
                          if (message.replyToId != null) Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                            child: Text('${message.replyToSenderName ?? ''}: ${message.replyToText ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          if (message.text.isNotEmpty) Text(message.text),
                          if (attachment.isNotEmpty && message.attachmentType == 'voice') OutlinedButton.icon(onPressed: () => _playVoice(attachment), icon: const Icon(Icons.play_arrow), label: Text(AppText.translate(language, 'play_voice_message'))),
                          if (attachment.isNotEmpty && message.attachmentType != 'voice') Text('${AppText.translate(language, message.attachmentType == 'video' ? 'video_label' : 'photo_label')}: $attachment', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ]),
                      ),
                    ));
                    /* return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: GestureDetector(
                          onTap: () {
                            final matches = availableUsers.where((user) => user.email == message.senderEmail).toList();
                            final target = matches.isEmpty ? null : matches.first;
                            if (target != null) setState(() => privateRecipientEmail = target.email);
                          },
                          child: Text(message.senderName),
                        ),
                        trailing: (message.senderEmail.toLowerCase() == currentEmail?.toLowerCase() || canModerate)
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') _deleteMessage(message, language);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'delete', child: Text(AppText.translate(language, 'delete'))),
                                ],
                              )
                            : null,
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.text.isNotEmpty) Text(message.text),
                            if (attachment.isNotEmpty)
                              if (message.attachmentType == 'voice')
                                OutlinedButton.icon(
                                  onPressed: () => _playVoice(attachment),
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(AppText.translate(language, 'play_voice_message')),
                                )
                              else
                                Text(
                                  '${AppText.translate(language, message.attachmentType == 'video' ? 'video_label' : 'photo_label')}: $attachment',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                          ],
                        ),
                      ),
                    ); */
                  },
                ),
              ),
              SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (replyToMessage != null) ListTile(
                    dense: true,
                    leading: const Icon(Icons.reply),
                    title: Text('${replyToMessage!.senderName}: ${replyToMessage!.text}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(onPressed: () => setState(() => replyToMessage = null), icon: const Icon(Icons.close)),
                  ),
                  Row(children: [
                    IconButton(
                      tooltip: AppText.translate(language, 'photo_or_video'),
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.attach_file),
                    ),
                    IconButton(
                      tooltip: AppText.translate(language, isRecording ? 'stop_recording' : 'record_voice'),
                      onPressed: _toggleRecording,
                      color: isRecording ? Colors.red : null,
                      icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    ),
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(hintText: AppText.translate(language, 'write_message_hint')),
                      ),
                    ),
                    IconButton(
                      tooltip: AppText.translate(language, 'send'),
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                    ),
                  ]),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
