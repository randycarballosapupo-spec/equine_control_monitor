import 'dart:async';

import '../models/chat_message.dart';
import '../service/auth_service.dart';
import '../service/supabase_config.dart';

class ChatService {
  static const _table = 'messages';

  static Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await SupabaseConfig.client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {'name': name.trim()},
    );
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await SupabaseConfig.client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }

  static Future<List<ChatMessage>> fetchMessages() async {
    final currentEmail = SupabaseConfig.client.auth.currentUser?.email?.toLowerCase();
    final response = await SupabaseConfig.client
        .from(_table)
        .select()
        .order('created_at', ascending: true);

    final data = response as List<dynamic>;
    return data
        .map((item) => ChatMessage.fromMap(Map<String, dynamic>.from(item as Map)))
      .where((message) => message.recipientEmail == null ||
        message.senderEmail.toLowerCase() == currentEmail ||
        message.recipientEmail!.toLowerCase() == currentEmail)
        .toList();
  }

  static Future<void> sendMessage({
    required String text,
    String? attachmentUrl,
    String? attachmentType,
    String? recipientEmail,
    ChatMessage? replyTo,
  }) async {
    final supabaseUser = SupabaseConfig.client.auth.currentUser;
    final localUser = await AuthService.currentUser();
    final senderName = supabaseUser?.userMetadata?['name'] ?? localUser?.name ?? 'Usuario';
    final senderEmail = supabaseUser?.email ?? localUser?.email ?? 'unknown@local';

    if (senderEmail == 'unknown@local') {
      throw StateError('Debe iniciar sesión para enviar mensajes.');
    }

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: senderName,
      senderEmail: senderEmail,
      recipientEmail: recipientEmail?.trim().toLowerCase(),
      text: text.trim(),
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      replyToId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSenderName: replyTo?.senderName,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    await SupabaseConfig.client.from(_table).insert(message.toInsertMap());
  }

  static Future<void> deleteMessage(String messageId) async {
    await SupabaseConfig.client.from(_table).delete().eq('id', messageId);
  }

  static Future<void> markRead(Iterable<ChatMessage> messages, String email) async {
    final ids = messages
        .where((message) => message.senderEmail.toLowerCase() != email.toLowerCase() && message.readAt == null)
        .map((message) => message.id);
    for (final id in ids) {
      await SupabaseConfig.client.from(_table).update({'delivered_at': DateTime.now().toUtc().toIso8601String(), 'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
    }
  }

  static Stream<List<Map<String, dynamic>>> subscribe() {
    final stream = SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id']);

    return stream.map((rows) => rows.map((row) => Map<String, dynamic>.from(row)).toList());
  }
}
