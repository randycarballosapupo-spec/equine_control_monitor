import 'supabase_config.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.senderEmail,
    required this.senderName,
    required this.recipientEmail,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderEmail;
  final String senderName;
  final String? recipientEmail;
  final String text;
  final String createdAt;

  factory AssistantMessage.fromMap(Map<String, dynamic> row) => AssistantMessage(
        id: '${row['id'] ?? ''}',
        senderEmail: '${row['sender_email'] ?? ''}',
        senderName: '${row['sender_name'] ?? 'Usuario'}',
        recipientEmail: row['recipient_email'] == null ? null : '${row['recipient_email']}',
        text: '${row['text'] ?? ''}',
        createdAt: '${row['created_at'] ?? ''}',
      );
}

class AssistantService {
  const AssistantService._();

  static const _table = 'assistant_messages';
  static dynamic get _client => SupabaseConfig.client;

  static Future<List<AssistantMessage>> messages({String? email}) async {
    final current = _client.auth.currentUser;
    final filterEmail = email ?? current?.email;
    if (filterEmail == null) return [];
    final rows = await _client
        .from(_table)
        .select()
        .or('sender_email.eq.$filterEmail,recipient_email.eq.$filterEmail')
        .order('created_at');
    return (rows as List)
        .map((row) => AssistantMessage.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Future<List<AssistantMessage>> ownerMessages() async {
    final rows = await _client.from(_table).select().order('created_at');
    return (rows as List)
        .map((row) => AssistantMessage.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Future<void> send({
    required String text,
    required String senderName,
    required String senderEmail,
    String? recipientEmail,
  }) async {
    await _client.from(_table).insert({
      'sender_id': _client.auth.currentUser?.id,
      'sender_email': senderEmail.trim().toLowerCase(),
      'sender_name': senderName.trim(),
      'recipient_email': recipientEmail?.trim().toLowerCase(),
      'text': text.trim(),
    });
  }

  static Stream<List<Map<String, dynamic>>> subscribe() => _client
      .from(_table)
      .stream(primaryKey: ['id'])
      .map((rows) => rows.map((row) => Map<String, dynamic>.from(row)).toList());
}
