class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    this.recipientEmail,
    this.deliveredAt,
    this.readAt,
    required this.text,
    this.attachmentUrl,
    this.attachmentType,
    required this.createdAt,
  });

  final String id;
  final String senderName;
  final String senderEmail;
  final String? recipientEmail;
  final String? deliveredAt;
  final String? readAt;
  final String text;
  final String? attachmentUrl;
  final String? attachmentType;
  final String createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: '${map['id'] ?? ''}',
      senderName: '${map['sender_name'] ?? 'Usuario'}',
      senderEmail: '${map['sender_email'] ?? ''}',
      recipientEmail: map['recipient_email'] == null ? null : '${map['recipient_email']}',
      deliveredAt: map['delivered_at'] == null ? null : '${map['delivered_at']}',
      readAt: map['read_at'] == null ? null : '${map['read_at']}',
      text: '${map['text'] ?? ''}',
      attachmentUrl: map['attachment_url'] == null ? null : '${map['attachment_url']}',
      attachmentType: map['attachment_type'] == null ? null : '${map['attachment_type']}',
      createdAt: '${map['created_at'] ?? DateTime.now().toUtc().toIso8601String()}',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sender_name': senderName,
        'sender_email': senderEmail,
        'recipient_email': recipientEmail,
        'delivered_at': deliveredAt,
        'read_at': readAt,
        'text': text,
        'attachment_url': attachmentUrl,
        'attachment_type': attachmentType,
        'created_at': createdAt,
      };

  Map<String, dynamic> toInsertMap() => {
        'sender_name': senderName,
        'sender_email': senderEmail,
        'recipient_email': recipientEmail,
        'delivered_at': deliveredAt,
        'read_at': readAt,
        'text': text,
        'attachment_url': attachmentUrl,
        'attachment_type': attachmentType,
        'created_at': createdAt,
      };
}
