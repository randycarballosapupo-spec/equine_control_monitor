import 'package:flutter_test/flutter_test.dart';
import 'package:equine_control_monitor/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('parses a Supabase row into a ChatMessage model', () {
      final message = ChatMessage.fromMap({
        'id': 'abc-1',
        'sender_name': 'Ana',
        'sender_email': 'ana@test.com',
        'text': 'Hola comunidad',
        'attachment_url': null,
        'attachment_type': null,
        'created_at': '2026-09-09T12:00:00.000Z',
      });

      expect(message.id, 'abc-1');
      expect(message.senderName, 'Ana');
      expect(message.text, 'Hola comunidad');
      expect(message.attachmentUrl, isNull);
      expect(message.createdAt.isNotEmpty, isTrue);
    });
  });
}
